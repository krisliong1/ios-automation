import Foundation
import CoreBluetooth
import Combine

/// 蓝牙连接管理器 - 兼容任何 BLE 设备
/// 基于 CoreBluetooth 框架
@MainActor
class BluetoothManager: NSObject, ObservableObject {

    // MARK: - Published Properties

    @Published var isBluetoothAvailable = false
    @Published var isScanning = false
    @Published var discoveredDevices: [BluetoothDevice] = []
    @Published var connectedDevice: BluetoothDevice?
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var receivedData: String = ""

    // MARK: - Private Properties

    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    private var discoveredPeripherals: [UUID: CBPeripheral] = [:]
    private var writeCharacteristic: CBCharacteristic?
    private var notifyCharacteristic: CBCharacteristic?

    // MARK: - Initialization

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    // MARK: - Public Methods

    /// 开始扫描蓝牙设备
    func startScanning(serviceUUIDs: [CBUUID]? = nil) {
        guard centralManager.state == .poweredOn else {
            print("❌ 蓝牙未打开")
            return
        }

        print("🔍 开始扫描蓝牙设备...")
        isScanning = true
        discoveredDevices.removeAll()
        discoveredPeripherals.removeAll()

        // 扫描所有设备（如果不指定 serviceUUIDs）
        centralManager.scanForPeripherals(
            withServices: serviceUUIDs,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )

        // 30 秒后自动停止扫描
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) { [weak self] in
            self?.stopScanning()
        }
    }

    /// 停止扫描
    func stopScanning() {
        guard isScanning else { return }

        print("⏹️ 停止扫描")
        centralManager.stopScan()
        isScanning = false
    }

    /// 连接到设备
    func connect(to device: BluetoothDevice) {
        guard let peripheral = discoveredPeripherals[device.id] else {
            print("❌ 设备不存在")
            return
        }

        print("📱 连接到设备: \(device.name)")
        connectionStatus = .connecting

        centralManager.connect(peripheral, options: nil)
        connectedPeripheral = peripheral
    }

    /// 断开连接
    func disconnect() {
        guard let peripheral = connectedPeripheral else { return }

        print("🔌 断开连接")
        centralManager.cancelPeripheralConnection(peripheral)
        connectionStatus = .disconnected
        connectedDevice = nil
        connectedPeripheral = nil
    }

    /// 发送数据到设备
    func sendData(_ data: String) {
        guard let peripheral = connectedPeripheral,
              let characteristic = writeCharacteristic else {
            print("❌ 未连接到设备或缺少写入特性")
            return
        }

        guard let dataToSend = data.data(using: .utf8) else { return }

        peripheral.writeValue(
            dataToSend,
            for: characteristic,
            type: .withResponse
        )

        print("📤 发送数据: \(data)")
    }

    /// 获取已连接设备的详细信息
    func getDeviceInfo() -> String? {
        guard let device = connectedDevice else { return nil }

        return """
        设备名称: \(device.name)
        UUID: \(device.id)
        信号强度: \(device.rssi) dBm
        连接状态: \(connectionStatus.description)
        服务数量: \(device.services.count)
        """
    }
}

// MARK: - CBCentralManagerDelegate

extension BluetoothManager: CBCentralManagerDelegate {

    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Task { @MainActor in
            switch central.state {
            case .poweredOn:
                print("✅ 蓝牙已打开")
                isBluetoothAvailable = true

            case .poweredOff:
                print("❌ 蓝牙已关闭")
                isBluetoothAvailable = false

            case .unsupported:
                print("❌ 设备不支持蓝牙")
                isBluetoothAvailable = false

            case .unauthorized:
                print("❌ 蓝牙权限未授权")
                isBluetoothAvailable = false

            case .resetting:
                print("⚠️ 蓝牙正在重置")

            case .unknown:
                print("❓ 蓝牙状态未知")

            @unknown default:
                break
            }
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        Task { @MainActor in
            let deviceName = peripheral.name ?? "未知设备"
            let device = BluetoothDevice(
                id: peripheral.identifier,
                name: deviceName,
                rssi: RSSI.intValue,
                services: []
            )

            // 避免重复添加
            if !discoveredDevices.contains(where: { $0.id == device.id }) {
                discoveredDevices.append(device)
                discoveredPeripherals[peripheral.identifier] = peripheral

                print("🔵 发现设备: \(deviceName) (RSSI: \(RSSI))")
            }
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {
        Task { @MainActor in
            print("✅ 已连接到设备: \(peripheral.name ?? "Unknown")")
            connectionStatus = .connected

            peripheral.delegate = self
            peripheral.discoverServices(nil)
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        Task { @MainActor in
            print("❌ 连接失败: \(error?.localizedDescription ?? "Unknown")")
            connectionStatus = .disconnected
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        Task { @MainActor in
            print("🔌 设备已断开")
            connectionStatus = .disconnected
            connectedDevice = nil
        }
    }
}

// MARK: - CBPeripheralDelegate

extension BluetoothManager: CBPeripheralDelegate {

    nonisolated func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverServices error: Error?
    ) {
        Task { @MainActor in
            guard let services = peripheral.services else { return }

            print("📋 发现 \(services.count) 个服务")

            var deviceServices: [BluetoothService] = []

            for service in services {
                let btService = BluetoothService(
                    uuid: service.uuid.uuidString,
                    isPrimary: service.isPrimary
                )
                deviceServices.append(btService)

                // 发现特性
                peripheral.discoverCharacteristics(nil, for: service)
            }

            // 更新已连接设备信息
            if let index = discoveredDevices.firstIndex(where: { $0.id == peripheral.identifier }) {
                discoveredDevices[index].services = deviceServices
                connectedDevice = discoveredDevices[index]
            }
        }
    }

    nonisolated func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        Task { @MainActor in
            guard let characteristics = service.characteristics else { return }

            print("📋 服务 \(service.uuid) 发现 \(characteristics.count) 个特性")

            for characteristic in characteristics {
                print("  - 特性: \(characteristic.uuid)")
                print("    属性: \(characteristic.properties)")

                // 保存写入特性
                if characteristic.properties.contains(.write) ||
                   characteristic.properties.contains(.writeWithoutResponse) {
                    writeCharacteristic = characteristic
                    print("    ✍️ 可写入")
                }

                // 保存通知特性
                if characteristic.properties.contains(.notify) {
                    notifyCharacteristic = characteristic
                    peripheral.setNotifyValue(true, for: characteristic)
                    print("    🔔 已启用通知")
                }

                // 读取特性值
                if characteristic.properties.contains(.read) {
                    peripheral.readValue(for: characteristic)
                    print("    📖 可读取")
                }
            }
        }
    }

    nonisolated func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        Task { @MainActor in
            guard let data = characteristic.value else { return }

            let dataString = String(data: data, encoding: .utf8) ?? data.hexString

            print("📥 收到数据: \(dataString)")
            receivedData = dataString
        }
    }

    nonisolated func peripheral(
        _ peripheral: CBPeripheral,
        didWriteValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        Task { @MainActor in
            if let error = error {
                print("❌ 写入失败: \(error.localizedDescription)")
            } else {
                print("✅ 数据写入成功")
            }
        }
    }
}

// MARK: - Data Models

/// 蓝牙设备
struct BluetoothDevice: Identifiable {
    let id: UUID
    let name: String
    let rssi: Int
    var services: [BluetoothService]

