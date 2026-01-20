import Foundation
import Network
import SystemConfiguration.CaptiveNetwork
import NetworkExtension

/// 网络连接管理器 - WiFi 连接和检测
@MainActor
class NetworkConnectionManager: ObservableObject {

    // MARK: - Published Properties

    @Published var isConnectedToWiFi = false
    @Published var currentNetworkInfo: WiFiNetworkInfo?
    @Published var networkStatus: NetworkStatus = .unknown
    @Published var connectionType: ConnectionType = .unknown

    // MARK: - Private Properties

    private let pathMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "NetworkMonitor")

    // MARK: - Initialization

    init() {
        startMonitoring()
    }

    deinit {
        stopMonitoring()
    }

    // MARK: - Public Methods

    /// 开始监控网络状态
    func startMonitoring() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.handlePathUpdate(path)
            }
        }

        pathMonitor.start(queue: monitorQueue)
        print("📡 开始监控网络状态")
    }

    /// 停止监控
    func stopMonitoring() {
        pathMonitor.cancel()
        print("📡 停止监控网络状态")
    }

    /// 获取当前 WiFi 信息（需要权限）
    func getCurrentWiFiInfo() async -> WiFiNetworkInfo? {
        // iOS 14+ 使用 NEHotspotNetwork
        if #available(iOS 14.0, *) {
            return await getWiFiInfoiOS14()
        } else {
            return getWiFiInfoLegacy()
        }
    }

    /// 连接到指定 WiFi 网络
    /// 注意：用户需要预先知道 SSID 和密码
    func connectToWiFi(ssid: String, password: String) async throws {
        let configuration = NEHotspotConfiguration(
            ssid: ssid,
            passphrase: password,
            isWEP: false
        )

        configuration.joinOnce = false // 永久保存

        do {
            try await NEHotspotConfigurationManager.shared.apply(configuration)
            print("✅ 已连接到 WiFi: \(ssid)")

            // 更新网络信息
            currentNetworkInfo = await getCurrentWiFiInfo()
        } catch {
            print("❌ 连接 WiFi 失败: \(error.localizedDescription)")
            throw NetworkError.connectionFailed(error.localizedDescription)
        }
    }

    /// 移除已保存的 WiFi 配置
    func removeWiFiConfiguration(ssid: String) {
        NEHotspotConfigurationManager.shared.removeConfiguration(forSSID: ssid)
        print("🗑️ 已移除 WiFi 配置: \(ssid)")
    }

    /// 检查网络连接性
    func checkConnectivity() -> Bool {
        let path = pathMonitor.currentPath
        return path.status == .satisfied
    }

    /// 获取网络详细信息
    func getNetworkDetails() -> String {
        let path = pathMonitor.currentPath

        var details = """
        📶 网络状态详情

        连接状态: \(networkStatus.description)
        连接类型: \(connectionType.description)
        是否满足: \(path.status == .satisfied ? "是" : "否")
        """

        // 可用接口
        let interfaces = path.availableInterfaces.map { $0.name }.joined(separator: ", ")
        if !interfaces.isEmpty {
            details += "\n可用接口: \(interfaces)"
        }

        // 网络特性
        if path.isExpensive {
            details += "\n💰 使用的是昂贵网络（蜂窝数据）"
        }

        if path.isConstrained {
            details += "\n⚠️ 网络受限（低数据模式）"
        }

        if #available(iOS 14.0, *) {
            if path.supportsIPv4 {
                details += "\n✅ 支持 IPv4"
            }
            if path.supportsIPv6 {
                details += "\n✅ 支持 IPv6"
            }
        }

        return details
    }

    // MARK: - Private Methods

    private func handlePathUpdate(_ path: NWPath) {
        // 更新连接状态
        switch path.status {
        case .satisfied:
            networkStatus = .connected
        case .unsatisfied:
            networkStatus = .disconnected
        case .requiresConnection:
            networkStatus = .requiresConnection
        @unknown default:
            networkStatus = .unknown
        }

        // 判断连接类型
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
            isConnectedToWiFi = true
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
            isConnectedToWiFi = false
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .ethernet
            isConnectedToWiFi = false
        } else {
            connectionType = .unknown
            isConnectedToWiFi = false
        }

        print("🌐 网络状态更新: \(networkStatus.description), 类型: \(connectionType.description)")

        // 如果连接到 WiFi，获取详细信息
        if isConnectedToWiFi {
            Task {
                currentNetworkInfo = await getCurrentWiFiInfo()
            }
        }
    }

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
        // iOS 13 及以下使用 CaptiveNetwork API（已过时）
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
                signalStrength: 0, // 无法获取
                isSecure: true, // 假设是安全的
                isAutoJoined: false
            )
        }

        return nil
    }
}

// MARK: - USB 连接管理器

