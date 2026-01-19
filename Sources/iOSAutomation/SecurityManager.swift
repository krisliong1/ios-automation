import Foundation
import AppIntents

#if os(iOS)
import IOSSecuritySuite
#endif

/// 统一安全检测管理器
/// iOS: 使用 IOSSecuritySuite（成熟开源库 2600+ stars）
/// macOS: 使用自定义实现（高度定制化功能）
@available(iOS 16.0, macOS 13.0, *)
@MainActor
public class SecurityManager: ObservableObject {

    // MARK: - Published Properties

    @Published public var isJailbroken = false
    @Published public var isDebugged = false
    @Published public var isEmulator = false
    @Published public var securityStatus: SecurityStatus = .secure
    @Published public var detectionResults: [SecurityCheck] = []

    // MARK: - Initialization

    public init() {}

    // MARK: - Security Detection

    /// 执行完整安全检测
    public func performSecurityCheck() async -> SecurityStatus {
        print("🔍 开始安全检测...")

        var checks: [SecurityCheck] = []
        var hasIssue = false

        #if os(iOS)
        // iOS 平台 - 使用 IOSSecuritySuite

        // 1. 越狱检测
        let jailbroken = IOSSecuritySuite.amIJailbroken()
        isJailbroken = jailbroken
        checks.append(SecurityCheck(
            type: .jailbreak,
            passed: !jailbroken,
            description: jailbroken ? "检测到越狱环境" : "未检测到越狱"
        ))
        if jailbroken { hasIssue = true }

        // 2. 调试器检测
        let debugged = IOSSecuritySuite.amIDebugged()
        isDebugged = debugged
        checks.append(SecurityCheck(
            type: .debugger,
            passed: !debugged,
            description: debugged ? "检测到调试器" : "未检测到调试器"
        ))
        if debugged { hasIssue = true }

        // 3. 模拟器检测
        let emulator = IOSSecuritySuite.amIRunInEmulator()
        isEmulator = emulator
        checks.append(SecurityCheck(
            type: .emulator,
            passed: !emulator,
            description: emulator ? "运行在模拟器中" : "运行在真机上"
        ))
        if emulator { hasIssue = true }

        // 4. 逆向工程工具检测
        let reverseEngineering = IOSSecuritySuite.amIReverseEngineered()
        checks.append(SecurityCheck(
            type: .reverseEngineering,
            passed: !reverseEngineering,
            description: reverseEngineering ? "检测到逆向工程工具" : "未检测到逆向工程工具"
        ))
        if reverseEngineering { hasIssue = true }

        // 5. 代理检测
        if IOSSecuritySuite.amIProxied() {
            checks.append(SecurityCheck(
                type: .proxy,
                passed: false,
                description: "检测到代理连接"
            ))
            hasIssue = true
        }

        print("📱 iOS 安全检测完成")

        #elseif os(macOS)
        // macOS 平台 - 使用自定义实现

        // 1. 虚拟机检测（kern.hv_vmm_present）
        let vmDetected = checkKernelHVMMPresent()
        checks.append(SecurityCheck(
            type: .virtualMachine,
            passed: !vmDetected,
            description: vmDetected ? "检测到虚拟机环境" : "物理机环境"
        ))
        if vmDetected { hasIssue = true }

        // 2. 硬件模型检测
        let hwModel = checkHardwareModel()
        checks.append(SecurityCheck(
            type: .hardwareModel,
            passed: !hwModel.isVM,
            description: "硬件型号: \(hwModel.model)"
        ))
        if hwModel.isVM { hasIssue = true }

        // 3. 系统完整性检测
        let sipEnabled = checkSIPStatus()
        checks.append(SecurityCheck(
            type: .systemIntegrity,
            passed: sipEnabled,
            description: sipEnabled ? "SIP 已启用" : "SIP 已禁用（不安全）"
        ))
        if !sipEnabled { hasIssue = true }

        print("🖥️ macOS 安全检测完成")
        #endif

        detectionResults = checks
        securityStatus = hasIssue ? .compromised : .secure

        let summary = """

        📊 安全检测结果
        ==================
        状态: \(securityStatus.description)
        检测项: \(checks.count)
        通过: \(checks.filter { $0.passed }.count)
        失败: \(checks.filter { !$0.passed }.count)
        """

        print(summary)

        return securityStatus
    }

