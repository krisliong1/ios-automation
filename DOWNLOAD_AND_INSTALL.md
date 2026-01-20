# iOS 自动化工具 v1.0.0 - 下载和安装指南

## 📦 立即下载（3 种方式）

---

## 方式 1: 下载完整 Release 包（推荐）⭐⭐⭐⭐⭐

### 选项 A: 下载 tar.gz 压缩包
```bash
# 下载压缩包（176KB，包含所有 53 个文件）
wget https://github.com/krisliong1/ios-automation/raw/claude/ios-automation-shortcuts-gsEpf/ios-automation-v1.0.0.tar.gz

# 解压
tar -xzf ios-automation-v1.0.0.tar.gz
cd release-v1.0.0/

# 查看内容
ls -la
```

### 选项 B: 克隆完整仓库
```bash
# 克隆指定分支（包含所有文件）
git clone -b claude/ios-automation-shortcuts-gsEpf \
  https://github.com/krisliong1/ios-automation.git

cd ios-automation/

# 查看所有工具
ls -la Sources/iOSAutomation/
ls -la examples/AIFixer/
ls -la docs/
```

**包含的内容**：
- ✅ 4 个核心工具模块（AIManager, SecurityManager, NetworkManager, TranslationManager）
- ✅ 5 个 AI Fixer 工具（KrisAIFixer, Integration, Learning, Translator, Router Config）
- ✅ 13+ 个示例模块
- ✅ 22 个完整文档
- ✅ Package.swift 配置
- ✅ 所有 Release 文档

---

## 方式 2: 只下载核心工具文件

### 下载 AI Manager（主要工具）
```bash
# 创建目录
mkdir -p ios-automation-tools

# 下载核心文件
wget -P ios-automation-tools/ \
  https://raw.githubusercontent.com/krisliong1/ios-automation/claude/ios-automation-shortcuts-gsEpf/Sources/iOSAutomation/AIManager.swift

wget -P ios-automation-tools/ \
  https://raw.githubusercontent.com/krisliong1/ios-automation/claude/ios-automation-shortcuts-gsEpf/Sources/iOSAutomation/SecurityManager.swift

wget -P ios-automation-tools/ \
  https://raw.githubusercontent.com/krisliong1/ios-automation/claude/ios-automation-shortcuts-gsEpf/Sources/iOSAutomation/NetworkManager.swift

wget -P ios-automation-tools/ \
  https://raw.githubusercontent.com/krisliong1/ios-automation/claude/ios-automation-shortcuts-gsEpf/Sources/iOSAutomation/TranslationManager.swift
```

### 下载 AI Fixer 工具
```bash
# 下载 Kris AI Fixer
wget -P ios-automation-tools/ \
  https://raw.githubusercontent.com/krisliong1/ios-automation/claude/ios-automation-shortcuts-gsEpf/examples/AIFixer/KrisAIFixer.swift

# 下载 Claude Code Router 配置
wget -P ios-automation-tools/ \
  https://raw.githubusercontent.com/krisliong1/ios-automation/claude/ios-automation-shortcuts-gsEpf/examples/AIFixer/ClaudeCodeRouterConfig.json
```

### 下载关键文档
```bash
# 下载 AI Manager 文档
wget -P ios-automation-tools/ \
  https://raw.githubusercontent.com/krisliong1/ios-automation/claude/ios-automation-shortcuts-gsEpf/docs/AI-Manager-Quick-Start.md

wget -P ios-automation-tools/ \
  https://raw.githubusercontent.com/krisliong1/ios-automation/claude/ios-automation-shortcuts-gsEpf/docs/AI-Manager-Integration-Guide.md

wget -P ios-automation-tools/ \
  https://raw.githubusercontent.com/krisliong1/ios-automation/claude/ios-automation-shortcuts-gsEpf/.claude-project/instructions.md
```

---

## 方式 3: 使用 curl（适合脚本）

### 一键下载脚本
创建文件 `download-ios-automation.sh`:

