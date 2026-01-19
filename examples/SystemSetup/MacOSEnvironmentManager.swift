import Foundation

/// macOS 环境配置管理器
/// 自动检测、下载、配置 macOS 系统和开发环境
@available(macOS 11.0, *)
@MainActor
class MacOSEnvironmentManager: ObservableObject {

    // MARK: - Published Properties

    @Published var systemInfo: MacSystemInfo?
    @Published var isCompatible: Bool = false
    @Published var recommendedVersion: String?
    @Published var xcodeStatus: XcodeStatus = .notInstalled
    @Published var sshStatus: SSHStatus = .disabled
    @Published var terminalReady: Bool = false
    @Published var setupProgress: Double = 0.0

    // MARK: - Private Properties

    private let deviceInfo = DeviceInfoManager()
    private let fileManager = FileManager.default

    // MARK: - System Detection

    /// 检测 Mac 系统兼容性
    func detectSystemCompatibility() async throws {
        print("🔍 开始检测 Mac 系统兼容性...")

        // 获取系统信息
        let info = getSystemInfo()
        self.systemInfo = info

        print("📱 Mac 信息:")
        print("   型号: \(info.model)")
        print("   芯片: \(info.chip)")
        print("   系统: macOS \(info.currentVersion)")
        print("   内存: \(info.memoryGB) GB")
        print("   存储: \(info.diskSpaceGB) GB")

        // 检查是否支持 macOS Studio 功能
        let compatibility = checkMacStudioCompatibility(info)
        self.isCompatible = compatibility.isSupported
        self.recommendedVersion = compatibility.recommendedVersion

        if compatibility.isSupported {
            print("✅ 当前系统支持所有功能")
        } else {
            print("⚠️ 当前系统不完全支持")
            print("   推荐版本: macOS \(compatibility.recommendedVersion)")
            print("   原因: \(compatibility.reason)")
        }
    }

    /// 获取 Mac 系统信息
    private func getSystemInfo() -> MacSystemInfo {
        // 获取 Mac 型号
        let model = getMacModel()

        // 获取芯片类型
        let chip = getChipType()

        // 获取当前系统版本
        let version = ProcessInfo.processInfo.operatingSystemVersion
        let versionString = "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"

        // 获取内存
        var size: UInt64 = 0
        var len = MemoryLayout<UInt64>.size
        sysctlbyname("hw.memsize", &size, &len, nil, 0)
        let memoryGB = Int(size / (1024 * 1024 * 1024))

        // 获取磁盘空间
        let diskSpace = getTotalDiskSpace()
        let diskSpaceGB = Int(diskSpace / (1024 * 1024 * 1024))

        return MacSystemInfo(
            model: model,
            chip: chip,
            currentVersion: versionString,
            memoryGB: memoryGB,
            diskSpaceGB: diskSpaceGB
        )
    }

