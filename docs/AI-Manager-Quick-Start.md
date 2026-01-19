# AI 管理器 - 快速开始

## 🎯 核心概念

**AI 管理器 = 主 AI 的"保姆"**

```
主 AI (Kris AI Fixer)
    ↓ 遇到问题（网络、搜索等）
管理 AI (AI Manager)
    ↓ 自动介入解决
    ├─ 切换提供商
    ├─ 切换搜索引擎
    └─ 修复后重试
```

---

## 🚀 5 分钟快速上手

### 1. 安装 claude-code-router

```bash
npm install -g claude-code-router
```

### 2. 配置 API Keys

创建 `~/.ccr/.env`:

```bash
ANTHROPIC_API_KEY=your_key_here
OPENROUTER_API_KEY=your_key_here  # 可选
DEEPSEEK_API_KEY=your_key_here    # 可选
```

### 3. 启动 Router

```bash
ccr start --daemon
```

### 4. 在代码中使用

```swift
import iOSAutomation

// 创建管理器
let manager = AIManager()

// 启动主 AI
manager.startMainAI()

// 执行任务（自动处理问题）
do {
    let result = try await manager.executeTask(
        description: "Xcode 虚拟机检测无法运行"
    )

    print(result.success ? "✅ 成功" : "❌ 失败")
} catch {
    print("❌ 错误: \(error)")
}
```

---

## 💡 工作原理

### 场景 1: 网络连接失败

```
1. 主 AI 尝试搜索解决方案
   ❌ 网络超时

2. 管理 AI 检测到网络问题
   🔍 测试其他提供商...
   ✅ DeepSeek 可用

3. 自动切换到 DeepSeek
   🔄 切换完成

4. 重试原始任务
   ✅ 任务成功
```

### 场景 2: 搜索被限制

```
1. 主 AI 尝试搜索 Stack Overflow
   ❌ 访问被拒绝

2. 管理 AI 检测到搜索限制
   🔄 切换到 DuckDuckGo
   🔄 启用 webSearch 路由

3. 重试搜索
   ✅ 搜索成功
```

### 场景 3: API 配额用尽

```
1. 主 AI 调用 Claude API
   ❌ 配额已用尽

2. 管理 AI 检测到配额问题
   🔍 寻找无限制提供商
   ✅ 切换到 Ollama (本地)

3. 重试任务
   ✅ 任务成功（本地运行）
```

---

## 🔧 提供商对比

| 提供商 | 特点 | 何时使用 | 配额 | 速度 |
|--------|------|---------|------|------|
| **Claude** | 高质量 | 默认使用 | 有限 | 快 |
| **DeepSeek** | 便宜快速 | 大量任务 | 有限 | 很快 |
| **Ollama** | 本地运行 | 无网络/无限制 | 无限 | 中等 |
| **OpenRouter** | 多模型 | 需要特定功能 | 有限 | 快 |
| **Gemini** | 多模态 | 图像处理 | 有限 | 快 |

---

## 📊 监控

### 查看系统状态

```swift
let status = manager.getStatusReport()
print(status)
```

输出:
```
🤖 AI 管理系统状态报告
========================

主 AI 状态: 🟢 运行中
管理 AI 状态: ⚪️ 空闲
当前提供商: Claude (默认)

健康状态: ✅ 健康

最近问题 (最多 5 条):
  • 🌐 网络错误
    时间: 2026-01-19 10:30:00
    描述: 网络连接超时
```

### 查看问题历史

```swift
for problem in manager.problemLog {
    print("\(problem.type.icon) \(problem.description)")
}
```

---

## 🎛️ 手动控制

### 手动切换提供商

```swift
// 切换到 DeepSeek（快速）
try await manager.switchProvider(to: .deepseek)

// 切换到 Ollama（本地）
try await manager.switchProvider(to: .ollama)

// 切换回默认
try await manager.switchProvider(to: .default)
```

### 使用快捷指令

在 iOS 快捷指令 App 中：
1. 添加 "切换 AI 提供商" 操作
2. 输入提供商名称：`deepseek` / `ollama` / `gemini`
3. 运行快捷指令

---

## ⚙️ 配置

### 基础配置

```swift
let manager = AIManager(
    config: RouterConfiguration(
        serverURL: "http://localhost",
        port: 3456,
        enableLogging: true
    )
)
```

### Router 配置

编辑配置文件 `examples/AIFixer/ClaudeCodeRouterConfig.json`：

```json
{
  "routes": {
    "default": {
      "provider": "anthropic",
      "model": "claude-sonnet-4"
    },
    "fast": {
      "provider": "deepseek",
      "model": "deepseek-chat"
    }
  }
}
```

复制到 `~/.ccr/config.json` 并重启 router：

```bash
ccr restart
```

---

## 🐛 常见问题

### Q: Router 无法启动？

```bash
# 检查是否安装
ccr --version

# 检查是否运行
ccr status

# 重新启动
ccr restart
```

### Q: 提示"网络未连接"？

1. 检查网络连接
2. 测试 router: `curl http://localhost:3456/health`
3. 查看日志: `tail -f ~/.ccr/logs/router.log`

### Q: 想使用 Ollama 但提示不可用？

```bash
# 安装 Ollama
brew install ollama

# 启动服务
ollama serve

# 下载模型
ollama pull llama3

# 测试
ollama run llama3 "Hello"
```

### Q: 如何完全离线使用？

```swift
// 只使用本地 Ollama
let manager = AIManager()
try await manager.switchProvider(to: .ollama)

// 禁用健康监控（减少网络请求）
manager.stopHealthMonitoring()
```

---

## 📚 进一步阅读

- **完整文档**: `docs/AI-Manager-Integration-Guide.md`
- **配置示例**: `examples/AIFixer/ClaudeCodeRouterConfig.json`
- **claude-code-router**: https://github.com/musistudio/claude-code-router

---

## 🎉 完成！

现在你的 AI 系统可以：

- ✅ 自动处理网络问题
- ✅ 自动切换提供商
- ✅ 自动解决搜索限制
- ✅ 监控系统健康
- ✅ 记录问题历史

**你的 AI 现在有了一个"保姆"！** 🤖👶
