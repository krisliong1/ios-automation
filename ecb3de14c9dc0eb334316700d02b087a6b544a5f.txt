// swift-tools-version: 5.9
// iOS 自动化项目 - 真正的跨平台支持
// 支持: iOS 16+, macOS 13+, watchOS 9+, tvOS 16+

import PackageDescription

let package = Package(
    name: "iOSAutomation",
    
    // 🎯 支持所有 Apple 平台
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .watchOS(.v9),
        .tvOS(.v16)
    ],
    
    products: [
        // 主库 - 所有平台都可用
        .library(
            name: "iOSAutomation",
            targets: ["iOSAutomation"]
        ),
        
        // CLI 工具 - 所有平台都可用（不仅仅是 macOS）
        .executable(
            name: "AutomationCLI",
            targets: ["AutomationCLI"]
        )
    ],
    
    dependencies: [
        // 安全检测 - 支持 iOS + macOS
        .package(url: "https://github.com/securing/IOSSecuritySuite", from: "1.9.0"),
        
        // 网络检测 - 支持所有平台
        .package(url: "https://github.com/ashleymills/Reachability.swift", from: "5.2.0"),
        
        // 蓝牙 - 支持 iOS + macOS + watchOS
        .package(url: "https://github.com/exPHAT/SwiftBluetooth", from: "1.0.0"),
    ],
    
    targets: [
        // 主库 - 智能适配所有平台
        .target(
            name: "iOSAutomation",
            dependencies: [
                // iOS + macOS + Catalyst 支持安全检测
                .product(
                    name: "IOSSecuritySuite", 
                    package: "IOSSecuritySuite",
                    condition: .when(platforms: [.iOS, .macOS, .macCatalyst])
                ),
                
                // 所有平台都支持网络检测
                .product(
                    name: "Reachability", 
                    package: "Reachability.swift"
                ),
                
                // iOS + macOS + watchOS 支持蓝牙
                .product(
                    name: "SwiftBluetooth", 
                    package: "SwiftBluetooth",
                    condition: .when(platforms: [.iOS, .macOS, .watchOS])
                ),
            ],
            path: "Sources/iOSAutomation",
            resources: [
                .process("Resources")
            ]
        ),
        
        // CLI 工具 - 所有平台都能编译
        .executableTarget(
            name: "AutomationCLI",
            dependencies: ["iOSAutomation"],
            path: "Sources/AutomationCLI"
        ),
        
        // 测试 - 所有平台
        .testTarget(
            name: "iOSAutomationTests",
            dependencies: ["iOSAutomation"],
            path: "Tests/iOSAutomationTests"
        ),
    ]
)
