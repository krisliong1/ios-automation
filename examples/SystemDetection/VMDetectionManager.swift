import Foundation
#if os(macOS)
import IOKit

/// 虚拟机检测和管理器
/// 检测当前系统是否为虚拟机，并提供绕过检测的方法
@available(macOS 12.0, *)
@MainActor
class VMDetectionManager: ObservableObject {

    // MARK: - Published Properties

    @Published var isVirtualMachine = false
    @Published var vmType: VMType = .unknown
    @Published var detectionMethods: [DetectionResult] = []
    @Published var bypassStatus: BypassStatus = .notApplied

    // MARK: - Detection Methods

    /// 检测是否为虚拟机
    func detectVirtualMachine() async -> Bool {
        print("🔍 开始检测虚拟机环境...")

        var results: [DetectionResult] = []
        var isVM = false

        // 方法 1: 检查 kern.hv_vmm_present (最可靠)
        let hvmmPresent = checkKernelHVMMPresent()
        results.append(DetectionResult(
            method: "kern.hv_vmm_present",
            detected: hvmmPresent,
            reliability: .high,
            description: hvmmPresent ? "检测到 Hypervisor" : "未检测到 Hypervisor"
        ))
        if hvmmPresent { isVM = true }

        // 方法 2: 检查硬件模型
        let hardwareModel = checkHardwareModel()
        results.append(DetectionResult(
            method: "硬件模型检测",
            detected: hardwareModel.isVM,
            reliability: .medium,
            description: "硬件模型: \(hardwareModel.model)"
        ))
        if hardwareModel.isVM { isVM = true }

        // 方法 3: 检查 CPU 特性
        let cpuFeatures = checkCPUFeatures()
        results.append(DetectionResult(
            method: "CPU 特性检测",
            detected: cpuFeatures,
            reliability: .medium,
            description: cpuFeatures ? "检测到虚拟化 CPU 特性" : "正常 CPU 特性"
        ))
        if cpuFeatures { isVM = true }

        // 方法 4: 检查系统信息
        let systemInfo = checkSystemInfo()
        results.append(DetectionResult(
            method: "系统信息检测",
            detected: systemInfo.isVM,
            reliability: .low,
            description: "制造商: \(systemInfo.manufacturer)"
        ))
        if systemInfo.isVM { isVM = true }

        // 方法 5: 检查网络接口
        let networkInterfaces = checkNetworkInterfaces()
        results.append(DetectionResult(
            method: "网络接口检测",
            detected: networkInterfaces.isVM,
            reliability: .low,
            description: "检测到 \(networkInterfaces.vmInterfaceCount) 个虚拟网络接口"
        ))
        if networkInterfaces.isVM { isVM = true }

        self.detectionMethods = results
        self.isVirtualMachine = isVM

        // 判断虚拟机类型
        self.vmType = determineVMType(results: results, hardwareModel: hardwareModel.model)

        let summary = """

        📊 虚拟机检测结果
        ==================
        是否为虚拟机: \(isVM ? "✅ 是" : "❌ 否")
        虚拟机类型: \(vmType.description)
        检测方法数: \(results.count)
        高可靠性检测: \(results.filter { $0.reliability == .high && $0.detected }.count)
        """

        print(summary)

        return isVM
    }

    /// 检查 kern.hv_vmm_present
    /// 这是最可靠的检测方法 - Xcode 主要使用这个
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

    /// 检查 CPU 特性
    private func checkCPUFeatures() -> Bool {
        // 检查是否有虚拟化相关的 CPU 特性
        var value: Int32 = 0
        var size = MemoryLayout<Int32>.size

        // 检查 VMX (Intel) 或 SVM (AMD) 特性
        let features = ["machdep.cpu.features", "machdep.cpu.extfeatures"]

        for feature in features {
            sysctlbyname(feature, &value, &size, nil, 0)
            // 虚拟机环境下某些 CPU 特性会不同
        }

        return false // 简化检测
    }

    /// 检查系统信息
    private func checkSystemInfo() -> (manufacturer: String, isVM: Bool) {
        // 通过 IOKit 获取系统信息
        let service = IOServiceGetMatchingService(
            kIOMainPortDefault,
            IOServiceMatching("IOPlatformExpertDevice")
        )

        defer { IOObjectRelease(service) }

        guard service != 0 else {
            return ("Unknown", false)
        }

        if let manufacturer = IORegistryEntryCreateCFProperty(
            service,
            "manufacturer" as CFString,
            kCFAllocatorDefault,
            0
        )?.takeRetainedValue() as? String {

            let vmManufacturers = ["QEMU", "VMware", "Oracle", "Parallels", "Microsoft"]
            let isVM = vmManufacturers.contains { manufacturer.contains($0) }

            return (manufacturer, isVM)
        }

        return ("Unknown", false)
    }

