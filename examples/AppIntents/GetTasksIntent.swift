import AppIntents
import SwiftData

/// 获取任务列表 Intent
struct GetTasksIntent: AppIntent {
    static var title: LocalizedStringResource = "获取任务列表"
    static var description = IntentDescription("获取未完成的任务")

    @Parameter(title: "只显示重要任务", default: false)
    var onlyImportant: Bool

    @Parameter(title: "最多显示数量", default: 10)
    var limit: Int

    @Parameter(title: "包含已完成", default: false)
    var includeCompleted: Bool

    static var parameterSummary: some ParameterSummary {
        Summary("获取任务列表") {
            \.$onlyImportant
            \.$limit
            \.$includeCompleted
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<[TaskEntity]> & ProvidesDialog {
        guard let container = ModelContainerProvider.shared.container else {
            throw IntentError.containerNotAvailable
        }

        let context = ModelContext(container)

        // 构建查询
        var descriptor = FetchDescriptor<Task>()

        // 设置过滤条件
        if !includeCompleted {
            descriptor.predicate = #Predicate { !$0.isCompleted }
        }

        if onlyImportant {
            descriptor.predicate = #Predicate { task in
                !task.isCompleted && (task.priority == "高" || task.priority == "紧急")
            }
        }

        // 设置排序
        descriptor.sortBy = [SortDescriptor(\.createdAt, order: .reverse)]

        // 设置数量限制
        descriptor.fetchLimit = limit

        // 执行查询
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
            message = "暂无任务"
        } else {
            let taskList = taskEntities.prefix(5).map { "• \($0.title)" }.joined(separator: "\n")
            message = "共 \(taskEntities.count) 个任务:\n\(taskList)" +
                     (taskEntities.count > 5 ? "\n..." : "")
        }

        return .result(value: taskEntities, dialog: message)
    }
}

/// 任务 Entity - 用于 Intent 返回
struct TaskEntity: AppEntity {
    var id: String
    var title: String
    var isCompleted: Bool
    var priority: String
    var dueDate: Date?
    var tags: [String]

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "任务")

    var displayRepresentation: DisplayRepresentation {
        let subtitle: String
        if isCompleted {
            subtitle = "✅ 已完成"
        } else if let dueDate = dueDate {
            subtitle = "📅 \(dueDate.formatted(date: .abbreviated, time: .omitted))"
        } else {
            subtitle = priority
        }

        return DisplayRepresentation(
            title: "\(title)",
            subtitle: "\(subtitle)"
        )
    }

    static var defaultQuery = TaskEntityQuery()
}

/// 任务查询 - 用于 Siri 等场景
struct TaskEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [TaskEntity] {
        guard let container = ModelContainerProvider.shared.container else {
            return []
        }

        let context = ModelContext(container)
        let uuids = identifiers.compactMap { UUID(uuidString: $0) }

        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate { task in
                uuids.contains(task.id)
            }
        )

        let tasks = try context.fetch(descriptor)

        return tasks.map { task in
            TaskEntity(
                id: task.id.uuidString,
                title: task.title,
                isCompleted: task.isCompleted,
                priority: task.priority ?? "普通",
                dueDate: task.dueDate,
                tags: task.tags
            )
        }
    }
}
