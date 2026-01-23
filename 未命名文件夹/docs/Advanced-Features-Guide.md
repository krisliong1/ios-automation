# iOS 自动化高级功能指南

> **版本**: 2.0
> **更新日期**: 2026-01-17
> **新增功能**: iCloud 同步、macOS 虚拟化、硬件连接

---

## 📑 目录

- [第一部分：iCloud 跨设备同步](#第一部分icloud-跨设备同步)
- [第二部分：macOS 虚拟化](#第二部分macos-虚拟化)
- [第三部分：硬件连接管理](#第三部分硬件连接管理)
- [第四部分：网络功能集成](#第四部分网络功能集成)
- [第五部分：实战应用](#第五部分实战应用)

---

# 第一部分：iCloud 跨设备同步

## 1.1 iCloud 文档同步简介

### 为什么需要 iCloud 同步？

✅ **跨设备无缝访问** - 在 iPhone、iPad、Mac 上同步数据
✅ **无需手动下载** - 自动同步，即时访问
✅ **节省存储空间** - 按需下载，不占用本地空间
✅ **自动备份** - 数据安全，永不丢失

### 技术原理

iCloud 使用 **Ubiquity Container** 机制：
- 文件自动上传到 iCloud
- 其他设备自动接收更新
- 按需下载，节省空间

---

## 1.2 配置 iCloud 功能

### 步骤 1：启用 iCloud Capability

**在 Xcode 中**:
1. 选择项目 → Target → Signing & Capabilities
2. 点击 "+ Capability"
3. 添加 "iCloud"
4. 勾选 "iCloud Documents"

### 步骤 2：配置权限

**Info.plist 添加**:
```xml
<key>NSUbiquitousContainers</key>
<dict>
    <key>iCloud.$(CFBundleIdentifier)</key>
    <dict>
        <key>NSUbiquitousContainerIsDocumentScopePublic</key>
        <true/>
        <key>NSUbiquitousContainerName</key>
        <string>AutomationHelper</string>
        <key>NSUbiquitousContainerSupportedFolderLevels</key>
        <string>Any</string>
    </dict>
</dict>
```

### 步骤 3：使用示例代码

**复制代码到项目**:
```swift
// 使用 iCloudSyncManager
let syncManager = iCloudSyncManager()

// 保存文档到 iCloud
try await syncManager.saveDocument("Hello World", filename: "test.txt")

// 从 iCloud 读取（无需下载）
let content = try await syncManager.readDocument(filename: "test.txt")

// 列出所有文档
let documents = try await syncManager.listDocuments()
```

---

## 1.3 在快捷指令中使用

### 快捷指令配置

**示例：保存笔记到 iCloud**
```
1. [询问输入]
   提示: "输入笔记内容"
   → 变量: noteContent

2. [获取当前日期]
   → 变量: currentDate

3. [格式化日期]
   日期: currentDate
   格式: yyyy-MM-dd-HHmmss
   → 变量: timestamp

4. [文本]
   note-[timestamp].txt
   → 变量: filename

5. [保存到 iCloud] AutomationHelper
   文件名: filename
   内容: noteContent

6. [显示通知]
   标题: "✅ 笔记已保存"
   正文: "已同步到 iCloud"
```

**示例：从 iCloud 读取最新笔记**
```
1. [列出 iCloud 文档] AutomationHelper

2. [从列表中获取项目]
   列表: [快捷指令输入]
   获取: 第一项

3. [从 iCloud 读取] AutomationHelper
   文件名: [步骤2的文件名]

4. [显示结果]
   文本: [快捷指令输入]
```

---

## 1.4 高级功能

### 监听文档变化

```swift
// 开始监听
syncManager.startMonitoringChanges()

// 自动接收更新通知
// 当其他设备修改文档时，会自动通知
```

### 批量同步

```swift
// 同步所有文档
try await syncManager.syncAllDocuments()

// 查看同步进度
print("进度: \(syncManager.syncProgress * 100)%")
```

---

# 第二部分：macOS 虚拟化

## 2.1 macOS 虚拟化简介

### 什么是 Virtualization Framework？

Apple 的 **Virtualization.framework** 允许在 macOS 上运行虚拟 macOS 系统。

**特性**:
- ✅ 原生性能（接近本地速度）
- ✅ 完整的 macOS 系统
- ✅ 图形加速支持
- ✅ 网络和文件共享

**要求**:
- macOS 12.0 (Monterey) 或更高
- Apple Silicon (M1/M2/M3) 或 Intel Mac
- 至少 8GB 内存
- 至少 64GB 可用存储空间

---

## 2.2 下载 macOS 镜像

### 方法 1：使用命令行

```bash
# 下载 macOS Sonoma 14.6.1
curl -LO https://updates.cdn-apple.com/2024SummerFCS/fullrestores/062-52859/932E0A8F-6644-4759-82DA-F8FA8DEA806A/UniversalMac_14.6.1_23G93_Restore.ipsw

# 下载 macOS Ventura 13.6
curl -LO https://updates.cdn-apple.com/2023FallFCS/fullrestores/042-88743/7FC45A40-79F9-4195-B5AE-5FCFBCE8B8EB/UniversalMac_13.6_22G120_Restore.ipsw
```

### 方法 2：使用快捷指令

**示例：搜索可用镜像**
```
1. [搜索 macOS 镜像] AutomationHelper
   → 显示可用镜像列表

2. [选择镜像]
   → 选择要下载的版本

3. [下载 macOS 镜像] AutomationHelper
   镜像: [步骤2的选择]
   保存位置: ~/Downloads/

4. [显示通知]
   标题: "下载完成"
   正文: "镜像已保存到下载文件夹"
```

### 方法 3：使用代码

```swift
let manager = MacOSVirtualizationManager()

// 搜索可用镜像
let images = try await manager.searchAvailableMacOSImages()

// 下载镜像
let image = images.first!
let destination = URL(fileURLWithPath: "~/Downloads/macOS.ipsw")
try await manager.downloadMacOSImage(image, to: destination)
```

---

## 2.3 验证镜像完整性

### 为什么需要验证？

- ✅ 确保下载完整
- ✅ 防止文件损坏
- ✅ 避免安装失败

### 验证方法

```swift
let manager = MacOSVirtualizationManager()
let imagePath = URL(fileURLWithPath: "~/Downloads/macOS.ipsw")

// 验证镜像
let isValid = try await manager.verifyImage(at: imagePath)

if isValid {
    print("✅ 镜像验证通过")
} else {
    print("❌ 镜像损坏，请重新下载")
}
```

### 验证步骤

1. **检查文件大小** - 应该与官方大小一致
2. **检查文件头** - IPSW 是 ZIP 格式，以 "PK" 开头
3. **完整性校验** - 可选：计算 SHA256 哈希值

---

## 2.4 创建和运行虚拟机

### 步骤 1：创建虚拟机配置

```swift
let manager = MacOSVirtualizationManager()

let ipswPath = URL(fileURLWithPath: "~/Downloads/macOS.ipsw")
let config = try await manager.createVirtualMachineConfiguration(
    ipswPath: ipswPath,
    diskSize: 64 * 1024 * 1024 * 1024 // 64 GB
)
```

### 步骤 2：启动虚拟机

```swift
try await manager.startVirtualMachine(configuration: config)

print("✅ 虚拟机已启动")
```

### 步骤 3：停止虚拟机

```swift
try await manager.stopVirtualMachine()
```

---

## 2.5 虚拟机配置详解

### CPU 配置

```swift
// 使用最多 CPU 核心（不超过最大支持数）
configuration.cpuCount = min(
    ProcessInfo.processInfo.processorCount,
    macOSConfiguration.maximumSupportedCPUCount
)
```

### 内存配置

```swift
// 分配 8GB 内存
let memorySize = 8 * 1024 * 1024 * 1024
configuration.memorySize = memorySize
```

### 显示配置

```swift
// 1920x1080 分辨率
let graphicsDevice = VZMacGraphicsDeviceConfiguration()
graphicsDevice.displays = [
    VZMacGraphicsDisplayConfiguration(
        widthInPixels: 1920,
        heightInPixels: 1080,
        pixelsPerInch: 80
    )
]
```

### 网络配置

```swift
// NAT 网络（共享主机网络）
let networkDevice = VZVirtioNetworkDeviceConfiguration()
networkDevice.attachment = VZNATNetworkDeviceAttachment()
```

---

## 2.6 常见问题

### Q1: 虚拟机启动失败？

**检查**:
- macOS 版本是否支持（需要 12.0+）
- 内存是否足够（至少 8GB）
- 镜像是否完整

### Q2: 性能较慢？

**优化**:
- 增加 CPU 核心数
- 增加内存分配
- 使用 SSD 存储磁盘镜像

### Q3: 无法连接网络？

**解决**:
- 检查网络配置
- 使用 NAT 模式
- 确保主机网络正常

---

# 第三部分：硬件连接管理

## 3.1 蓝牙连接（CoreBluetooth）

### 3.1.1 配置蓝牙权限

**Info.plist 添加**:
```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>需要蓝牙权限以连接外部设备</string>

<key>NSBluetoothPeripheralUsageDescription</key>
<string>需要蓝牙权限以连接外围设备</string>
```

### 3.1.2 扫描蓝牙设备

```swift
let manager = BluetoothManager()

// 扫描所有设备
manager.startScanning()

// 扫描特定服务的设备
let serviceUUIDs = [CBUUID(string: "180A")] // 设备信息服务
manager.startScanning(serviceUUIDs: serviceUUIDs)

// 30 秒后自动停止
```

### 3.1.3 连接设备

```swift
// 从发现的设备中选择
let devices = manager.discoveredDevices
let device = devices.first!

// 连接
manager.connect(to: device)

// 等待连接成功
// manager.connectionStatus == .connected
```

### 3.1.4 发送和接收数据

```swift
// 发送数据
manager.sendData("Hello Bluetooth")

// 接收数据（自动通过通知特性）
print("收到数据: \(manager.receivedData)")
```

### 3.1.5 在快捷指令中使用

**示例：扫描并连接蓝牙设备**
```
1. [扫描蓝牙设备] AutomationHelper
   扫描时长: 10 秒

2. [从列表中选择]
   提示: "选择要连接的设备"
   列表: [发现的设备]

3. [连接蓝牙设备] AutomationHelper
   设备名称: [步骤2的设备名]

4. [显示通知]
   标题: "✅ 已连接"
   正文: [设备名称]
```

---

## 3.2 WiFi 连接管理

### 3.2.1 获取 WiFi 信息

```swift
let manager = NetworkConnectionManager()

// 获取当前 WiFi 信息
if let wifiInfo = await manager.getCurrentWiFiInfo() {
    print("SSID: \(wifiInfo.ssid)")
    print("信号强度: \(wifiInfo.signalQuality)")
    print("是否安全: \(wifiInfo.isSecure)")
}
```

### 3.2.2 连接到 WiFi

```swift
// 连接到指定网络（需要知道 SSID 和密码）
try await manager.connectToWiFi(
    ssid: "MyWiFi",
    password: "password123"
)
```

### 3.2.3 监控网络状态

```swift
// 开始监控
manager.startMonitoring()

// 网络状态会自动更新
// manager.networkStatus
// manager.connectionType (WiFi/蜂窝数据/以太网)
```

### 3.2.4 在快捷指令中使用

```
1. [获取 WiFi 信息] AutomationHelper

2. [显示结果]
   文本: [WiFi 信息]
```

---

## 3.3 USB 设备检测

### 3.3.1 配置外部配件支持

**Info.plist 添加**:
```xml
<key>UISupportedExternalAccessoryProtocols</key>
<array>
    <string>com.example.protocol</string>
</array>
```

### 3.3.2 检测已连接设备

```swift
let manager = USBConnectionManager()

// 刷新设备列表
manager.refreshAccessoryList()

// 查看已连接设备
for accessory in manager.connectedAccessories {
    print("设备: \(accessory.name)")
    print("制造商: \(accessory.manufacturer)")
    print("型号: \(accessory.modelNumber)")
}
```

### 3.3.3 监控连接变化

```swift
// 开始监控
manager.startMonitoring()

// 设备连接/断开时自动更新
// manager.connectedAccessories
```

### 3.3.4 在快捷指令中使用

```
1. [检测 USB 设备] AutomationHelper

2. [显示结果]
   文本: [已连接设备列表]
```

---

# 第四部分：网络功能集成

## 4.1 网络状态检测

### 实时监控

```swift
let manager = NetworkConnectionManager()

// 检查是否连接
let isConnected = manager.checkConnectivity()

// 获取详细信息
let details = manager.getNetworkDetails()
print(details)
```

### 网络类型判断

```swift
switch manager.connectionType {
case .wifi:
    print("连接到 WiFi")
case .cellular:
    print("使用蜂窝数据")
case .ethernet:
    print("使用以太网")
case .unknown:
    print("未知连接类型")
}
```

---

## 4.2 网络搜索集成

### 搜索 macOS 镜像

参考资源：
- [Apple Virtualization Framework](https://developer.apple.com/documentation/virtualization)
- [Tart Virtualization](https://tart.run/) - macOS VM 管理工具
- [UTM for Mac](https://mac.getutm.app/) - 虚拟机应用

### IPSW 镜像下载地址

**macOS Sonoma 14.6.1**:
```
https://updates.cdn-apple.com/2024SummerFCS/fullrestores/062-52859/932E0A8F-6644-4759-82DA-F8FA8DEA806A/UniversalMac_14.6.1_23G93_Restore.ipsw
```

**macOS Ventura 13.6**:
```
https://updates.cdn-apple.com/2023FallFCS/fullrestores/042-88743/7FC45A40-79F9-4195-B5AE-5FCFBCE8B8EB/UniversalMac_13.6_22G120_Restore.ipsw
```

---

# 第五部分：实战应用

## 5.1 场景 1：跨设备笔记同步

### 需求

在 iPhone 上记录笔记，自动同步到 iPad 和 Mac。

### 实现

**快捷指令配置**:
```
1. [询问输入] "输入笔记内容"
   → noteContent

2. [获取当前日期]
   → currentDate

3. [格式化日期] "yyyy-MM-dd HHmmss"
   → timestamp

4. [文本] "note-\(timestamp).md"
   → filename

5. [保存到 iCloud] AutomationHelper
   文件名: filename
   内容: "# 笔记\n\n\(noteContent)"

6. [显示通知] "笔记已同步到所有设备"
```

---

## 5.2 场景 2：自动化开发环境

### 需求

在 macOS 虚拟机中运行测试环境，与主系统隔离。

### 实现

1. **下载 macOS 镜像**
2. **创建虚拟机**
3. **在虚拟机中安装开发工具**
4. **测试完成后，快照保存状态**

---

## 5.3 场景 3：智能设备控制

### 需求

通过蓝牙连接智能家居设备，实现自动化控制。

### 实现

**快捷指令配置**:
```
1. [扫描蓝牙设备] AutomationHelper

2. [连接蓝牙设备] "智能灯泡"

3. [发送蓝牙命令] "turn_on"

4. [显示通知] "灯已打开"
```

---

## 📚 参考资源

### 官方文档

- [CoreBluetooth](https://developer.apple.com/documentation/corebluetooth) - 蓝牙开发
- [NetworkExtension](https://developer.apple.com/documentation/networkextension) - 网络功能
- [Virtualization Framework](https://developer.apple.com/documentation/virtualization) - 虚拟化

### 第三方工具

- [Tart](https://tart.run/) - macOS VM 管理
- [UTM](https://mac.getutm.app/) - 虚拟机应用
- [LANScanner](https://github.com/uxmstudio/LANScanner) - 网络扫描

### 社区资源

- [Apple Developer Forums - Network Extension](https://forums.developer.apple.com/forums/tags/networkextension)
- [CoreBluetooth 教程](https://medium.com/macoclock/core-bluetooth-ble-swift-d2e7b84ea98e)

---

## ✅ 总结

本指南涵盖了：

1. ✅ **iCloud 同步** - 跨设备文档同步
2. ✅ **macOS 虚拟化** - 运行虚拟 macOS 系统
3. ✅ **蓝牙连接** - 兼容任何 BLE 设备
4. ✅ **WiFi 管理** - 网络连接和检测
5. ✅ **USB 检测** - 外部设备管理

**下一步**:
- 尝试实战场景
- 根据需求定制功能
- 分享你的自动化方案

---

**最后更新**: 2026-01-17
**版本**: 2.0