    var signalStrength: String {
        switch rssi {
        case -50...0: return "强 📶"
        case -70 ..< -50: return "中等 📶"
        case -90 ..< -70: return "弱 📶"
        default: return "很弱 📶"
        }
    }
}

/// 蓝牙服务
struct BluetoothService: Identifiable {
    let id = UUID()
    let uuid: String
    let isPrimary: Bool
}

/// 连接状态
enum ConnectionStatus {
    case disconnected
    case connecting
    case connected
    case error(String)

    var description: String {
        switch self {
        case .disconnected: return "未连接"
        case .connecting: return "连接中..."
        case .connected: return "已连接"
        case .error(let message): return "错误: \(message)"
        }
    }
}

// MARK: - Extensions

extension Data {
    var hexString: String {
        map { String(format: "%02hhx", $0) }.joined()
    }
}

// MARK: - App Intents

import AppIntents

/// 扫描蓝牙设备 Intent
struct ScanBluetoothDevicesIntent: AppIntent {
    static var title: LocalizedStringResource = "扫描蓝牙设备"
    static var description = IntentDescription("扫描附近的蓝牙设备")

    @Parameter(title: "扫描时长（秒）", default: 10)
    var duration: Int

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let manager = BluetoothManager()

        // 等待蓝牙初始化
        try await Task.sleep(nanoseconds: 1_000_000_000)

        guard manager.isBluetoothAvailable else {
            return .result(dialog: "❌ 蓝牙不可用，请在设置中打开蓝牙")
        }

        manager.startScanning()

        // 扫描指定时长
        try await Task.sleep(nanoseconds: UInt64(duration) * 1_000_000_000)

        manager.stopScanning()

        let devices = manager.discoveredDevices

        if devices.isEmpty {
            return .result(dialog: "📡 未发现蓝牙设备")
        }

        let deviceList = devices.map { device in
            "• \(device.name) (\(device.signalStrength))"
        }.joined(separator: "\n")

        let message = """
        📱 发现 \(devices.count) 个蓝牙设备

        \(deviceList)
        """

        return .result(dialog: message)
    }
}

/// 连接蓝牙设备 Intent
struct ConnectBluetoothDeviceIntent: AppIntent {
    static var title: LocalizedStringResource = "连接蓝牙设备"
    static var description = IntentDescription("连接到指定的蓝牙设备")

    @Parameter(title: "设备名称")
    var deviceName: String

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let manager = BluetoothManager()

        try await Task.sleep(nanoseconds: 1_000_000_000)

        // 先扫描
        manager.startScanning()
        try await Task.sleep(nanoseconds: 5_000_000_000) // 5 秒
        manager.stopScanning()

        // 查找设备
        guard let device = manager.discoveredDevices.first(where: {
            $0.name.contains(deviceName)
        }) else {
            return .result(dialog: "❌ 未找到设备: \(deviceName)")
        }

        // 连接
        manager.connect(to: device)

        // 等待连接
        try await Task.sleep(nanoseconds: 3_000_000_000)

        if manager.connectionStatus == .connected {
            return .result(dialog: "✅ 已连接到 \(device.name)")
        } else {
            return .result(dialog: "❌ 连接失败")
        }
    }
}
