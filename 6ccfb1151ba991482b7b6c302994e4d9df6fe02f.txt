import Foundation

// ✅ 分平台导入
#if os(iOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import AppKit
#elseif os(watchOS)
import WatchKit
#endif

/// 系统版本检测器 - 运行时检测当前系统版本
public class SystemVersionDetector {
    
    public static let shared = SystemVersionDetector()
    
    // 当前系统详细版本
    public struct SystemVersion: Sendable {  // ✅ 添加 Sendable
        public let major: Int
        public let minor: Int
        public let patch: Int
        public let platform: Platform
        public let deviceModel: String
        public let isSimulator: Bool
        
        public var fullVersion: String {
            "\(major).\(minor).\(patch)"
        }
        
        public var description: String {
            "\(platform.rawValue) \(fullVersion) (\(deviceModel))"
        }
    }
    
    public enum Platform: String, Sendable {  // ✅ 添加 Sendable
        case iOS = "iOS"
        case macOS = "macOS"
        case watchOS = "watchOS"
        case tvOS = "tvOS"
        case unknown = "Unknown"
    }
    
    private init() {}
    
    /// 获取当前系统版本
    public func detectVersion() -> SystemVersion {
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        
        #if os(iOS)
        let platform = Platform.iOS
        #elseif os(macOS)
        let platform = Platform.macOS
        #elseif os(watchOS)
        let platform = Platform.watchOS
        #elseif os(tvOS)
        let platform = Platform.tvOS
        #else
        let platform = Platform.unknown
        #endif
        
        return SystemVersion(
            major: osVersion.majorVersion,
            minor: osVersion.minorVersion,
            patch: osVersion.patchVersion,
            platform: platform,
            deviceModel: getDeviceModel(),
            isSimulator: isRunningOnSimulator()
        )
    }
    
    /// 检查是否满足最低版本要求
    public func checkMinimumVersion() -> CompatibilityResult {
        let version = detectVersion()
        
        switch version.platform {
        case .iOS:
            if version.major >= 16 {
                return .compatible(version: version)
            } else {
                return .incompatible(
                    version: version,
                    reason: "需要 iOS 16.0 或更高版本，当前版本：iOS \(version.fullVersion)"
                )
            }
            
        case .macOS:
            if version.major >= 13 {
                return .compatible(version: version)
            } else {
                return .incompatible(
                    version: version,
                    reason: "需要 macOS 13.0 (Ventura) 或更高版本，当前版本：macOS \(version.fullVersion)"
                )
            }
            
        case .watchOS:
            if version.major >= 9 {
                return .compatible(version: version)
            } else {
                return .incompatible(
                    version: version,
                    reason: "需要 watchOS 9.0 或更高版本，当前版本：watchOS \(version.fullVersion)"
                )
            }
            
        case .tvOS:
            if version.major >= 16 {
                return .compatible(version: version)
            } else {
                return .incompatible(
                    version: version,
                    reason: "需要 tvOS 16.0 或更高版本，当前版本：tvOS \(version.fullVersion)"
                )
            }
            
        case .unknown:
            return .incompatible(version: version, reason: "未知平台")
        }
    }
    
    // ✅ 修复：获取设备型号（所有平台）
    private func getDeviceModel() -> String {
        #if os(iOS) || os(tvOS)
        // iOS/tvOS: 使用 utsname
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier.isEmpty ? "Unknown iOS Device" : identifier
        
        #elseif os(macOS)
        // macOS: 获取硬件型号
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var model = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &model, &size, nil, 0)
        return String(cString: model)
        
        #elseif os(watchOS)
        // watchOS: 使用 WKInterfaceDevice
        return WKInterfaceDevice.current().model
        
        #else
        return "Unknown Device"
        #endif
    }
    
    // 检测是否运行在模拟器
    private func isRunningOnSimulator() -> Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
}

// ✅ 添加 Sendable 支持
public enum CompatibilityResult: Sendable {
    case compatible(version: SystemVersionDetector.SystemVersion)
    case incompatible(version: SystemVersionDetector.SystemVersion, reason: String)
    
    public var isCompatible: Bool {
        if case .compatible = self {
            return true
        }
        return false
    }
}
