import Foundation
import AppIntents

/// Shadowrocket 配置管理器
/// 自动检测设备并配置 Shadowrocket 代理工具
@available(iOS 16.0, macOS 13.0, *)
@MainActor
class ShadowrocketManager: ObservableObject {

    // MARK: - Published Properties

    @Published var isConfigured: Bool = false
    @Published var currentConfig: ProxyConfig?
    @Published var subscriptionURL: String?
    @Published var lastUpdateTime: Date?
    @Published var connectionStatus: ConnectionStatus = .disconnected

    // MARK: - Private Properties

    private let deviceInfo = DeviceInfoManager()
    private let configURL: URL

    // MARK: - Initialization

    init() {
        // 配置文件路径
        let documentsPath = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]

        configURL = documentsPath.appendingPathComponent("shadowrocket_config.json")

        loadConfiguration()
    }

    // MARK: - Configuration

    /// 自动配置 Shadowrocket
    func autoConfigureShadowrocket() async throws {
        print("🚀 开始自动配置 Shadowrocket")

        // 步骤 1: 检测设备兼容性
        try checkDeviceCompatibility()

        // 步骤 2: 生成推荐配置
        let config = try await generateRecommendedConfig()

        // 步骤 3: 保存配置
        try saveConfiguration(config)

        // 步骤 4: 生成配置文件
        try exportConfigurationFile(config)

        currentConfig = config
        isConfigured = true

        print("✅ Shadowrocket 配置完成")
    }

    /// 检测设备兼容性
    private func checkDeviceCompatibility() throws {
        print("📱 检测设备兼容性...")

        deviceInfo.detectDeviceInfo()

        let requirements = DeviceInfoManager.CompatibilityRequirements(
            minimumIOSVersion: "14.0",
            minimumMacOSVersion: "11.0",
            requiredRAM: 1 * 1024 * 1024 * 1024, // 1GB
            requiredDisk: 100 * 1024 * 1024,     // 100MB
            supportedDevices: nil,
            excludedDevices: nil
        )

        let (compatible, reasons) = deviceInfo.checkCompatibility(requirements: requirements)

        if !compatible {
            print("❌ 设备不兼容:")
            for reason in reasons {
                print("   - \(reason)")
            }
            throw ShadowrocketError.deviceNotCompatible(reasons.joined(separator: ", "))
        }

        print("✅ 设备兼容性检查通过")
        print("   设备: \(deviceInfo.deviceModel)")
        print("   系统: \(deviceInfo.systemVersion)")
        print("   架构: \(deviceInfo.cpuArchitecture)")
    }

    /// 生成推荐配置
    private func generateRecommendedConfig() async throws -> ProxyConfig {
        print("⚙️ 生成推荐配置...")

        // 根据设备型号和系统生成最优配置
        let config = ProxyConfig(
            name: "自动配置 - \(deviceInfo.deviceModel)",
            deviceModel: deviceInfo.deviceModel,
            systemVersion: deviceInfo.systemVersion,
            servers: generateDefaultServers(),
            rules: generateDefaultRules(),
            dns: generateDNSConfig(),
            general: generateGeneralConfig(),
            createdAt: Date()
        )

        print("✅ 配置生成完成")
        return config
    }

    /// 生成默认服务器配置
    private func generateDefaultServers() -> [ProxyServer] {
        return [
            ProxyServer(
                name: "主服务器",
                type: .shadowsocks,
                server: "example.com",
                port: 8388,
                method: "aes-256-gcm",
                password: "password",
                enabled: true
            )
        ]
    }

    /// 生成默认规则
    private func generateDefaultRules() -> [ProxyRule] {
        return [
            ProxyRule(type: .direct, pattern: "GEOIP,CN"),
            ProxyRule(type: .proxy, pattern: "DOMAIN-SUFFIX,google.com"),
            ProxyRule(type: .proxy, pattern: "DOMAIN-SUFFIX,youtube.com"),
            ProxyRule(type: .proxy, pattern: "DOMAIN-SUFFIX,twitter.com"),
            ProxyRule(type: .proxy, pattern: "DOMAIN-SUFFIX,facebook.com"),
            ProxyRule(type: .proxy, pattern: "FINAL"),
        ]
    }

    /// 生成 DNS 配置
    private func generateDNSConfig() -> DNSConfig {
        return DNSConfig(
            servers: ["223.5.5.5", "114.114.114.114", "8.8.8.8"],
            fallback: ["1.1.1.1", "8.8.4.4"],
            enableDoH: true,
            dohURL: "https://dns.alidns.com/dns-query"
        )
    }

    /// 生成通用配置
    private func generateGeneralConfig() -> GeneralConfig {
        let isDarkMode = true // 可以从系统获取

        return GeneralConfig(
            bypassSystemProxy: false,
            skipProxy: ["127.0.0.1", "192.168.0.0/16", "10.0.0.0/8"],
            dnsServer: ["223.5.5.5", "114.114.114.114"],
            alwaysRealIP: ["*.apple.com"],
            hijackDNS: ["8.8.8.8:53", "8.8.4.4:53"],
            ipv6: true,
            preferIPv6: false,
            dnsFollow: true,
            allowWifiAccess: false,
            theme: isDarkMode ? "dark" : "light"
        )
    }

    // MARK: - Configuration Management

    /// 保存配置
    func saveConfiguration(_ config: ProxyConfig) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(config)
        try data.write(to: configURL)

        currentConfig = config
        lastUpdateTime = Date()

        print("💾 配置已保存到: \(configURL.path)")
    }

    /// 加载配置
    func loadConfiguration() {
        guard FileManager.default.fileExists(atPath: configURL.path) else {
            print("⚠️ 未找到配置文件")
            return
        }

        do {
            let data = try Data(contentsOf: configURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            currentConfig = try decoder.decode(ProxyConfig.self, from: data)
            isConfigured = true

            print("✅ 配置已加载")
        } catch {
            print("❌ 加载配置失败: \(error)")
        }
    }

    /// 导出配置文件（Shadowrocket 格式）
    func exportConfigurationFile(_ config: ProxyConfig) throws {
        let documentsPath = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]

        // 导出为 Shadowrocket 配置文件
        let configFilePath = documentsPath.appendingPathComponent("shadowrocket.conf")

        let configContent = generateShadowrocketConfig(config)
        try configContent.write(to: configFilePath, atomically: true, encoding: .utf8)

        print("📄 Shadowrocket 配置文件已生成: \(configFilePath.path)")
    }

    /// 生成 Shadowrocket 配置文件内容
    private func generateShadowrocketConfig(_ config: ProxyConfig) -> String {
        var content = """
        # Shadowrocket 配置文件
        # 生成时间: \(ISO8601DateFormatter().string(from: Date()))
        # 设备型号: \(config.deviceModel)
        # 系统版本: \(config.systemVersion)

        [General]
        bypass-system = \(config.general.bypassSystemProxy)
        skip-proxy = \(config.general.skipProxy.joined(separator: ", "))
        dns-server = \(config.general.dnsServer.joined(separator: ", "))
        ipv6 = \(config.general.ipv6)

        """

        // 添加代理服务器
        content += "\n[Proxy]\n"
        for server in config.servers where server.enabled {
            content += generateProxyLine(server) + "\n"
        }

        // 添加规则
        content += "\n[Rule]\n"
        for rule in config.rules {
            content += "\(rule.type.rawValue),\(rule.pattern)\n"
        }

        return content
    }

    /// 生成代理服务器配置行
    private func generateProxyLine(_ server: ProxyServer) -> String {
        switch server.type {
        case .shadowsocks:
            return "\(server.name) = ss, \(server.server), \(server.port), encrypt-method=\(server.method), password=\(server.password)"
        case .vmess:
            return "\(server.name) = vmess, \(server.server), \(server.port), username=\(server.uuid ?? ""), tls=\(server.tls)"
        case .trojan:
            return "\(server.name) = trojan, \(server.server), \(server.port), password=\(server.password), sni=\(server.sni ?? "")"
        case .http, .https:
            return "\(server.name) = \(server.type.rawValue), \(server.server), \(server.port)"
        }
    }

    // MARK: - Subscription Management

    /// 添加订阅链接
    func addSubscription(url: String) async throws {
        print("📥 添加订阅链接...")

        guard let subscriptionURL = URL(string: url) else {
            throw ShadowrocketError.invalidSubscriptionURL
        }

        // 下载订阅配置
        let (data, _) = try await URLSession.shared.data(from: subscriptionURL)

        // 解析订阅内容（Base64 编码的服务器列表）
        let servers = try parseSubscription(data)

        print("✅ 订阅解析成功，共 \(servers.count) 个服务器")

        // 更新配置
        if var config = currentConfig {
            config.servers = servers
            try saveConfiguration(config)
        }

        self.subscriptionURL = url
    }

    /// 解析订阅内容
    private func parseSubscription(_ data: Data) throws -> [ProxyServer] {
        // 尝试 Base64 解码
        var content: String
        if let base64Decoded = Data(base64Encoded: data),
           let decodedString = String(data: base64Decoded, encoding: .utf8) {
            content = decodedString
        } else if let directString = String(data: data, encoding: .utf8) {
            content = directString
        } else {
            throw ShadowrocketError.invalidSubscriptionFormat
        }

        var servers: [ProxyServer] = []

        // 解析每一行
        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }

            if let server = parseServerLine(trimmed) {
                servers.append(server)
            }
        }

        return servers
    }

    /// 解析服务器配置行
    private func parseServerLine(_ line: String) -> ProxyServer? {
        // ss://base64编码
        if line.hasPrefix("ss://") {
            return parseShadowsocksURL(line)
        }
        // vmess://base64编码
        else if line.hasPrefix("vmess://") {
            return parseVmessURL(line)
        }
        // trojan://
        else if line.hasPrefix("trojan://") {
            return parseTrojanURL(line)
        }

        return nil
    }

    /// 解析 Shadowsocks URL
    private func parseShadowsocksURL(_ url: String) -> ProxyServer? {
        // 简化的解析（实际需要更复杂的处理）
        guard let base64String = url.components(separatedBy: "ss://").last,
              let decoded = Data(base64Encoded: base64String),
              let config = String(data: decoded, encoding: .utf8) else {
            return nil
        }

        // 解析格式: method:password@server:port
        let components = config.components(separatedBy: "@")
        guard components.count == 2 else { return nil }

        let methodPassword = components[0].components(separatedBy: ":")
        let serverPort = components[1].components(separatedBy: ":")

        guard methodPassword.count == 2, serverPort.count == 2 else { return nil }

        return ProxyServer(
            name: "SS - \(serverPort[0])",
            type: .shadowsocks,
            server: serverPort[0],
            port: Int(serverPort[1]) ?? 8388,
            method: methodPassword[0],
            password: methodPassword[1],
            enabled: true
        )
    }

    /// 解析 Vmess URL
    private func parseVmessURL(_ url: String) -> ProxyServer? {
        // Vmess 配置解析（简化版）
        guard let base64String = url.components(separatedBy: "vmess://").last,
              let decoded = Data(base64Encoded: base64String),
              let json = try? JSONSerialization.jsonObject(with: decoded) as? [String: Any] else {
            return nil
        }

        guard let address = json["add"] as? String,
              let port = json["port"] as? Int,
              let uuid = json["id"] as? String else {
            return nil
        }

        let tls = (json["tls"] as? String) == "tls"
        let name = json["ps"] as? String ?? "Vmess - \(address)"

        return ProxyServer(
            name: name,
            type: .vmess,
            server: address,
            port: port,
            method: "",
            password: "",
            uuid: uuid,
            tls: tls,
            enabled: true
        )
    }

    /// 解析 Trojan URL
    private func parseTrojanURL(_ url: String) -> ProxyServer? {
        // trojan://password@server:port#name
        guard let content = url.components(separatedBy: "trojan://").last else {
            return nil
        }

        let parts = content.components(separatedBy: "@")
        guard parts.count == 2 else { return nil }

        let password = parts[0]
        let serverInfo = parts[1].components(separatedBy: "#")
        let serverPort = serverInfo[0].components(separatedBy: ":")

        guard serverPort.count == 2 else { return nil }

        let name = serverInfo.count > 1 ? serverInfo[1] : "Trojan - \(serverPort[0])"

        return ProxyServer(
            name: name,
            type: .trojan,
            server: serverPort[0],
            port: Int(serverPort[1]) ?? 443,
            method: "",
            password: password,
            enabled: true
        )
    }

    /// 更新订阅
    func updateSubscription() async throws {
        guard let urlString = subscriptionURL else {
            throw ShadowrocketError.noSubscriptionConfigured
        }

        print("🔄 更新订阅...")
        try await addSubscription(url: urlString)
        print("✅ 订阅更新完成")
    }

    // MARK: - Connection Management

    /// 测试连接
    func testConnection() async -> Bool {
        print("🔌 测试连接...")

        // 尝试连接到 Google
        guard let url = URL(string: "https://www.google.com") else { return false }

        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                connectionStatus = .connected
                print("✅ 连接成功")
                return true
            }
        } catch {
            print("❌ 连接失败: \(error)")
        }

        connectionStatus = .failed
        return false
    }

    /// 获取配置摘要
    func getConfigurationSummary() -> String {
        guard let config = currentConfig else {
            return "未配置"
        }

        return """
        📱 Shadowrocket 配置摘要
        ========================

        设备信息
        --------
        设备型号: \(config.deviceModel)
        系统版本: \(config.systemVersion)

        服务器配置
        ----------
        总服务器数: \(config.servers.count)
        已启用: \(config.servers.filter { $0.enabled }.count)

        规则配置
        --------
        总规则数: \(config.rules.count)

        DNS 配置
        --------
        主 DNS: \(config.dns.servers.joined(separator: ", "))
        DoH: \(config.dns.enableDoH ? "已启用" : "未启用")

        创建时间
        --------
        \(config.createdAt.formatted())

        """
    }
}

