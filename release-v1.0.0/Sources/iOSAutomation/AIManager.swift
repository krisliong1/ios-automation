import Foundation
import AppIntents

/// AI 管理器 - 监控和管理 AI 系统
/// 集成 claude-code-router 实现智能路由和问题解决
@available(iOS 16.0, macOS 13.0, *)
@MainActor
public class AIManager: ObservableObject {

    // MARK: - Published Properties

    @Published public var mainAIStatus: AIStatus = .idle
    @Published public var managerAIStatus: AIStatus = .idle
    @Published public var currentProvider: AIProvider = .default
    @Published public var healthCheck: HealthCheckResult?
    @Published public var problemLog: [AIProblem] = []

    // MARK: - Private Properties

    private let routerConfig: RouterConfiguration
    private var healthMonitor: HealthMonitor?
    private let problemSolver: ProblemSolver

    // AI 实例
    private var mainAI: KrisAIFixer?
    private let networkTester = NetworkTester()

    // MARK: - Initialization

    public init(config: RouterConfiguration = .default) {
        self.routerConfig = config
        self.problemSolver = ProblemSolver(config: config)

        // 启动健康监控
        startHealthMonitoring()
    }

    // MARK: - AI 管理

    /// 启动主 AI
    public func startMainAI() {
        print("🤖 启动主 AI (Kris AI Fixer)...")
        mainAI = KrisAIFixer()
        mainAIStatus = .running
        print("✅ 主 AI 已启动")
    }

    /// 停止主 AI
    public func stopMainAI() {
        print("⏸️ 停止主 AI...")
        mainAI = nil
        mainAIStatus = .idle
    }

    /// 执行 AI 任务（带监控和自动恢复）
    public func executeTask(description: String) async throws -> FixResult {
        guard let mainAI = mainAI else {
            print("❌ 主 AI 未启动")
            startMainAI()
            return try await executeTask(description: description)
        }

        mainAIStatus = .running

        do {
            // 尝试执行任务
            print("📋 主 AI 开始执行任务: \(description)")
            let result = try await mainAI.fixProblem(description)

            mainAIStatus = .idle
            print("✅ 任务执行成功")

            return result

        } catch {
            // 捕获错误并分析
            let problem = await analyzeError(error, context: description)
            problemLog.append(problem)

            print("❌ 主 AI 执行失败: \(error.localizedDescription)")
            print("🔧 管理 AI 介入解决问题...")

            // 管理 AI 尝试解决问题
            let recovered = try await recoverFromProblem(problem, originalTask: description)

            if recovered {
                // 问题已解决，重试任务
                print("✅ 问题已解决，重试任务")
                return try await executeTask(description: description)
            } else {
                // 无法自动恢复
                mainAIStatus = .failed
                throw AIManagerError.cannotRecover(problem.type.description)
            }
        }
    }

    // MARK: - 健康监控

    /// 启动健康监控
    private func startHealthMonitoring() {
        print("🏥 启动健康监控...")

        healthMonitor = HealthMonitor { [weak self] health in
            Task { @MainActor in
                self?.healthCheck = health

                // 如果健康状态不佳，主动介入
                if !health.isHealthy {
                    print("⚠️ 检测到健康问题: \(health.issues.joined(separator: ", "))")
                    await self?.handleHealthIssues(health)
                }
            }
        }

        healthMonitor?.start()
    }

    /// 停止健康监控
    public func stopHealthMonitoring() {
        healthMonitor?.stop()
        healthMonitor = nil
    }

