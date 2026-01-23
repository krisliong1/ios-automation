# Shadowrocket 自动配置指南

## 📖 简介

本系统提供了 **Shadowrocket 的完整自动化配置方案**，包括：

✅ **自动设备检测** - 识别 iPhone/iPad 型号和系统版本
✅ **智能配置生成** - 根据设备特性生成最优配置
✅ **订阅管理** - 支持添加和更新订阅链接
✅ **配置导出** - 生成标准 Shadowrocket 配置文件
✅ **连接测试** - 自动验证代理是否正常工作

---

## 🚀 快速开始

### 方法 1: 使用快捷指令（推荐）

1. **打开快捷指令 App**
2. **搜索 "配置 Shadowrocket"**
3. **运行快捷指令**
4. **等待自动配置完成**

系统会自动：
- ✅ 检测你的设备型号（如 iPhone 14 Pro）
- ✅ 检测系统版本（如 iOS 17.0）
- ✅ 生成适合你设备的最优配置
- ✅ 保存配置文件到文件 App

### 方法 2: 使用代码

```swift
import Foundation

let manager = ShadowrocketManager()

Task {
    do {
        // 自动配置
        try await manager.autoConfigureShadowrocket()

        // 查看配置摘要
        print(manager.getConfigurationSummary())

    } catch {
        print("配置失败: \(error)")
    }
}
```

---

## 📱 设备检测

### 自动检测的信息

系统会自动检测以下设备信息：

| 信息类型 | 示例 | 用途 |
|---------|------|------|
| 设备型号 | iPhone 14 Pro | 优化配置参数 |
| 系统版本 | iOS 17.0 | 兼容性检查 |
| CPU 架构 | Apple Silicon (ARM64) | 性能优化 |
| 总内存 | 6 GB | 资源分配 |
| 磁盘空间 | 128 GB | 存储检查 |
| 屏幕尺寸 | 1179 x 2556 | UI 适配 |

### 支持的设备

#### iPhone
- ✅ iPhone 15 系列（全系列）
- ✅ iPhone 14 系列（全系列）
- ✅ iPhone 13 系列（全系列）
- ✅ iPhone 12 系列（全系列）
- ✅ iPhone 11 系列（全系列）
- ✅ iPhone SE（2代/3代）

#### iPad
- ✅ iPad Pro（所有型号）
- ✅ iPad Air（4代/5代）
- ✅ iPad（9代/10代）
- ✅ iPad mini（6代）

#### macOS
- ✅ MacBook Pro
- ✅ MacBook Air
- ✅ iMac
- ✅ Mac mini
- ✅ Mac Studio
- ✅ Mac Pro

### 系统要求

| 平台 | 最低版本 | 推荐版本 |
|-----|---------|---------|
| iOS | 14.0 | 17.0+ |
| iPadOS | 14.0 | 17.0+ |
| macOS | 11.0 | 14.0+ |

### 硬件要求

- **内存**: 最低 1 GB RAM
- **存储**: 最低 100 MB 可用空间
- **网络**: 支持 WiFi 或蜂窝网络

---

## ⚙️ 配置详解

### 1. 自动配置流程

```
┌─────────────────┐
│ 1. 设备检测      │
│   检测型号和系统  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 2. 兼容性检查    │
│   验证系统要求   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 3. 生成配置      │
│   服务器+规则    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 4. 保存配置      │
│   JSON + CONF   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 5. 配置完成 ✅   │
└─────────────────┘
```

### 2. 生成的配置内容

系统会自动生成以下配置：

#### 服务器配置
```swift
{
    "name": "主服务器",
    "type": "ss",
    "server": "example.com",
    "port": 8388,
    "method": "aes-256-gcm",
    "password": "your-password",
    "enabled": true
}
```

#### 代理规则
```
DIRECT, GEOIP,CN           // 中国大陆直连
PROXY, DOMAIN-SUFFIX,google.com
PROXY, DOMAIN-SUFFIX,youtube.com
PROXY, DOMAIN-SUFFIX,twitter.com
PROXY, FINAL               // 其他走代理
```

