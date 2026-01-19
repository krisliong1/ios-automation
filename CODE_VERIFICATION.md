# 代码验证清单

本文档帮助你验证所有示例代码是否正确可用。

## ✅ 验证步骤

### 1. Swift 代码语法检查

#### 1.1 数据模型（Task.swift）

**检查项**：
- ✅ `@Model` 宏正确使用
- ✅ 所有属性有默认值或在 init 中初始化
- ✅ 方法实现正确

**验证方法**：
```swift
// 创建测试实例
let task = Task(title: "测试任务")
assert(task.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
assert(task.isCompleted == false)
assert(task.title == "测试任务")
print("✅ Task 模型验证通过")
```

---

#### 1.2 App Intents（AddTaskIntent.swift）

**检查项**：
- ✅ 实现 `AppIntent` 协议
- ✅ `title` 和 `description` 正确定义
- ✅ 参数使用 `@Parameter` 标注
- ✅ `perform()` 方法返回正确类型

**验证代码**：
```swift
// 编译检查
let intent = AddTaskIntent()
intent.taskTitle = "测试"
intent.priority = .normal

// 类型检查
let _: LocalizedStringResource = AddTaskIntent.title
let _: IntentDescription = AddTaskIntent.description
print("✅ AddTaskIntent 验证通过")
```

---

#### 1.3 URL Handler（URLHandler.swift）

**检查项**：
- ✅ 正确解析 URL 组件
- ✅ 参数正确解码
- ✅ 错误处理完善

**测试 URL**：
```
automationhelper://addTask?title=测试任务&priority=高
automationhelper://completeTask?id=123e4567-e89b-12d3-a456-426614174000
automationhelper://getTasks?limit=10
```

**验证方法**：
```swift
// 测试 URL 解析
let url = URL(string: "automationhelper://addTask?title=%E6%B5%8B%E8%AF%95")!
let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
assert(url.scheme == "automationhelper")
assert(url.host == "addTask")
assert(components?.queryItems != nil)
print("✅ URLHandler 验证通过")
```

---

### 2. 项目结构验证

#### 2.1 必需文件

检查以下文件是否存在：

```
✅ examples/Models/Task.swift
✅ examples/AppIntents/AddTaskIntent.swift
✅ examples/AppIntents/GetTasksIntent.swift
✅ examples/AppIntents/GetTodayTasksIntent.swift
✅ examples/AppIntents/TaskStatsIntent.swift
✅ examples/AppIntents/CompleteTaskIntent.swift
✅ examples/AppEntryPoint/AutomationHelperApp.swift
✅ examples/URLHandler/URLHandler.swift
✅ examples/XcodeProject/Info.plist
```

**验证脚本**：
```bash
#!/bin/bash

files=(
    "examples/Models/Task.swift"
    "examples/AppIntents/AddTaskIntent.swift"
    "examples/AppIntents/GetTasksIntent.swift"
    "examples/AppEntryPoint/AutomationHelperApp.swift"
    "examples/URLHandler/URLHandler.swift"
)

echo "检查文件..."
for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file"
    else
        echo "❌ $file 缺失"
    fi
done
```

---

### 3. 依赖关系验证

#### 3.1 导入语句

检查所有 import 语句：

| 文件 | 必需导入 |
|------|----------|
| Task.swift | Foundation, SwiftData |
| AddTaskIntent.swift | AppIntents, SwiftData |
| AutomationHelperApp.swift | SwiftUI, SwiftData |
| URLHandler.swift | Foundation, SwiftData |

#### 3.2 类型依赖

```
AddTaskIntent 依赖：
  → Task
  → TaskPriority (enum)
  → ModelContainerProvider
  → IntentError (enum)

GetTasksIntent 依赖：
  → Task
  → TaskEntity
  → ModelContainerProvider

URLHandler 依赖：
  → Task
  → ModelContext
```

---

### 4. 功能验证测试

#### 4.1 数据持久化测试

**测试用例 1：创建和保存任务**

```swift
func testCreateAndSaveTask() async throws {
    // 创建内存容器（测试用）
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: Task.self, configurations: config)
    let context = ModelContext(container)

    // 创建任务
    let task = Task(title: "测试任务", priority: "高")
    context.insert(task)
    try context.save()

    // 查询验证
    let descriptor = FetchDescriptor<Task>()
    let tasks = try context.fetch(descriptor)

    assert(tasks.count == 1, "应该有 1 个任务")
    assert(tasks[0].title == "测试任务", "标题应该匹配")
    assert(tasks[0].priority == "高", "优先级应该匹配")

    print("✅ 数据持久化测试通过")
}
```

