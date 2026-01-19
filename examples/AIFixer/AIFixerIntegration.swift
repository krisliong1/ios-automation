import Foundation
import SwiftUI

/// AI Fixer 集成助手
/// 提供便捷的方法将 AI Fixer 集成到现有模块中
@available(iOS 16.0, macOS 13.0, *)
class AIFixerIntegration {

    // MARK: - Singleton

    static let shared = AIFixerIntegration()
    private let fixer = KrisAIFixer()

    private init() {}

    // MARK: - Integration Methods

    /// 包装任何异步函数，自动添加 AI Fixer 错误处理
    func withAutoFix<T>(
        context: String,
        operation: () async throws -> T
    ) async throws -> T {
        do {
            return try await operation()
        } catch {
            // 自动触发 AI Fixer
            await fixer.onValidationFailed(error: error, context: context)
            throw error // 仍然抛出错误
        }
    }

    /// 包装同步函数，自动添加 AI Fixer 错误处理
    func withAutoFixSync<T>(
        context: String,
        operation: () throws -> T
    ) rethrows -> T {
        do {
            return try operation()
        } catch {
            // 在后台任务中触发 AI Fixer
            Task {
                await fixer.onValidationFailed(error: error, context: context)
            }
            throw error
        }
    }

    /// 手动触发 AI Fixer
    func fix(problem: String) async throws -> FixResult {
        return try await fixer.fixProblem(problem)
    }

    /// 检查并修复（如果条件满足）
    func checkAndFix(condition: Bool, problem: String) async {
        if condition {
            _ = try? await fixer.fixProblem(problem)
        }
    }
}

// MARK: - 扩展现有模块

#if os(macOS)

/// VMDetectionManager 的 AI Fixer 集成
@available(macOS 12.0, *)
extension VMDetectionManager {

    /// 检测虚拟机并自动触发 AI Fixer（如果检测到）
    func detectVirtualMachineWithAutoFix() async -> Bool {
        let isVM = await detectVirtualMachine()

        if isVM {
            print("⚠️ 检测到虚拟机，触发 AI Fixer...")

            Task {
                do {
                    let result = try await AIFixerIntegration.shared.fix(
                        problem: """
                        Xcode 检测到虚拟机环境
                        虚拟机类型: \(vmType.description)
                        需要绕过虚拟机检测以使用 Xcode
                        """
                    )

                    if result.success {
                        print("✅ AI Fixer 已生成解决方案")
                        print("方案: \(result.solution.title)")

                        // 显示步骤
                        for (index, step) in result.solution.steps.enumerated() {
                            print("\(index + 1). \(step)")
                        }
                    }
                } catch {
                    print("❌ AI Fixer 失败: \(error)")
                }
            }
        }

        return isVM
    }
}

#endif

// MARK: - iCloudSyncManager 集成

/// iCloudSyncManager 的 AI Fixer 集成
@available(iOS 14.0, *)
extension iCloudSyncManager {

    /// 保存文档（带 AI Fixer）
    func saveDocumentWithAutoFix(filename: String, content: String) async throws {
        try await AIFixerIntegration.shared.withAutoFix(
            context: "iCloud 文档保存: \(filename)"
        ) {
            try await saveDocument(filename: filename, content: content)
        }
    }

    /// 读取文档（带 AI Fixer）
    func readDocumentWithAutoFix(filename: String) async throws -> String {
        try await AIFixerIntegration.shared.withAutoFix(
            context: "iCloud 文档读取: \(filename)"
        ) {
            try await readDocument(filename: filename)
        }
    }

    /// 同步文档（带 AI Fixer）
    func syncDocumentWithAutoFix(filename: String) async throws {
        try await AIFixerIntegration.shared.withAutoFix(
            context: "iCloud 文档同步: \(filename)"
        ) {
            try await syncDocument(filename: filename)
        }
    }
}

// MARK: - BluetoothManager 集成

/// BluetoothManager 的 AI Fixer 集成
@MainActor
extension BluetoothManager {

    /// 连接设备（带 AI Fixer）
    func connectWithAutoFix(to device: BluetoothDevice) async {
        connect(to: device)

        // 等待连接结果
        try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 秒

        if connectionStatus != .connected {
            // 连接失败，触发 AI Fixer
            let error = NSError(
                domain: "BluetoothConnection",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "蓝牙连接失败"]
            )

            await AIFixerIntegration.shared.fixer.onValidationFailed(
                error: error,
                context: "蓝牙设备连接: \(device.name)"
            )
        }
    }

    /// 扫描设备（带 AI Fixer）
    func scanWithAutoFix(duration: Int = 10) async -> [BluetoothDevice] {
        startScanning()

        // 等待扫描
        try? await Task.sleep(nanoseconds: UInt64(duration) * 1_000_000_000)

        stopScanning()

        if discoveredDevices.isEmpty {
            // 没有发现设备，触发 AI Fixer
            let error = NSError(
                domain: "BluetoothScan",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "未发现蓝牙设备"]
            )

            await AIFixerIntegration.shared.fixer.onValidationFailed(
                error: error,
                context: "蓝牙设备扫描"
            )
        }

        return discoveredDevices
    }
}

// MARK: - NetworkConnectionManager 集成

/// NetworkConnectionManager 的 AI Fixer 集成
@MainActor
extension NetworkConnectionManager {

