import Foundation
import SwiftData

/// AI Fixer 学习和优化系统
/// 持久化学习数据，不断优化解决方案
@available(iOS 17.0, macOS 14.0, *)
@MainActor
class AIFixerLearningSystem: ObservableObject {

    // MARK: - Published Properties

    @Published var learningEntries: [LearningEntry] = []
    @Published var statistics: LearningStatistics?

    // MARK: - Private Properties

    private var modelContainer: ModelContainer?
    private var modelContext: ModelContext?

    // MARK: - Initialization

    init() {
        setupPersistence()
        loadLearningData()
        updateStatistics()
    }

    // MARK: - Persistence Setup

    private func setupPersistence() {
        do {
            let schema = Schema([
                PersistentLearningEntry.self
            ])

            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )

            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )

            if let container = modelContainer {
                modelContext = ModelContext(container)
            }

            print("📚 学习系统持久化已初始化")
        } catch {
            print("❌ 学习系统初始化失败: \(error)")
        }
    }

    // MARK: - Learning Data Management

    /// 保存学习数据
    func saveLearningEntry(_ entry: LearningEntry) {
        // 添加到内存
        learningEntries.append(entry)

        // 保存到持久化存储
        guard let context = modelContext else { return }

        let persistentEntry = PersistentLearningEntry(from: entry)
        context.insert(persistentEntry)

        do {
            try context.save()
            print("📚 学习数据已保存: \(entry.problem.category.rawValue)")
            updateStatistics()
        } catch {
            print("❌ 保存学习数据失败: \(error)")
        }
    }

    /// 加载学习数据
    func loadLearningData() {
        guard let context = modelContext else { return }

        let descriptor = FetchDescriptor<PersistentLearningEntry>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        do {
            let entries = try context.fetch(descriptor)
            learningEntries = entries.map { $0.toLearningEntry() }

            print("📚 已加载 \(learningEntries.count) 条学习数据")
        } catch {
            print("❌ 加载学习数据失败: \(error)")
        }
    }

    /// 清理旧数据
    func cleanupOldData(olderThan days: Int = 90) {
        guard let context = modelContext else { return }

        let cutoffDate = Date().addingTimeInterval(-Double(days * 24 * 60 * 60))

        let descriptor = FetchDescriptor<PersistentLearningEntry>(
            predicate: #Predicate { $0.timestamp < cutoffDate }
        )

        do {
            let oldEntries = try context.fetch(descriptor)

            for entry in oldEntries {
                context.delete(entry)
            }

            try context.save()

            print("📚 已清理 \(oldEntries.count) 条旧数据")

            loadLearningData()
            updateStatistics()
        } catch {
            print("❌ 清理数据失败: \(error)")
        }
    }

    // MARK: - Statistics

    /// 更新统计信息
    func updateStatistics() {
        let totalProblems = learningEntries.count
        let successfulFixes = learningEntries.filter { $0.wasSuccessful }.count
        let failedFixes = totalProblems - successfulFixes

        let successRate = totalProblems > 0
            ? Double(successfulFixes) / Double(totalProblems)
            : 0.0

        // 按类别统计
        var categoryStats: [ProblemCategory: CategoryStatistics] = [:]

        for category in ProblemCategory.allCases {
            let categoryEntries = learningEntries.filter { $0.problem.category == category }
            let successCount = categoryEntries.filter { $0.wasSuccessful }.count

            if !categoryEntries.isEmpty {
                categoryStats[category] = CategoryStatistics(
                    totalCount: categoryEntries.count,
                    successCount: successCount,
                    successRate: Double(successCount) / Double(categoryEntries.count)
                )
            }
        }

        // 最常见问题
        let problemCounts = Dictionary(grouping: learningEntries) { $0.problem.category }
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }

        let mostCommonProblems = problemCounts.prefix(5).map {
            MostCommonProblem(category: $0.key, count: $0.value)
        }

        // 最成功的解决方案来源
        let successfulSources = learningEntries
            .filter { $0.wasSuccessful }
            .map { $0.solution.source }

        let sourceCounts = Dictionary(grouping: successfulSources) { $0 }
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }

        let topSources = sourceCounts.prefix(5).map {
            TopSource(source: $0.key, count: $0.value)
        }

        statistics = LearningStatistics(
            totalProblems: totalProblems,
            successfulFixes: successfulFixes,
            failedFixes: failedFixes,
            successRate: successRate,
            categoryStatistics: categoryStats,
            mostCommonProblems: mostCommonProblems,
            topSources: topSources
        )
    }

    // MARK: - Query Methods

    /// 查找相似问题的成功解决方案
    func findSimilarSuccessfulSolutions(for problem: Problem) -> [Solution] {
        let similarEntries = learningEntries.filter {
            $0.problem.category == problem.category &&
            $0.wasSuccessful &&
            // 检查关键词重叠
            !Set($0.problem.keywords).intersection(problem.keywords).isEmpty
        }

        return similarEntries.map { $0.solution }
    }

    /// 获取某个类别的最佳解决方案
    func getBestSolutionForCategory(_ category: ProblemCategory) -> Solution? {
        let successfulEntries = learningEntries.filter {
            $0.problem.category == category && $0.wasSuccessful
        }

        // 按置信度排序
        return successfulEntries
            .map { $0.solution }
            .max { $0.confidence < $1.confidence }
    }

    /// 获取最成功的搜索源
    func getMostSuccessfulSources(limit: Int = 5) -> [String] {
        let successfulSources = learningEntries
            .filter { $0.wasSuccessful }
            .map { $0.solution.source }

        let sourceCounts = Dictionary(grouping: successfulSources) { $0 }
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }

        return Array(sourceCounts.prefix(limit).map { $0.key })
    }

    /// 优化搜索查询（基于历史成功）
    func optimizeSearchQuery(for problem: Problem) -> String {
        var query = problem.description

        // 从历史成功案例中学习关键词
        let similarSuccessful = learningEntries.filter {
            $0.problem.category == problem.category && $0.wasSuccessful
        }

        if let mostSuccessful = similarSuccessful.first {
            // 添加成功案例的关键词
            let successKeywords = mostSuccessful.problem.keywords
            for keyword in successKeywords {
                if !query.contains(keyword) {
                    query += " \(keyword)"
                }
            }
        }

        // 添加年份
        let year = Calendar.current.component(.year, from: Date())
        query += " \(year)"

        return query
    }

    // MARK: - Export & Import

    /// 导出学习数据（用于备份）
    func exportLearningData() -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        do {
            let data = try encoder.encode(learningEntries)
            print("📤 学习数据已导出 (\(data.count) 字节)")
            return data
        } catch {
            print("❌ 导出失败: \(error)")
            return nil
        }
    }

    /// 导入学习数据（从备份恢复）
    func importLearningData(from data: Data) {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let entries = try decoder.decode([LearningEntry].self, from: data)

            // 合并到现有数据
            for entry in entries {
                saveLearningEntry(entry)
            }

            print("📥 已导入 \(entries.count) 条学习数据")
        } catch {
            print("❌ 导入失败: \(error)")
        }
    }

    /// 生成学习报告
    func generateReport() -> String {
        guard let stats = statistics else {
            return "📊 暂无统计数据"
        }

        var report = """
        📊 Kris AI Fixer 学习报告
        =========================

        总体统计
        --------
        总问题数: \(stats.totalProblems)
        成功修复: \(stats.successfulFixes)
        失败修复: \(stats.failedFixes)
        成功率: \(String(format: "%.1f%%", stats.successRate * 100))

        """

        // 最常见问题
        if !stats.mostCommonProblems.isEmpty {
            report += "\n最常见问题\n----------\n"
            for (index, problem) in stats.mostCommonProblems.enumerated() {
                report += "\(index + 1). \(problem.category.rawValue) (\(problem.count) 次)\n"
            }
        }

        // 最佳解决方案来源
        if !stats.topSources.isEmpty {
            report += "\n最成功的解决方案来源\n------------------\n"
            for (index, source) in stats.topSources.enumerated() {
                report += "\(index + 1). \(source.source) (\(source.count) 次)\n"
            }
        }

        // 按类别统计
        report += "\n按类别统计\n----------\n"
        for (category, catStats) in stats.categoryStatistics.sorted(by: { $0.value.totalCount > $1.value.totalCount }) {
            report += """
            \(category.rawValue):
              - 总数: \(catStats.totalCount)
              - 成功: \(catStats.successCount)
              - 成功率: \(String(format: "%.1f%%", catStats.successRate * 100))

            """
        }

        return report
    }
}