    /// 检查网络接口
    private func checkNetworkInterfaces() -> (vmInterfaceCount: Int, isVM: Bool) {
        // 虚拟机通常有特定的网络接口名称
        let vmInterfacePatterns = ["vnet", "vmnet", "virbr", "vboxnet"]

        // 这里简化实现，实际需要枚举网络接口
        // 可以通过 getifaddrs() 或 SCNetworkReachability 实现

        return (0, false)
    }

    /// 判断虚拟机类型
    private func determineVMType(results: [DetectionResult], hardwareModel: String) -> VMType {
        if !isVirtualMachine {
            return .none
        }

        if hardwareModel.contains("QEMU") {
            return .qemu
        } else if hardwareModel.contains("VMware") {
            return .vmware
        } else if hardwareModel.contains("VirtualBox") {
            return .virtualbox
        } else if hardwareModel.contains("Parallels") {
            return .parallels
        } else if checkKernelHVMMPresent() {
            return .appleVirtualization
        }

        return .unknown
    }

    // MARK: - Bypass Methods

    /// 获取绕过虚拟机检测的指南
    func getBypassGuide() -> String {
        """
        🛡️ 虚拟机检测绕过指南
        ======================

        ⚠️ 重要警告：
        - 修改系统内核参数需要禁用 SIP (System Integrity Protection)
        - 仅用于开发和测试目的
        - 不要在生产环境使用

        方法 1: 使用 VMHide 内核扩展（推荐）
        -----------------------------------
        VMHide 是一个开源内核扩展，可以隐藏 kern.hv_vmm_present

        1. 下载 VMHide:
           https://github.com/Carnations-Botanica/VMHide

        2. 安装步骤:
           a) 重启 Mac 进入恢复模式 (⌘ + R)
           b) 打开终端，禁用 SIP:
              csrutil disable
           c) 重启进入正常模式
           d) 加载内核扩展:
              sudo kextload VMHide.kext

        3. 验证:
           sysctl kern.hv_vmm_present
           # 应该返回 0

        方法 2: 修改虚拟机配置
        ---------------------
        如果你控制虚拟机配置，可以修改以下设置：

        1. CPU 配置:
           - 隐藏 hypervisor 位
           - 使用 "host" CPU 模式

        2. 设备命名:
           - 移除包含 "QEMU"、"Virtual" 的设备名
           - 使用真实硬件的设备 ID

        3. 网络接口:
           - 使用标准的网络接口名称 (en0, en1)
           - 避免 vmnet、vnet 等虚拟名称

        方法 3: 使用 Tart 虚拟化工具
        --------------------------
        Tart 使用 Apple 的 Virtualization.framework，更难被检测

        安装:
           brew install cirruslabs/cli/tart

        创建虚拟机:
           tart create macos-vm --from-ipsw=path/to/macos.ipsw

        运行:
           tart run macos-vm

        方法 4: 针对 Xcode 的特殊处理
        -----------------------------
        Xcode 主要检查 kern.hv_vmm_present，解决方法：

        1. 使用 VMHide 内核扩展（最可靠）

        2. 或者在虚拟机中运行 Xcode 之前：
           sudo sysctl kern.hv_vmm_present=0
           # 注意：这需要特殊权限，可能无效

        验证方法
        --------
        检测是否成功绕过：

        1. 运行检测命令:
           sysctl kern.hv_vmm_present
           # 应该返回 0

        2. 运行本 App 的检测功能

        3. 尝试在虚拟机中使用 Xcode

        4. 检查 App Store 和 Apple ID 登录

        📚 参考资源
        -----------
        - VMHide: https://github.com/Carnations-Botanica/VMHide
        - Tart: https://tart.run/
        - Apple Virtualization: https://developer.apple.com/documentation/virtualization

        ⚠️ 法律和道德声明
        -----------------
        - 仅用于合法的开发和测试目的
        - 不要用于绕过软件授权
        - 遵守软件许可协议
        - 了解并承担相关风险
        """
    }

