# AI 管理器集成指南

## 📋 概述

AI 管理器是一个智能监控和管理系统，集成了 [claude-code-router](https://github.com/musistudio/claude-code-router) 来实现：

- 🤖 **监控主 AI**：实时监控 Kris AI Fixer 的运行状态
- 🔧 **自动问题解决**：当主 AI 遇到网络、搜索等问题时自动介入
- 🔄 **智能路由**：根据问题类型切换到不同的 AI 提供商
- 🏥 **健康检查**：定期检查系统健康状态

---

## 🎯 核心功能

### 1. 问题检测和分类

AI 管理器能自动检测以下问题：

| 问题类型 | 图标 | 描述 | 自动恢复 |
|---------|------|------|---------|
| 网络错误 | 🌐 | 网络连接失败、超时 | ✅ 是 |
| 搜索受限 | 🔍 | 搜索引擎被限制 | ✅ 是 |
| 超时 | ⏱️ | 请求超时 | ✅ 是 |
| API 限制 | 🔄 | API 配额用尽 | ✅ 是 |
| 权限拒绝 | 🔐 | 权限不足 | ❌ 否（需手动） |
| 健康检查 | 🏥 | 系统健康问题 | ✅ 是 |

### 2. 智能路由切换

使用 claude-code-router 的路由功能：

#### 提供商选项

| 提供商 | 特点 | 适用场景 | 配额 |
|--------|------|---------|------|
| **Claude (默认)** | 高质量、稳定 | 标准任务 | 有限制 |
| **OpenRouter** | 多模型支持 | 需要特定模型 | 有限制 |
| **DeepSeek** | 快速、便宜 | 大量请求、快速响应 | 有限制 |
| **Ollama** | 本地运行 | 离线使用、无限制 | ✅ 无限制 |
| **Google Gemini** | 多模态 | 图像处理 | 有限制 |

#### 路由场景

```javascript
// claude-code-router 配置示例
{
  "routes": {
    "default": {
      "provider": "anthropic",
      "model": "claude-sonnet-4"
    },
    "background": {
      "provider": "deepseek",
      "model": "deepseek-chat"
    },
    "webSearch": {
      "provider": "openrouter",
      "model": "anthropic/claude-3.5-sonnet",
      "features": ["web-search"]
    },
    "longContext": {
      "provider": "anthropic",
      "model": "claude-opus-4"
    }
  }
}
```

---

## 🚀 安装和配置

### 前置要求

1. **Node.js** 16+ (用于运行 claude-code-router)
2. **iOS 16+ / macOS 13+**
3. **Swift 5.9+**

### 步骤 1: 安装 claude-code-router

```bash
# 使用 npm
npm install -g claude-code-router

# 或使用 yarn
yarn global add claude-code-router

# 验证安装
ccr --version
```

### 步骤 2: 配置 claude-code-router

创建配置文件 `~/.ccr/config.json`:

```json
{
  "server": {
    "port": 3456,
    "host": "localhost"
  },
  "routes": {
    "default": {
      "provider": "anthropic",
      "model": "claude-sonnet-4",
      "apiKey": "${ANTHROPIC_API_KEY}"
    },
    "webSearch": {
      "provider": "openrouter",
      "model": "anthropic/claude-3.5-sonnet",
      "apiKey": "${OPENROUTER_API_KEY}",
      "features": ["web-search"]
    },
    "background": {
      "provider": "deepseek",
      "model": "deepseek-chat",
      "apiKey": "${DEEPSEEK_API_KEY}"
    },
    "local": {
      "provider": "ollama",
      "model": "llama3",
      "baseURL": "http://localhost:11434"
    }
  },
  "logging": {
    "level": "info",
    "file": "~/.ccr/logs/router.log"
  }
}
```

### 步骤 3: 配置环境变量

创建 `~/.ccr/.env`:

```bash
# Anthropic API Key
ANTHROPIC_API_KEY=your_key_here

# OpenRouter API Key (用于 webSearch)
OPENROUTER_API_KEY=your_key_here

# DeepSeek API Key (用于快速响应)
DEEPSEEK_API_KEY=your_key_here

# 可选: Google Gemini
GOOGLE_API_KEY=your_key_here
```

### 步骤 4: 启动 router

```bash
# 启动 router 服务
ccr start

# 或在后台运行
ccr start --daemon

# 检查状态
ccr status
```

### 步骤 5: 在 iOS 项目中集成

#### 5.1 添加 AI 管理器到项目

```swift
import iOSAutomation

// 创建 AI 管理器实例
let manager = AIManager(
    config: RouterConfiguration(
        serverURL: "http://localhost",
        port: 3456,
        enableLogging: true
    )
)

// 启动主 AI
manager.startMainAI()

// 执行任务（带自动问题解决）
do {
    let result = try await manager.executeTask(
        description: "Xcode 编译失败，错误代码 1"
    )

    if result.success {
        print("✅ 任务完成")
    }
} catch {
    print("❌ 任务失败: \(error)")
}
```

#### 5.2 获取系统状态

```swift
// 获取状态报告
let status = manager.getStatusReport()
print(status)

// 输出示例:
// 🤖 AI 管理系统状态报告
// ========================
//
// 主 AI 状态: 🟢 运行中
// 管理 AI 状态: ⚪️ 空闲
// 当前提供商: Claude (默认)
//
// 健康状态: ✅ 健康
```

---

## 🔧 使用场景

### 场景 1: 网络连接问题

**问题**: 主 AI 无法连接到搜索引擎

```
❌ 主 AI 执行失败: 网络连接超时
🔧 管理 AI 介入解决问题...
🌐 诊断网络问题...
🔍 测试 AI 提供商连接...
✅ 找到可用提供商: DeepSeek
🔄 切换到提供商: DeepSeek
✅ 问题已解决，重试任务
```

**解决方案**: 自动切换到可用的提供商

### 场景 2: 搜索受限

**问题**: 默认搜索引擎限制访问

```
❌ 搜索失败: 访问被拒绝
🔍 解决搜索限制问题...
🔄 切换到备用搜索引擎...
✅ 切换到: DuckDuckGo
🔄 使用 claude-code-router webSearch 路由...
✅ 问题已解决
```

**解决方案**:
1. 切换到备用搜索引擎（DuckDuckGo, GitHub等）
2. 使用 claude-code-router 的 webSearch 路由

### 场景 3: API 配额用尽

**问题**: Claude API 配额已用完

```
❌ API 错误: 配额已用尽
🔄 解决 API 限制问题...
🔍 测试提供商...
✅ 切换到无限制提供商: Ollama (本地)
✅ 问题已解决
```

**解决方案**: 切换到本地运行的 Ollama

---

## 📊 监控和日志

### 健康监控

AI 管理器每 30 秒执行一次健康检查：

```swift
// 健康检查项目
- 网络连接状态
- 网络延迟
- 内存使用率
- AI 响应时间
```

### 问题日志

所有问题都会被记录：

```swift
// 查看问题历史
for problem in manager.problemLog {
    print("\(problem.type.icon) \(problem.description)")
}
```

### Router 日志

claude-code-router 日志位置：

```
~/.ccr/logs/router.log
```

查看日志：

```bash
# 实时查看
tail -f ~/.ccr/logs/router.log

# 搜索错误
grep "ERROR" ~/.ccr/logs/router.log
```

---

## 🎛️ 高级配置

### 自定义路由规则

编辑 `~/.ccr/config.json`:

```json
{
  "routes": {
    "myCustomRoute": {
      "provider": "openrouter",
      "model": "anthropic/claude-3.5-sonnet",
      "apiKey": "${OPENROUTER_API_KEY}",
      "temperature": 0.7,
      "maxTokens": 4096,
      "features": ["web-search", "code-execution"]
    }
  }
}
```

在代码中使用：

```swift
// 切换到自定义路由
try await manager.executeRouterCommand(
    command: "/route",
    args: ["myCustomRoute"]
)
```

### 手动切换提供商

```swift
// 方法 1: 通过代码
try await manager.switchProvider(to: .deepseek)

// 方法 2: 通过 App Intent
let intent = SwitchAIProviderIntent(providerName: "deepseek")
try await intent.perform()

// 方法 3: 通过快捷指令
// 在快捷指令 App 中调用 "切换 AI 提供商"
```

---

## 🐛 故障排除

### 问题 1: Router 无法启动

**错误**: `ccr: command not found`

**解决**:
```bash
# 重新安装
npm install -g claude-code-router

# 检查 PATH
echo $PATH

# 手动添加到 PATH
export PATH="$PATH:$(npm root -g)"
```

### 问题 2: 连接失败

**错误**: `网络未连接`

**解决**:
1. 检查 router 是否运行: `ccr status`
2. 检查端口是否被占用: `lsof -i :3456`
3. 检查防火墙设置
4. 重启 router: `ccr restart`

### 问题 3: API Key 无效

**错误**: `API Key 无效`

**解决**:
1. 检查 `.env` 文件配置
2. 验证 API Key:
   ```bash
   curl -H "Authorization: Bearer $ANTHROPIC_API_KEY" \
        https://api.anthropic.com/v1/models
   ```
3. 重新生成 API Key

### 问题 4: Ollama 无法连接

**错误**: `Ollama 提供商不可用`

**解决**:
```bash
# 安装 Ollama
brew install ollama

# 启动 Ollama 服务
ollama serve

# 下载模型
ollama pull llama3

# 测试
ollama run llama3 "Hello"
```

---

## 📚 API 参考

### AIManager 主要方法

```swift
class AIManager {
    // 启动主 AI
    func startMainAI()

    // 执行任务（带自动恢复）
    func executeTask(description: String) async throws -> FixResult

    // 获取状态报告
    func getStatusReport() -> String

    // 手动切换提供商
    func switchProvider(to provider: AIProvider) async throws

    // 停止健康监控
    func stopHealthMonitoring()
}
```

### 配置选项

```swift
struct RouterConfiguration {
    let serverURL: String      // Router 服务器地址
    let port: Int              // Router 端口
    let enableLogging: Bool    // 是否启用日志
}
```

### 提供商枚举

```swift
enum AIProvider {
    case `default`    // Claude 默认
    case openrouter   // OpenRouter
    case deepseek     // DeepSeek
    case ollama       // Ollama (本地)
    case gemini       // Google Gemini
}
```

---

## 🎯 最佳实践

### 1. 选择合适的提供商

| 任务类型 | 推荐提供商 | 原因 |
|---------|----------|------|
| 复杂问题解决 | Claude | 最高质量 |
| 大量简单任务 | DeepSeek | 快速、便宜 |
| 离线使用 | Ollama | 无需网络 |
| 需要搜索 | OpenRouter | 支持 webSearch |
| 图像处理 | Gemini | 多模态 |

### 2. 配额管理

```swift
// 监控 API 使用量
let usage = await manager.getAPIUsage()

// 接近限制时自动切换
if usage.remaining < 100 {
    try await manager.switchProvider(to: .ollama)
}
```

### 3. 错误处理

```swift
do {
    let result = try await manager.executeTask(description: task)
} catch AIManagerError.cannotRecover(let reason) {
    // 无法自动恢复，需要手动介入
    print("需要手动解决: \(reason)")
} catch {
    // 其他错误
    print("错误: \(error)")
}
```

### 4. 性能优化

```swift
// 对于后台任务，使用快速模型
let config = RouterConfiguration(
    serverURL: "http://localhost",
    port: 3456,
    enableLogging: false  // 减少日志开销
)

// 批量任务使用 DeepSeek
try await manager.switchProvider(to: .deepseek)
```

---

## 🔗 相关资源

- [claude-code-router GitHub](https://github.com/musistudio/claude-code-router)
- [OpenRouter 文档](https://openrouter.ai/docs)
- [DeepSeek API 文档](https://platform.deepseek.com/docs)
- [Ollama 文档](https://ollama.ai/docs)
- [Google Gemini API](https://ai.google.dev/docs)

---

## 📝 更新日志

### v1.0.0 (2026-01-19)

- ✅ 初始版本
- ✅ 集成 claude-code-router
- ✅ 支持 5 个 AI 提供商
- ✅ 自动问题检测和恢复
- ✅ 健康监控系统
- ✅ App Intents 支持

---

## 💡 示例项目

完整示例代码：

```swift
import SwiftUI
import iOSAutomation

@main
struct MyApp: App {
    @StateObject private var aiManager = AIManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(aiManager)
                .task {
                    // 启动 AI 管理器
                    aiManager.startMainAI()
                }
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var aiManager: AIManager
    @State private var taskDescription = ""
    @State private var result: FixResult?

    var body: some View {
        VStack(spacing: 20) {
            // 状态显示
            HStack {
                Text("主 AI: \(aiManager.mainAIStatus.icon)")
                Text("管理 AI: \(aiManager.managerAIStatus.icon)")
                Text("提供商: \(aiManager.currentProvider.name)")
            }

            // 任务输入
            TextField("描述问题", text: $taskDescription)
                .textFieldStyle(.roundedBorder)

            // 执行按钮
            Button("解决问题") {
                Task {
                    do {
                        result = try await aiManager.executeTask(
                            description: taskDescription
                        )
                    } catch {
                        print("错误: \(error)")
                    }
                }
            }

            // 结果显示
            if let result = result {
                VStack(alignment: .leading) {
                    Text(result.success ? "✅ 成功" : "❌ 失败")
                    Text(result.message)

                    ForEach(result.solution.steps.indices, id: \.self) { index in
                        Text("\(index + 1). \(result.solution.steps[index])")
                    }
                }
            }

            // 状态报告
            Button("查看状态") {
                print(aiManager.getStatusReport())
            }
        }
        .padding()
    }
}
```

---

**集成完成！** 现在你的 AI 系统可以自动处理网络、搜索等问题了。🎉
