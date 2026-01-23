# 🚀 立即使用指南

## ⚡ 3 种使用方式

---

## 方法 1: Claude iOS App（最简单）⭐⭐⭐⭐⭐

### 5 分钟设置

#### 第 1 步：克隆仓库到本地

```bash
git clone https://github.com/krisliong1/ios-automation.git
cd ios-automation
git checkout claude/ios-automation-shortcuts-gsEpf
```

#### 第 2 步：在 Claude App 创建项目

1. 打开 Claude iOS App
2. 点击 "Projects" → "+"
3. 命名：`iOS 自动化 AI 管理器`

#### 第 3 步：添加文档

点击 "Add Knowledge"，从本地选择这 3 个文件：

```
✅ docs/AI-Manager-Quick-Start.md
✅ docs/AI-Manager-Integration-Guide.md
✅ .claude-project/instructions.md
```

#### 第 4 步：开始使用

在项目对话中输入：

```
检查 AI 状态
```

看到状态信息 = 🎉 成功！

### 日常使用

```
帮我解决：Xcode 编译失败
搜索：iOS 17 新特性
切换到快速模式
```

**详细指南**: `QUICK_START_GUIDE.md`

---

## 方法 2: 集成到 Xcode 项目 ⭐⭐⭐⭐

### 步骤 1：克隆仓库

```bash
git clone https://github.com/krisliong1/ios-automation.git
cd ios-automation
git checkout claude/ios-automation-shortcuts-gsEpf
```

### 步骤 2：复制源文件到你的项目

```bash
# 复制核心文件
cp Sources/iOSAutomation/*.swift YourProject/

# 或者只复制需要的模块
cp Sources/iOSAutomation/AIManager.swift YourProject/
cp Sources/iOSAutomation/SecurityManager.swift YourProject/
cp Sources/iOSAutomation/NetworkManager.swift YourProject/
cp Sources/iOSAutomation/TranslationManager.swift YourProject/
```

### 步骤 3：添加依赖

在你的项目 `Package.swift` 中添加：

```swift
dependencies: [
    // 安全检测
    .package(url: "https://github.com/securing/IOSSecuritySuite", from: "1.9.0"),

    // 网络检测
    .package(url: "https://github.com/ashleymills/Reachability.swift", from: "5.1.0"),
]
```

或在 Xcode 中：
1. File → Add Package Dependencies
2. 输入 URL 并添加

### 步骤 4：使用代码

```swift
import iOSAutomation

// AI 管理器
let manager = AIManager()
manager.startMainAI()
let result = try await manager.executeTask(description: "问题描述")

// 安全检测
let security = SecurityManager()
let status = await security.performSecurityCheck()

// 网络管理
let network = NetworkManager()
network.startMonitoring()

// 翻译
let translator = TranslationManager()
let translated = await translator.translateToChinese("Hello")
```

---

## 方法 3: 使用 Swift Package Manager ⭐⭐⭐

### 在 Package.swift 中添加

```swift
dependencies: [
    .package(
        url: "https://github.com/krisliong1/ios-automation",
        branch: "claude/ios-automation-shortcuts-gsEpf"
    )
]
```

### 在你的代码中导入

```swift
import iOSAutomation

let manager = AIManager()
// 使用功能...
```

---

## 🎯 推荐使用方式

### 如果你是：

#### iOS 开发初学者
→ **方法 1**（Claude App）
- 不需要编码
- 直接对话使用
- 5 分钟上手

#### 有经验的开发者
→ **方法 2**（复制源文件）
- 完全控制
- 可以修改
- 集成到现有项目

#### 使用 SPM 的项目
→ **方法 3**（Package Manager）
- 自动更新
- 依赖管理
- 最佳实践

---

## 💡 快速示例

### Claude App 使用

```
你：帮我解决 Xcode 虚拟机检测问题

AI：🔍 分析问题...
    检测到：虚拟机检测

    搜索解决方案...
    找到 3 个方案

    【最佳】使用 VMHide 内核扩展
    1. 重启 Mac 进入恢复模式
    2. 禁用 SIP
    3. 安装 VMHide
    [详细步骤...]
```

### 代码使用

```swift
// AI 管理器自动解决问题
let manager = AIManager()
manager.startMainAI()

let result = try await manager.executeTask(
    description: "Xcode 编译失败，错误代码 65"
)

if result.success {
    print("✅ 解决方案：\(result.solution.title)")
    for step in result.solution.steps {
        print("- \(step)")
    }
}
```

---

## 📚 重要文档位置

### 快速开始
- **5 分钟上手**: `QUICK_START_GUIDE.md`
- **Release 说明**: `RELEASE_NOTES.md`

### 使用指南
- **AI 管理器**: `docs/AI-Manager-Quick-Start.md`
- **Claude App**: `CLAUDE_APP_PROJECT_SETUP.md`
- **完整文档**: `docs/AI-Manager-Integration-Guide.md`

### 代码示例
- **配置示例**: `examples/AIFixer/ClaudeCodeRouterConfig.json`
- **项目说明**: `.claude-project/instructions.md`

---

## 🔧 依赖安装（如果使用完整功能）

### 安装 claude-code-router

```bash
# 使用 npm
npm install -g claude-code-router

# 配置 API Key
mkdir -p ~/.ccr
echo "ANTHROPIC_API_KEY=your_key_here" > ~/.ccr/.env

# 启动服务
ccr start --daemon
```

### 验证安装

```bash
ccr status
# 应该显示：Running
```

---

## 🐛 常见问题

### Q: 克隆后找不到文件？

A: 确保切换到正确的分支：
```bash
git checkout claude/ios-automation-shortcuts-gsEpf
```

### Q: 依赖安装失败？

A: 使用 CocoaPods 或手动添加：
```bash
pod 'IOSSecuritySuite'
pod 'ReachabilitySwift'
```

### Q: Claude App 找不到文档？

A: 确保：
1. 文件路径正确
2. 文档格式为 .md
3. 文件可读

---

## 📞 需要帮助？

### 在 Claude App 中
```
这个项目怎么用？
给我一些示例
如何集成到我的项目？
```

### GitHub Issues
https://github.com/krisliong1/ios-automation/issues

---

## 🎉 立即开始

### 最快方式（1 分钟）

```bash
# 1. 克隆
git clone https://github.com/krisliong1/ios-automation.git
cd ios-automation
git checkout claude/ios-automation-shortcuts-gsEpf

# 2. 查看快速指南
cat QUICK_START_GUIDE.md

# 3. 开始使用！
```

### 推荐顺序

1. ✅ 先看 `QUICK_START_GUIDE.md`（5 分钟）
2. ✅ 按照方法 1 在 Claude App 试用
3. ✅ 如果满意，集成到项目（方法 2 或 3）

---

**版本**: v1.0.0
**更新**: 2026-01-19
**作者**: Claude AI

**开始使用吧！** 🚀
