import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// 设备信息管理器
/// 检测设备型号、系统版本、硬件配置等信息
@available(iOS 14.0, macOS 11.0, *)
class DeviceInfoManager: ObservableObject {

    // MARK: - Published Properties

    @Published var deviceModel: String = ""
    @Published var systemVersion: String = ""
    @Published var deviceName: String = ""
    @Published var isSimulator: Bool = false
    @Published var cpuArchitecture: String = ""
    @Published var totalMemory: String = ""
    @Published var diskSpace: String = ""
    @Published var deviceIdentifier: String = ""

    // MARK: - Device Info

    /// 设备详细信息
    struct DeviceInfo: Codable {
        let model: String              // 设备型号（如 iPhone 14 Pro）
        let modelIdentifier: String    // 设备标识符（如 iPhone15,2）
        let systemName: String          // 系统名称（iOS/macOS）
        let systemVersion: String       // 系统版本（如 17.0）
        let deviceName: String          // 设备名称（用户设置的名称）
        let isSimulator: Bool           // 是否为模拟器
        let cpuType: String             // CPU 类型（arm64/x86_64）
        let totalRAM: UInt64            // 总内存（字节）
        let totalDisk: UInt64           // 总磁盘空间（字节）
        let screenSize: String          // 屏幕尺寸
        let screenScale: CGFloat        // 屏幕缩放比例
    }

    // MARK: - Initialization

    init() {
        detectDeviceInfo()
    }

    // MARK: - Detection Methods

    /// 检测设备信息
    func detectDeviceInfo() {
        #if os(iOS)
        detectIOSDeviceInfo()
        #elseif os(macOS)
        detectMacOSDeviceInfo()
        #endif

        print("📱 设备信息检测完成")
        print("   型号: \(deviceModel)")
        print("   系统: \(systemVersion)")
        print("   架构: \(cpuArchitecture)")
    }

    #if os(iOS)
    /// 检测 iOS 设备信息
    private func detectIOSDeviceInfo() {
        let device = UIDevice.current

        // 设备名称和系统
        deviceName = device.name
        systemVersion = "\(device.systemName) \(device.systemVersion)"

        // 设备型号标识符
        let modelIdentifier = getModelIdentifier()
        deviceIdentifier = modelIdentifier

        // 翻译为用户友好的型号名称
        deviceModel = translateModelIdentifier(modelIdentifier)

        // 检测是否为模拟器
        isSimulator = checkIfSimulator()

        // CPU 架构
        cpuArchitecture = getCPUArchitecture()

        // 内存信息
        totalMemory = formatBytes(getPhysicalMemory())

        // 磁盘空间
        totalDisk = formatBytes(getTotalDiskSpace())
    }
    #endif

    #if os(macOS)
    /// 检测 macOS 设备信息
    private func detectMacOSDeviceInfo() {
        // macOS 设备信息
        deviceName = Host.current().localizedName ?? "Mac"
        systemVersion = "macOS \(ProcessInfo.processInfo.operatingSystemVersionString)"

        // 获取 Mac 型号
        deviceModel = getMacModel()
        deviceIdentifier = getMacModelIdentifier()

        // 检测是否为虚拟机
        isSimulator = false // macOS 没有模拟器概念

        // CPU 架构
        cpuArchitecture = getCPUArchitecture()

        // 内存信息
        totalMemory = formatBytes(getPhysicalMemory())

        // 磁盘空间
        totalDisk = formatBytes(getTotalDiskSpace())
    }
    #endif

    // MARK: - iOS Model Detection