#### DNS 配置
```
主 DNS:
- 223.5.5.5 (阿里 DNS)
- 114.114.114.114

备用 DNS:
- 1.1.1.1 (Cloudflare)
- 8.8.8.8 (Google)

DoH: https://dns.alidns.com/dns-query
```

### 3. 配置文件位置

配置文件保存在：

```
📁 文件 App
  └─ 我的 iPhone/iPad
      └─ Shadowrocket
          ├─ shadowrocket_config.json  (配置数据)
          └─ shadowrocket.conf         (导出配置)
```

---

## 📥 订阅管理

### 添加订阅

#### 方法 1: 快捷指令

1. 打开快捷指令
2. 搜索 "添加 Shadowrocket 订阅"
3. 输入订阅链接
4. 运行

#### 方法 2: 代码

```swift
let manager = ShadowrocketManager()

Task {
    let subscriptionURL = "https://example.com/subscription"

    try await manager.addSubscription(url: subscriptionURL)
    print("订阅添加成功")
}
```

### 支持的订阅格式

#### 1. Base64 编码订阅

```
https://example.com/sub?token=xxx
```

返回 Base64 编码的服务器列表：
```
c3M6Ly9ZV1Z6TFRJMU5pMW5ZMjA2Y0dGemMzZHZjbVJBYzJWeWRtVnlPamd6T
```

#### 2. 直接文本订阅

```
ss://YWVzLTI1Ni1nY206cGFzc3dvcmRAc2VydmVyOjgzODg=
vmess://eyJ2IjoyLCJwcyI6InRlc3QiLCJhZGQiOiJleGFtcGxlLmNvbSJ9
trojan://password@server.com:443#name
```

### 更新订阅

#### 自动更新

```swift
let manager = ShadowrocketManager()

Task {
    try await manager.updateSubscription()
    print("订阅更新成功")
}
```

#### 手动更新

1. 打开快捷指令
2. 搜索 "更新 Shadowrocket 订阅"
3. 运行

---

## 🔧 高级配置

### 自定义服务器

```swift
let server = ProxyServer(
    name: "自定义服务器",
    type: .shadowsocks,
    server: "my-server.com",
    port: 8388,
    method: "aes-256-gcm",
    password: "my-password",
    enabled: true
)

if var config = manager.currentConfig {
    config.servers.append(server)
    try manager.saveConfiguration(config)
}
```

### 支持的代理类型

#### 1. Shadowsocks (SS)

```swift
ProxyServer(
    name: "SS Server",
    type: .shadowsocks,
    server: "example.com",
    port: 8388,
    method: "aes-256-gcm",      // 加密方式
    password: "password",
    enabled: true
)
```

**支持的加密方式：**
- aes-256-gcm（推荐）
- aes-128-gcm
- chacha20-ietf-poly1305

#### 2. VMess

```swift
ProxyServer(
    name: "VMess Server",
    type: .vmess,
    server: "example.com",
    port: 443,
    method: "",
    password: "",
    uuid: "uuid-here",
    tls: true,
    enabled: true
)
```

#### 3. Trojan

```swift
ProxyServer(
    name: "Trojan Server",
    type: .trojan,
    server: "example.com",
    port: 443,
    method: "",
    password: "password",
    sni: "example.com",
    enabled: true
)
```

### 自定义规则

```swift
let rules = [
    // 直连规则
    ProxyRule(type: .direct, pattern: "GEOIP,CN"),
    ProxyRule(type: .direct, pattern: "DOMAIN-SUFFIX,apple.com"),

    // 代理规则
    ProxyRule(type: .proxy, pattern: "DOMAIN-SUFFIX,google.com"),
    ProxyRule(type: .proxy, pattern: "DOMAIN-KEYWORD,youtube"),

    // 屏蔽规则
    ProxyRule(type: .reject, pattern: "DOMAIN-SUFFIX,ad.com"),

    // 最终规则
    ProxyRule(type: .proxy, pattern: "FINAL")
]
```

### DNS 配置

```swift
let dnsConfig = DNSConfig(
    servers: ["223.5.5.5", "114.114.114.114"],
    fallback: ["1.1.1.1", "8.8.8.8"],
    enableDoH: true,
    dohURL: "https://dns.alidns.com/dns-query"
)
```

