# iOS 自动化项目配置

> 这是项目的核心配置文件，包含所有重要信息和常用命令
> 用于快速恢复上下文，节省 token

## 📋 项目概览

**项目名称**: iOS 自动化开发平台
**仓库**: krisliong1/ios-automation
**当前分支**: claude/ios-automation-shortcuts-gsEpf
**主要开发者**: Kris

## 🎯 核心功能模块

### 1. Kris AI Fixer（智能问题解决）
- **位置**: `examples/AIFixer/`
- **文件**:
  - KrisAIFixer.swift (1000+ 行)
  - AITranslator.swift (500+ 行)
  - AIFixerIntegration.swift (300+ 行)
  - AIFixerLearning.swift (500+ 行)
- **功能**: 自动诊断、搜索、修复 iOS 问题
- **特性**: 实时翻译、自动触发、学习优化

### 2. AI 翻译系统
- **位置**: `examples/AIFixer/AITranslator.swift`
- **功能**: 任何语言→中文，保持代码可执行
- **API**: MyMemory、LibreTranslate
- **特性**: 智能术语保留、代码注释翻译

### 3. Shadowrocket 配置
- **位置**: `examples/NetworkTools/ShadowrocketManager.swift`
- **功能**: 自动检测设备并配置代理
- **支持**: SS/VMess/Trojan、订阅管理

### 4. 设备检测系统
- **位置**: `examples/SystemDetection/DeviceInfoManager.swift`
- **功能**: 识别 iPhone/iPad/Mac 型号和系统
- **支持**: 150+ 设备型号

### 5. 其他模块
- iCloud 同步: `examples/CloudSync/iCloudSyncManager.swift`
- 蓝牙管理: `examples/HardwareConnection/BluetoothManager.swift`
- 网络连接: `examples/HardwareConnection/NetworkConnectionManager.swift`
- VM 检测: `examples/SystemDetection/VMDetectionManager.swift`

## 🚀 快速命令

### Git 操作
```bash
# 检查状态
git status

# 提交更改
git add -A
git commit -m "描述"

# 推送到远程
git push -u origin claude/ios-automation-shortcuts-gsEpf

# 查看最近提交
git log --oneline -5
```

### 常用任务

#### 添加新功能
1. 创建文件
2. 编写代码
3. 创建文档（可选）
4. 提交并推送

#### 更新现有功能
1. 读取文件
2. 修改代码
3. 测试（可选）
4. 提交并推送

## 📝 待办事项

### 当前任务
- [ ] 待确认：用户提到的"必须执行的"功能

### 已完成
- [x] Kris AI Fixer（问题诊断和修复）
- [x] AI 翻译系统（多语言翻译）
- [x] Shadowrocket 配置（设备检测+代理）
- [x] 设备信息管理器
- [x] VM 检测和绕过
- [x] iCloud 同步
- [x] 蓝牙管理
- [x] 网络连接管理

## 🔧 技术栈

- **语言**: Swift 5.9+
- **框架**: SwiftUI, SwiftData, App Intents
- **平台**: iOS 16+, macOS 13+
- **架构**: MVVM, Async/Await

## 📚 文档位置

- AI Fixer 指南: `docs/Kris-AI-Fixer-Guide.md`
- 翻译系统指南: `docs/AI-Translation-Guide.md`
- Shadowrocket 指南: `docs/Shadowrocket-Setup-Guide.md`
- VM 检测指南: `docs/VM-Detection-Bypass-Guide.md`
- 主指南: `docs/iOS-Automation-Complete-Guide.md`

## 🎨 代码风格

- 使用中英文双语注释
- 遵循 Swift 命名规范
- 所有异步操作使用 async/await
- UI 更新使用 @MainActor

## 💡 快速参考

### 创建新功能模板

```swift
import Foundation
import AppIntents

@available(iOS 16.0, *)
@MainActor
class NewFeatureManager: ObservableObject {

    @Published var status: String = ""

    func performAction() async throws {
        print("🚀 执行操作...")
        // 实现功能
        print("✅ 完成")
    }
}

// App Intent
@available(iOS 16.0, *)
struct NewFeatureIntent: AppIntent {
    static var title: LocalizedStringResource = "功能名称"

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // 实现逻辑
        return .result(dialog: "完成")
    }
}
```

### Git Commit 模板

```bash
git commit -m "$(cat <<'EOF'
[类型] 功能标题

描述：
✅ 功能1
✅ 功能2

文件：
- path/to/file1.swift (行数)
- path/to/file2.swift (行数)

技术亮点：
- 技术1
- 技术2
EOF
)"
```

## 🔍 问题排查

### 编译错误
1. 清理构建: `Cmd + Shift + K`
2. 重启 Xcode
3. 检查 Swift 版本兼容性

### Git 冲突
1. `git stash`
2. `git pull`
3. `git stash pop`
4. 解决冲突

## 📊 项目统计

- **总代码行数**: ~10,000+ 行
- **文件数**: 20+ 个 Swift 文件
- **文档数**: 10+ 个 Markdown 文件
- **功能模块**: 8 个主要模块

## 🌟 核心理念

1. **自动化优先** - 能自动化的都自动化
2. **智能检测** - 先检测设备和系统
3. **用户友好** - 中文文档和提示
4. **持续学习** - AI 系统不断优化
5. **节省 Token** - 使用此配置文件快速恢复上下文

---

## 📌 快速开始新对话

当开始新的对话时，只需说：

**"读取项目配置文件，继续开发 [功能名称]"**

我会自动读取此文件，快速恢复上下文，无需重复说明！

---

**更新时间**: 2026-01-17
**版本**: v2.0
