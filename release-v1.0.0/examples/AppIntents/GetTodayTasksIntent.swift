import AppIntents
import SwiftData
import Foundation

/// 获取今日任务 Intent
struct GetTodayTasksIntent: AppIntent {
    static var title: LocalizedStringResource = "获取今日任务"
    static var description = IntentDescription("获取今天到期的任务列表")

    @Parameter(title: "包含已完成", default: false)
    var includeCompleted: Bool

    static var parameterSummary: some ParameterSummary {
        Summary("获取今日任务") {
            \.$includeCompleted
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<[TaskEntity]> & ProvidesDialog {
        guard let container = ModelContainerProvider.shared.container else {
            throw IntentError.containerNotAvailable
        }

        let context = ModelContext(container)

        // 获取今天的日期范围
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        // 构建查询
        var descriptor: FetchDescriptor<Task>

        if includeCompleted {
            descriptor = FetchDescriptor<Task>(
                predicate: #Predicate { task in
                    guard let dueDate = task.dueDate else { return false }
                    return dueDate >= today && dueDate < tomorrow
                }
            )
        } else {
            descriptor = FetchDescriptor<Task>(
                predicate: #Predicate { task in
                    guard let dueDate = task.dueDate else { return false }
                    return dueDate >= today && dueDate < tomorrow && !task.isCompleted
                }
            )
        }

        descriptor.sortBy = [SortDescriptor(\.dueDate)]

        let tasks = try context.fetch(descriptor)

        // 转换为 Entity
        let taskEntities = tasks.map { task in
            TaskEntity(
                id: task.id.uuidString,
                title: task.title,
                isCompleted: task.isCompleted,
                priority: task.priority ?? "普通",
                dueDate: task.dueDate,
                tags: task.tags
            )
        }

        // 构建消息
        let message: String
        if taskEntities.isEmpty {
            message = "今天没有到期的任务"
        } else {
            let completedCount = taskEntities.filter { $0.isCompleted }.count
            let pendingCount = taskEntities.count - completedCount

            var lines = ["今日任务 (共 \(taskEntities.count) 项):"]

            if pendingCount > 0 {
                lines.append("\n待办 (\(pendingCount)):")
                taskEntities.filter { !$0.isCompleted }.forEach { task in
                    let priorityMark = task.priority == "紧急" || task.priority == "高" ? "❗️" : "•"
                    lines.append("\(priorityMark) \(task.title)")
                }
            }

            if includeCompleted && completedCount > 0 {
                lines.append("\n已完成 (\(completedCount)):")
                taskEntities.filter { $0.isCompleted }.forEach { task in
                    lines.append("✓ \(task.title)")
                }
            }

            message = lines.joined(separator: "\n")
        }

        return .result(value: taskEntities, dialog: message)
    }
}