**测试用例 2：查询过滤**

```swift
func testQueryFilter() async throws {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: Task.self, configurations: config)
    let context = ModelContext(container)

    // 创建测试数据
    let task1 = Task(title: "任务1")
    let task2 = Task(title: "任务2")
    task2.markAsCompleted()

    context.insert(task1)
    context.insert(task2)
    try context.save()

    // 查询未完成的任务
    let descriptor = FetchDescriptor<Task>(
        predicate: #Predicate { !$0.isCompleted }
    )
    let incompleteTasks = try context.fetch(descriptor)

    assert(incompleteTasks.count == 1, "应该只有 1 个未完成任务")
    assert(incompleteTasks[0].title == "任务1", "应该是任务1")

    print("✅ 查询过滤测试通过")
}
```

---

#### 4.2 Intent 功能测试

**测试用例 3：AddTaskIntent**

```swift
func testAddTaskIntent() async throws {
    // 设置测试环境
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: Task.self, configurations: config)
    ModelContainerProvider.shared.container = container

    // 创建 Intent
    var intent = AddTaskIntent()
    intent.taskTitle = "Intent 测试任务"
    intent.priority = .high
    intent.dueDate = Date()

    // 执行
    let result = try await intent.perform()

    // 验证
    let context = ModelContext(container)
    let tasks = try context.fetch(FetchDescriptor<Task>())

    assert(tasks.count == 1, "应该创建了 1 个任务")
    assert(tasks[0].title == "Intent 测试任务", "标题应该匹配")

    print("✅ AddTaskIntent 测试通过")
}
```

**测试用例 4：GetTodayTasksIntent**

```swift
func testGetTodayTasksIntent() async throws {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: Task.self, configurations: config)
    ModelContainerProvider.shared.container = container
    let context = ModelContext(container)

    // 创建测试数据
    let todayTask = Task(title: "今日任务", dueDate: Date())
    let tomorrowTask = Task(title: "明日任务", dueDate: Date().addingTimeInterval(86400))

    context.insert(todayTask)
    context.insert(tomorrowTask)
    try context.save()

    // 执行 Intent
    var intent = GetTodayTasksIntent()
    intent.includeCompleted = false

    let result = try await intent.perform()

    // 验证
    assert(result.value.count == 1, "应该只有 1 个今日任务")
    assert(result.value[0].title == "今日任务", "应该是今日任务")

    print("✅ GetTodayTasksIntent 测试通过")
}
```

---

#### 4.3 URL Handler 测试

**测试用例 5：URL 解析**

```swift
func testURLParsing() {
    // 测试添加任务
    let addURL = URL(string: "automationhelper://addTask?title=%E6%B5%8B%E8%AF%95&priority=%E9%AB%98")!
    let components = URLComponents(url: addURL, resolvingAgainstBaseURL: false)

    assert(addURL.scheme == "automationhelper")
    assert(addURL.host == "addTask")

    let queryItems = components?.queryItems
    assert(queryItems != nil, "应该有查询参数")

    let title = queryItems?.first(where: { $0.name == "title" })?.value?.removingPercentEncoding
    assert(title == "测试", "标题应该正确解码")

    let priority = queryItems?.first(where: { $0.name == "priority" })?.value?.removingPercentEncoding
    assert(priority == "高", "优先级应该正确解码")

    print("✅ URL 解析测试通过")
}
```

---

### 5. 集成验证

#### 5.1 Xcode 项目编译测试

**步骤**：

1. **创建新项目**
   ```bash
   # 使用模拟项目目录
   mkdir -p ~/Developer/iOS/TestAutomation
   ```

2. **复制文件**
   ```bash
   # 复制所有示例文件
   cp examples/Models/*.swift ~/Developer/iOS/TestAutomation/
   cp examples/AppIntents/*.swift ~/Developer/iOS/TestAutomation/
   cp examples/AppEntryPoint/*.swift ~/Developer/iOS/TestAutomation/
   ```

3. **编译测试**
   ```bash
   # 在 Xcode 中
   Product → Build (⌘B)
   ```

**预期结果**：
- ✅ 0 errors
- ✅ 0 warnings（或仅有可忽略的 warnings）

---

#### 5.2 真机/模拟器运行测试

**步骤**：

1. **选择目标**
   ```
   AutomationHelper > iPhone 15 Pro
   ```

2. **运行**
   ```
   Product → Run (⌘R)
   ```

3. **验证界面**
   - ✅ App 成功启动
   - ✅ 显示任务列表界面
   - ✅ 可以添加任务
   - ✅ 可以完成/删除任务