// MARK: - SwiftData Models

/// 持久化学习条目（用于 SwiftData）
@available(iOS 17.0, macOS 14.0, *)
@Model
final class PersistentLearningEntry {
    var id: UUID
    var problemDescription: String
    var problemCategory: String
    var solutionTitle: String
    var solutionSource: String
    var wasSuccessful: Bool
    var timestamp: Date

    init(
        id: UUID,
        problemDescription: String,
        problemCategory: String,
        solutionTitle: String,
        solutionSource: String,
        wasSuccessful: Bool,
        timestamp: Date
    ) {
        self.id = id
        self.problemDescription = problemDescription
        self.problemCategory = problemCategory
        self.solutionTitle = solutionTitle
        self.solutionSource = solutionSource
        self.wasSuccessful = wasSuccessful
        self.timestamp = timestamp
    }

    convenience init(from entry: LearningEntry) {
        self.init(
            id: UUID(),
            problemDescription: entry.problem.description,
            problemCategory: entry.problem.category.rawValue,
            solutionTitle: entry.solution.title,
            solutionSource: entry.solution.source,
            wasSuccessful: entry.wasSuccessful,
            timestamp: entry.timestamp
        )
    }

    func toLearningEntry() -> LearningEntry {
        // 简化的转换（实际使用中需要完整的数据）
        let problem = Problem(
            id: UUID(),
            description: problemDescription,
            category: ProblemCategory(rawValue: problemCategory) ?? .unknown,
            severity: .medium,
            keywords: [],
            requiresCustomCode: false,
            detectedAt: timestamp,
            context: [:]
        )

        let solution = Solution(
            id: UUID(),
            title: solutionTitle,
            description: "",
            steps: [],
            code: [],
            source: solutionSource,
            confidence: 0.8,
            estimatedTime: 10,
            requiresManualIntervention: false
        )

        return LearningEntry(
            problem: problem,
            solution: solution,
            wasSuccessful: wasSuccessful,
            timestamp: timestamp
        )
    }
}

