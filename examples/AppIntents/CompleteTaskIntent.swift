import AppIntents
import SwiftData

/// 完成任务 Intent
struct CompleteTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "完成任务"
    static var description = IntentDescription("将指定任务标记为已完成")

    // 参数
    @Parameter(title: "任务")
    var task: TaskEntity

    static var parameterSummary: some ParameterSummary {
        Summary("完成任务 \(\.$task)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let container = ModelContainerProvider.shared.container else {
            throw IntentError.containerNotAvailable
        }

        let context = ModelContext(container)

        // 查找任务
        guard let uuid = UUID(uuidString: task.id) else {
            throw IntentError.invalidParameter
        }

        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate { $0.id == uuid }
        )

        let tasks = try context.fetch(descriptor)

        guard let taskToComplete = tasks.first else {
            throw IntentError.invalidParameter
        }

        // 标记为完成
        taskToComplete.markAsCompleted()
        try context.save()

        return .result(dialog: "已完成任务「\(taskToComplete.title)」")
    }
}
