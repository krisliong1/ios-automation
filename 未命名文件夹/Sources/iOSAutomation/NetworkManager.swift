import Foundation
import Reachability
import NetworkExtension
import SystemConfiguration.CaptiveNetwork
import ExternalAccessory
import AppIntents

/// 统一网络管理器
/// 使用 Reachability.swift 进行网络可达性监控（成熟开源库，事实标准）
/// 保留 WiFi 配置和 USB 管理的自定义实现
@available(iOS 16.0, macOS 13.0, *)
@MainActor
public class NetworkManager: ObservableObject {

    // MARK: - Published Properties

    @Published public var isConnected = false
    @Published public var connectionType: ConnectionType = .unavailable
    @Published public var isWiFi = false
    @Published public var isCellular = false
    @Published public var currentWiFiInfo: WiFiNetworkInfo?

    // MARK: - Private Properties

    private var reachability: Reachability?

    // MARK: - Initialization

    public init() {
        setupReachability()
    }

    deinit {
        stopMonitoring()
    }

    // MARK: - Network Monitoring

    /// 开始监控网络状态
    public func startMonitoring() {
        do {
            try reachability?.startNotifier()
            print("📡 开始监控网络状态")
        } catch {
            print("❌ 无法启动网络监控: \(error)")
        }
    }

    /// 停止监控
    public func stopMonitoring() {
        reachability?.stopNotifier()
        print("📡 停止监控网络状态")
    }

    /// 检查网络是否可用
    public func isNetworkAvailable() -> Bool {
        return reachability?.connection != .unavailable
    }

    /// 获取网络状态报告
    public func getNetworkStatus() -> String {
        guard let reachability = reachability else {
            return "⚠️ 网络监控未初始化"
        }

        var status = """
        📶 网络状态报告
        ==================

        连接状态: \(isConnected ? "✅ 已连接" : "❌ 未连接")
        连接类型: \(connectionType.description)
        """

        switch reachability.connection {
        case .wifi:
            status += "\n\n当前使用 WiFi 连接"
            if let wifiInfo = currentWiFiInfo {
                status += """

                WiFi 详情:
                - SSID: \(wifiInfo.ssid)
                - 信号: \(wifiInfo.signalQuality)
                - 安全: \(wifiInfo.isSecure ? "加密" : "开放")
                """
            }

        case .cellular:
            status += "\n\n当前使用蜂窝数据"
            status += "\n💰 注意：可能产生流量费用"

        case .unavailable:
            status += "\n\n⚠️ 网络不可用"

        case .none:
            status += "\n\n状态未知"
        }

        return status
    }

    // MARK: - Private Methods

    private func setupReachability() {
        do {
            reachability = try Reachability()

            // 配置网络变化回调
            reachability?.whenReachable = { [weak self] reachability in
                Task { @MainActor in
                    self?.handleReachable(reachability)
                }
            }

            reachability?.whenUnreachable = { [weak self] _ in
                Task { @MainActor in
                    self?.handleUnreachable()
                }
            }

        } catch {
            print("❌ 无法创建 Reachability: \(error)")
        }
    }

    private func handleReachable(_ reachability: Reachability) {
        isConnected = true

        switch reachability.connection {
        case .wifi:
            connectionType = .wifi
            isWiFi = true
            isCellular = false
            print("🌐 网络可达: WiFi")

            // 获取 WiFi 信息
            Task {
                currentWiFiInfo = await WiFiManager.shared.getCurrentWiFiInfo()
            }

        case .cellular:
            connectionType = .cellular
            isWiFi = false
            isCellular = true
            print("🌐 网络可达: 蜂窝数据")

        case .unavailable, .none:
            handleUnreachable()
        }
    }

    private func handleUnreachable() {
        isConnected = false
        connectionType = .unavailable
        isWiFi = false
        isCellular = false
        currentWiFiInfo = nil
        print("🌐 网络不可达")
    }
}

// MARK: - WiFi Manager

/// WiFi 配置和管理器（保留自定义实现）
@available(iOS 16.0, *)
@MainActor
public class WiFiManager: ObservableObject {

    public static let shared = WiFiManager()

    private init() {}