// MARK: - Data Models

/// 代理配置
struct ProxyConfig: Codable {
    var name: String
    var deviceModel: String
    var systemVersion: String
    var servers: [ProxyServer]
    var rules: [ProxyRule]
    var dns: DNSConfig
    var general: GeneralConfig
    var createdAt: Date
}

/// 代理服务器
struct ProxyServer: Codable {
    var name: String
    var type: ProxyType
    var server: String
    var port: Int
    var method: String
    var password: String
    var uuid: String?
    var tls: Bool = false
    var sni: String?
    var enabled: Bool
}

/// 代理类型
enum ProxyType: String, Codable {
    case shadowsocks = "ss"
    case vmess = "vmess"
    case trojan = "trojan"
    case http = "http"
    case https = "https"
}

/// 代理规则
struct ProxyRule: Codable {
    var type: RuleType
    var pattern: String
}

/// 规则类型
enum RuleType: String, Codable {
    case direct = "DIRECT"
    case proxy = "PROXY"
    case reject = "REJECT"
}

/// DNS 配置
struct DNSConfig: Codable {
    var servers: [String]
    var fallback: [String]
    var enableDoH: Bool
    var dohURL: String?
}

/// 通用配置
struct GeneralConfig: Codable {
    var bypassSystemProxy: Bool
    var skipProxy: [String]
    var dnsServer: [String]
    var alwaysRealIP: [String]
    var hijackDNS: [String]
    var ipv6: Bool
    var preferIPv6: Bool
    var dnsFollow: Bool
    var allowWifiAccess: Bool
    var theme: String
}