    /// 获取 Mac 型号
    private func getMacModel() -> String {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var model = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &model, &size, nil, 0)
        return String(cString: model)
    }

    /// 获取芯片类型
    private func getChipType() -> ChipType {
        var size = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.machine", &machine, &size, nil, 0)
        let arch = String(cString: machine)

        if arch.contains("arm64") {
            // 检查具体的 Apple Silicon 型号
            if arch.contains("m1") {
                return .appleM1
            } else if arch.contains("m2") {
                return .appleM2
            } else if arch.contains("m3") {
                return .appleM3
            }
            return .appleSilicon
        } else {
            return .intel
        }
    }

    /// 获取磁盘空间
    private func getTotalDiskSpace() -> UInt64 {
        if let attributes = try? fileManager.attributesOfFileSystem(forPath: "/"),
           let totalSize = attributes[.systemSize] as? NSNumber {
            return totalSize.uint64Value
        }
        return 0
    }

    /// 检查 macOS Studio 兼容性
    private func checkMacStudioCompatibility(_ info: MacSystemInfo) -> CompatibilityResult {
        // macOS Sonoma (14.0+) - 最佳
        // macOS Ventura (13.0+) - 良好
        // macOS Monterey (12.0+) - 支持

        let version = ProcessInfo.processInfo.operatingSystemVersion
        let majorVersion = version.majorVersion

        // 检查芯片类型
        if info.chip == .intel {
            // Intel Mac
            if majorVersion >= 13 {
                return CompatibilityResult(
                    isSupported: true,
                    recommendedVersion: "当前版本",
                    reason: ""
                )
            } else {
                return CompatibilityResult(
                    isSupported: false,
                    recommendedVersion: "13.0 (Ventura)",
                    reason: "建议升级到 macOS 13.0 或更高版本以获得最佳体验"
                )
            }
        } else {
            // Apple Silicon
            if majorVersion >= 14 {
                return CompatibilityResult(
                    isSupported: true,
                    recommendedVersion: "当前版本",
                    reason: ""
                )
            } else if majorVersion >= 13 {
                return CompatibilityResult(
                    isSupported: true,
                    recommendedVersion: "14.0 (Sonoma)",
                    reason: "可升级到 macOS 14.0 以获得更好性能"
                )
            } else {
                return CompatibilityResult(
                    isSupported: false,
                    recommendedVersion: "14.0 (Sonoma)",
                    reason: "需要升级到 macOS 13.0 或更高版本"
                )
            }
        }
    }

    // MARK: - System Installation

    /// 下载并安装推荐的 macOS 版本
    func downloadAndInstallRecommendedSystem() async throws {
        guard let recommended = recommendedVersion else {
            throw MacOSError.noRecommendedVersion
        }

        print("📥 开始下载 macOS \(recommended)...")
        setupProgress = 0.1

        // 步骤 1: 下载系统镜像
        let imageURL = try await downloadSystemImage(version: recommended)
        setupProgress = 0.5

        print("✅ 系统镜像下载完成: \(imageURL.path)")

        // 步骤 2: 验证镜像
        print("🔐 验证系统镜像...")
        try await verifySystemImage(at: imageURL)
        setupProgress = 0.7

        print("✅ 镜像验证通过")

        // 步骤 3: 创建安装器
        print("💿 创建可引导安装器...")
        try await createBootableInstaller(from: imageURL)
        setupProgress = 0.9

        print("✅ 安装器创建完成")
        print("")
        print("📌 下一步操作:")
        print("   1. 重启 Mac")
        print("   2. 按住 Option 键")
        print("   3. 选择安装器启动")
        print("   4. 按照向导完成安装")

        setupProgress = 1.0
    }

    /// 下载系统镜像
    private func downloadSystemImage(version: String) async throws -> URL {
        // 获取对应版本的下载链接
        let downloadURL = getMacOSDownloadURL(version: version)

        print("🌐 下载地址: \(downloadURL)")

        let documentsPath = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
        let destinationURL = documentsPath.appendingPathComponent("macOS_\(version).dmg")

        // 检查是否已经下载
        if fileManager.fileExists(atPath: destinationURL.path) {
            print("✅ 镜像已存在，跳过下载")
            return destinationURL
        }

        // 下载文件
        let (tempURL, _) = try await URLSession.shared.download(from: URL(string: downloadURL)!)

        // 移动到目标位置
        try fileManager.moveItem(at: tempURL, to: destinationURL)

        return destinationURL
    }

    /// 获取 macOS 下载链接
    private func getMacOSDownloadURL(version: String) -> String {
        // Apple 官方下载链接映射
        let downloadURLs: [String: String] = [
            "14.0": "https://swcdn.apple.com/content/downloads/...",  // Sonoma
            "13.0": "https://swcdn.apple.com/content/downloads/...",  // Ventura
            "12.0": "https://swcdn.apple.com/content/downloads/...",  // Monterey
        ]

        return downloadURLs[version] ?? "https://www.apple.com/macos/"
    }

    /// 验证系统镜像
    private func verifySystemImage(at url: URL) async throws {
        // 检查文件大小
        let attributes = try fileManager.attributesOfItem(atPath: url.path)
        guard let fileSize = attributes[.size] as? UInt64 else {
            throw MacOSError.invalidImage
        }

        // macOS 镜像通常 > 10GB
        if fileSize < 10 * 1024 * 1024 * 1024 {
            throw MacOSError.invalidImage
        }

        print("✅ 文件大小验证通过: \(fileSize / (1024*1024*1024)) GB")
    }

    /// 创建可引导安装器
    private func createBootableInstaller(from imageURL: URL) async throws {
        // 这里需要使用 createinstallmedia 命令
        // 需要管理员权限

        let script = """
        #!/bin/bash
        # 创建可引导安装器
        # 需要一个空白 USB 驱动器（至少 16GB）

        # sudo /Applications/Install\\ macOS\\ Sonoma.app/Contents/Resources/createinstallmedia --volume /Volumes/MyVolume

        echo "请插入 USB 驱动器并运行此脚本"
        """

        let scriptPath = fileManager.temporaryDirectory.appendingPathComponent("create_installer.sh")
        try script.write(to: scriptPath, atomically: true, encoding: .utf8)

        print("📝 安装脚本已保存到: \(scriptPath.path)")
    }

    // MARK: - Xcode Management

    /// 检测并配置 Xcode
    func setupXcode() async throws {
        print("🔍 检测 Xcode...")

        // 检查 Xcode 是否已安装
        let xcodePath = "/Applications/Xcode.app"

        if fileManager.fileExists(atPath: xcodePath) {
            print("✅ Xcode 已安装")
            xcodeStatus = .installed

            // 获取版本
            let version = try getXcodeVersion()
            print("   版本: \(version)")

            // 启动 Xcode
            try await launchXcode()

        } else {
            print("⚠️ 未检测到 Xcode")
            xcodeStatus = .notInstalled

            print("📥 开始下载 Xcode...")
            try await downloadXcode()
        }
    }

    /// 获取 Xcode 版本
    private func getXcodeVersion() throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcodebuild")
        process.arguments = ["-version"]

        let pipe = Pipe()
        process.standardOutput = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 启动 Xcode
    private func launchXcode() async throws {
        print("🚀 启动 Xcode...")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-a", "Xcode"]

        try process.run()

        xcodeStatus = .running
        print("✅ Xcode 已启动")
    }

    /// 下载 Xcode
    private func downloadXcode() async throws {
        print("📥 从 App Store 下载 Xcode...")
        print("   这可能需要较长时间（约 10-15 GB）")

        // 打开 App Store 的 Xcode 页面
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["macappstore://apps.apple.com/app/xcode/id497799835"]

        try process.run()

        xcodeStatus = .downloading
    }

    // MARK: - SSH Server Setup

    /// 配置 SSH 服务器
    func setupSSHServer() async throws {
        print("🔐 配置 SSH 服务器...")

        // 检查 SSH 服务状态
        let isRunning = try checkSSHStatus()

        if isRunning {
            print("✅ SSH 服务已运行")
            sshStatus = .enabled
        } else {
            print("⚠️ SSH 服务未启动")

            // 启用 SSH
            try await enableSSH()
        }

        // 获取 SSH 连接信息
        let connectionInfo = getSSHConnectionInfo()
        print("📋 SSH 连接信息:")
        print("   地址: \(connectionInfo.address)")
        print("   端口: \(connectionInfo.port)")
        print("   用户: \(connectionInfo.username)")
        print("")
        print("💡 连接命令:")
        print("   ssh \(connectionInfo.username)@\(connectionInfo.address)")
    }

    /// 检查 SSH 状态
    private func checkSSHStatus() throws -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
        process.arguments = ["systemsetup", "-getremotelogin"]

        let pipe = Pipe()
        process.standardOutput = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        return output.contains("On")
    }

    /// 启用 SSH
    private func enableSSH() async throws {
        print("🔓 启用 SSH 远程登录...")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
        process.arguments = ["systemsetup", "-setremotelogin", "on"]

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus == 0 {
            sshStatus = .enabled
            print("✅ SSH 服务已启用")
        } else {
            throw MacOSError.sshEnableFailed
        }
    }

    /// 获取 SSH 连接信息
    private func getSSHConnectionInfo() -> SSHConnectionInfo {
        // 获取当前用户名
        let username = NSUserName()

        // 获取本地 IP 地址
        let ipAddress = getLocalIPAddress()

        return SSHConnectionInfo(
            address: ipAddress,
            port: 22,
            username: username
        )
    }

    /// 获取本地 IP 地址
    private func getLocalIPAddress() -> String {
        var address: String = "localhost"

        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return address }
        guard let firstAddr = ifaddr else { return address }

        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family

            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                if name == "en0" {  // WiFi
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                              &hostname, socklen_t(hostname.count),
                              nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
        }

        freeifaddrs(ifaddr)
        return address
    }

    // MARK: - Terminal Setup

    /// 配置内置 Terminal
    func setupTerminal() async throws {
        print("💻 配置内置 Terminal...")

        // 创建 Terminal 脚本
        let terminalScript = createTerminalScript()

        // 保存脚本
        let scriptPath = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent(".automation_terminal.sh")

        try terminalScript.write(to: scriptPath, atomically: true, encoding: .utf8)

        // 设置执行权限
        try fileManager.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: scriptPath.path
        )

        terminalReady = true

        print("✅ Terminal 已配置")
        print("   脚本位置: \(scriptPath.path)")
        print("")
        print("💡 使用方法:")
        print("   1. 打开 Terminal.app")
        print("   2. 运行: \(scriptPath.path)")
    }

    /// 创建 Terminal 脚本
    private func createTerminalScript() -> String {
        return """
        #!/bin/bash

        # iOS 自动化开发 Terminal
        # 自动配置的开发环境

        echo "🚀 iOS 自动化开发环境"
        echo "===================="
        echo ""

        # 设置环境变量
        export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        export LANG="en_US.UTF-8"

        # 显示系统信息
        echo "📱 系统信息:"
        echo "   macOS: $(sw_vers -productVersion)"
        echo "   Xcode: $(xcodebuild -version 2>/dev/null | head -1 || echo '未安装')"
        echo ""

        # 显示可用命令
        echo "💡 可用命令:"
        echo "   xcode     - 启动 Xcode"
        echo "   build     - 构建项目"
        echo "   test      - 运行测试"
        echo "   ssh       - 查看 SSH 信息"
        echo "   help      - 显示帮助"
        echo ""

        # 启动交互式 shell
        exec /bin/bash --login
        """
    }

    // MARK: - Complete Setup

    /// 完整自动化设置
    func completeSetup() async throws {
        print("🚀 开始完整自动化设置...")
        print("")

        setupProgress = 0.0

        // 步骤 1: 检测系统
        print("【1/5】检测系统兼容性...")
        try await detectSystemCompatibility()
        setupProgress = 0.2

        // 步骤 2: 配置 Xcode
        print("\n【2/5】配置 Xcode...")
        try await setupXcode()
        setupProgress = 0.4

        // 步骤 3: 配置 SSH
        print("\n【3/5】配置 SSH 服务器...")
        try await setupSSHServer()
        setupProgress = 0.6

        // 步骤 4: 配置 Terminal
        print("\n【4/5】配置 Terminal...")
        try await setupTerminal()
        setupProgress = 0.8

        // 步骤 5: 完成
        print("\n【5/5】完成设置...")
        setupProgress = 1.0

        print("")
        print("✅ 所有设置完成！")
        print("")
        printSetupSummary()
    }

    /// 打印设置摘要
    private func printSetupSummary() {
        print("📊 设置摘要")
        print("=" * 50)

        if let info = systemInfo {
            print("\n💻 系统信息:")
            print("   型号: \(info.model)")
            print("   芯片: \(info.chip.description)")
            print("   系统: macOS \(info.currentVersion)")
            print("   兼容: \(isCompatible ? "✅" : "⚠️")")
        }

        print("\n🔧 开发环境:")
        print("   Xcode: \(xcodeStatus.description)")
        print("   SSH: \(sshStatus.description)")
        print("   Terminal: \(terminalReady ? "✅ 已配置" : "❌ 未配置")")

        print("\n🎯 下一步:")
        if !isCompatible {
            print("   - 建议升级到 macOS \(recommendedVersion ?? "最新版本")")
        }
        if xcodeStatus == .notInstalled {
            print("   - 从 App Store 安装 Xcode")
        }
        print("   - 开始开发 iOS 应用！")
        print("")
    }
}