// MARK: - Statistics Models

/// 学习统计
struct LearningStatistics {
    let totalProblems: Int
    let successfulFixes: Int
    let failedFixes: Int
    let successRate: Double
    let categoryStatistics: [ProblemCategory: CategoryStatistics]
    let mostCommonProblems: [MostCommonProblem]
    let topSources: [TopSource]
}

/// 类别统计
struct CategoryStatistics {
    let totalCount: Int
    let successCount: Int
    let successRate: Double
}

/// 最常见问题
struct MostCommonProblem {
    let category: ProblemCategory
    let count: Int
}

/// 最佳来源
struct TopSource {
    let source: String
    let count: Int
}

// MARK: - ProblemCategory Extension

extension ProblemCategory: CaseIterable {
    static var allCases: [ProblemCategory] {
        [
            .xcodeIssue,
            .xcodeVMDetection,
            .compilationError,
            .certificateIssue,
            .permissionIssue,
            .networkIssue,
            .dependencyIssue,
            .performanceIssue,
            .crashIssue,
            .iCloudIssue,
            .bluetoothIssue,
            .unknown
        ]
    }
}

// MARK: - Legacy Persistence (iOS 16 / macOS 13)

/// 用于 iOS 16 / macOS 13 的简单持久化
@available(iOS 16.0, macOS 13.0, *)
class LegacyLearningPersistence {

    private let fileURL: URL

    init() {
        let documentsPath = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]

        fileURL = documentsPath.appendingPathComponent("ai_fixer_learning.json")
    }

    func save(_ entries: [LearningEntry]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        do {
            let data = try encoder.encode(entries)
            try data.write(to: fileURL)
            print("📚 学习数据已保存到: \(fileURL.path)")
        } catch {
            print("❌ 保存失败: \(error)")
        }
    }

    func load() -> [LearningEntry] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let data = try Data(contentsOf: fileURL)
            let entries = try decoder.decode([LearningEntry].self, from: data)
            print("📚 已加载 \(entries.count) 条学习数据")
            return entries
        } catch {
            print("❌ 加载失败: \(error)")
            return []
        }
    }
}
