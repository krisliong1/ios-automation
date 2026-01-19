import Foundation
import AppIntents

// MARK: - 完整自动化设置

/// 完整 macOS 环境设置 Intent
@available(macOS 13.0, *)
struct CompleteSetupIntent: AppIntent {
    static var title: LocalizedStringResource = "完整 macOS 环境设置"
    static var description = IntentDescription("自动检测、配置 Xcode、SSH、Terminal")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let manager = MacOSEnvironmentManager()

        do {
            try await manager.completeSetup()

            return .result(dialog: """
            ✅ macOS 环境设置完成！

            系统已就绪，包括：
            ✓ 系统兼容性检测
            ✓ Xcode 配置
            ✓ SSH 服务器
            ✓ Terminal 脚本

            可以开始开发了！
            """)

        } catch {
            return .result(dialog: "❌ 设置失败: \(error.localizedDescription)")
        }
    }
}

// MARK: - 系统检测

/// 检测 Mac 兼容性 Intent
@available(macOS 13.0, *)
struct DetectSystemIntent: AppIntent {
    static var title: LocalizedStringResource = "检测 Mac 系统兼容性"
    static var description = IntentDescription("检测 Mac 是否支持开发环境")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let manager = MacOSEnvironmentManager()

        do {
            try await manager.detectSystemCompatibility()

            guard let info = manager.systemInfo else {
                return .result(dialog: "❌ 无法获取系统信息")
            }

            var message = """
            📱 Mac 系统信息

            型号: \(info.model)
            芯片: \(info.chip.description)
            系统: macOS \(info.currentVersion)
            内存: \(info.memoryGB) GB
            存储: \(info.diskSpaceGB) GB

            """

            if manager.isCompatible {
                message += "✅ 系统完全兼容，可以正常使用所有功能！"
            } else {
                message += """
                ⚠️ 建议升级系统

                推荐版本: macOS \(manager.recommendedVersion ?? "最新版本")
                升级后可获得更好的开发体验。
                """
            }

            return .result(dialog: message)

        } catch {
            return .result(dialog: "❌ 检测失败: \(error.localizedDescription)")
        }
    }
}

// MARK: - Xcode 管理

/// 配置 Xcode Intent
@available(macOS 13.0, *)
struct SetupXcodeIntent: AppIntent {
    static var title: LocalizedStringResource = "配置 Xcode"
    static var description = IntentDescription("检测并配置 Xcode 开发环境")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let manager = MacOSEnvironmentManager()

        do {
            try await manager.setupXcode()

            let status = manager.xcodeStatus

            switch status {
            case .installed, .running:
                return .result(dialog: """
                ✅ Xcode 已就绪！

                状态: \(status.description)

                可以开始开发 iOS 应用了。
                """)

            case .notInstalled:
                return .result(dialog: """
                📥 Xcode 未安装

                已打开 App Store 下载页面。
                Xcode 约 10-15 GB，请耐心等待下载完成。

                下载完成后再次运行此快捷指令。
                """)

            case .downloading:
                return .result(dialog: """
                ⏳ Xcode 下载中...

                请在 App Store 查看下载进度。
                """)
            }

        } catch {
            return .result(dialog: "❌ 配置失败: \(error.localizedDescription)")
        }
    }
}

/// 启动 Xcode Intent
@available(macOS 13.0, *)
struct LaunchXcodeIntent: AppIntent {
    static var title: LocalizedStringResource = "启动 Xcode"
    static var description = IntentDescription("快速启动 Xcode")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-a", "Xcode"]

        try process.run()

        return .result(dialog: "🚀 Xcode 已启动")
    }
}

// MARK: - SSH 管理

/// 配置 SSH Server Intent
@available(macOS 13.0, *)
struct SetupSSHIntent: AppIntent {
    static var title: LocalizedStringResource = "配置 SSH 服务器"
    static var description = IntentDescription("启用并配置 SSH 远程访问")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let manager = MacOSEnvironmentManager()

        do {
            try await manager.setupSSHServer()

            return .result(dialog: """
            ✅ SSH 服务器已配置！

            状态: \(manager.sshStatus.description)

            💡 现在可以通过 SSH 远程连接到这台 Mac。
            """)

        } catch {
            return .result(dialog: "❌ 配置失败: \(error.localizedDescription)")
        }
    }
}

/// 获取 SSH 连接信息 Intent
@available(macOS 13.0, *)
struct GetSSHInfoIntent: AppIntent {
    static var title: LocalizedStringResource = "获取 SSH 连接信息"
    static var description = IntentDescription("查看 SSH 连接地址和端口")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let manager = MacOSEnvironmentManager()

        // 获取连接信息
        let username = NSUserName()

        // 简化版获取 IP
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/sbin/ifconfig")
        process.arguments = ["en0"]

        let pipe = Pipe()
        process.standardOutput = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        // 提取 IP 地址
        var ipAddress = "localhost"
        if let range = output.range(of: "inet ([0-9.]+)", options: .regularExpression) {
            let match = String(output[range])
            ipAddress = match.replacingOccurrences(of: "inet ", with: "")
        }