    /// 获取当前 WiFi 信息
    public func getCurrentWiFiInfo() async -> WiFiNetworkInfo? {
        #if os(iOS)
        if #available(iOS 14.0, *) {
            return await getWiFiInfoiOS14()
        } else {
            return getWiFiInfoLegacy()
        }
        #else
        return nil
        #endif
    }

    /// 连接到指定 WiFi 网络
    public func connectToWiFi(ssid: String, password: String) async throws {
        #if os(iOS)
        let configuration = NEHotspotConfiguration(
            ssid: ssid,
            passphrase: password,
            isWEP: false
        )

        configuration.joinOnce = false // 永久保存

        do {
            try await NEHotspotConfigurationManager.shared.apply(configuration)
            print("✅ 已连接到 WiFi: \(ssid)")
        } catch {
            print("❌ 连接 WiFi 失败: \(error.localizedDescription)")
            throw NetworkError.connectionFailed(error.localizedDescription)
        }
        #endif
    }

    /// 移除已保存的 WiFi 配置
    public func removeWiFiConfiguration(ssid: String) {
        #if os(iOS)
        NEHotspotConfigurationManager.shared.removeConfiguration(forSSID: ssid)
        print("🗑️ 已移除 WiFi 配置: \(ssid)")
        #endif
    }

    // MARK: - Private Methods

    #if os(iOS)
    @available(iOS 14.0, *)
    private func getWiFiInfoiOS14() async -> WiFiNetworkInfo? {
        do {
            let networks = try await NEHotspotNetwork.fetchCurrent()
            guard let network = networks else { return nil }

            return WiFiNetworkInfo(
                ssid: network.ssid,
                bssid: network.bssid ?? "Unknown",
                signalStrength: Int(network.signalStrength),
                isSecure: network.isSecure,
                isAutoJoined: network.didAutoJoin
            )
        } catch {
            print("❌ 获取 WiFi 信息失败: \(error)")
            return nil
        }
    }

    private func getWiFiInfoLegacy() -> WiFiNetworkInfo? {
        guard let interfaces = CNCopySupportedInterfaces() as? [String] else {
            return nil
        }

        for interface in interfaces {
            guard let info = CNCopyCurrentNetworkInfo(interface as CFString) as? [String: Any] else {
                continue
            }

            let ssid = info[kCNNetworkInfoKeySSID as String] as? String ?? "Unknown"
            let bssid = info[kCNNetworkInfoKeyBSSID as String] as? String ?? "Unknown"

            return WiFiNetworkInfo(
                ssid: ssid,
                bssid: bssid,
                signalStrength: 0,
                isSecure: true,
                isAutoJoined: false
            )
        }

        return nil
    }
    #endif
}

// MARK: - USB Manager

/// USB/外部配件管理器（保留自定义实现）
@available(iOS 16.0, *)
@MainActor
public class USBManager: NSObject, ObservableObject {

    public static let shared = USBManager()

    @Published public var connectedAccessories: [ConnectedAccessory] = []
    @Published public var isMonitoring = false

    private override init() {
        super.init()
        setupNotifications()
    }

    /// 开始监控 USB 连接
    public func startMonitoring() {
        isMonitoring = true
        refreshAccessoryList()
        print("🔌 开始监控 USB/配件连接")
    }

    /// 停止监控
    public func stopMonitoring() {
        isMonitoring = false
        print("🔌 停止监控 USB/配件连接")
    }

    /// 刷新配件列表
    public func refreshAccessoryList() {
        #if os(iOS)
        let accessories = EAAccessoryManager.shared().connectedAccessories

        connectedAccessories = accessories.map { accessory in
            ConnectedAccessory(
                name: accessory.name,
                manufacturer: accessory.manufacturer,
                modelNumber: accessory.modelNumber,
                serialNumber: accessory.serialNumber,
                firmwareRevision: accessory.firmwareRevision,
                hardwareRevision: accessory.hardwareRevision,
                protocolStrings: accessory.protocolStrings
            )
        }

        print("🔌 发现 \(connectedAccessories.count) 个已连接配件")
        #endif
    }

    /// 获取配件详细信息
    public func getAccessoryDetails(_ accessory: ConnectedAccessory) -> String {
        """
        📱 配件详细信息

        名称: \(accessory.name)
        制造商: \(accessory.manufacturer)
        型号: \(accessory.modelNumber)
        序列号: \(accessory.serialNumber)
        固件版本: \(accessory.firmwareRevision)
        硬件版本: \(accessory.hardwareRevision)
        支持协议: \(accessory.protocolStrings.joined(separator: ", "))
        """
    }

    // MARK: - Private Methods

    private func setupNotifications() {
        #if os(iOS)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(accessoryDidConnect),
            name: .EAAccessoryDidConnect,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(accessoryDidDisconnect),
            name: .EAAccessoryDidDisconnect,
            object: nil
        )

