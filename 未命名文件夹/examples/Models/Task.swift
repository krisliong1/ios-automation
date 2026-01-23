import Foundation
import SwiftData

/// 任务数据模型
@Model
class Task {
    /// 唯一标识符
    var id: UUID

    /// 任务标题
    var title: String

    /// 是否已完成
    var isCompleted: Bool

    /// 优先级
    var priority: String?

    /// 截止日期
    var dueDate: Date?

    /// 标签
    var tags: [String]

    /// 创建时间
    var createdAt: Date

    /// 完成时间
    var completedAt: Date?

    /// 备注
    var notes: String?

    /// 初始化
    init(title: String, priority: String? = nil, dueDate: Date? = nil, tags: [String] = []) {
        self.id = UUID()
        self.title = title
        self.isCompleted = false
        self.priority = priority
        self.dueDate = dueDate
        self.tags = tags
        self.createdAt = Date()
        self.notes = nil
    }

    /// 标记为完成
    func markAsCompleted() {
        isCompleted = true
        completedAt = Date()
    }

    /// 标记为未完成
    func markAsIncomplete() {
        isCompleted = false
        completedAt = nil
    }

    /// 是否逾期
    var isOverdue: Bool {
        guard let dueDate = dueDate, !isCompleted else {
            return false
        }
        return dueDate < Date()
    }

    /// 是否今天到期
    var isDueToday: Bool {
        guard let dueDate = dueDate else {
            return false
        }
        return Calendar.current.isDateInToday(dueDate)
    }

    /// 剩余天数
    var daysUntilDue: Int? {
        guard let dueDate = dueDate else {
            return nil
        }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: dueDate)
        return components.day
    }
}

/// 任务优先级枚举（可选使用）
enum TaskPriorityLevel: String, Codable {
    case low = "低"
    case normal = "普通"
    case high = "高"
    case urgent = "紧急"

    var color: String {
        switch self {
        case .low: return "gray"
        case .normal: return "blue"
        case .high: return "orange"
        case .urgent: return "red"
        }
    }

    var sortOrder: Int {
        switch self {
        case .urgent: return 0
        case .high: return 1
        case .normal: return 2
        case .low: return 3
        }
    }
}