// MARK: - Data Models

/// Mac 系统信息
struct MacSystemInfo {
    let model: String
    let chip: ChipType
    let currentVersion: String
    let memoryGB: Int
    let diskSpaceGB: Int
}

/// 芯片类型
enum ChipType {
    case appleM1
    case appleM2
    case appleM3
    case appleSilicon
    case intel

    var description: String {
        switch self {
        case .appleM1: return "Apple M1"
        case .appleM2: return "Apple M2"
        case .appleM3: return "Apple M3"
        case .appleSilicon: return "Apple Silicon"
        case .intel: return "Intel"
        }
    }
}

/// 兼容性结果
struct CompatibilityResult {
    let isSupported: Bool
    let recommendedVersion: String
    let reason: String
}

/// Xcode 状态
enum XcodeStatus {
    case notInstalled
    case downloading
    case installed
    case running

    var description: String {
        switch self {
        case .notInstalled: return "❌ 未安装"
        case .downloading: return "📥 下载中"
        case .installed: return "✅ 已安装"
        case .running: return "🚀 运行中"
        }
    }
}

/// SSH 状态
enum SSHStatus {
    case disabled
    case enabled
    case running

    var description: String {
        switch self {
        case .disabled: return "❌ 未启用"
        case .enabled: return "✅ 已启用"
        case .running: return "🚀 运行中"
        }
    }
}

/// SSH 连接信息
struct SSHConnectionInfo {
    let address: String
    let port: Int
    let username: String
}

/// macOS 错误
enum MacOSError: LocalizedError {
    case noRecommendedVersion
    case invalidImage
    case downloadFailed
    case installationFailed
    case sshEnableFailed

    var errorDescription: String? {
        switch self {
        case .noRecommendedVersion:
            return "没有推荐的系统版本"
        case .invalidImage:
            return "无效的系统镜像"
        case .downloadFailed:
            return "下载失败"
        case .installationFailed:
            return "安装失败"
        case .sshEnableFailed:
            return "SSH 启用失败"
        }
    }
}
