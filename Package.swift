// swift-tools-version: 5.9
// iOS 自动化项目 - Swift Package 配置

import PackageDescription

let package = Package(
    name: "iOSAutomation",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "iOSAutomation",
            targets: ["iOSAutomation"]
        ),
    ],
    dependencies: [
        // 安全检测 - iOS 平台
        .package(url: "https://github.com/securing/IOSSecuritySuite", from: "1.9.0"),

        // 网络可达性检测
        .package(url: "https://github.com/ashleymills/Reachability.swift", from: "5.1.0"),

        // 蓝牙管理 - 现代 async/await
        .package(url: "https://github.com/exPHAT/SwiftBluetooth", from: "1.0.0"),

        // iCloud 同步
        .package(url: "https://github.com/jayhickey/Cirrus", from: "1.0.0"),

        // 调试工具（可选）
        .package(url: "https://github.com/DebugSwift/DebugSwift", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "iOSAutomation",
            dependencies: [
                .product(name: "IOSSecuritySuite", package: "IOSSecuritySuite"),
                .product(name: "Reachability", package: "Reachability.swift"),
                .product(name: "SwiftBluetooth", package: "SwiftBluetooth"),
                .product(name: "Cirrus", package: "Cirrus"),
                .product(name: "DebugSwift", package: "DebugSwift"),
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "iOSAutomationTests",
            dependencies: ["iOSAutomation"],
            path: "Tests"
        ),
    ]
)