---

## 🔌 连接测试

### 自动测试

```swift
let manager = ShadowrocketManager()

let success = await manager.testConnection()

if success {
    print("✅ 连接成功")
} else {
    print("❌ 连接失败")
}
```

### 测试流程

```
1. 发送请求到 https://www.google.com
2. 检查 HTTP 响应码
3. 200 = 成功
4. 其他 = 失败
```

---

## 📊 配置摘要

### 查看配置摘要

```swift
let summary = manager.getConfigurationSummary()
print(summary)
```

### 输出示例

```
📱 Shadowrocket 配置摘要
========================

设备信息
--------
设备型号: iPhone 14 Pro
系统版本: iOS 17.0

服务器配置
----------
总服务器数: 5
已启用: 3

规则配置
--------
总规则数: 6

DNS 配置
--------
主 DNS: 223.5.5.5, 114.114.114.114
DoH: 已启用

创建时间
--------
2026-01-17 10:30:00
```

---

## 📖 完整示例

### 示例 1: 初次配置

```swift
import Foundation

func setupShadowrocket() async {
    let manager = ShadowrocketManager()

    do {
        // 1. 自动配置
        try await manager.autoConfigureShadowrocket()

        // 2. 添加订阅
        try await manager.addSubscription(
            url: "https://example.com/subscription?token=xxx"
        )

        // 3. 测试连接
        let success = await manager.testConnection()
        print("连接测试: \(success ? "成功" : "失败")")

        // 4. 查看配置
        print(manager.getConfigurationSummary())

    } catch {
        print("设置失败: \(error)")
    }
}

// 运行
Task {
    await setupShadowrocket()
}
```

### 示例 2: 更新订阅

```swift
func updateSubscription() async {
    let manager = ShadowrocketManager()

    do {
        // 更新订阅
        try await manager.updateSubscription()

        // 重新测试连接
        let success = await manager.testConnection()
        print("更新后连接: \(success ? "正常" : "失败")")

    } catch {
        print("更新失败: \(error)")
    }
}
```

### 示例 3: 自定义配置

```swift
func customConfiguration() {
    let manager = ShadowrocketManager()

    // 创建自定义服务器
    let myServer = ProxyServer(
        name: "我的服务器",
        type: .shadowsocks,
        server: "my-server.com",
        port: 8388,
        method: "aes-256-gcm",
        password: "my-password",
        enabled: true
    )

    // 创建自定义规则
    let myRules = [
        ProxyRule(type: .direct, pattern: "GEOIP,CN"),
        ProxyRule(type: .proxy, pattern: "FINAL")
    ]

    // 创建完整配置
    let config = ProxyConfig(
        name: "自定义配置",
        deviceModel: manager.deviceInfo.deviceModel,
        systemVersion: manager.deviceInfo.systemVersion,
        servers: [myServer],
        rules: myRules,
        dns: DNSConfig(
            servers: ["223.5.5.5"],
            fallback: ["1.1.1.1"],
            enableDoH: true,
            dohURL: "https://dns.alidns.com/dns-query"
        ),
        general: GeneralConfig(
            bypassSystemProxy: false,
            skipProxy: ["127.0.0.1"],
            dnsServer: ["223.5.5.5"],
            alwaysRealIP: [],
            hijackDNS: [],
            ipv6: true,
            preferIPv6: false,
            dnsFollow: true,
            allowWifiAccess: false,
            theme: "dark"
        ),
        createdAt: Date()
    )

    // 保存配置
    do {
        try manager.saveConfiguration(config)
        print("✅ 自定义配置已保存")
    } catch {
        print("❌ 保存失败: \(error)")
    }
}
```

---

## 🐛 故障排除

### 问题 1: 设备检测失败

**症状：** 无法识别设备型号

**解决方法：**
```swift
let deviceInfo = DeviceInfoManager()
deviceInfo.detectDeviceInfo()

print("设备型号: \(deviceInfo.deviceModel)")
print("系统版本: \(deviceInfo.systemVersion)")
```

### 问题 2: 订阅解析失败

**症状：** 添加订阅后没有服务器

**可能原因：**
- 订阅链接格式错误
- 网络连接问题
- 订阅内容格式不支持