```bash
#!/bin/bash

# iOS 自动化工具 v1.0.0 一键下载脚本

BASE_URL="https://raw.githubusercontent.com/krisliong1/ios-automation/claude/ios-automation-shortcuts-gsEpf"

# 创建目录结构
mkdir -p ios-automation/{Sources/iOSAutomation,examples/AIFixer,docs,.claude-project}

echo "📦 下载核心工具模块..."
curl -L "$BASE_URL/Sources/iOSAutomation/AIManager.swift" -o ios-automation/Sources/iOSAutomation/AIManager.swift
curl -L "$BASE_URL/Sources/iOSAutomation/SecurityManager.swift" -o ios-automation/Sources/iOSAutomation/SecurityManager.swift
curl -L "$BASE_URL/Sources/iOSAutomation/NetworkManager.swift" -o ios-automation/Sources/iOSAutomation/NetworkManager.swift
curl -L "$BASE_URL/Sources/iOSAutomation/TranslationManager.swift" -o ios-automation/Sources/iOSAutomation/TranslationManager.swift

echo "🤖 下载 AI Fixer 工具..."
curl -L "$BASE_URL/examples/AIFixer/KrisAIFixer.swift" -o ios-automation/examples/AIFixer/KrisAIFixer.swift
curl -L "$BASE_URL/examples/AIFixer/AIFixerIntegration.swift" -o ios-automation/examples/AIFixer/AIFixerIntegration.swift
curl -L "$BASE_URL/examples/AIFixer/AIFixerLearning.swift" -o ios-automation/examples/AIFixer/AIFixerLearning.swift
curl -L "$BASE_URL/examples/AIFixer/ClaudeCodeRouterConfig.json" -o ios-automation/examples/AIFixer/ClaudeCodeRouterConfig.json

echo "📚 下载文档..."
curl -L "$BASE_URL/docs/AI-Manager-Quick-Start.md" -o ios-automation/docs/AI-Manager-Quick-Start.md
curl -L "$BASE_URL/docs/AI-Manager-Integration-Guide.md" -o ios-automation/docs/AI-Manager-Integration-Guide.md
curl -L "$BASE_URL/docs/AI-Manager-Claude-App-Usage.md" -o ios-automation/docs/AI-Manager-Claude-App-Usage.md
curl -L "$BASE_URL/.claude-project/instructions.md" -o ios-automation/.claude-project/instructions.md

echo "📄 下载 Release 文档..."
curl -L "$BASE_URL/RELEASE_NOTES.md" -o ios-automation/RELEASE_NOTES.md
curl -L "$BASE_URL/HOW_TO_USE.md" -o ios-automation/HOW_TO_USE.md
curl -L "$BASE_URL/QUICK_START_GUIDE.md" -o ios-automation/QUICK_START_GUIDE.md
curl -L "$BASE_URL/TOOLS_CHECKLIST.md" -o ios-automation/TOOLS_CHECKLIST.md

echo "📦 下载 Package.swift..."
curl -L "$BASE_URL/Package.swift" -o ios-automation/Package.swift

echo "✅ 下载完成！"
echo "📂 文件位置: ./ios-automation/"
echo ""
echo "下一步："
echo "  cd ios-automation/"
echo "  cat QUICK_START_GUIDE.md"
```

**使用方法**：
```bash
chmod +x download-ios-automation.sh
./download-ios-automation.sh
```

---

## 📋 验证下载

下载完成后，验证所有文件：

```bash
cd ios-automation/  # 或 release-v1.0.0/

# 检查核心模块（应该有 4 个文件）
ls -lh Sources/iOSAutomation/
# 应该看到：
# - AIManager.swift (25KB)
# - SecurityManager.swift (9.6KB)
# - NetworkManager.swift (14.8KB)
# - TranslationManager.swift (15.2KB)

# 检查 AI Fixer（应该有 5 个文件）
ls -lh examples/AIFixer/
# 应该看到：
# - KrisAIFixer.swift (42.5KB)
# - AIFixerIntegration.swift (11.6KB)
# - AIFixerLearning.swift (15.2KB)
# - AITranslator.swift (17.4KB)
# - ClaudeCodeRouterConfig.json (2.3KB)

# 检查关键文档（应该有 3 个）
ls -lh docs/AI-Manager*.md
# 应该看到：
# - AI-Manager-Quick-Start.md
# - AI-Manager-Integration-Guide.md
# - AI-Manager-Claude-App-Usage.md

ls -lh .claude-project/
# 应该看到：
# - instructions.md

# 检查 Release 文档
ls -lh *.md
# 应该看到：
# - RELEASE_NOTES.md
# - HOW_TO_USE.md
# - QUICK_START_GUIDE.md
# - TOOLS_CHECKLIST.md
# 等等...
```

---

## 🚀 快速开始使用

### 1. Claude iOS App（最简单）

下载完成后：

```bash
# 1. 打开 Claude iOS App
# 2. 创建新 Project："iOS 自动化 AI 管理器"
# 3. 添加这 3 个文件到知识库：
#    - docs/AI-Manager-Quick-Start.md
#    - docs/AI-Manager-Integration-Guide.md
#    - .claude-project/instructions.md
# 4. 在对话中使用："检查 AI 状态"
```

详细步骤查看：`QUICK_START_GUIDE.md`

### 2. 集成到 Xcode 项目

```bash
# 复制核心文件到你的项目
cp Sources/iOSAutomation/*.swift /path/to/YourProject/

# 添加依赖到 Package.swift（参考 Package.swift）
```

详细步骤查看：`HOW_TO_USE.md`

### 3. 作为 Swift Package 使用

在你的 `Package.swift` 中添加：

```swift
dependencies: [
    .package(
        url: "https://github.com/krisliong1/ios-automation",
        branch: "claude/ios-automation-shortcuts-gsEpf"
    )
]
```

---

## 📊 下载内容清单

| 类别 | 文件数 | 大小 | 说明 |
|------|--------|------|------|
| 核心模块 | 4 | 64.6 KB | AI Manager 等 |
| AI Fixer | 5 | 88.6 KB | Kris AI Fixer 等 |
| 文档 | 22+ | 350+ KB | 完整指南 |
| 示例 | 13+ | - | 各种功能示例 |
| **总计** | **53** | **~500 KB** | 完整工具包 |