    #if os(macOS)
    // MARK: - macOS 自定义检测方法

    /// 检查 kern.hv_vmm_present（最可靠的虚拟机检测）
    private func checkKernelHVMMPresent() -> Bool {
        var value: Int32 = 0
        var size = MemoryLayout<Int32>.size

        let result = sysctlbyname("kern.hv_vmm_present", &value, &size, nil, 0)

        if result == 0 {
            print("kern.hv_vmm_present = \(value)")
            return value != 0
        }

        return false
    }

    /// 检查硬件模型
    private func checkHardwareModel() -> (model: String, isVM: Bool) {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)

        var model = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &model, &size, nil, 0)

        let modelString = String(cString: model)

        // 虚拟机通常包含这些关键词
        let vmKeywords = ["VM", "Virtual", "QEMU", "VirtualBox", "VMware", "Parallels"]
        let isVM = vmKeywords.contains { modelString.contains($0) }

        return (modelString, isVM)
    }

    /// 检查 SIP (System Integrity Protection) 状态
    private func checkSIPStatus() -> Bool {
        let process = Process()
        process.launchPath = "/usr/bin/csrutil"
        process.arguments = ["status"]

        let pipe = Pipe()
        process.standardOutput = pipe

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""

            // SIP 启用时输出包含 "enabled"
            return output.contains("enabled")
        } catch {
            print("⚠️ 无法检查 SIP 状态: \(error)")
            return true // 默认假设已启用
        }
    }
    #endif

    // MARK: - 便捷方法

    /// 快速检查是否安全
    public func isSecure() async -> Bool {
        let status = await performSecurityCheck()
        return status == .secure
    }

    /// 获取详细报告
    public func getSecurityReport() -> String {
        guard !detectionResults.isEmpty else {
            return "尚未执行安全检测，请先调用 performSecurityCheck()"
        }

        var report = """
        📋 安全检测详细报告
        ===================

        整体状态: \(securityStatus.icon) \(securityStatus.description)

        检测详情:
        """

        for check in detectionResults {
            report += "\n\(check.passed ? "✅" : "❌") \(check.type.rawValue): \(check.description)"
        }

        return report
    }
}

// MARK: - Data Models

/// 安全状态
public enum SecurityStatus {
    case secure       // 安全
    case compromised  // 已被攻破
    case unknown      // 未知

    public var description: String {
        switch self {
        case .secure: return "安全"
        case .compromised: return "存在安全风险"
        case .unknown: return "未知"
        }
    }

    public var icon: String {
        switch self {
        case .secure: return "🟢"
        case .compromised: return "🔴"
        case .unknown: return "⚪️"
        }
    }
}

/// 安全检查项
public struct SecurityCheck: Identifiable {
    public let id = UUID()
    public let type: SecurityCheckType
    public let passed: Bool
    public let description: String

    public init(type: SecurityCheckType, passed: Bool, description: String) {
        self.type = type
        self.passed = passed
        self.description = description
    }
}

/// 安全检查类型
public enum SecurityCheckType: String {
    case jailbreak = "越狱检测"
    case debugger = "调试器检测"
    case emulator = "模拟器检测"
    case reverseEngineering = "逆向工程检测"
    case proxy = "代理检测"
    case virtualMachine = "虚拟机检测"
    case hardwareModel = "硬件模型检测"
    case systemIntegrity = "系统完整性检测"
}

// MARK: - App Intents

/// 安全检测 Intent
public struct PerformSecurityCheckIntent: AppIntent {
    public static var title: LocalizedStringResource = "执行安全检测"
    public static var description = IntentDescription("检测设备是否存在越狱、调试器、虚拟机等安全风险")

    public init() {}

    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let manager = SecurityManager()
        let status = await manager.performSecurityCheck()

        if status == .secure {
            return .result(dialog: "✅ 设备安全，未检测到安全风险")
        }

        let report = manager.getSecurityReport()

        return .result(dialog: report)
    }
}

/// 获取安全报告 Intent
public struct GetSecurityReportIntent: AppIntent {
    public static var title: LocalizedStringResource = "获取安全报告"
    public static var description = IntentDescription("获取详细的设备安全检测报告")

    public init() {}

    public func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let manager = SecurityManager()
        _ = await manager.performSecurityCheck()
        let report = manager.getSecurityReport()

        return .result(
            value: report,
            dialog: "已生成安全报告"
        )
    }
}
