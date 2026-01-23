import Foundation
#if canImport(IOSSecuritySuite)
import IOSSecuritySuite
#endif
import Reachability

/// iOS 自动化核心 - 全平台支持
/// 支持: iOS 16+, macOS 13+, watchOS 9+, tvOS 16+
@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
public class AutomationCore {
    public static let shared = AutomationCore()
    
    private var config: Configuration
    private var securityChecker: SecurityChecker?
    private var networkMonitor: NetworkMonitor
    
    // 平台能力检测
    public struct PlatformCapabilities {
        public let canDial: Bool           // 能否拨号
        public let canAccessContacts: Bool // 能否访问联系人
        public let canUseBluetooth: Bool   // 能否使用蓝牙
        public let canUseCloudKit: Bool    // 能否使用 iCloud
        public let hasSecurityCheck: Bool  // 能否安全检测
        public let hasFileSystem: Bool     // 能否访问文件系统
    }
    
    public var capabilities: PlatformCapabilities {
        #if os(iOS)
        return PlatformCapabilities(
            canDial: true,
            canAccessContacts: true,
            canUseBluetooth: true,
            canUseCloudKit: true,
            hasSecurityCheck: true,
            hasFileSystem: true
        )
        #elseif os(macOS)
        return PlatformCapabilities(
            canDial: true,  // 通过连续互通
            canAccessContacts: true,
            canUseBluetooth: true,
            canUseCloudKit: true,
            hasSecurityCheck: true,
            hasFileSystem: true
        )
        #elseif os(watchOS)
        return PlatformCapabilities(
            canDial: true,  // watchOS 可以直接拨号
            canAccessContacts: true,
            canUseBluetooth: true,
            canUseCloudKit: true,
            hasSecurityCheck: false,
            hasFileSystem: false
        )
        #elseif os(tvOS)
        return PlatformCapabilities(
            canDial: false,
            canAccessContacts: false,
            canUseBluetooth: false,
            canUseCloudKit: true,
            hasSecurityCheck: false,
            hasFileSystem: true
        )
        #else
        return PlatformCapabilities(
            canDial: false,
            canAccessContacts: false,
            canUseBluetooth: false,
            canUseCloudKit: false,
            hasSecurityCheck: false,
            hasFileSystem: false
        )
        #endif
    }
    
    public var currentPlatform: Platform {
        #if os(iOS)
        return .iOS
        #elseif os(macOS)
        return .macOS
        #elseif os(watchOS)
        return .watchOS
        #elseif os(tvOS)
        return .tvOS
        #else
        return .unknown
        #endif
    }
    
    private init() {
        self.config = Configuration()
        
        // 如果平台支持，启用安全检查
        #if canImport(IOSSecuritySuite)
        if capabilities.hasSecurityCheck {
            self.securityChecker = SecurityChecker()
        }
        #endif
        
        self.networkMonitor = NetworkMonitor()
    }
    
    /// 初始化 - 自动适配平台
    public func initialize() async throws {
        print("""
        🚀 iOS Automation 初始化
        ━━━━━━━━━━━━━━━━━━━━━
        🖥️  平台: \(currentPlatform.name)
        📱 系统: \(ProcessInfo.processInfo.operatingSystemVersionString)
        """)
        
        print("\n✨ 平台能力:")
        print("   📞 拨号: \(capabilities.canDial ? "✓" : "✗")")
        print("   👥 联系人: \(capabilities.canAccessContacts ? "✓" : "✗")")
        print("   📡 蓝牙: \(capabilities.canUseBluetooth ? "✓" : "✗")")
        print("   ☁️  iCloud: \(capabilities.canUseCloudKit ? "✓" : "✗")")
        print("   🔒 安全检测: \(capabilities.hasSecurityCheck ? "✓" : "✗")")
        print("   📂 文件系统: \(capabilities.hasFileSystem ? "✓" : "✗")")
        
        // 执行安全检查（如果支持）
        if capabilities.hasSecurityCheck && config.enableSecurity {
            try securityChecker?.performSecurityCheck()
        }
        
        // 启动网络监控
        try await networkMonitor.startMonitoring()
        
        print("\n✅ 初始化成功\n")
    }
    
    public func getStatus() -> String {
        """
        📊 系统状态
        ━━━━━━━━━━━━━━━━━━━━━
        🖥️  \(currentPlatform.name)
        📦 v1.0.0
        🌐 \(networkMonitor.connectionType)
        \(securityChecker.map { "🔒 \($0.isSecure ? "安全" : "警告")" } ?? "")
        """
    }
}

public enum Platform {
    case iOS, macOS, watchOS, tvOS, unknown
    
    var name: String {
        switch self {
        case .iOS: return "iOS"
        case .macOS: return "macOS"
        case .watchOS: return "watchOS"
        case .tvOS: return "tvOS"
        case .unknown: return "Unknown"
        }
    }
}
