import AppIntents
import SwiftData

/// 添加任务 Intent - 快捷指令可调用
struct AddTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "添加任务"
    static var description = IntentDescription("快速添加新任务到任务列表")

    // 参数定义
    @Parameter(title: "任务标题", requestValueDialog: "这个任务叫什么？")
    var taskTitle: String

    @Parameter(title: "优先级", default: .normal)
    var priority: TaskPriority

    @Parameter(title: "截止日期")
    var dueDate: Date?

    @Parameter(title: "标签")
    var tags: [String]?

    // 参数摘要 - 在快捷指令中显示
    static var parameterSummary: some ParameterSummary {
        Summary("添加任务 \(\.$taskTitle)") {
            \.$priority
            \.$dueDate
            \.$tags
        }
    }

    // 执行逻辑
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // 获取数据容器
        guard let container = ModelContainerProvider.shared.container else {
            throw IntentError.containerNotAvailable
        }

        let context = ModelContext(container)

        // 创建任务
        let task = Task(title: taskTitle)
        task.priority = priority.rawValue
        task.dueDate = dueDate
        task.tags = tags ?? []
        task.createdAt = Date()

        // 保存到数据库
        context.insert(task)
        try context.save()

        // 构建返回消息
        var message = "已添加任务「\(taskTitle)」"

        if let dueDate = dueDate {
            message += "\n截止日期：\(dueDate.formatted(date: .abbreviated, time: .shortened))"
        }

        if priority != .normal {
            message += "\n优先级：\(priority.rawValue)"
        }

        return .result(dialog: message)
    }
}

/// 优先级枚举
enum TaskPriority: String, AppEnum {
    case low = "低"
    case normal = "普通"
    case high = "高"
    case urgent = "紧急"

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "优先级")

    static var caseDisplayRepresentations: [TaskPriority: DisplayRepresentation] = [
        .low: DisplayRepresentation(title: "低", subtitle: "不着急"),
        .normal: DisplayRepresentation(title: "普通", subtitle: "正常处理"),
        .high: DisplayRepresentation(title: "高", subtitle: "重要"),
        .urgent: DisplayRepresentation(title: "紧急", subtitle: "立即处理")
    ]
}

/// Intent 错误定义
enum IntentError: Error, LocalizedError, CustomLocalizedStringResourceConvertible {
    case containerNotAvailable
    case saveFailed
    case invalidParameter

    var errorDescription: String? {
        switch self {
        case .containerNotAvailable:
            return "数据容器不可用"
        case .saveFailed:
            return "保存失败"
        case .invalidParameter:
            return "参数无效"
        }
    }

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .containerNotAvailable:
            return "数据容器不可用，请重启应用"
        case .saveFailed:
            return "保存任务失败，请重试"
        case .invalidParameter:
            return "提供的参数无效"
        }
    }
}

/// 数据容器提供者（单例）
class ModelContainerProvider: @unchecked Sendable {
    static let shared = ModelContainerProvider()
    var container: ModelContainer?

    private init() {}
}
