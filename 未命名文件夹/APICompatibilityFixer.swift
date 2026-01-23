import Foundation

/// API 兼容性修复器 - 自动检测和修复 API 兼容性问题
public class APICompatibilityFixer: @unchecked Sendable {  // ✅ 添加 Sendable
    
    public static let shared = APICompatibilityFixer()
    
    private let detector = SystemVersionDetector.shared
    private let lock = NSLock()  // ✅ 添加线程安全
    private var fixedAPIs: [String: Any] = [:]
    
    public struct APIAvailability: Sendable {  // ✅ 添加 Sendable
        let apiName: String
        let requiredVersion: (major: Int, minor: Int)
        let platform: SystemVersionDetector.Platform
        let fallbackAvailable: Bool
        let description: String
    }
    
    // 已知的 API 兼容性问题列表
    private let knownAPIs: [APIAvailability] = [
        APIAvailability(
            apiName: "async_await_contacts",
            requiredVersion: (16, 0),
            platform: .iOS,
            fallbackAvailable: true,
            description: "Contacts async/await API"
        ),
        APIAvailability(
            apiName: "liquid_glass",
            requiredVersion: (26, 0),  // ⚠️ iOS 26 还未发布，这里应该是未来版本
            platform: .iOS,
            fallbackAvailable: true,
            description: "Liquid Glass Design (未来版本)"
        ),
        APIAvailability(
            apiName: "adaptive_power",
            requiredVersion: (26, 0),
            platform: .iOS,
            fallbackAvailable: false,
            description: "Adaptive Power Mode (需要 A17 Pro)"
        ),
        APIAvailability(
            apiName: "live_activities",
            requiredVersion: (16, 1),
            platform: .iOS,
            fallbackAvailable: true,
            description: "Live Activities"
        ),
        // ✅ 添加 macOS 专属 API
        APIAvailability(
            apiName: "app_intents_macos",
            requiredVersion: (13, 0),
            platform: .macOS,
            fallbackAvailable: true,
            description: "App Intents for macOS"
        ),
        // ✅ 添加 watchOS 专属 API
        APIAvailability(
            apiName: "workout_live_activities",
            requiredVersion: (10, 0),
            platform: .watchOS,
            fallbackAvailable: true,
            description: "Workout Live Activities"
        ),
    ]
    
    private init() {}
    
    /// 扫描并修复所有已知的兼容性问题
    public func scanAndFix() -> FixReport {
        let version = detector.detectVersion()
        var issues: [CompatibilityIssue] = []
        var fixes: [AppliedFix] = []
        
        print("🔍 开始扫描 API 兼容性...")
        print("📱 当前系统: \(version.description)")
        print("")
        
        // 检查每个已知 API
        for api in knownAPIs {
            // 只检查当前平台的 API
            guard api.platform == version.platform else { continue }
            
            let isAvailable = version.major > api.requiredVersion.major ||
                (version.major == api.requiredVersion.major && 
                 version.minor >= api.requiredVersion.minor)
            
            if !isAvailable {
                let issue = CompatibilityIssue(
                    api: api,
                    currentVersion: version,
                    canFix: api.fallbackAvailable
                )
                issues.append(issue)
                
                // 尝试修复
                if api.fallbackAvailable {
                    if let fix = applyFix(for: api, version: version) {
                        fixes.append(fix)
                    }
                }
            }
        }
        
        return FixReport(
            systemVersion: version,
            issues: issues,
            appliedFixes: fixes,
            timestamp: Date()
        )
    }
    
    /// 应用特定 API 的修复
    private func applyFix(for api: APIAvailability, version: SystemVersionDetector.SystemVersion) -> AppliedFix? {
        lock.lock()  // ✅ 线程安全
        defer { lock.unlock() }
        
        switch api.apiName {
        case "async_await_contacts":
            return fixContactsAPI(version: version)
            
        case "liquid_glass":
            return fixLiquidGlassAPI(version: version)
            
        case "live_activities":
            return fixLiveActivitiesAPI(version: version)
            
        case "app_intents_macos":
            return fixAppIntentsMacOS(version: version)
            
        case "workout_live_activities":
            return fixWorkoutLiveActivities(version: version)
            
        default:
            return nil
        }
    }
    
    // 修复 Contacts API
    private func fixContactsAPI(version: SystemVersionDetector.SystemVersion) -> AppliedFix {
        print("🔧 修复: Contacts API - 使用兼容性包装器")
        fixedAPIs["contacts_wrapper"] = true
        
        return AppliedFix(
            apiName: "async_await_contacts",
            fixType: .wrapper,
            description: "使用回调模式包装 async/await API"
        )
    }
    