/// 连接状态
enum ConnectionStatus {
    case disconnected
    case connecting
    case connected
    case failed
}

/// Shadowrocket 错误
enum ShadowrocketError: LocalizedError {
    case deviceNotCompatible(String)
    case invalidSubscriptionURL
    case invalidSubscriptionFormat
    case noSubscriptionConfigured
    case configurationFailed

    var errorDescription: String? {
        switch self {
        case .deviceNotCompatible(let reason):
            return "设备不兼容: \(reason)"
        case .invalidSubscriptionURL:
            return "无效的订阅链接"
        case .invalidSubscriptionFormat:
            return "无效的订阅格式"
        case .noSubscriptionConfigured:
            return "未配置订阅"
        case .configurationFailed:
            return "配置失败"
        }
    }
}

// MARK: - App Intents

/// 配置 Shadowrocket Intent
@available(iOS 16.0, *)
struct ConfigureShadowrocketIntent: AppIntent {
    static var title: LocalizedStringResource = "配置 Shadowrocket"
    static var description = IntentDescription("自动检测设备并配置 Shadowrocket 代理")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let manager = ShadowrocketManager()

        do {
            try await manager.autoConfigureShadowrocket()

            let summary = manager.getConfigurationSummary()

            return .result(dialog: """
            ✅ Shadowrocket 配置完成！

            \(summary)

            配置文件已保存，可以在文件 App 中查看。
            """)

        } catch {
            return .result(dialog: "❌ 配置失败: \(error.localizedDescription)")
        }
    }
}