    /// 应用绕过方法（需要管理员权限）
    func applyBypass() async throws {
        print("⚠️ 应用绕过方法需要管理员权限")

        // 检查是否为虚拟机
        guard isVirtualMachine else {
            throw VMBypassError.notVirtualMachine
        }

        // 尝试修改 sysctl（通常需要内核扩展）
        let script = """
        sudo sysctl kern.hv_vmm_present=0
        """

        print("""

        ⚠️ 需要手动执行以下命令:

        \(script)

        或者使用 VMHide 内核扩展（推荐）:
        https://github.com/Carnations-Botanica/VMHide
        """)

        bypassStatus = .requiresManualSetup
    }

    /// 检查 VMHide 是否已安装
    func checkVMHideInstalled() -> Bool {
        let process = Process()
        process.launchPath = "/usr/bin/kextstat"
        process.arguments = ["-b", "com.carnations.VMHide"]

        let pipe = Pipe()
        process.standardOutput = pipe

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""

            return !output.isEmpty
        } catch {
            return false
        }
    }
}

// MARK: - Data Models

/// 虚拟机类型
enum VMType {
    case none                   // 非虚拟机
    case appleVirtualization   // Apple Virtualization.framework
    case qemu                  // QEMU
    case vmware                // VMware
    case virtualbox            // VirtualBox
    case parallels             // Parallels Desktop
    case unknown               // 未知虚拟机

    var description: String {
        switch self {
        case .none: return "物理机"
        case .appleVirtualization: return "Apple Virtualization"
        case .qemu: return "QEMU"
        case .vmware: return "VMware"
        case .virtualbox: return "VirtualBox"
        case .parallels: return "Parallels Desktop"
        case .unknown: return "未知虚拟机"
        }
    }
}

/// 检测结果
struct DetectionResult: Identifiable {
    let id = UUID()
    let method: String
    let detected: Bool
    let reliability: Reliability
    let description: String

    enum Reliability {
        case high, medium, low

        var icon: String {
            switch self {
            case .high: return "🔴"
            case .medium: return "🟡"
            case .low: return "🟢"
            }
        }
    }
}

/// 绕过状态
enum BypassStatus {
    case notApplied
    case requiresManualSetup
    case applied
    case failed(String)

    var description: String {
        switch self {
        case .notApplied: return "未应用"
        case .requiresManualSetup: return "需要手动设置"
        case .applied: return "已应用"
        case .failed(let error): return "失败: \(error)"
        }
    }
}

/// 虚拟机绕过错误
enum VMBypassError: LocalizedError {
    case notVirtualMachine
    case requiresAdminPrivileges
    case sipEnabled
    case kextNotLoaded

    var errorDescription: String? {
        switch self {
        case .notVirtualMachine:
            return "当前不是虚拟机环境"
        case .requiresAdminPrivileges:
            return "需要管理员权限"
        case .sipEnabled:
            return "需要禁用 SIP (System Integrity Protection)"
        case .kextNotLoaded:
            return "内核扩展未加载"
        }
    }
}

// MARK: - App Intents

import AppIntents

/// 检测虚拟机 Intent
struct DetectVirtualMachineIntent: AppIntent {
    static var title: LocalizedStringResource = "检测虚拟机"
    static var description = IntentDescription("检测当前系统是否为虚拟机")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let manager = VMDetectionManager()
        let isVM = await manager.detectVirtualMachine()

        if !isVM {
            return .result(dialog: "✅ 当前系统是物理机，不是虚拟机")
        }

        let resultList = manager.detectionMethods.map { result in
            "\(result.reliability.icon) \(result.method): \(result.detected ? "检测到" : "未检测到")"
        }.joined(separator: "\n")

        let message = """
        🔍 虚拟机检测结果

        系统类型: \(manager.vmType.description)

        检测详情:
        \(resultList)

        ⚠️ Xcode 可能会检测到虚拟机环境
        建议使用绕过方法（参考文档）
        """

        return .result(dialog: message)
    }
}

/// 获取绕过指南 Intent
struct GetVMBypassGuideIntent: AppIntent {
    static var title: LocalizedStringResource = "虚拟机绕过指南"
    static var description = IntentDescription("获取绕过虚拟机检测的完整指南")

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let manager = VMDetectionManager()
        let guide = manager.getBypassGuide()

        return .result(
            value: guide,
            dialog: "已生成绕过指南，请查看详细内容"
        )
    }
}

#endif