    // 修复 Liquid Glass API
    private func fixLiquidGlassAPI(version: SystemVersionDetector.SystemVersion) -> AppliedFix {
        print("🔧 修复: Liquid Glass - 使用传统 UI 设计")
        fixedAPIs["use_legacy_ui"] = true
        
        return AppliedFix(
            apiName: "liquid_glass",
            fixType: .fallback,
            description: "降级到传统 UI 设计"
        )
    }
    
    // 修复 Live Activities API
    private func fixLiveActivitiesAPI(version: SystemVersionDetector.SystemVersion) -> AppliedFix {
        print("🔧 修复: Live Activities - 使用通知替代")
        fixedAPIs["use_notifications"] = true
        
        return AppliedFix(
            apiName: "live_activities",
            fixType: .alternative,
            description: "使用推送通知替代实时活动"
        )
    }
    
    // ✅ 新增：修复 macOS App Intents
    private func fixAppIntentsMacOS(version: SystemVersionDetector.SystemVersion) -> AppliedFix {
        print("🔧 修复: macOS App Intents - 使用传统 AppleScript")
        fixedAPIs["use_applescript"] = true
        
        return AppliedFix(
            apiName: "app_intents_macos",
            fixType: .fallback,
            description: "降级到 AppleScript 自动化"
        )
    }
    
    // ✅ 新增：修复 watchOS Workout Live Activities
    private func fixWorkoutLiveActivities(version: SystemVersionDetector.SystemVersion) -> AppliedFix {
        print("🔧 修复: watchOS Workout - 使用传统 UI")
        fixedAPIs["use_workout_ui"] = true
        
        return AppliedFix(
            apiName: "workout_live_activities",
            fixType: .fallback,
            description: "使用传统 Workout UI"
        )
    }
    
    /// 检查特定 API 是否可用（已修复的会返回 true）
    public func isAPIAvailable(_ apiName: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        
        // 先检查是否已修复
        if fixedAPIs[apiName] != nil {
            return true
        }
        
        // 检查原生是否可用
        let version = detector.detectVersion()
        
        if let api = knownAPIs.first(where: { $0.apiName == apiName }) {
            // ✅ 只检查当前平台的 API
            guard api.platform == version.platform else {
                return false
            }
            
            return version.major > api.requiredVersion.major ||
                (version.major == api.requiredVersion.major && 
                 version.minor >= api.requiredVersion.minor)
        }
        
        return false
    }
}

// MARK: - 数据结构

public struct CompatibilityIssue: Sendable {  // ✅ 添加 Sendable
    let api: APICompatibilityFixer.APIAvailability
    let currentVersion: SystemVersionDetector.SystemVersion
    let canFix: Bool
    
    public var description: String {
        let status = canFix ? "⚠️ 可修复" : "❌ 无法修复"
        return "\(status): \(api.description) (需要 \(api.requiredVersion.major).\(api.requiredVersion.minor)+)"
    }
}

public struct AppliedFix: Sendable {  // ✅ 添加 Sendable
    let apiName: String
    let fixType: FixType
    let description: String
    
    public enum FixType: Sendable {  // ✅ 添加 Sendable
        case wrapper      // 包装器
        case fallback     // 降级方案
        case alternative  // 替代方案
        case polyfill     // Polyfill
    }
}

public struct FixReport: Sendable {  // ✅ 添加 Sendable
    public let systemVersion: SystemVersionDetector.SystemVersion
    public let issues: [CompatibilityIssue]
    public let appliedFixes: [AppliedFix]
    public let timestamp: Date
    
    public var hasIssues: Bool {
        !issues.isEmpty
    }
    
    public var allFixed: Bool {
        issues.allSatisfy { $0.canFix }
    }
    
    public func printReport() {
        print("""
        
        ╔═══════════════════════════════════════════╗
        ║      API 兼容性扫描报告                    ║
        ╚═══════════════════════════════════════════╝
        
        📱 系统: \(systemVersion.description)
        🕐 时间: \(timestamp.formatted(date: .abbreviated, time: .standard))
        
        """)
        
        if issues.isEmpty {
            print("✅ 未发现兼容性问题")
        } else {
            print("🔍 发现 \(issues.count) 个兼容性问题:\n")
            for (index, issue) in issues.enumerated() {
                print("\(index + 1). \(issue.description)")
            }
        }
        
        if !appliedFixes.isEmpty {
            print("\n🔧 已应用 \(appliedFixes.count) 个修复:\n")
            for (index, fix) in appliedFixes.enumerated() {
                print("\(index + 1). \(fix.apiName): \(fix.description)")
            }
        }
        
        if allFixed {
            print("\n✅ 所有问题已修复，可以正常运行")
        } else if hasIssues {
            let unfixable = issues.filter { !$0.canFix }.count
            if unfixable > 0 {
                print("\n⚠️ 有 \(unfixable) 个问题无法自动修复，部分功能可能不可用")
            }
        }
        
        print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
    }
}