---

## 🔗 所有文件的直接链接

### 核心工具模块
- [AIManager.swift](https://github.com/krisliong1/ios-automation/blob/claude/ios-automation-shortcuts-gsEpf/Sources/iOSAutomation/AIManager.swift)
- [SecurityManager.swift](https://github.com/krisliong1/ios-automation/blob/claude/ios-automation-shortcuts-gsEpf/Sources/iOSAutomation/SecurityManager.swift)
- [NetworkManager.swift](https://github.com/krisliong1/ios-automation/blob/claude/ios-automation-shortcuts-gsEpf/Sources/iOSAutomation/NetworkManager.swift)
- [TranslationManager.swift](https://github.com/krisliong1/ios-automation/blob/claude/ios-automation-shortcuts-gsEpf/Sources/iOSAutomation/TranslationManager.swift)

### AI Fixer 工具
- [KrisAIFixer.swift](https://github.com/krisliong1/ios-automation/blob/claude/ios-automation-shortcuts-gsEpf/examples/AIFixer/KrisAIFixer.swift)
- [AIFixerIntegration.swift](https://github.com/krisliong1/ios-automation/blob/claude/ios-automation-shortcuts-gsEpf/examples/AIFixer/AIFixerIntegration.swift)
- [AIFixerLearning.swift](https://github.com/krisliong1/ios-automation/blob/claude/ios-automation-shortcuts-gsEpf/examples/AIFixer/AIFixerLearning.swift)
- [AITranslator.swift](https://github.com/krisliong1/ios-automation/blob/claude/ios-automation-shortcuts-gsEpf/examples/AIFixer/AITranslator.swift)
- [ClaudeCodeRouterConfig.json](https://github.com/krisliong1/ios-automation/blob/claude/ios-automation-shortcuts-gsEpf/examples/AIFixer/ClaudeCodeRouterConfig.json)

### 关键文档（必读）
- [AI-Manager-Quick-Start.md](https://github.com/krisliong1/ios-automation/blob/claude/ios-automation-shortcuts-gsEpf/docs/AI-Manager-Quick-Start.md)
- [AI-Manager-Integration-Guide.md](https://github.com/krisliong1/ios-automation/blob/claude/ios-automation-shortcuts-gsEpf/docs/AI-Manager-Integration-Guide.md)
- [AI-Manager-Claude-App-Usage.md](https://github.com/krisliong1/ios-automation/blob/claude/ios-automation-shortcuts-gsEpf/docs/AI-Manager-Claude-App-Usage.md)
- [instructions.md](https://github.com/krisliong1/ios-automation/blob/claude/ios-automation-shortcuts-gsEpf/.claude-project/instructions.md)

### Release 文档
- [RELEASE_NOTES.md](https://github.com/krisliong1/ios-automation/blob/claude/ios-automation-shortcuts-gsEpf/RELEASE_NOTES.md)
- [HOW_TO_USE.md](https://github.com/krisliong1/ios-automation/blob/claude/ios-automation-shortcuts-gsEpf/HOW_TO_USE.md)
- [QUICK_START_GUIDE.md](https://github.com/krisliong1/ios-automation/blob/claude/ios-automation-shortcuts-gsEpf/QUICK_START_GUIDE.md)
- [TOOLS_CHECKLIST.md](https://github.com/krisliong1/ios-automation/blob/claude/ios-automation-shortcuts-gsEpf/TOOLS_CHECKLIST.md)

### 配置文件
- [Package.swift](https://github.com/krisliong1/ios-automation/blob/claude/ios-automation-shortcuts-gsEpf/Package.swift)

---

## ❓ 常见问题

### Q: 我只想要 AI Manager，其他都不要？
A: 使用"方式 2"，只下载需要的文件：
```bash
wget https://raw.githubusercontent.com/krisliong1/ios-automation/claude/ios-automation-shortcuts-gsEpf/Sources/iOSAutomation/AIManager.swift
```

### Q: 如何更新到最新版本？
A: 重新克隆或下载：
```bash
git clone -b claude/ios-automation-shortcuts-gsEpf \
  https://github.com/krisliong1/ios-automation.git
```

### Q: 下载的文件在哪里？
A: 查看完整文件树：
```bash
tree ios-automation/
# 或
find ios-automation/ -type f
```

### Q: 如何验证下载完整？
A: 检查文件数量：
```bash
find ios-automation/ -type f | wc -l
# 应该显示 53 或更多
```

---

## 📞 需要帮助？

- 📖 查看完整文档：`docs/iOS-Automation-Complete-Guide.md`
- 🚀 5 分钟快速开始：`QUICK_START_GUIDE.md`
- 📋 工具清单：`TOOLS_CHECKLIST.md`
- 📝 Release 说明：`RELEASE_NOTES.md`

---

**v1.0.0** - 2026年1月
**仓库**: https://github.com/krisliong1/ios-automation
**分支**: `claude/ios-automation-shortcuts-gsEpf`