    #if os(iOS)
    /// 获取设备型号标识符
    private func getModelIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)

        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }

        return identifier
    }

    /// 翻译设备标识符为友好名称
    private func translateModelIdentifier(_ identifier: String) -> String {
        let modelMapping: [String: String] = [
            // iPhone 15 系列
            "iPhone15,4": "iPhone 15",
            "iPhone15,5": "iPhone 15 Plus",
            "iPhone16,1": "iPhone 15 Pro",
            "iPhone16,2": "iPhone 15 Pro Max",

            // iPhone 14 系列
            "iPhone14,7": "iPhone 14",
            "iPhone14,8": "iPhone 14 Plus",
            "iPhone15,2": "iPhone 14 Pro",
            "iPhone15,3": "iPhone 14 Pro Max",

            // iPhone 13 系列
            "iPhone14,4": "iPhone 13 mini",
            "iPhone14,5": "iPhone 13",
            "iPhone14,2": "iPhone 13 Pro",
            "iPhone14,3": "iPhone 13 Pro Max",

            // iPhone 12 系列
            "iPhone13,1": "iPhone 12 mini",
            "iPhone13,2": "iPhone 12",
            "iPhone13,3": "iPhone 12 Pro",
            "iPhone13,4": "iPhone 12 Pro Max",

            // iPhone 11 系列
            "iPhone12,1": "iPhone 11",
            "iPhone12,3": "iPhone 11 Pro",
            "iPhone12,5": "iPhone 11 Pro Max",

            // iPhone SE
            "iPhone14,6": "iPhone SE (3rd generation)",
            "iPhone12,8": "iPhone SE (2nd generation)",

            // iPad Pro
            "iPad13,18": "iPad Pro 12.9-inch (6th generation)",
            "iPad13,16": "iPad Pro 11-inch (4th generation)",
            "iPad8,11": "iPad Pro 12.9-inch (5th generation)",
            "iPad8,9": "iPad Pro 11-inch (3rd generation)",

            // iPad Air
            "iPad13,16": "iPad Air (5th generation)",
            "iPad13,1": "iPad Air (4th generation)",

            // iPad
            "iPad13,18": "iPad (10th generation)",
            "iPad12,1": "iPad (9th generation)",

            // iPad mini
            "iPad14,1": "iPad mini (6th generation)",
        ]

        return modelMapping[identifier] ?? identifier
    }

    /// 检测是否为模拟器
    private func checkIfSimulator() -> Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    #endif

    // MARK: - macOS Model Detection

    #if os(macOS)
    /// 获取 Mac 型号
    private func getMacModel() -> String {
        let service = IOServiceGetMatchingService(
            kIOMasterPortDefault,
            IOServiceMatching("IOPlatformExpertDevice")
        )

        defer { IOObjectRelease(service) }

        guard service != 0 else { return "Unknown Mac" }

        if let modelData = IORegistryEntryCreateCFProperty(
            service,
            "model" as CFString,
            kCFAllocatorDefault,
            0
        )?.takeRetainedValue() as? Data {
            if let model = String(data: modelData, encoding: .utf8)?
                .trimmingCharacters(in: .controlCharacters) {
                return translateMacModel(model)
            }
        }

        return "Unknown Mac"
    }

    /// 获取 Mac 型号标识符
    private func getMacModelIdentifier() -> String {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)

        var model = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &model, &size, nil, 0)

        return String(cString: model)
    }

    /// 翻译 Mac 型号
    private func translateMacModel(_ identifier: String) -> String {
        // 简化的 Mac 型号翻译
        if identifier.contains("MacBookPro") {
            return "MacBook Pro"
        } else if identifier.contains("MacBookAir") {
            return "MacBook Air"
        } else if identifier.contains("iMac") {
            return "iMac"
        } else if identifier.contains("Macmini") {
            return "Mac mini"
        } else if identifier.contains("MacPro") {
            return "Mac Pro"
        } else if identifier.contains("MacStudio") {
            return "Mac Studio"
        }

        return identifier
    }
    #endif

    // MARK: - CPU Architecture

    /// 获取 CPU 架构
    private func getCPUArchitecture() -> String {
        var size = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)

        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.machine", &machine, &size, nil, 0)

        let arch = String(cString: machine)

        switch arch {
        case "arm64", "arm64e":
            return "Apple Silicon (ARM64)"
        case "x86_64", "i386":
            return "Intel (x86_64)"
        default:
            return arch
        }
    }

    // MARK: - Memory Detection

    /// 获取物理内存大小
    private func getPhysicalMemory() -> UInt64 {
        var size: UInt64 = 0
        var len = MemoryLayout<UInt64>.size
        sysctlbyname("hw.memsize", &size, &len, nil, 0)
        return size
    }

    /// 获取总磁盘空间
    private func getTotalDiskSpace() -> UInt64 {
        #if os(iOS)
        if let attributes = try? FileManager.default.attributesOfFileSystem(
            forPath: NSHomeDirectory()
        ) {
            if let totalSize = attributes[.systemSize] as? NSNumber {
                return totalSize.uint64Value
            }
        }
        #elseif os(macOS)
        if let attributes = try? FileManager.default.attributesOfFileSystem(
            forPath: "/"
        ) {
            if let totalSize = attributes[.systemSize] as? NSNumber {
                return totalSize.uint64Value
            }
        }
        #endif

        return 0
    }

    /// 格式化字节数
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }

    // MARK: - System Version Check

    /// 检查系统版本是否满足要求
    func checkSystemVersion(minimum: String) -> Bool {
        let current = ProcessInfo.processInfo.operatingSystemVersion

        let components = minimum.split(separator: ".").compactMap { Int($0) }
        guard components.count >= 2 else { return false }

        let requiredMajor = components[0]
        let requiredMinor = components[1]
        let requiredPatch = components.count > 2 ? components[2] : 0

        if current.majorVersion > requiredMajor { return true }
        if current.majorVersion < requiredMajor { return false }

        if current.minorVersion > requiredMinor { return true }
        if current.minorVersion < requiredMinor { return false }

        return current.patchVersion >= requiredPatch
    }

    /// 检查是否为特定设备型号
    func isDevice(_ models: [String]) -> Bool {
        return models.contains { deviceIdentifier.contains($0) }
    }

    /// 检查是否为 iPad
    func isIPad() -> Bool {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad
        #else
        return false
        #endif
    }

    /// 检查是否为 iPhone
    func isIPhone() -> Bool {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .phone
        #else
        return false
        #endif
    }

    // MARK: - Export Device Info

    /// 获取完整设备信息
    func getDeviceInfo() -> DeviceInfo {
        #if os(iOS)
        let screen = UIScreen.main
        let screenSize = "\(Int(screen.bounds.width)) x \(Int(screen.bounds.height))"
        let screenScale = screen.scale
        #elseif os(macOS)
        let screen = NSScreen.main
        let screenSize = screen != nil ? "\(Int(screen!.frame.width)) x \(Int(screen!.frame.height))" : "Unknown"
        let screenScale = screen?.backingScaleFactor ?? 1.0
        #endif

        return DeviceInfo(
            model: deviceModel,
            modelIdentifier: deviceIdentifier,
            systemName: systemVersion.components(separatedBy: " ").first ?? "Unknown",
            systemVersion: systemVersion.components(separatedBy: " ").last ?? "Unknown",
            deviceName: deviceName,
            isSimulator: isSimulator,
            cpuType: cpuArchitecture,
            totalRAM: getPhysicalMemory(),
            totalDisk: getTotalDiskSpace(),
            screenSize: screenSize,
            screenScale: screenScale
        )
    }

    /// 生成设备信息报告
    func generateReport() -> String {
        let info = getDeviceInfo()

        return """
        📱 设备信息报告
        ================

        基本信息
        --------
        设备名称: \(info.deviceName)
        设备型号: \(info.model)
        型号标识: \(info.modelIdentifier)
        系统版本: \(info.systemName) \(info.systemVersion)
        模拟器: \(info.isSimulator ? "是" : "否")

        硬件配置
        --------
        CPU 架构: \(info.cpuType)
        总内存: \(formatBytes(info.totalRAM))
        磁盘空间: \(formatBytes(info.totalDisk))

        显示
        ----
        屏幕尺寸: \(info.screenSize)
        缩放比例: \(info.screenScale)x

        """
    }
}