        return .result(dialog: """
        🔐 SSH 连接信息

        地址: \(ipAddress)
        端口: 22
        用户: \(username)

        💡 连接命令:
        ssh \(username)@\(ipAddress)

        从其他设备运行此命令即可连接到这台 Mac。
        """)
    }
}

// MARK: - Terminal 管理

/// 配置 Terminal Intent
@available(macOS 13.0, *)
struct SetupTerminalIntent: AppIntent {
    static var title: LocalizedStringResource = "配置内置 Terminal"
    static var description = IntentDescription("创建自动化 Terminal 脚本")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let manager = MacOSEnvironmentManager()

        do {
            try await manager.setupTerminal()

            let scriptPath = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(".automation_terminal.sh")

            return .result(dialog: """
            ✅ Terminal 已配置！

            脚本位置:
            \(scriptPath.path)

            💡 使用方法:
            1. 打开 Terminal.app
            2. 运行脚本启动自动化环境

            或直接运行快捷指令"启动自动化 Terminal"
            """)

        } catch {
            return .result(dialog: "❌ 配置失败: \(error.localizedDescription)")
        }
    }
}

/// 启动自动化 Terminal Intent
@available(macOS 13.0, *)
struct LaunchTerminalIntent: AppIntent {
    static var title: LocalizedStringResource = "启动自动化 Terminal"
    static var description = IntentDescription("打开配置好的开发 Terminal")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let scriptPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".automation_terminal.sh")

        // 检查脚本是否存在
        if !FileManager.default.fileExists(atPath: scriptPath.path) {
            return .result(dialog: """
            ⚠️ Terminal 脚本未找到

            请先运行"配置内置 Terminal"快捷指令。
            """)
        }

        // 打开 Terminal 并执行脚本
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-a", "Terminal", scriptPath.path]

        try process.run()

        return .result(dialog: "🚀 自动化 Terminal 已启动")
    }
}

// MARK: - 系统下载

/// 下载推荐系统 Intent
@available(macOS 13.0, *)
struct DownloadRecommendedSystemIntent: AppIntent {
    static var title: LocalizedStringResource = "下载推荐 macOS 版本"
    static var description = IntentDescription("下载并准备系统升级")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let manager = MacOSEnvironmentManager()

        // 先检测兼容性
        try await manager.detectSystemCompatibility()

        if manager.isCompatible {
            return .result(dialog: """
            ✅ 当前系统已是最佳版本

            系统: macOS \(manager.systemInfo?.currentVersion ?? "未知")

            无需升级。
            """)
        }

        guard let recommended = manager.recommendedVersion else {
            return .result(dialog: "❌ 无法确定推荐版本")
        }

        return .result(dialog: """
        📥 推荐升级到 macOS \(recommended)

        ⚠️ 注意:
        - 系统升级需要较长时间
        - 请备份重要数据
        - 需要至少 50GB 可用空间

        建议:
        1. 打开"系统设置"
        2. 点击"通用" > "软件更新"
        3. 按照向导完成升级

        或访问 Apple 官网下载完整安装器。
        """)
    }
}

// MARK: - 快捷菜单

/// macOS 环境快捷菜单
@available(macOS 13.0, *)
struct MacOSSetupShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CompleteSetupIntent(),
            phrases: [
                "完整设置 macOS 环境",
                "配置开发环境",
                "自动配置 Mac"
            ],
            shortTitle: "完整设置",
            systemImageName: "gear"
        )

        AppShortcut(
            intent: DetectSystemIntent(),
            phrases: [
                "检测 Mac 兼容性",
                "检查系统"
            ],
            shortTitle: "检测系统",
            systemImageName: "checkmark.shield"
        )

        AppShortcut(
            intent: SetupXcodeIntent(),
            phrases: [
                "配置 Xcode",
                "安装 Xcode"
            ],
            shortTitle: "配置 Xcode",
            systemImageName: "hammer"
        )

        AppShortcut(
            intent: LaunchXcodeIntent(),
            phrases: [
                "启动 Xcode",
                "打开 Xcode"
            ],
            shortTitle: "启动 Xcode",
            systemImageName: "play"
        )

        AppShortcut(
            intent: SetupSSHIntent(),
            phrases: [
                "配置 SSH",
                "启用远程登录"
            ],
            shortTitle: "配置 SSH",
            systemImageName: "network"
        )

        AppShortcut(
            intent: GetSSHInfoIntent(),
            phrases: [
                "获取 SSH 信息",
                "查看连接地址"
            ],
            shortTitle: "SSH 信息",
            systemImageName: "info.circle"
        )

        AppShortcut(
            intent: LaunchTerminalIntent(),
            phrases: [
                "启动自动化 Terminal",
                "打开 Terminal"
            ],
            shortTitle: "启动 Terminal",
            systemImageName: "terminal"
        )
    }
}
