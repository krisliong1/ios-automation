# 故障排查指南

本指南帮助你解决 iOS 自动化开发中的常见问题。

## 📑 目录

- [Xcode 项目问题](#xcode-项目问题)
- [App Intents 问题](#app-intents-问题)
- [URL Scheme 问题](#url-scheme-问题)
- [快捷指令问题](#快捷指令问题)
- [数据持久化问题](#数据持久化问题)
- [权限问题](#权限问题)
- [性能问题](#性能问题)

---

## Xcode 项目问题

### ❌ 编译错误：Cannot find type 'Task'

**症状**：
```
Cannot find type 'Task' in scope
```

**原因**：
- 未添加 `Task.swift` 文件
- 文件未加入到 Target

**解决方案**：

1. **检查文件是否存在**
   ```
   项目导航器中查找 Task.swift
   ```

2. **确保文件加入 Target**
   - 选择 `Task.swift`
   - 右侧面板 → Target Membership
   - ✓ 勾选你的 App Target

3. **重新添加文件**
   ```
   File → Add Files to "ProjectName"
   选择 Task.swift
   ✓ Copy items if needed
   ✓ Add to targets: [你的 Target]
   ```

---

### ❌ 编译错误：Module 'AppIntents' not found

**症状**：
```
Module 'AppIntents' not found
```

**原因**：
- 项目部署目标低于 iOS 16.0
- 未正确导入框架

**解决方案**：

1. **检查部署目标**
   - 选择项目 → Target → General
   - Minimum Deployments: **iOS 17.0** 或更高

2. **确保导入语句正确**
   ```swift
   import AppIntents  // ✅ 正确
   import AppIntent   // ❌ 错误
   ```

---

### ❌ 运行失败：Code Signing Error

**症状**：
```
Code signing is required for product type 'Application'
```

**原因**：
- 未选择开发团队
- 证书过期或无效

**解决方案**：

1. **配置签名**
   - 项目 → Target → Signing & Capabilities
   - Team: 选择你的 Apple ID
   - ✓ Automatically manage signing

2. **重新登录 Apple ID**
   ```
   Xcode → Settings → Accounts
   点击 Apple ID → Sign Out
   重新 Sign In
   ```

3. **清理证书缓存**
   ```bash
   # 在终端中
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```

---

## App Intents 问题

### ❌ Intent 不显示在快捷指令中

**症状**：
在快捷指令 App 中搜索不到你的 Intent

**原因**：
- App 未运行过
- Intent 未正确实现
- 系统索引未更新

**解决方案**：

1. **运行 App**
   ```
   在真机或模拟器上至少运行一次
   ```

2. **重启快捷指令 App**
   ```
   双击 Home 键 → 关闭快捷指令
   重新打开
   ```

3. **检查 Intent 实现**
   ```swift
   struct MyIntent: AppIntent {  // ✅ 必须实现 AppIntent
       static var title: LocalizedStringResource = "标题"  // ✅ 必需
       static var description = IntentDescription("描述")  // ✅ 必需

       func perform() async throws -> some IntentResult {  // ✅ 必需
           return .result()
       }
   }
   ```

4. **重建系统索引**
   ```
   删除 App
   重新安装
   运行一次
   ```

---

### ❌ Intent 执行失败：Container not available

**症状**：
```
IntentError.containerNotAvailable
```

**原因**：
- ModelContainer 未正确初始化
- ModelContainerProvider 未设置

**解决方案**：

1. **检查 App 入口**
   ```swift
   @main
   struct MyApp: App {
       var sharedModelContainer: ModelContainer = {
           // ...创建 container
           let container = try ModelContainer(...)

           // ✅ 关键：设置到全局提供者
           ModelContainerProvider.shared.container = container

           return container
       }()
   }
   ```

2. **在 Intent 中检查**
   ```swift
   func perform() async throws -> some IntentResult {
       guard let container = ModelContainerProvider.shared.container else {
           throw IntentError.containerNotAvailable
       }
       // ...
   }
   ```

---

### ❌ 参数不显示或无法编辑

**症状**：
快捷指令中 Intent 的参数显示异常

**原因**：
- 参数类型不支持
- 缺少必要的协议实现

**解决方案**：

1. **使用支持的参数类型**
   ```swift
   // ✅ 支持的基础类型
   @Parameter(title: "文本") var text: String
   @Parameter(title: "数字") var number: Int
   @Parameter(title: "日期") var date: Date
   @Parameter(title: "开关") var toggle: Bool

   // ✅ 支持的枚举（需要实现 AppEnum）
   @Parameter(title: "优先级") var priority: TaskPriority

   // ✅ 支持的实体（需要实现 AppEntity）
   @Parameter(title: "任务") var task: TaskEntity
   ```

2. **正确实现 AppEnum**
   ```swift
   enum MyEnum: String, AppEnum {
       case option1 = "选项1"
       case option2 = "选项2"

       static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "类型名")

       static var caseDisplayRepresentations: [MyEnum: DisplayRepresentation] = [
           .option1: "选项1",
           .option2: "选项2"
       ]
   }
   ```

---

## URL Scheme 问题

### ❌ 打开 URL 无响应

**症状**：
使用 URL Scheme 打开 App 后没有任何反应

**原因**：
- URL Scheme 未注册
- onOpenURL 未实现
- URLHandler 未正确集成

**解决方案**：

1. **检查 Info.plist 配置**
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
       <dict>
           <key>CFBundleURLSchemes</key>
           <array>
               <string>automationhelper</string>  ✅ 你的 scheme
           </array>
       </dict>
   </array>
   ```

2. **实现 URL 处理**
   ```swift
   @main
   struct MyApp: App {
       var body: some Scene {
           WindowGroup {
               ContentView()
           }
           .onOpenURL { url in  // ✅ 必须实现
               print("收到 URL: \(url)")
               handleURL(url)
           }
       }
   }
   ```

3. **检查 URL 格式**
   ```
   ✅ 正确: automationhelper://addTask?title=测试
   ❌ 错误: automationhelper:/addTask?title=测试  (少一个 /)
   ❌ 错误: automation-helper://addTask  (scheme 不匹配)
   ```

4. **添加日志调试**
   ```swift
   func handle(_ url: URL) {
       print("📱 URL Scheme: \(url.scheme ?? "nil")")
       print("📱 URL Host: \(url.host ?? "nil")")
       print("📱 URL Query: \(url.query ?? "nil")")
       // ...
   }
   ```

---

### ❌ URL 参数乱码

**症状**：
中文参数显示为乱码或解析失败

**原因**：
- 未进行 URL 编码
- 编码方式不正确

**解决方案**：

1. **在快捷指令中使用 URL 编码**
   ```
   [文本] "中文任务"
   ↓
   [URL 编码] 文本
   ↓
   [文本] automationhelper://addTask?title=[已编码文本]
   ```

2. **在代码中正确解码**
   ```swift
   // ✅ 正确：使用 removingPercentEncoding
   let title = titleItem.value?.removingPercentEncoding ?? ""

   // ❌ 错误：直接使用 value
   let title = titleItem.value ?? ""  // 可能是编码后的字符串
   ```

---

## 快捷指令问题

### ❌ 自动化不触发

**症状**：
设置的自动化（如定时触发）不执行

**原因**：
- 自动化未启用
- 设置了"运行前询问"
- 系统后台刷新被禁用

**解决方案**：

1. **检查自动化设置**
   ```
   快捷指令 → 自动化 → 选择你的自动化
   ✓ 启用此自动化
   ✗ 运行前询问（取消勾选）
   ```

2. **启用后台刷新**
   ```
   设置 → 快捷指令 → 后台 App 刷新
   → 开启
   ```

3. **检查勿扰模式**
   ```
   定时自动化在勿扰模式下可能不触发
   设置 → 专注模式 → 勿扰模式
   → 允许来自快捷指令的通知
   ```

---

### ❌ 快捷指令运行卡住

**症状**：
快捷指令运行到某一步就不继续了

**原因**：
- 等待用户输入但未设置默认值
- API 请求超时
- 死循环

**解决方案**：

1. **检查"询问"动作**
   ```
   [询问输入]
   ✓ 设置默认答案
   ✓ 允许无响应（如果可选）
   ```

2. **添加超时处理**
   ```
   [获取 URL 内容]
   → 添加 [如果] 判断结果
   → 添加 [等待] 限制时间
   ```

3. **检查循环条件**
   ```
   [重复操作]
   → 确保有退出条件
   → 避免无限循环
   ```

---

## 数据持久化问题

### ❌ 数据保存后消失

**症状**：
添加的任务重启 App 后消失

**原因**：
- 使用了内存存储
- 未调用 save()
- ModelConfiguration 错误

**解决方案**：

1. **检查 ModelConfiguration**
   ```swift
   // ✅ 正确：持久化存储
   let config = ModelConfiguration(
       schema: schema,
       isStoredInMemoryOnly: false  // ✅ false
   )

   // ❌ 错误：仅内存存储
   let config = ModelConfiguration(
       schema: schema,
       isStoredInMemoryOnly: true  // ❌ 数据不会保存
   )
   ```

2. **确保调用 save()**
   ```swift
   context.insert(task)
   try context.save()  // ✅ 必须调用
   ```

3. **检查错误处理**
   ```swift
   do {
       try context.save()
   } catch {
       print("❌ 保存失败: \(error)")  // ✅ 捕获错误
   }
   ```

---

### ❌ 数据查询结果为空

**症状**：
明明有数据，但查询返回空数组

**原因**：
- Predicate 条件错误
- 使用了错误的 context
- 数据未刷新

**解决方案**：

1. **检查 Predicate**
   ```swift
   // ✅ 正确
   let descriptor = FetchDescriptor<Task>(
       predicate: #Predicate { !$0.isCompleted }
   )

   // ❌ 常见错误：逻辑反了
   predicate: #Predicate { $0.isCompleted }  // 查询已完成的
   ```

2. **使用相同的 context**
   ```swift
   // ✅ 正确：使用同一个 context
   context.insert(task)
   try context.save()
   let tasks = try context.fetch(descriptor)  // 使用同一个 context
   ```

3. **添加调试日志**
   ```swift
   let tasks = try context.fetch(descriptor)
   print("📊 查询到 \(tasks.count) 个任务")
   tasks.forEach { print("  - \($0.title)") }
   ```

---

## 权限问题

### ❌ 定位权限被拒绝

**症状**：
```
Location authorization denied
```

**解决方案**：

1. **检查 Info.plist**
   ```xml
   <key>NSLocationWhenInUseUsageDescription</key>
   <string>说明文字</string>
   ```

2. **请求权限**
   ```swift
   import CoreLocation

   let manager = CLLocationManager()
   manager.requestWhenInUseAuthorization()
   ```

3. **检查系统设置**
   ```
   设置 → 隐私与安全性 → 定位服务 → [你的 App]
   → 设置为"使用时"或"始终"
   ```

---

### ❌ 通知不显示

**症状**：
调用通知 API 但没有显示

**解决方案**：

1. **请求通知权限**
   ```swift
   import UserNotifications

   let center = UNUserNotificationCenter.current()
   try await center.requestAuthorization(options: [.alert, .sound, .badge])
   ```

2. **检查系统设置**
   ```
   设置 → 通知 → [你的 App]
   ✓ 允许通知
   ```

---

## 性能问题

### ❌ App 启动慢

**原因**：
- 数据库数据量大
- 初始化操作太多

**解决方案**：

1. **延迟加载**
   ```swift
   .task {  // ✅ 视图出现后再加载
       await loadData()
   }
   ```

2. **分页加载**
   ```swift
   descriptor.fetchLimit = 50  // ✅ 限制数量
   ```

---

### ❌ 滚动卡顿

**原因**：
- 列表项过于复杂
- 未使用 LazyVStack

**解决方案**：

1. **使用 LazyVStack**
   ```swift
   // ✅ 正确
   ScrollView {
       LazyVStack {
           ForEach(items) { item in
               ItemRow(item: item)
           }
       }
   }
   ```

2. **简化视图层次**
   ```swift
   // ✅ 使用简单的布局
   // ❌ 避免过多嵌套
   ```

---

## 🆘 仍然无法解决？

### 收集诊断信息

1. **查看控制台日志**
   ```
   Xcode → View → Debug Area → Activate Console (⇧⌘C)
   ```

2. **检查崩溃日志**
   ```
   Xcode → Window → Devices and Simulators
   → 选择设备 → View Device Logs
   ```

3. **创建最小复现示例**
   ```
   创建一个最简单的项目来复现问题
   ```

### 寻求帮助

- **Apple Developer Forums**: https://developer.apple.com/forums/
- **Stack Overflow**: 标签 `ios`, `swiftui`, `app-intents`
- **GitHub Issues**: 在项目仓库提交 Issue

---

## 📚 相关资源

- [快速开始指南](QUICKSTART.md)
- [完整开发指南](docs/iOS-Automation-Complete-Guide.md)
- [示例代码](examples/)

---

**最后更新**: 2026-01-17