// MARK: - Device Compatibility Checker

@available(iOS 14.0, macOS 11.0, *)
extension DeviceInfoManager {

    /// 检查应用兼容性
    struct CompatibilityRequirements {
        let minimumIOSVersion: String?
        let minimumMacOSVersion: String?
        let requiredRAM: UInt64?  // 字节
        let requiredDisk: UInt64? // 字节
        let supportedDevices: [String]? // 设备标识符列表
        let excludedDevices: [String]? // 排除的设备
    }

    /// 检查设备兼容性
    func checkCompatibility(requirements: CompatibilityRequirements) -> (compatible: Bool, reasons: [String]) {
        var compatible = true
        var reasons: [String] = []

        #if os(iOS)
        // 检查 iOS 版本
        if let minVersion = requirements.minimumIOSVersion {
            if !checkSystemVersion(minimum: minVersion) {
                compatible = false
                reasons.append("需要 iOS \(minVersion) 或更高版本")
            }
        }
        #elseif os(macOS)
        // 检查 macOS 版本
        if let minVersion = requirements.minimumMacOSVersion {
            if !checkSystemVersion(minimum: minVersion) {
                compatible = false
                reasons.append("需要 macOS \(minVersion) 或更高版本")
            }
        }
        #endif

        // 检查内存
        if let requiredRAM = requirements.requiredRAM {
            let totalRAM = getPhysicalMemory()
            if totalRAM < requiredRAM {
                compatible = false
                reasons.append("需要至少 \(formatBytes(requiredRAM)) 内存")
            }
        }

        // 检查磁盘空间
        if let requiredDisk = requirements.requiredDisk {
            let totalDisk = getTotalDiskSpace()
            if totalDisk < requiredDisk {
                compatible = false
                reasons.append("需要至少 \(formatBytes(requiredDisk)) 磁盘空间")
            }
        }

        // 检查支持的设备列表
        if let supportedDevices = requirements.supportedDevices {
            let isSupported = supportedDevices.contains { deviceIdentifier.contains($0) }
            if !isSupported {
                compatible = false
                reasons.append("设备型号不支持")
            }
        }

        // 检查排除的设备列表
        if let excludedDevices = requirements.excludedDevices {
            let isExcluded = excludedDevices.contains { deviceIdentifier.contains($0) }
            if isExcluded {
                compatible = false
                reasons.append("此设备不支持")
            }
        }

        return (compatible, reasons)
    }
}