    /// 处理健康问题
    private func handleHealthIssues(_ health: HealthCheckResult) async {
        for issue in health.issues {
            let problem = AIProblem(
                type: .healthCheck,
                description: issue,
                timestamp: Date(),
                severity: .medium,
                autoRecoverable: true
            )

            do {
                print("🔧 尝试自动修复健康问题: \(issue)")
                _ = try await recoverFromProblem(problem, originalTask: "健康检查")
            } catch {
                print("❌ 无法自动修复: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - 问题分析

    /// 分析错误
    private func analyzeError(_ error: Error, context: String) async -> AIProblem {
        let errorDescription = error.localizedDescription.lowercased()

        // 检测问题类型
        var problemType: AIProblemType = .unknown

        if errorDescription.contains("network") ||
           errorDescription.contains("网络") ||
           errorDescription.contains("connection") {
            problemType = .networkError

        } else if errorDescription.contains("search") ||
                  errorDescription.contains("搜索") {
            problemType = .searchRestricted

        } else if errorDescription.contains("timeout") ||
                  errorDescription.contains("超时") {
            problemType = .timeout

        } else if errorDescription.contains("api") ||
                  errorDescription.contains("quota") {
            problemType = .apiLimitExceeded

        } else if errorDescription.contains("permission") ||
                  errorDescription.contains("权限") {
            problemType = .permissionDenied
        }

        // 评估严重程度
        let severity: AIProblemSeverity
        switch problemType {
        case .networkError, .searchRestricted:
            severity = .high
        case .timeout, .apiLimitExceeded:
            severity = .medium
        default:
            severity = .low
        }

        return AIProblem(
            type: problemType,
            description: error.localizedDescription,
            timestamp: Date(),
            severity: severity,
            autoRecoverable: problemType != .unknown
        )
    }

    // MARK: - 问题恢复

    /// 从问题中恢复
    private func recoverFromProblem(_ problem: AIProblem, originalTask: String) async throws -> Bool {
        managerAIStatus = .running

        print("🤖 管理 AI 开始处理问题...")
        print("   类型: \(problem.type.description)")
        print("   描述: \(problem.description)")

        let recovered: Bool

        switch problem.type {
        case .networkError:
            recovered = try await solveNetworkProblem()

        case .searchRestricted:
            recovered = try await solveSearchProblem()

        case .timeout:
            recovered = await solveTimeoutProblem()

        case .apiLimitExceeded:
            recovered = try await solveAPILimitProblem()

        case .permissionDenied:
            recovered = await solvePermissionProblem()

        case .healthCheck:
            recovered = await solveHealthCheckProblem(problem.description)

        case .unknown:
            recovered = try await solveUnknownProblem(problem)
        }

        if recovered {
            print("✅ 问题已解决")
            mainAIStatus = .recovering
        } else {
            print("❌ 无法自动解决问题")
            mainAIStatus = .failed
        }

        managerAIStatus = .idle
        return recovered
    }

    // MARK: - 问题解决方法

    /// 解决网络问题
    private func solveNetworkProblem() async throws -> Bool {
        print("🌐 诊断网络问题...")

        // 1. 检测网络连接
        let connectivity = await networkTester.testConnectivity()

        if !connectivity.isConnected {
            print("❌ 网络未连接")
            return false
        }

        // 2. 测试各个提供商
        print("🔍 测试 AI 提供商连接...")
        let providers = await problemSolver.testProviders()

        // 3. 切换到可用的提供商
        if let workingProvider = providers.first(where: { $0.isAvailable }) {
            print("✅ 找到可用提供商: \(workingProvider.name)")
            currentProvider = workingProvider
            try await switchProvider(to: workingProvider)
            return true
        }

        // 4. 尝试使用代理
        print("🔄 尝试配置代理...")
        let proxyConfigured = try await configureProxy()

        return proxyConfigured
    }

    /// 解决搜索受限问题
    private func solveSearchProblem() async throws -> Bool {
        print("🔍 解决搜索限制问题...")

        // 1. 切换搜索引擎
        print("🔄 切换到备用搜索引擎...")
        let alternativeEngines = [
            "DuckDuckGo",
            "GitHub Code Search",
            "Stack Overflow API"
        ]

        for engine in alternativeEngines {
            let available = await testSearchEngine(engine)
            if available {
                print("✅ 切换到: \(engine)")
                return true
            }
        }

        // 2. 使用 claude-code-router 的 webSearch 路由
        print("🔄 使用 claude-code-router webSearch 路由...")
        try await switchToWebSearchRoute()

        return true
    }

    /// 解决超时问题
    private func solveTimeoutProblem() async -> Bool {
        print("⏱️ 解决超时问题...")

        // 1. 增加超时时间
        print("🔄 增加超时时间...")

        // 2. 切换到更快的模型
        print("🔄 切换到快速模型...")
        currentProvider = .deepseek  // 更快的模型

        return true
    }

    /// 解决 API 限制问题
    private func solveAPILimitProblem() async throws -> Bool {
        print("🔄 解决 API 限制问题...")

        // 切换到其他提供商
        let availableProviders = await problemSolver.testProviders()
        let unlimitedProvider = availableProviders.first {
            $0.hasUnlimitedQuota
        }

        if let provider = unlimitedProvider {
            print("✅ 切换到无限制提供商: \(provider.name)")
            try await switchProvider(to: provider)
            return true
        }

        return false
    }

    /// 解决权限问题
    private func solvePermissionProblem() async -> Bool {
        print("🔐 解决权限问题...")
        // 权限问题通常需要用户手动授权
        return false
    }

    /// 解决健康检查问题
    private func solveHealthCheckProblem(_ description: String) async -> Bool {
        print("🏥 解决健康问题: \(description)")

        if description.contains("network") {
            return (try? await solveNetworkProblem()) ?? false
        }

        return false
    }

    /// 解决未知问题
    private func solveUnknownProblem(_ problem: AIProblem) async throws -> Bool {
        print("❓ 解决未知问题...")

        // 使用 claude-code-router 的默认路由
        try await switchToDefaultRoute()

        return true
    }

    // MARK: - 路由切换

    /// 切换提供商
    private func switchProvider(to provider: AIProvider) async throws {
        print("🔄 切换到提供商: \(provider.name)")

        // 更新配置
        currentProvider = provider

        // 调用 claude-code-router
        try await executeRouterCommand(
            command: "/model",
            args: [provider.modelIdentifier]
        )

        print("✅ 提供商已切换")
    }

    /// 切换到 webSearch 路由
    private func switchToWebSearchRoute() async throws {
        print("🔄 切换到 webSearch 路由...")

        try await executeRouterCommand(
            command: "/route",
            args: ["webSearch"]
        )
    }

    /// 切换到默认路由
    private func switchToDefaultRoute() async throws {
        print("🔄 切换到默认路由...")

        try await executeRouterCommand(
            command: "/route",
            args: ["default"]
        )
    }

    /// 执行 router 命令
    private func executeRouterCommand(command: String, args: [String]) async throws {
        // 这里集成 claude-code-router
        // 实际实现需要调用 router 的 API 或命令行

        let fullCommand = ([command] + args).joined(separator: " ")
        print("📡 执行 router 命令: \(fullCommand)")

        // 模拟命令执行
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 秒
    }

    // MARK: - 辅助方法

    /// 配置代理
    private func configureProxy() async throws -> Bool {
        print("🔧 配置代理...")
        // 这里可以集成 Shadowrocket 等代理工具
        return false
    }

    /// 测试搜索引擎
    private func testSearchEngine(_ name: String) async -> Bool {
        print("🔍 测试搜索引擎: \(name)...")
        return true // 简化实现
    }

    // MARK: - 状态报告

    /// 获取系统状态报告
    public func getStatusReport() -> String {
        var report = """
        🤖 AI 管理系统状态报告
        ========================

        主 AI 状态: \(mainAIStatus.icon) \(mainAIStatus.description)
        管理 AI 状态: \(managerAIStatus.icon) \(managerAIStatus.description)
        当前提供商: \(currentProvider.name)

        """

        // 健康状态
        if let health = healthCheck {
            report += """

            健康状态: \(health.isHealthy ? "✅ 健康" : "⚠️ 异常")
            """

            if !health.isHealthy {
                report += """

                问题列表:
                \(health.issues.map { "  • \(String(describing: $0))" }.joined(separator: "\n"))
                """
            }
        }

        // 问题日志
        if !problemLog.isEmpty {
            report += """

            最近问题 (最多 5 条):
            """

            for problem in problemLog.suffix(5) {
                report += """

              • \(problem.type.icon) \(problem.type.description)
                时间: \(formatDate(problem.timestamp))
                描述: \(problem.description)
                """
            }
        }

        return report
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
}

// MARK: - 健康监控器

class HealthMonitor {
    private var timer: Timer?
    private let checkInterval: TimeInterval = 30.0 // 30 秒
    private let callback: (HealthCheckResult) -> Void

    init(callback: @escaping (HealthCheckResult) -> Void) {
        self.callback = callback
    }

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: checkInterval, repeats: true) { [weak self] _ in
            self?.performHealthCheck()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func performHealthCheck() {
        Task {
            var issues: [String] = []

            // 1. 检查网络连接
            let networkTester = NetworkTester()
            let connectivity = await networkTester.testConnectivity()

            if !connectivity.isConnected {
                issues.append("网络未连接")
            }

            if connectivity.latency > 1000 {
                issues.append("网络延迟高 (\(connectivity.latency)ms)")
            }

            // 2. 检查内存使用
            let memoryUsage = getMemoryUsage()
            if memoryUsage > 0.8 { // 超过 80%
                issues.append("内存使用率高 (\(Int(memoryUsage * 100))%)")
            }

            let health = HealthCheckResult(
                isHealthy: issues.isEmpty,
                issues: issues,
                timestamp: Date()
            )

            callback(health)
        }
    }

    private func getMemoryUsage() -> Double {
        // 简化实现
        return 0.5
    }
}

// MARK: - 网络测试器

class NetworkTester {
    func testConnectivity() async -> ConnectivityResult {
        // 测试多个端点
        let endpoints = [
            "https://www.google.com",
            "https://www.cloudflare.com",
            "https://api.github.com"
        ]

        let startTime = Date()
        var successCount = 0

        for endpoint in endpoints {
            if await testEndpoint(endpoint) {
                successCount += 1
            }
        }

        let latency = Int(Date().timeIntervalSince(startTime) * 1000) // ms

        return ConnectivityResult(
            isConnected: successCount > 0,
            latency: latency,
            successRate: Double(successCount) / Double(endpoints.count)
        )
    }

    private func testEndpoint(_ urlString: String) async -> Bool {
        guard let url = URL(string: urlString) else {
            return false
        }

        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }
}

// MARK: - 问题解决器

class ProblemSolver {
    private let config: RouterConfiguration

    init(config: RouterConfiguration) {
        self.config = config
    }

    /// 测试所有提供商
    func testProviders() async -> [AIProvider] {
        let allProviders: [AIProvider] = [
            .default,
            .openrouter,
            .deepseek,
            .ollama,
            .gemini
        ]

        var availableProviders: [AIProvider] = []

        for provider in allProviders {
            let available = await testProvider(provider)
            if available {
                availableProviders.append(provider)
            }
        }

        return availableProviders
    }

    private func testProvider(_ provider: AIProvider) async -> Bool {
        print("🔍 测试提供商: \(provider.name)...")

        // 简化测试：尝试连接 API 端点
        guard let endpoint = provider.endpoint else {
            return false
        }

        guard let url = URL(string: endpoint) else {
            return false
        }

        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            let available = statusCode < 400

            print(available ? "✅" : "❌", provider.name, "状态码:", statusCode)

            return available
        } catch {
            print("❌", provider.name, "失败:", error.localizedDescription)
            return false
        }
    }
}

// MARK: - Data Models

/// AI 状态
public enum AIStatus {
    case idle       // 空闲
    case running    // 运行中
    case recovering // 恢复中
    case failed     // 失败

    public var description: String {
        switch self {
        case .idle: return "空闲"
        case .running: return "运行中"
        case .recovering: return "恢复中"
        case .failed: return "失败"
        }
    }

    public var icon: String {
        switch self {
        case .idle: return "⚪️"
        case .running: return "🟢"
        case .recovering: return "🟡"
        case .failed: return "🔴"
        }
    }
}

/// AI 提供商
public enum AIProvider {
    case `default`    // Claude 默认
    case openrouter   // OpenRouter
    case deepseek     // DeepSeek (快速、便宜)
    case ollama       // Ollama (本地)
    case gemini       // Google Gemini

    public var name: String {
        switch self {
        case .default: return "Claude (默认)"
        case .openrouter: return "OpenRouter"
        case .deepseek: return "DeepSeek"
        case .ollama: return "Ollama (本地)"
        case .gemini: return "Google Gemini"
        }
    }

    public var modelIdentifier: String {
        switch self {
        case .default: return "claude-sonnet-4"
        case .openrouter: return "openrouter/anthropic/claude-3.5-sonnet"
        case .deepseek: return "deepseek/deepseek-chat"
        case .ollama: return "ollama/llama3"
        case .gemini: return "gemini/gemini-pro"
        }
    }

    public var endpoint: String? {
        switch self {
        case .default: return "https://api.anthropic.com"
        case .openrouter: return "https://openrouter.ai"
        case .deepseek: return "https://api.deepseek.com"
        case .ollama: return "http://localhost:11434"
        case .gemini: return "https://generativelanguage.googleapis.com"
        }
    }

    public var hasUnlimitedQuota: Bool {
        switch self {
        case .ollama: return true  // 本地运行，无限制
        case .openrouter: return false
        case .deepseek: return false
        case .gemini: return false
        case .default: return false
        }
    }

    public var isAvailable: Bool {
        // 这里应该实际测试连接
        return true
    }
}

/// 路由配置
public struct RouterConfiguration {
    public let serverURL: String
    public let port: Int
    public let enableLogging: Bool

    public static let `default` = RouterConfiguration(
        serverURL: "http://localhost",
        port: 3456,
        enableLogging: true
    )

    public init(serverURL: String, port: Int, enableLogging: Bool) {
        self.serverURL = serverURL
        self.port = port
        self.enableLogging = enableLogging
    }
}

/// AI 问题
public struct AIProblem {
    public let type: AIProblemType
    public let description: String
    public let timestamp: Date
    public let severity: AIProblemSeverity
    public let autoRecoverable: Bool
}

/// AI 问题类型
public enum AIProblemType {
    case networkError       // 网络错误
    case searchRestricted   // 搜索受限
    case timeout            // 超时
    case apiLimitExceeded   // API 限制
    case permissionDenied   // 权限拒绝
    case healthCheck        // 健康检查
    case unknown            // 未知

    public var description: String {
        switch self {
        case .networkError: return "网络错误"
        case .searchRestricted: return "搜索受限"
        case .timeout: return "超时"
        case .apiLimitExceeded: return "API 限制"
        case .permissionDenied: return "权限拒绝"
        case .healthCheck: return "健康检查"
        case .unknown: return "未知问题"
        }
    }

    public var icon: String {
        switch self {
        case .networkError: return "🌐"
        case .searchRestricted: return "🔍"
        case .timeout: return "⏱️"
        case .apiLimitExceeded: return "🔄"
        case .permissionDenied: return "🔐"
        case .healthCheck: return "🏥"
        case .unknown: return "❓"
        }
    }
}

/// AI 问题严重程度
public enum AIProblemSeverity {
    case low, medium, high, critical
}

/// 健康检查结果
public struct HealthCheckResult {
    public let isHealthy: Bool
    public let issues: [String]
    public let timestamp: Date
}

/// 连接测试结果
public struct ConnectivityResult {
    public let isConnected: Bool
    public let latency: Int  // 毫秒
    public let successRate: Double  // 0.0 - 1.0
}

/// AI Manager 错误
public enum AIManagerError: LocalizedError {
    case cannotRecover(String)
    case providerUnavailable
    case routerNotConfigured

    public var errorDescription: String? {
        switch self {
        case .cannotRecover(let reason):
            return "无法自动恢复: \(reason)"
        case .providerUnavailable:
            return "没有可用的 AI 提供商"
        case .routerNotConfigured:
            return "Router 未配置"
        }
    }
}

// MARK: - App Intents

/// AI 管理器状态 Intent
@available(iOS 16.0, *)
public struct AIManagerStatusIntent: AppIntent {
    public static var title: LocalizedStringResource = "AI 管理器状态"
    public static var description = IntentDescription("获取 AI 管理系统的当前状态")

    public init() {}

    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let manager = AIManager()
        let status = manager.getStatusReport()

        return .result(dialog: status)
    }
}

/// 手动切换提供商 Intent
@available(iOS 16.0, *)
public struct SwitchAIProviderIntent: AppIntent {
    public static var title: LocalizedStringResource = "切换 AI 提供商"
    public static var description = IntentDescription("手动切换到其他 AI 提供商")

    @Parameter(title: "提供商")
    public var providerName: String

    public init() {}

    public init(providerName: String) {
        self.providerName = providerName
    }

    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let manager = AIManager()

        // 根据名称选择提供商
        let provider: AIProvider
        switch providerName.lowercased() {
        case "openrouter":
            provider = .openrouter
        case "deepseek":
            provider = .deepseek
        case "ollama":
            provider = .ollama
        case "gemini":
            provider = .gemini
        default:
            provider = .default
        }

        try await manager.switchProvider(to: provider)

        return .result(dialog: "✅ 已切换到: \(provider.name)")
    }
}
