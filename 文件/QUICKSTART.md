# 快速开始指南

本指南将帮助你在 **15 分钟内** 创建第一个集成快捷指令的 iOS App。

## 📋 准备工作

### 必需条件

- ✅ Mac（macOS 14.0+）
- ✅ Xcode 15.0+
- ✅ iPhone/iPad（iOS 17.0+，用于测试）
- ✅ Apple ID（免费账号即可）

### 检查环境

```bash
# 检查 Xcode 版本
xcodebuild -version

# 应该显示：
# Xcode 15.x
# Build version xxx
```

---

## 🚀 步骤 1：创建 Xcode 项目（3 分钟）

### 1.1 打开 Xcode

```bash
open -a Xcode
```

### 1.2 创建新项目

1. 点击 **"Create New Project"**
2. 选择 **iOS** → **App**
3. 点击 **Next**

### 1.3 配置项目信息

```
Product Name:      AutomationHelper
Team:             [选择你的 Apple ID]
Organization ID:   com.yourname
Bundle Identifier: com.yourname.AutomationHelper
Interface:        SwiftUI
Language:         Swift
Storage:          SwiftData
Include Tests:    ✓ 勾选
```

### 1.4 保存项目

```
位置: ~/Developer/iOS/AutomationHelper
✓ Create Git repository on my Mac
```

点击 **Create**。

---

## 📦 步骤 2：添加示例代码（5 分钟）

### 2.1 复制数据模型

在 Xcode 中：

1. **File** → **New** → **File**
2. 选择 **Swift File**
3. 命名为 `Task.swift`
4. 复制以下代码：

```bash
# 在终端中复制文件
cp examples/Models/Task.swift ~/Developer/iOS/AutomationHelper/AutomationHelper/
```

或者手动复制 `examples/Models/Task.swift` 的内容。

### 2.2 添加 App Intents

创建以下文件并复制内容：

**AddTaskIntent.swift**
```bash
cp examples/AppIntents/AddTaskIntent.swift ~/Developer/iOS/AutomationHelper/AutomationHelper/
```

**GetTasksIntent.swift**
```bash
cp examples/AppIntents/GetTasksIntent.swift ~/Developer/iOS/AutomationHelper/AutomationHelper/
```

**GetTodayTasksIntent.swift**
```bash
cp examples/AppIntents/GetTodayTasksIntent.swift ~/Developer/iOS/AutomationHelper/AutomationHelper/
```

**TaskStatsIntent.swift**
```bash
cp examples/AppIntents/TaskStatsIntent.swift ~/Developer/iOS/AutomationHelper/AutomationHelper/
```

**CompleteTaskIntent.swift**
```bash
cp examples/AppIntents/CompleteTaskIntent.swift ~/Developer/iOS/AutomationHelper/AutomationHelper/
```

### 2.3 更新 App 入口

用以下内容替换 `AutomationHelperApp.swift`：

```bash
cp examples/AppEntryPoint/AutomationHelperApp.swift ~/Developer/iOS/AutomationHelper/AutomationHelper/AutomationHelperApp.swift
```

### 2.4 配置 Info.plist（可选 - 用于 URL Scheme）

复制配置：

```bash
cp examples/XcodeProject/Info.plist ~/Developer/iOS/AutomationHelper/AutomationHelper/
```

或在 Xcode 中手动配置：

1. 选择项目 → Target → **Info**
2. 展开 **URL Types**
3. 点击 **+** 添加：
   - Identifier: `com.yourname.automationhelper`
   - URL Schemes: `automationhelper`

### 2.5 添加 URL Handler（可选）

```bash
cp examples/URLHandler/URLHandler.swift ~/Developer/iOS/AutomationHelper/AutomationHelper/
```

---

## ▶️ 步骤 3：运行项目（2 分钟）

### 3.1 选择模拟器

在 Xcode 顶部工具栏：

```
AutomationHelper > iPhone 15 Pro
```

### 3.2 运行

点击 **▶️ 运行按钮** 或按 **⌘ + R**

等待编译完成（首次可能需要 1-2 分钟）。

### 3.3 验证运行

App 应该成功启动，显示任务管理界面。

---

## 🎯 步骤 4：在快捷指令中使用（5 分钟）

### 4.1 打开快捷指令 App

在 iPhone/模拟器上打开 **快捷指令** App。

### 4.2 创建新快捷指令

1. 点击右上角 **+**
2. 点击 **"添加操作"**
3. 搜索 **"AutomationHelper"** 或 **"自动化助手"**

### 4.3 配置第一个快捷指令

选择 **"添加任务"** 动作：

```
任务标题: "测试任务"
优先级: 普通
截止日期: 今天 18:00
```

点击 **▶️ 运行**。

### 4.4 验证结果

1. 应该看到通知："已添加任务「测试任务」"
2. 返回 AutomationHelper App
3. 应该看到新添加的任务

---

## ✅ 成功！下一步做什么？

### 尝试更多 Intent

创建快捷指令使用以下动作：

1. **获取今日任务** - 查看今天到期的任务
2. **任务统计** - 查看任务完成情况
3. **完成任务** - 标记任务为已完成
4. **获取任务列表** - 查看所有任务

### 创建自动化

1. 打开快捷指令 App
2. 选择 **"自动化"** 标签
3. 创建 **"时间"** 触发器
4. 设置为每天早上 8:00
5. 添加 **"获取今日任务"** 动作
6. 添加 **"朗读文本"** 动作
7. 启用自动化

现在每天早上 8 点，系统会自动播报今日任务！

### 尝试 URL Scheme

在快捷指令中创建：

```
1. [文本] "买菜"

2. [URL 编码] [上一步]

3. [文本] automationhelper://addTask?title=[已编码文本]&priority=普通

4. [打开 URL] [上一步]
```

运行后会通过 URL 方式添加任务。

---

## 🐛 遇到问题？

### App 无法编译

**错误：** "Cannot find type 'Task' in scope"

**解决：** 确保已添加 `Task.swift` 文件到项目中。

### Intent 不显示在快捷指令中

**解决方法：**

1. 确保 App 至少运行过一次
2. 重启快捷指令 App
3. 在 iPhone 设置中检查 Siri 权限

### URL Scheme 不工作

**检查：**

1. Info.plist 中是否配置了 URL Scheme
2. URLHandler 是否正确集成
3. 查看 Xcode 控制台的日志输出

---

## 📚 进一步学习

1. **阅读完整指南**
   - [iOS 自动化完整指南](docs/iOS-Automation-Complete-Guide.md)

2. **查看更多示例**
   - [快捷指令配置示例](examples/Shortcuts/shortcuts-examples.md)

3. **研究实战案例**
   - 完整指南中的 5 个实战场景

4. **探索高级功能**
   - SwiftData 数据持久化
   - HealthKit 集成
   - 后台任务处理

---

## 💡 常用命令

### 清理构建

```bash
# 在 Xcode 中
Product → Clean Build Folder (⇧⌘K)
```

### 重置模拟器

```bash
# 在终端中
xcrun simctl erase all
```

### 查看日志

```bash
# 在 Xcode 中
View → Debug Area → Activate Console (⇧⌘C)
```

---

## 🎉 恭喜！

你已经成功创建了第一个集成快捷指令的 iOS App！

接下来可以：

- ✅ 添加更多自定义 Intent
- ✅ 创建复杂的自动化工作流
- ✅ 集成第三方 API
- ✅ 发布到 App Store

**祝你开发愉快！** 🚀

---

**遇到问题？** 查看 [故障排查指南](TROUBLESHOOTING.md)

**想要更多示例？** 查看 [examples/](examples/) 目录
