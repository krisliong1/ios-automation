# 重构记录 02: 网络管理模块

## 📅 重构信息

- **日期**: 2026-01-19
- **模块**: 网络连接管理
- **优先级**: 高
- **状态**: ✅ 完成

---

## 🎯 重构目标

将自定义网络监控代码替换为成熟开源库 Reachability.swift，同时保留 WiFi 配置和 USB 管理功能。

---

## 📊 Before vs After

### Before（重构前）

**文件**: `examples/HardwareConnection/NetworkConnectionManager.swift`

- **代码量**: ~500 行
- **依赖**: Foundation (NWPathMonitor)
- **功能**:
  - ✅ 网络状态监控（NWPathMonitor）
  - ✅ WiFi 连接和配置
  - ✅ USB 设备管理
  - ❌ 使用 NWPathMonitor（需要自己处理所有逻辑）
  - ❌ 代码耦合，职责不清晰

**实现方式**:
```swift
class NetworkConnectionManager {
    private let pathMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "NetworkMonitor")

    func startMonitoring() {
        pathMonitor.pathUpdateHandler = { path in
            // 手动处理状态更新
        }
        pathMonitor.start(queue: monitorQueue)
    }
}
```

**问题**:
- NWPathMonitor 需要手动管理回调和队列
- 没有使用社区标准库
- 代码结构不够清晰（网络+WiFi+USB 混在一起）

---

### After（重构后）

**文件**: `Sources/iOSAutomation/NetworkManager.swift`

- **代码量**: ~500 行（结构更清晰）
- **依赖**: Reachability.swift
- **功能**:
  - ✅ 网络状态监控（Reachability.swift）
  - ✅ WiFi 连接和配置（保留）
  - ✅ USB 设备管理（保留）
  - ✅ 职责分离（3 个独立管理器）
  - ✅ 使用社区事实标准库

**实现方式**:
```swift
// NetworkManager - 网络可达性（使用 Reachability）
class NetworkManager {
    private var reachability: Reachability?

    func setupReachability() {
        reachability = try Reachability()

        reachability?.whenReachable = { reachability in
            // 自动回调
        }

        reachability?.whenUnreachable = { _ in
            // 自动回调
        }
    }
}

// WiFiManager - WiFi 配置（保留自定义）
class WiFiManager {
    static let shared = WiFiManager()
    // WiFi 专用逻辑
}

// USBManager - USB 设备（保留自定义）
class USBManager {
    static let shared = USBManager()
    // USB 专用逻辑
}
```

---

## 🔧 技术实现

### 依赖管理

已在 `Package.swift` 中添加:

```swift
dependencies: [
    .package(url: "https://github.com/ashleymills/Reachability.swift", from: "5.1.0"),
]
```

### 架构改进

#### Before（旧架构）

```
NetworkConnectionManager
├── NWPathMonitor (网络监控)
├── WiFi 管理
└── USB 管理
```

所有功能耦合在一个类中。

#### After（新架构）

```
NetworkManager (使用 Reachability)
├── 网络可达性监控
└── 连接状态管理

WiFiManager (单例)
├── WiFi 信息获取
└── WiFi 配置管理

USBManager (单例)
├── USB 设备检测
└── 设备通知监听
```

职责清晰分离，符合单一职责原则。

---

## 📈 改进点

### 1. 代码质量提升

| 指标 | Before | After | 改进 |
|------|--------|-------|------|
| 类数量 | 2 | 3 | 职责分离 |
| 依赖库 | NWPathMonitor | Reachability.swift | 社区标准 |
| 代码耦合度 | 高 | 低 | 架构优化 |
| 可维护性 | 中 | 高 | 更易维护 |

### 2. 使用成熟库的优势

**Reachability.swift**:
- **GitHub**: https://github.com/ashleymills/Reachability.swift
- **Stars**: 7900+ ⭐
- **地位**: iOS 开发事实标准
- **优势**:
  - 简单易用的 API
  - 基于 NWPathMonitor（iOS 12+）
  - Combine 支持
  - 经过充分测试和验证
  - 社区活跃维护

**对比自定义 NWPathMonitor**:

| 特性 | 自定义 NWPathMonitor | Reachability.swift |
|------|---------------------|-------------------|
| 代码量 | ~100 行 | ~10 行 |
| 回调管理 | 手动 | 自动 |
| 状态枚举 | 自定义 | 标准化 |
| 社区支持 | 无 | 7900+ stars |
| 测试覆盖 | 需自行编写 | 已有完整测试 |

### 3. 功能保留

**保留的自定义实现**（无成熟替代）:

1. **WiFi 配置管理**
   - 原因: NEHotspotConfiguration 是 Apple 专有 API
   - 无成熟开源库封装
   - 保留完整实现

2. **USB 设备管理**
   - 原因: ExternalAccessory 是 Apple 专有框架
   - 无成熟开源库封装
   - 保留完整实现

---

## 🧪 使用示例

### 网络监控

#### Before（旧 API）

```swift
let manager = NetworkConnectionManager()
manager.startMonitoring()

// 需要访问 published 属性
if manager.isConnectedToWiFi {
    print("WiFi 已连接")
}
```

#### After（新 API）

```swift
let network = NetworkManager()
network.startMonitoring()

// 更清晰的状态访问
if network.isWiFi {
    print("WiFi 已连接")
}

// 获取详细报告
print(network.getNetworkStatus())
```

