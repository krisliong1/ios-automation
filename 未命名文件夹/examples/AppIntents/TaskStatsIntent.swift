import AppIntents
import SwiftData
import Foundation

/// 任务统计 Intent
struct TaskStatsIntent: AppIntent {
    static var title: LocalizedStringResource = "任务统计"
    static var description = IntentDescription("获取任务完成情况的统计信息")

    @Parameter(title: "时间范围", default: .week)
    var timeRange: TimeRangeOption

    static var parameterSummary: some ParameterSummary {
        Summary("任务统计") {
            \.$timeRange
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let container = ModelContainerProvider.shared.container else {
            throw IntentError.containerNotAvailable
        }

        let context = ModelContext(container)

        // 获取所有任务
        let allTasks = try context.fetch(FetchDescriptor<Task>())

        // 根据时间范围过滤
        let startDate = getStartDate(for: timeRange)
        let tasksInRange = allTasks.filter { task in
            task.createdAt >= startDate
        }

        // 统计数据
        let total = tasksInRange.count
        let completed = tasksInRange.filter { $0.isCompleted }.count
        let pending = total - completed
        let overdue = tasksInRange.filter { $0.isOverdue }.count

        // 按优先级统计
        let urgent = tasksInRange.filter { $0.priority == "紧急" }.count
        let high = tasksInRange.filter { $0.priority == "高" }.count

        // 完成率
        let completionRate = total > 0 ? Int(Double(completed) / Double(total) * 100) : 0

        // 今日完成
        let todayStart = Calendar.current.startOfDay(for: Date())
        let todayCompleted = tasksInRange.filter { task in
            guard let completedAt = task.completedAt else { return false }
            return completedAt >= todayStart
        }.count

        // 构建消息
        let timeRangeName = timeRange.rawValue
        let message = """
        📊 任务统计报告 (\(timeRangeName))

        📈 总览
        • 总任务: \(total)
        • 已完成: \(completed)
        • 待办: \(pending)
        • 逾期: \(overdue)

        ⚡️ 优先级
        • 紧急: \(urgent)
        • 高: \(high)

        🎯 完成情况
        • 完成率: \(completionRate)%
        • 今日完成: \(todayCompleted)

        \(getEncouragement(completionRate: completionRate))
        """

        return .result(dialog: message)
    }

    private func getStartDate(for range: TimeRangeOption) -> Date {
        let calendar = Calendar.current
        let now = Date()

        switch range {
        case .today:
            return calendar.startOfDay(for: now)
        case .week:
            return calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            return calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .all:
            return Date.distantPast
        }
    }

    private func getEncouragement(completionRate: Int) -> String {
        switch completionRate {
        case 90...100:
            return "🌟 太棒了！继续保持！"
        case 70..<90:
            return "👍 做得很好！"
        case 50..<70:
            return "💪 继续加油！"
        default:
            return "🎯 相信自己，一步一步来！"
        }
    }
}

/// 时间范围选项
enum TimeRangeOption: String, AppEnum {
    case today = "今天"
    case week = "本周"
    case month = "本月"
    case all = "全部"

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "时间范围")

    static var caseDisplayRepresentations: [TimeRangeOption: DisplayRepresentation] = [
        .today: "今天",
        .week: "本周",
        .month: "本月",
        .all: "全部时间"
    ]
}