**解决方法：**
1. 检查订阅链接是否有效
2. 尝试在浏览器中打开订阅链接
3. 检查网络连接

### 问题 3: 连接测试失败

**症状：** testConnection() 返回 false

**解决方法：**
1. 检查服务器配置是否正确
2. 验证服务器端口是否开放
3. 确认密码和加密方式正确
4. 尝试更换其他服务器

### 问题 4: 配置文件未生成

**症状：** 找不到配置文件

**解决方法：**
```swift
// 检查配置文件路径
let documentsPath = FileManager.default.urls(
    for: .documentDirectory,
    in: .userDomainMask
)[0]

print("配置目录: \(documentsPath.path)")

// 列出所有文件
if let files = try? FileManager.default.contentsOfDirectory(
    atPath: documentsPath.path
) {
    print("文件列表: \(files)")
}
```

---

## 🔐 安全建议

### 1. 密码安全

- ✅ 使用强密码（至少 16 位）
- ✅ 定期更换密码
- ❌ 不要使用简单密码（如 123456）

### 2. 订阅链接

- ✅ 使用 HTTPS 订阅链接
- ✅ 不要分享订阅链接
- ❌ 不要在公共场所查看订阅链接

### 3. 配置备份

```swift
// 导出配置
let encoder = JSONEncoder()
encoder.outputFormatting = .prettyPrinted

if let data = try? encoder.encode(manager.currentConfig),
   let json = String(data: data, encoding: .utf8) {
    // 保存到安全位置
    print(json)
}
```

---

## 📚 API 参考

### ShadowrocketManager

#### 主要方法

```swift
// 自动配置
func autoConfigureShadowrocket() async throws

// 添加订阅
func addSubscription(url: String) async throws

// 更新订阅
func updateSubscription() async throws

// 测试连接
func testConnection() async -> Bool

// 保存配置
func saveConfiguration(_ config: ProxyConfig) throws

// 加载配置
func loadConfiguration()

// 获取配置摘要
func getConfigurationSummary() -> String
```

#### 属性

```swift
@Published var isConfigured: Bool
@Published var currentConfig: ProxyConfig?
@Published var subscriptionURL: String?
@Published var lastUpdateTime: Date?
@Published var connectionStatus: ConnectionStatus
```

### DeviceInfoManager

#### 主要方法

```swift
// 检测设备信息
func detectDeviceInfo()

// 检查系统版本
func checkSystemVersion(minimum: String) -> Bool

// 检查设备兼容性
func checkCompatibility(requirements: CompatibilityRequirements)
    -> (compatible: Bool, reasons: [String])

// 获取设备信息
func getDeviceInfo() -> DeviceInfo

// 生成报告
func generateReport() -> String
```

---

## 🎓 最佳实践

### 1. 定期更新订阅

```swift
// 建议每周更新一次
let manager = ShadowrocketManager()

Task {
    try? await manager.updateSubscription()
}
```

### 2. 测试多个服务器

```swift
// 测试所有服务器，选择最快的
func testAllServers() async {
    guard let config = manager.currentConfig else { return }

    for server in config.servers where server.enabled {
        print("测试: \(server.name)")
        let success = await manager.testConnection()
        print("结果: \(success ? "成功" : "失败")")
    }
}
```

### 3. 备份配置

```swift
// 定期备份配置
func backupConfiguration() {
    guard let config = manager.currentConfig else { return }

    do {
        let encoder = JSONEncoder()
        let data = try encoder.encode(config)

        // 保存到 iCloud
        // ...

    } catch {
        print("备份失败: \(error)")
    }
}
```

---

## 🌟 总结

Shadowrocket 自动配置系统为你提供了：

✅ **智能检测** - 自动识别设备型号和系统
✅ **一键配置** - 无需手动设置
✅ **订阅管理** - 轻松添加和更新订阅
✅ **配置导出** - 标准格式，兼容性好
✅ **连接测试** - 自动验证配置正确性

现在你可以：
1. 打开快捷指令
2. 搜索 "配置 Shadowrocket"
3. 运行快捷指令
4. 享受自动化配置！

**Happy Networking! 🚀**
