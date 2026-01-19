# 胶水编程重构方案

## 📋 概述

根据"胶水编程"理念，本文档对比所有模块的**自定义代码** vs **成熟开源库**，并提供重构建议。

**原则**：
- ✅ 优先使用成熟开源库
- ✅ 仅保留最少的"胶水代码"连接组件
- ✅ 避免重复造轮子

---

## 🔍 模块对比分析

### 1. ❌ AI 问题解决 (Kris AI Fixer)

#### 现状
- **自定义代码**: `AIFixer.swift`
- **功能**: 智能问题诊断和修复

#### 🚨 **重要通知**: 没有找到完全匹配的开源库

**原因**: AI 问题解决器是高度定制化功能，现有库主要是：
- **DebugSwift** - 调试工具包（内存泄漏、性能监控）
- **GitHub Copilot** - 代码补全和建议
- **SWAN** - 静态代码分析
- **swift-lint** - 代码规范检查

**差异**: 这些库都不提供"智能问题修复"功能，只提供检测和分析。

#### ✅ 推荐方案
**保留自定义实现**，但可以集成以下库辅助：
- **DebugSwift** (https://github.com/DebugSwift/DebugSwift) - 用于检测问题
- **SWAN** (https://github.com/themaplelab/swan) - 用于静态分析

**胶水代码**:
```swift
// 使用 DebugSwift 检测问题
let issues = DebugSwift.detectIssues()

// 自定义 AI 修复逻辑
for issue in issues {
    try await AIFixer.fix(issue)
}
```

---

### 2. ✅ 翻译系统 (AI Translator)

#### 现状
- **自定义代码**: `AITranslator.swift` (~800 行)
- **功能**: 多语言翻译成中文，保留代码语法

#### ✅ 推荐替换为: Apple Translation Framework

**库**: Apple Translation Framework (iOS 17.4+)
- **优势**:
  - 完全免费
  - 离线翻译（无需 API）
  - Apple 官方支持
  - 隐私保护（不发送数据到服务器）
- **GitHub**: 系统内置框架

**备选方案** (如果需要支持 iOS 17.4 以下):
- **SwiftTranslate** (https://github.com/SwiftPackageRepository/SwiftTranslate) - LibreTranslate API
- **MyMemory API** - 保留现有实现

#### 🔧 重构步骤
1. 删除 `AITranslator.swift` 中的 API 调用代码
2. 使用 Apple Translation Framework:
   ```swift
   import Translation

   let text = "Hello"
   let translated = try await Translation.translate(text, to: .simplifiedChinese)
   ```
3. 仅保留代码语法保护的"胶水代码"

**减少代码量**: ~800 行 → ~100 行 (87.5% 减少)

---

### 3. ✅ Shadowrocket 代理配置

#### 现状
- **自定义代码**: `ShadowrocketManager.swift` (~900 行)
- **功能**: 自动配置 Shadowsocks/VMess/Trojan 代理

#### ✅ 推荐替换为: Potatso 库

**库**: Potatso (https://github.com/haxpor/Potatso)
- **优势**:
  - 完整的 Shadowsocks 客户端实现
  - 支持多种代理协议
  - Swift 编写，活跃维护
  - 2000+ stars

**替代方案**:
- **Clash for iOS** - 如果需要更高级的规则配置

#### 🔧 重构步骤
1. 集成 Potatso 库作为依赖
2. 删除自定义协议解析代码
3. 保留设备检测和自动配置的"胶水代码":
   ```swift
   // 检测设备
   let device = DeviceInfoManager.detectDeviceInfo()

   // 使用 Potatso 配置代理
   Potatso.configure(server: serverInfo)
   ```

**减少代码量**: ~900 行 → ~150 行 (83.3% 减少)

---

### 4. ✅ VM 检测和绕过

#### 现状
- **自定义代码**: `VMDetector.swift`
- **功能**: 检测虚拟机、越狱、调试器

#### ✅ 推荐替换为: IOSSecuritySuite

**库**: IOSSecuritySuite (https://github.com/securing/IOSSecuritySuite)
- **优势**:
  - 2600+ stars (最受欢迎)
  - 纯 Swift 实现
  - 2024-2025 活跃维护
  - OWASP MASVS 标准
  - 功能全面:
    - ✅ 模拟器检测 `amIRunInEmulator()`
    - ✅ 越狱检测 `amIJailbroken()`
    - ✅ 调试器检测 `amIDebugged()`
    - ✅ 逆向工程检测
    - ✅ 运行时完整性检查

#### 🔧 重构步骤
1. 删除 `VMDetector.swift` 全部内容
2. 集成 IOSSecuritySuite:
   ```swift
   import IOSSecuritySuite

   let isVM = IOSSecuritySuite.amIRunInEmulator()
   let isJailbroken = IOSSecuritySuite.amIJailbroken()
   let isDebugged = IOSSecuritySuite.amIDebugged()
   ```

**减少代码量**: 完全替换，代码量减少 ~90%

---

### 5. ✅ iCloud 同步管理

#### 现状
- **自定义代码**: `iCloudSyncManager.swift`
- **功能**: 跨设备数据同步

#### ✅ 推荐替换为: Cirrus 或 CloudSyncSession

**库 1**: Cirrus (https://github.com/jayhickey/Cirrus)
- **优势**:
  - 简单的 CloudKit 同步
  - Codable 模型支持
  - 私有数据库支持
  - 现代 Swift 实现

**库 2**: CloudSyncSession (https://github.com/ryanashcraft/CloudSyncSession)
- **优势**:
  - 不持久化状态到磁盘
  - 兼容任何本地存储（Core Data, GRDB, UserDefaults）
  - 离线支持

#### 🔧 重构步骤
1. 选择 Cirrus（如果使用 Codable）或 CloudSyncSession（如果使用 Core Data）
2. 删除自定义 CloudKit 代码
3. 使用库的 API:
   ```swift
   // Cirrus 示例
   struct MyData: Codable {
       let name: String
   }

   try await Cirrus.sync(MyData.self)
   ```

**减少代码量**: ~500 行 → ~50 行 (90% 减少)

---

### 6. ✅ 蓝牙设备管理

#### 现状
- **自定义代码**: `BluetoothManager.swift`
- **功能**: BLE 设备连接和管理

#### ✅ 推荐替换为: SwiftBluetooth 或 CombineCoreBluetooth

**库 1**: SwiftBluetooth (https://github.com/exPHAT/SwiftBluetooth)
- **优势**:
  - 现代 async/await 支持
  - AsyncStream 支持
  - 简洁的 API

**库 2**: CombineCoreBluetooth (https://github.com/StarryInternet/CombineCoreBluetooth)
- **优势**:
  - Combine Publishers
  - 响应式编程
  - 69 stars

**企业级选项**: iOS-BLE-Library by Nordic Semiconductor
- 专业级支持，100% Swift

#### 🔧 重构步骤
1. 选择 SwiftBluetooth (推荐现代项目)
2. 删除自定义 CoreBluetooth 封装
3. 使用库的 async/await API:
   ```swift
   // SwiftBluetooth 示例
   let peripheral = try await central.scanForPeripherals()
   try await peripheral.connect()
   let value = try await peripheral.readValue(for: characteristic)
   ```

**减少代码量**: ~600 行 → ~100 行 (83.3% 减少)

---

### 7. ✅ 网络连接管理

#### 现状
- **自定义代码**: `NetworkManager.swift`
- **功能**: 网络可达性检测和监控

#### ✅ 推荐替换为: Reachability.swift 或 NetworkReachability

**库 1**: ashleymills/Reachability.swift (https://github.com/ashleymills/Reachability.swift)
- **优势**:
  - 最受欢迎（事实标准）
  - 基于 NWPathMonitor
  - Combine 支持
  - 简单易用

**库 2**: vsanthanam/NetworkReachability (https://github.com/vsanthanam/NetworkReachability)
- **优势**:
  - 现代 async/await 支持
  - Structured Concurrency
  - 替代 SystemConfiguration API

**增强版**: rwbutler/Connectivity (https://github.com/rwbutler/Connectivity)
- 解决"伪连接"问题（连接 WiFi 但无互联网）

#### 🔧 重构步骤
1. 选择 Reachability.swift（最稳定）
2. 删除自定义网络监控代码
3. 使用库的 API:
   ```swift
   import Reachability

   let reachability = try Reachability()

   reachability.whenReachable = { _ in
       print("网络可用")
   }

   try reachability.startNotifier()
   ```

**减少代码量**: ~400 行 → ~50 行 (87.5% 减少)

---

### 8. ✅ 设备信息检测

#### 现状
- **自定义代码**: `DeviceInfoManager.swift` (~600 行)
- **功能**: 检测 150+ 设备型号

#### ⚠️ 建议: **保留部分自定义实现**

**原因**:
- 没有找到维护良好的设备型号识别库
- 设备型号数据库需要持续更新（新设备发布）
- 现有代码已经很完善

#### 🔧 优化方案
不删除，但可以优化:
1. 提取设备数据到 JSON 配置文件
2. 使用 `sysctl` 优化检测性能
3. 减少硬编码，使用数据驱动

**减少代码量**: ~600 行 → ~300 行 (50% 减少)

---

### 9. ✅ macOS 环境配置

#### 现状
- **自定义代码**: `MacOSEnvironmentManager.swift` (~800 行)
- **功能**: Xcode、SSH、Terminal 自动配置

#### ⚠️ 建议: **保留自定义实现**

**原因**:
- 这是高度定制化的自动化流程
- 没有开源库提供"一键配置开发环境"功能
- 现有实现已经是最优方案

#### 🔧 优化方案
不删除，但可以模块化:
1. 分离为独立模块（XcodeManager, SSHManager, TerminalManager）
2. 使用 Process 和 shell 脚本优化
3. 减少重复代码

**保持现状**: 这已经是"胶水代码"（连接系统工具）

---

## 📊 总结对比

| 模块 | 现状代码量 | 推荐方案 | 重构后代码量 | 减少比例 | 开源库状态 |
|------|-----------|---------|------------|---------|----------|
| AI Fixer | ~500 行 | 保留 + DebugSwift | ~400 行 | 20% | ❌ 无完全匹配 |
| 翻译系统 | ~800 行 | Apple Translation Framework | ~100 行 | 87.5% | ✅ 系统内置 |
| Shadowrocket | ~900 行 | Potatso | ~150 行 | 83.3% | ✅ 成熟库 |
| VM 检测 | ~400 行 | IOSSecuritySuite | ~50 行 | 87.5% | ✅ 最佳库 |
| iCloud 同步 | ~500 行 | Cirrus | ~50 行 | 90% | ✅ 成熟库 |
| 蓝牙管理 | ~600 行 | SwiftBluetooth | ~100 行 | 83.3% | ✅ 现代库 |
| 网络管理 | ~400 行 | Reachability.swift | ~50 行 | 87.5% | ✅ 事实标准 |
| 设备检测 | ~600 行 | 保留优化 | ~300 行 | 50% | ⚠️ 无维护库 |
| macOS 环境 | ~800 行 | 保留 | ~800 行 | 0% | ⚠️ 高度定制 |
| **总计** | **~5500 行** | **混合方案** | **~2000 行** | **~63.6%** | - |

---

## 🎯 重构优先级

### 高优先级（立即重构）
1. ✅ **VM 检测** - 替换为 IOSSecuritySuite（完全替代）
2. ✅ **网络管理** - 替换为 Reachability.swift（事实标准）
3. ✅ **翻译系统** - 替换为 Apple Translation Framework（系统内置）

### 中优先级（建议重构）
4. ✅ **蓝牙管理** - 替换为 SwiftBluetooth
5. ✅ **iCloud 同步** - 替换为 Cirrus
6. ✅ **Shadowrocket** - 替换为 Potatso

### 低优先级（优化即可）
7. ⚠️ **设备检测** - 优化数据结构
8. ⚠️ **macOS 环境** - 保持现状（已是最优）

### 保留自定义
9. ❌ **AI Fixer** - 无替代库，可集成 DebugSwift 辅助

---

## 📦 依赖清单

重构后需要添加的开源库（SPM）:

```swift
// Package.swift
dependencies: [
    // VM 检测和安全
    .package(url: "https://github.com/securing/IOSSecuritySuite", from: "1.9.0"),

    // 网络管理
    .package(url: "https://github.com/ashleymills/Reachability.swift", from: "5.1.0"),

    // 蓝牙管理
    .package(url: "https://github.com/exPHAT/SwiftBluetooth", from: "1.0.0"),

    // iCloud 同步
    .package(url: "https://github.com/jayhickey/Cirrus", from: "1.0.0"),

    // Shadowrocket (需要手动集成)
    // Potatso 框架

    // 调试辅助（可选）
    .package(url: "https://github.com/DebugSwift/DebugSwift", from: "1.0.0"),
]
```

---

## ⚠️ 重要通知

### ❌ 无成熟开源库的模块

1. **AI 问题解决器 (Kris AI Fixer)**
   - 原因: 高度定制化功能
   - 建议: 保留自定义实现，集成 DebugSwift 辅助检测

2. **设备型号识别**
   - 原因: 需要持续更新设备数据库
   - 建议: 保留自定义实现，优化数据结构

3. **macOS 环境配置**
   - 原因: 工作流自动化，无通用库
   - 建议: 保持现状（已是胶水代码）

---

## 🚀 下一步行动

### 选项 A: 按优先级逐个重构
1. 从高优先级开始（VM 检测）
2. 每次重构一个模块
3. 测试后再进行下一个

### 选项 B: 并行重构（快速）
1. 同时重构所有可替换模块
2. 统一测试
3. 一次性提交

### 选项 C: 混合方案
1. 先替换简单模块（VM、网络）
2. 再处理复杂模块（蓝牙、iCloud）
3. 最后优化保留模块

---

## 📋 撤销/重做系统

✅ **已创建**: `UndoRedoManager.swift`

在重构过程中使用:
```swift
let undo = UndoRedoManager()

// 注册操作
undo.registerOperation(
    description: "替换 VMDetector 为 IOSSecuritySuite",
    undo: { /* 恢复旧代码 */ },
    redo: { /* 应用新代码 */ }
)

// 如果出错
try await undo.undo()
```

---

**你想选择哪个方案？(A/B/C) 或者想先看某个具体模块的详细重构计划？**