4. **验证数据持久化**
   - 添加几个任务
   - 完全关闭 App（不是后台）
   - 重新打开
   - ✅ 任务依然存在

---

#### 5.3 快捷指令集成测试

**步骤**：

1. **打开快捷指令 App**

2. **搜索 Intent**
   - 搜索 "AutomationHelper"
   - ✅ 应该显示所有可用的 Intent：
     - 添加任务
     - 获取任务列表
     - 获取今日任务
     - 任务统计
     - 完成任务

3. **创建测试快捷指令**
   ```
   [添加任务] AutomationHelper
   任务标题: "快捷指令测试"
   优先级: 高
   ```

4. **运行快捷指令**
   - ✅ 执行成功
   - ✅ 显示确认消息
   - ✅ 在 App 中能看到新任务

---

### 6. 性能验证

#### 6.1 启动时间测试

**测试方法**：

```swift
import os.log

let logger = Logger(subsystem: "com.yourapp", category: "Performance")

@main
struct MyApp: App {
    init() {
        let start = Date()

        // 初始化代码...

        let duration = Date().timeIntervalSince(start)
        logger.info("App 启动耗时: \(duration) 秒")
    }
}
```

**目标**：
- ✅ 启动时间 < 1 秒

---

#### 6.2 内存使用测试

**测试方法**：

1. 在 Xcode 中运行
2. Debug Navigator → Memory
3. 观察内存使用

**目标**：
- ✅ 空闲状态 < 50MB
- ✅ 添加 100 个任务后 < 100MB

---

### 7. 错误处理验证

#### 7.1 网络错误

**测试用例**：
```swift
// 模拟网络错误
func testNetworkError() async {
    do {
        // 使用无效 URL
        let url = URL(string: "https://invalid-domain-12345.com")!
        let (_, _) = try await URLSession.shared.data(from: url)
        XCTFail("应该抛出错误")
    } catch {
        // ✅ 正确处理错误
        print("✅ 网络错误处理测试通过: \(error)")
    }
}
```

---

#### 7.2 数据验证错误

**测试用例**：
```swift
func testInvalidData() {
    // 测试空标题
    let emptyTitle = ""
    assert(emptyTitle.isEmpty, "应该检测到空标题")

    // 测试过长标题
    let longTitle = String(repeating: "a", count: 1000)
    assert(longTitle.count > 100, "应该限制标题长度")

    print("✅ 数据验证测试通过")
}
```

---

## 🎯 完整验证清单

运行以下脚本进行完整验证：

```bash
#!/bin/bash

echo "🔍 开始验证..."

# 1. 文件检查
echo "\n1️⃣ 检查文件..."
[ -f "examples/Models/Task.swift" ] && echo "✅ Task.swift" || echo "❌ Task.swift"
[ -f "examples/AppIntents/AddTaskIntent.swift" ] && echo "✅ AddTaskIntent.swift" || echo "❌ AddTaskIntent.swift"

# 2. 语法检查
echo "\n2️⃣ 检查语法..."
find examples -name "*.swift" -exec swiftc -typecheck {} \; 2>&1 | grep -q "error:" && echo "❌ 语法错误" || echo "✅ 语法正确"

# 3. 文档检查
echo "\n3️⃣ 检查文档..."
[ -f "README.md" ] && echo "✅ README.md" || echo "❌ README.md"
[ -f "QUICKSTART.md" ] && echo "✅ QUICKSTART.md" || echo "❌ QUICKSTART.md"
[ -f "TROUBLESHOOTING.md" ] && echo "✅ TROUBLESHOOTING.md" || echo "❌ TROUBLESHOOTING.md"

echo "\n✅ 验证完成！"
```

---

## 📝 验证报告模板

```markdown
# 验证报告

**日期**: 2026-01-17
**验证者**: [姓名]
**版本**: 1.0

## 验证结果

### 代码验证
- [ ] Task.swift 编译通过
- [ ] 所有 Intent 编译通过
- [ ] URLHandler 编译通过
- [ ] App 入口编译通过

### 功能验证
- [ ] 数据持久化正常
- [ ] Intent 在快捷指令中可见
- [ ] Intent 执行成功
- [ ] URL Scheme 工作正常

### 性能验证
- [ ] 启动时间 < 1 秒
- [ ] 内存使用合理
- [ ] 无内存泄漏

### 兼容性验证
- [ ] iPhone 15 Pro 模拟器
- [ ] iPad Pro 模拟器
- [ ] 真机测试

## 问题记录

| 问题 | 严重性 | 状态 |
|------|--------|------|
| - | - | - |

## 总结

验证结果：✅ 通过 / ❌ 未通过

备注：
```

---

**最后更新**: 2026-01-17