import ExternalAccessory

/// USB/外部配件连接管理器
@MainActor
class USBConnectionManager: NSObject, ObservableObject {

    // MARK: - Published Properties

    @Published var connectedAccessories: [ConnectedAccessory] = []
    @Published var isMonitoring = false

    // MARK: - Initialization

    override init() {
        super.init()
        setupNotifications()
    }

    // MARK: - Public Methods

    /// 开始监控 USB 连接
    func startMonitoring() {
        isMonitoring = true
        refreshAccessoryList()
        print("🔌 开始监控 USB/配件连接")
    }

    /// 停止监控
    func stopMonitoring() {
        isMonitoring = false
        print("🔌 停止监控 USB/配件连接")
    }

    /// 刷新配件列表
    func refreshAccessoryList() {
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
    }

    /// 获取配件详细信息
    func getAccessoryDetails(_ accessory: ConnectedAccessory) -> String {
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
    }

    @objc private func accessoryDidConnect(_ notification: Notification) {
        Task { @MainActor in
            guard let accessory = notification.userInfo?[EAAccessoryKey] as? EAAccessory else {
                return
            }

            print("✅ 配件已连接: \(accessory.name)")
            refreshAccessoryList()
        }
    }

    @objc private func accessoryDidDisconnect(_ notification: Notification) {
        Task { @MainActor in
            guard let accessory = notification.userInfo?[EAAccessoryKey] as? EAAccessory else {
                return
            }

            print("🔌 配件已断开: \(accessory.name)")
            refreshAccessoryList()
        }
    }
}

// MARK: - Data Models

/// WiFi 网络信息
struct WiFiNetworkInfo: Identifiable {
    let id = UUID()
    let ssid: String
    let bssid: String
    let signalStrength: Int // -100 到 0 (dBm)
    let isSecure: Bool
    let isAutoJoined: Bool

    var signalQuality: String {
        switch signalStrength {
        case -50...0: return "优秀 📶"
        case -60 ..< -50: return "良好 📶"
        case -70 ..< -60: return "一般 📶"
        default: return "较弱 📶"
        }
    }
}

/// 网络状态
enum NetworkStatus {
    case connected
    case disconnected
    case requiresConnection
    case unknown

    var description: String {
        switch self {
        case .connected: return "已连接"
        case .disconnected: return "未连接"
        case .requiresConnection: return "需要连接"
        case .unknown: return "未知"
        }
    }
}

/// 连接类型
enum ConnectionType {
    case wifi
    case cellular
    case ethernet
    case unknown

    var description: String {
        switch self {
        case .wifi: return "WiFi"
        case .cellular: return "蜂窝数据"
        case .ethernet: return "以太网"
        case .unknown: return "未知"
        }
    }
}

/// 已连接的配件
struct ConnectedAccessory: Identifiable {
    let id = UUID()
    let name: String
    let manufacturer: String
    let modelNumber: String
    let serialNumber: String
    let firmwareRevision: String
    let hardwareRevision: String
    let protocolStrings: [String]
}

/// 网络错误
enum NetworkError: LocalizedError {
    case connectionFailed(String)
    case notAvailable
    case permissionDenied

    var errorDescription: String? {
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

import AppIntents

/// 获取 WiFi 信息 Intent
struct GetWiFiInfoIntent: AppIntent {
    static var title: LocalizedStringResource = "获取 WiFi 信息"
    static var description = IntentDescription("获取当前连接的 WiFi 网络信息")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let manager = NetworkConnectionManager()

        guard manager.isConnectedToWiFi else {
            return .result(dialog: "❌ 未连接到 WiFi")
        }

        if let wifiInfo = await manager.getCurrentWiFiInfo() {
            let message = """
            📶 WiFi 信息

            网络名称: \(wifiInfo.ssid)
            信号质量: \(wifiInfo.signalQuality)
            安全性: \(wifiInfo.isSecure ? "✅ 加密" : "⚠️ 开放")
            自动连接: \(wifiInfo.isAutoJoined ? "是" : "否")
            """

            return .result(dialog: message)
        } else {
            return .result(dialog: "⚠️ 无法获取 WiFi 信息")
        }
    }
}

/// 检测 USB 设备 Intent
struct DetectUSBDevicesIntent: AppIntent {
    static var title: LocalizedStringResource = "检测 USB 设备"
    static var description = IntentDescription("检测已连接的 USB 设备和配件")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let manager = USBConnectionManager()
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

/// 获取网络详情 Intent
struct GetNetworkDetailsIntent: AppIntent {
    static var title: LocalizedStringResource = "获取网络详情"
    static var description = IntentDescription("获取详细的网络连接信息")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let manager = NetworkConnectionManager()
        let details = manager.getNetworkDetails()

        return .result(dialog: details)
    }
}