        EAAccessoryManager.shared().registerForLocalNotifications()
        #endif
    }

    @objc private func accessoryDidConnect(_ notification: Notification) {
        Task { @MainActor in
            #if os(iOS)
            guard let accessory = notification.userInfo?[EAAccessoryKey] as? EAAccessory else {
                return
            }

            print("✅ 配件已连接: \(accessory.name)")
            refreshAccessoryList()
            #endif
        }
    }

    @objc private func accessoryDidDisconnect(_ notification: Notification) {
        Task { @MainActor in
            #if os(iOS)
            guard let accessory = notification.userInfo?[EAAccessoryKey] as? EAAccessory else {
                return
            }

            print("🔌 配件已断开: \(accessory.name)")
            refreshAccessoryList()
            #endif
        }
    }
}

// MARK: - Data Models

/// 连接类型
public enum ConnectionType {
    case wifi
    case cellular
    case unavailable

    public var description: String {
        switch self {
        case .wifi: return "WiFi"
        case .cellular: return "蜂窝数据"
        case .unavailable: return "不可用"
        }
    }
}

/// WiFi 网络信息
public struct WiFiNetworkInfo: Identifiable {
    public let id = UUID()
    public let ssid: String
    public let bssid: String
    public let signalStrength: Int
    public let isSecure: Bool
    public let isAutoJoined: Bool

    public var signalQuality: String {
        switch signalStrength {
        case -50...0: return "优秀 📶"
        case -60 ..< -50: return "良好 📶"
        case -70 ..< -60: return "一般 📶"
        default: return "较弱 📶"
        }
    }
}

/// 已连接的配件
public struct ConnectedAccessory: Identifiable {
    public let id = UUID()
    public let name: String
    public let manufacturer: String
    public let modelNumber: String
    public let serialNumber: String
    public let firmwareRevision: String
    public let hardwareRevision: String
    public let protocolStrings: [String]
}

/// 网络错误
public enum NetworkError: LocalizedError {
    case connectionFailed(String)
    case notAvailable
    case permissionDenied

    public var errorDescription: String? {
        switch self {
        case .connectionFailed(let message):
            return "连接失败: \(message)"
        case .notAvailable:
            return "网络不可用"
        case .permissionDenied:
            return "权限被拒绝"
        }
    }
}

// MARK: - App Intents

/// 获取网络状态 Intent
public struct GetNetworkStatusIntent: AppIntent {
    public static var title: LocalizedStringResource = "获取网络状态"
    public static var description = IntentDescription("获取当前网络连接状态和详细信息")

    public init() {}

    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let manager = NetworkManager()
        manager.startMonitoring()

        // 等待状态更新
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 秒

        let status = manager.getNetworkStatus()

        return .result(dialog: status)
    }
}

/// 获取 WiFi 信息 Intent
public struct GetWiFiInfoIntent: AppIntent {
    public static var title: LocalizedStringResource = "获取 WiFi 信息"
    public static var description = IntentDescription("获取当前连接的 WiFi 网络详细信息")

    public init() {}

    public func perform() async throws -> some IntentResult & ProvidesDialog {
        if let wifiInfo = await WiFiManager.shared.getCurrentWiFiInfo() {
            let message = """
            📶 WiFi 信息

            网络名称: \(wifiInfo.ssid)
            信号质量: \(wifiInfo.signalQuality)
            安全性: \(wifiInfo.isSecure ? "✅ 加密" : "⚠️ 开放")
            自动连接: \(wifiInfo.isAutoJoined ? "是" : "否")
            """

            return .result(dialog: message)
        } else {
            return .result(dialog: "❌ 未连接到 WiFi 或无法获取信息")
        }
    }
}

/// 检测 USB 设备 Intent
public struct DetectUSBDevicesIntent: AppIntent {
    public static var title: LocalizedStringResource = "检测 USB 设备"
    public static var description = IntentDescription("检测已连接的 USB 设备和配件")

    public init() {}

    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let manager = USBManager.shared
        manager.refreshAccessoryList()

        let accessories = manager.connectedAccessories

        if accessories.isEmpty {
            return .result(dialog: "🔌 未检测到 USB 设备")
        }

        let deviceList = accessories.map { accessory in
            "• \(accessory.name) (\(accessory.manufacturer))"
        }.joined(separator: "\n")

        let message = """
        🔌 已连接设备 (\(accessories.count) 个)

        \(deviceList)
        """

        return .result(dialog: message)
    }
}