    /// 连接 WiFi（带 AI Fixer）
    func connectToWiFiWithAutoFix(ssid: String, password: String) async {
        do {
            try await connectToWiFi(ssid: ssid, password: password)
        } catch {
            await AIFixerIntegration.shared.fixer.onValidationFailed(
                error: error,
                context: "WiFi 连接: \(ssid)"
            )
        }
    }

    /// 检查网络状态（带 AI Fixer）
    func checkConnectivityWithAutoFix() async -> Bool {
        let isConnected = checkConnectivity()

        if !isConnected {
            let error = NSError(
                domain: "NetworkConnectivity",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "网络连接失败"]
            )

            await AIFixerIntegration.shared.fixer.onValidationFailed(
                error: error,
                context: "网络连接检查"
            )
        }

        return isConnected
    }
}

// MARK: - 通用错误处理装饰器

/// 错误处理装饰器 - 为任何函数添加 AI Fixer
@propertyWrapper
struct AutoFix<T> {
    private var value: T
    private let context: String

    init(wrappedValue: T, context: String) {
        self.value = wrappedValue
        self.context = context
    }

    var wrappedValue: T {
        get { value }
        set { value = newValue }
    }

    /// 执行带自动修复的操作
    func execute(_ operation: () async throws -> T) async throws -> T {
        try await AIFixerIntegration.shared.withAutoFix(
            context: context,
            operation: operation
        )
    }
}

// MARK: - 验证触发器示例

/// 演示如何在自定义类中使用 AI Fixer
@available(iOS 16.0, *)
class MyCustomManager: ObservableObject {

    private let aiFixer = KrisAIFixer()

    // MARK: - 方法 1: 使用 do-catch

    func performOperationWithAIFixer() async {
        do {
            try await someOperation()
        } catch {
            // 验证失败，自动触发 AI Fixer
            await aiFixer.onValidationFailed(
                error: error,
                context: "自定义操作"
            )
        }
    }

    // MARK: - 方法 2: 使用集成助手

    func performOperationWithHelper() async {
        do {
            try await AIFixerIntegration.shared.withAutoFix(
                context: "自定义操作"
            ) {
                try await someOperation()
            }
        } catch {
            print("操作失败: \(error)")
        }
    }

    // MARK: - 方法 3: 条件触发

    func performValidation() async {
        let isValid = await checkSomething()

        await AIFixerIntegration.shared.checkAndFix(
            condition: !isValid,
            problem: "验证失败：条件不满足"
        )
    }

    // MARK: - 辅助方法

    private func someOperation() async throws {
        // 模拟操作
        throw NSError(domain: "Test", code: -1)
    }

    private func checkSomething() async -> Bool {
        return false
    }
}

// MARK: - SwiftUI 集成

/// SwiftUI View 修饰符
@available(iOS 16.0, *)
extension View {

    /// 添加 AI Fixer 错误处理
    func withAIFixer(context: String) -> some View {
        self.environment(\.aiFixerContext, context)
    }
}

/// Environment Key
@available(iOS 16.0, *)
struct AIFixerContextKey: EnvironmentKey {
    static let defaultValue: String = "未知上下文"
}

@available(iOS 16.0, *)
extension EnvironmentValues {
    var aiFixerContext: String {
        get { self[AIFixerContextKey.self] }
        set { self[AIFixerContextKey.self] = newValue }
    }
}

// MARK: - 使用示例

#if DEBUG

/// AI Fixer 集成示例
@available(iOS 16.0, macOS 13.0, *)
class AIFixerIntegrationExamples {

    // MARK: - 示例 1: 基础使用

    func example1_BasicUsage() async {
        do {
            let result = try await AIFixerIntegration.shared.fix(
                problem: "Xcode 编译错误"
            )

            print("✅ 修复结果: \(result.message)")
        } catch {
            print("❌ 修复失败: \(error)")
        }
    }

    // MARK: - 示例 2: 自动包装

    func example2_AutoWrap() async {
        do {
            let value = try await AIFixerIntegration.shared.withAutoFix(
                context: "示例操作"
            ) {
                try await someFailingOperation()
            }

            print("✅ 操作成功: \(value)")
        } catch {
            print("❌ 操作失败: \(error)")
        }
    }

    // MARK: - 示例 3: 条件修复

    func example3_ConditionalFix() async {
        let hasError = true

        await AIFixerIntegration.shared.checkAndFix(
            condition: hasError,
            problem: "发现错误条件"
        )
    }

    // MARK: - 示例 4: 多个集成点

    func example4_MultipleIntegrations() async {
        // 蓝牙
        let btManager = BluetoothManager()
        let devices = await btManager.scanWithAutoFix(duration: 10)

        // iCloud
        let iCloudManager = iCloudSyncManager()
        do {
            try await iCloudManager.saveDocumentWithAutoFix(
                filename: "test.txt",
                content: "Hello"
            )
        } catch {
            print("iCloud 保存失败: \(error)")
        }

        #if os(macOS)
        // VM 检测
        if #available(macOS 12.0, *) {
            let vmManager = VMDetectionManager()
            let isVM = await vmManager.detectVirtualMachineWithAutoFix()
            print("是否为虚拟机: \(isVM)")
        }
        #endif
    }

    // MARK: - 辅助方法

    private func someFailingOperation() async throws -> String {
        throw NSError(domain: "Example", code: -1, userInfo: [
            NSLocalizedDescriptionKey: "示例错误"
        ])
    }
}

#endif