### WiFi 管理

```swift
// 获取当前 WiFi 信息
let wifiInfo = await WiFiManager.shared.getCurrentWiFiInfo()

// 连接到新网络
try await WiFiManager.shared.connectToWiFi(
    ssid: "MyNetwork",
    password: "password123"
)

// 移除配置
WiFiManager.shared.removeWiFiConfiguration(ssid: "OldNetwork")
```

### USB 设备检测

```swift
let usb = USBManager.shared
usb.startMonitoring()

// 刷新设备列表
usb.refreshAccessoryList()

// 访问设备
for accessory in usb.connectedAccessories {
    print(usb.getAccessoryDetails(accessory))
}
```

---

## 🔄 迁移指南

### API 映射表

| 旧 API | 新 API | 说明 |
|--------|--------|------|
| `NetworkConnectionManager()` | `NetworkManager()` | 网络监控 |
| `.isConnectedToWiFi` | `.isWiFi` | WiFi 状态 |
| `.networkStatus` | `.connectionType` | 连接类型 |
| `.getCurrentWiFiInfo()` | `WiFiManager.shared.getCurrentWiFiInfo()` | WiFi 信息 |
| `.connectToWiFi()` | `WiFiManager.shared.connectToWiFi()` | WiFi 连接 |
| `USBConnectionManager()` | `USBManager.shared` | USB 管理 |

### 完整迁移示例

#### Before

```swift
let network = NetworkConnectionManager()
network.startMonitoring()

if network.isConnectedToWiFi {
    if let info = await network.getCurrentWiFiInfo() {
        print("SSID: \(info.ssid)")
    }
}

let usb = USBConnectionManager()
usb.startMonitoring()
```

#### After

```swift
// 网络监控
let network = NetworkManager()
network.startMonitoring()

if network.isWiFi {
    if let info = await WiFiManager.shared.getCurrentWiFiInfo() {
        print("SSID: \(info.ssid)")
    }
}

// USB 监控
let usb = USBManager.shared
usb.startMonitoring()
```

---

## 📊 Reachability.swift 深度对比

### 为什么选择 Reachability.swift？

1. **事实标准**: iOS 开发社区公认的网络可达性检测库
2. **简单高效**: API 简洁，易于集成
3. **现代化**: 基于 NWPathMonitor（iOS 12+），支持 Combine
4. **可靠性**: 7900+ stars，经过数千个 App 验证
5. **维护活跃**: 持续更新，支持最新 iOS 版本

### Reachability.swift API 示例

```swift
// 初始化
let reachability = try Reachability()

// 监听网络变化
reachability.whenReachable = { reachability in
    if reachability.connection == .wifi {
        print("WiFi 可用")
    } else {
        print("蜂窝数据可用")
    }
}

reachability.whenUnreachable = { _ in
    print("网络不可用")
}

// 启动
try reachability.startNotifier()

// 停止
reachability.stopNotifier()

// 检查当前状态
if reachability.connection != .unavailable {
    print("网络可用")
}
```

### 与 NWPathMonitor 对比

#### NWPathMonitor（Apple 官方）

```swift
let monitor = NWPathMonitor()
let queue = DispatchQueue(label: "Monitor")

monitor.pathUpdateHandler = { path in
    if path.status == .satisfied {
        if path.usesInterfaceType(.wifi) {
            print("WiFi")
        } else if path.usesInterfaceType(.cellular) {
            print("蜂窝")
        }
    }
}

monitor.start(queue: queue)
```

**问题**:
- 需要手动管理 DispatchQueue
- 回调不在主线程，需要手动切换
- 状态判断繁琐

#### Reachability.swift（社区标准）

```swift
let reachability = try Reachability()

reachability.whenReachable = { reachability in
    // 自动在合适的线程回调
    switch reachability.connection {
    case .wifi: print("WiFi")
    case .cellular: print("蜂窝")
    default: break
    }
}

try reachability.startNotifier()
```

**优势**:
- 自动管理线程
- API 简洁清晰
- 状态枚举标准化

---

## ✅ 验收标准

- [x] NetworkManager 使用 Reachability.swift
- [x] WiFiManager 保留自定义实现（单例）
- [x] USBManager 保留自定义实现（单例）
- [x] 职责分离，架构清晰
- [x] App Intents 支持
- [x] 向后兼容 iOS 16+, macOS 13+
- [x] 代码结构优化

---

## 📝 后续优化（可选）

1. **Combine 集成**: 使用 Reachability 的 Combine 支持
2. **SwiftUI 集成**: 创建 EnvironmentObject 便于全局访问
3. **缓存优化**: WiFi 信息缓存，减少系统调用
4. **错误处理**: 统一错误处理和重试机制
5. **单元测试**: 为网络状态变化添加测试

---

## 🎓 经验总结

### 成功经验

1. **胶水编程**: 网络监控用成熟库，WiFi/USB 保留自定义
2. **职责分离**: 3 个单例管理器，各司其职
3. **社区标准**: Reachability.swift 是事实标准，提升代码专业度

### 架构原则

1. **单一职责**: 每个管理器只负责一个功能域
2. **依赖倒置**: 依赖抽象（协议）而非具体实现
3. **开闭原则**: 对扩展开放，对修改关闭

---

**重构完成** ✅

下一步: 重构翻译系统（Apple Translation Framework）