/// 添加订阅 Intent
@available(iOS 16.0, *)
struct AddSubscriptionIntent: AppIntent {
    static var title: LocalizedStringResource = "添加 Shadowrocket 订阅"
    static var description = IntentDescription("添加 Shadowrocket 订阅链接")

    @Parameter(title: "订阅 URL")
    var subscriptionURL: String

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let manager = ShadowrocketManager()

        do {
            try await manager.addSubscription(url: subscriptionURL)

            return .result(dialog: "✅ 订阅添加成功！")

        } catch {
            return .result(dialog: "❌ 添加失败: \(error.localizedDescription)")
        }
    }
}

/// 更新订阅 Intent
@available(iOS 16.0, *)
struct UpdateSubscriptionIntent: AppIntent {
    static var title: LocalizedStringResource = "更新 Shadowrocket 订阅"
    static var description = IntentDescription("更新现有的 Shadowrocket 订阅")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let manager = ShadowrocketManager()

        do {
            try await manager.updateSubscription()

            return .result(dialog: "✅ 订阅更新成功！")

        } catch {
            return .result(dialog: "❌ 更新失败: \(error.localizedDescription)")
        }
    }
}

/// 测试连接 Intent
@available(iOS 16.0, *)
struct TestConnectionIntent: AppIntent {
    static var title: LocalizedStringResource = "测试 Shadowrocket 连接"
    static var description = IntentDescription("测试 Shadowrocket 代理连接")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let manager = ShadowrocketManager()

        let success = await manager.testConnection()

        if success {
            return .result(dialog: "✅ 连接测试成功！代理工作正常。")
        } else {
            return .result(dialog: "❌ 连接测试失败。请检查配置。")
        }
    }
}
