# 在 Claude App 中使用 AI 管理器

## 🎯 快速使用方法

在 Claude App 对话框中，你可以通过以下方式使用 AI 管理器：

---

## 方法 1: 使用快捷指令（推荐）⭐

### 第一次设置

1. **打开 iOS 快捷指令 App**

2. **创建新快捷指令 "AI 管理器"**

3. **添加操作**：
   ```
   • 添加 "运行快捷指令"
   • 选择 "AI 管理器状态" 或 "执行 AI 任务"
   ```

4. **添加到 Siri**（可选）：
   ```
   "嘿 Siri，运行 AI 管理器"
   ```

### 日常使用

在 Claude App 中输入：

```
@快捷指令 AI管理器状态
```

或者：

```
@快捷指令 执行AI任务 "Xcode编译失败"
```

---

## 方法 2: 使用 Siri 语音命令

### 设置语音命令

1. 打开快捷指令 App
2. 创建快捷指令
3. 点击 "添加到 Siri"
4. 录制语音命令

### 常用语音命令

```
"嘿 Siri，AI 管理器状态"
"嘿 Siri，切换到快速模式"
"嘿 Siri，解决编译问题"
```

---

## 方法 3: 在 Claude Code CLI 中使用

如果你使用 Claude Code 命令行工具：

### 创建 MCP 服务器

创建文件 `~/.claude/mcp-servers/ai-manager.js`:

```javascript
#!/usr/bin/env node

const { spawn } = require('child_process');

// AI 管理器 MCP 服务器
const server = {
  name: "ai-manager",
  version: "1.0.0",

  tools: [
    {
      name: "check_status",
      description: "检查 AI 管理器状态",
      handler: async () => {
        // 调用 Swift 命令行工具
        return executeSwiftCommand("status");
      }
    },
    {
      name: "fix_problem",
      description: "让 AI 管理器解决问题",
      parameters: {
        problem: { type: "string", description: "问题描述" }
      },
      handler: async (params) => {
        return executeSwiftCommand("fix", params.problem);
      }
    },
    {
      name: "switch_provider",
      description: "切换 AI 提供商",
      parameters: {
        provider: {
          type: "string",
          enum: ["default", "deepseek", "ollama", "gemini"],
          description: "提供商名称"
        }
      },
      handler: async (params) => {
        return executeSwiftCommand("switch", params.provider);
      }
    }
  ]
};

function executeSwiftCommand(command, ...args) {
  // 执行 Swift 命令行工具
  const cmd = spawn('swift', [
    'run', 'ai-manager-cli', command, ...args
  ]);

  return new Promise((resolve, reject) => {
    let output = '';
    cmd.stdout.on('data', (data) => output += data);
    cmd.on('close', (code) => {
      if (code === 0) resolve(output);
      else reject(new Error(output));
    });
  });
}

// 启动服务器
console.log(JSON.stringify(server));
```

### 在 Claude Code 中配置

编辑 `~/.claude/settings.json`:

```json
{
  "mcpServers": {
    "ai-manager": {
      "command": "node",
      "args": ["~/.claude/mcp-servers/ai-manager.js"]
    }
  }
}
```

### 在对话框中使用

```
你：@ai-manager check_status

Claude：🤖 AI 管理系统状态报告
========================
主 AI 状态: 🟢 运行中
管理 AI 状态: ⚪️ 空闲
当前提供商: Claude (默认)
健康状态: ✅ 健康
```

```
你：@ai-manager fix_problem "Xcode 虚拟机检测失败"

Claude：🔍 分析问题...
🌐 搜索解决方案...
✅ 找到 3 个解决方案
💡 最佳方案：使用 VMHide 内核扩展
```

---

## 方法 4: 创建简单的 Web 界面

### 创建 HTML 界面

创建 `ai-manager-ui.html`:

```html
<!DOCTYPE html>
<html>
<head>
    <title>AI 管理器</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, sans-serif;
            max-width: 800px;
            margin: 50px auto;
            padding: 20px;
        }
        .status { padding: 20px; background: #f0f0f0; border-radius: 8px; }
        .button {
            background: #007AFF;
            color: white;
            padding: 10px 20px;
            border: none;
            border-radius: 8px;
            margin: 5px;
            cursor: pointer;
        }
        .button:hover { background: #0051D5; }
        #output {
            margin-top: 20px;
            padding: 20px;
            background: #1e1e1e;
            color: #d4d4d4;
            border-radius: 8px;
            font-family: 'Monaco', monospace;
            white-space: pre-wrap;
        }
    </style>
</head>
<body>
    <h1>🤖 AI 管理器控制面板</h1>

    <div class="status" id="status">
        <h2>状态</h2>
        <p id="statusText">等待检查...</p>
    </div>

    <h2>操作</h2>
    <button class="button" onclick="checkStatus()">📊 检查状态</button>
    <button class="button" onclick="switchProvider('deepseek')">⚡ 快速模式</button>
    <button class="button" onclick="switchProvider('ollama')">💻 本地模式</button>
    <button class="button" onclick="switchProvider('default')">🔄 默认模式</button>

    <h2>解决问题</h2>
    <input type="text" id="problemInput" placeholder="描述问题..." style="width: 70%; padding: 10px;">
    <button class="button" onclick="fixProblem()">🔧 解决</button>

    <div id="output"></div>

    <script>
        const API_URL = 'http://localhost:3456';

        async function checkStatus() {
            try {
                const response = await fetch(`${API_URL}/status`);
                const data = await response.json();
                document.getElementById('statusText').textContent =
                    `主 AI: ${data.mainAI}\n管理 AI: ${data.managerAI}\n提供商: ${data.provider}`;
                log('✅ 状态检查完成');
            } catch (error) {
                log('❌ 错误: ' + error.message);
            }
        }

        async function switchProvider(provider) {
            try {
                const response = await fetch(`${API_URL}/switch`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ provider })
                });
                const data = await response.json();
                log(`✅ 已切换到: ${provider}`);
                checkStatus();
            } catch (error) {
                log('❌ 错误: ' + error.message);
            }
        }

        async function fixProblem() {
            const problem = document.getElementById('problemInput').value;
            if (!problem) {
                alert('请输入问题描述');
                return;
            }

            try {
                log('🔍 分析问题中...');
                const response = await fetch(`${API_URL}/fix`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ problem })
                });
                const data = await response.json();

                log('✅ 解决方案：\n' + data.solution);
                log('步骤：');
                data.steps.forEach((step, i) => {
                    log(`  ${i+1}. ${step}`);
                });
            } catch (error) {
                log('❌ 错误: ' + error.message);
            }
        }

        function log(message) {
            const output = document.getElementById('output');
            const time = new Date().toLocaleTimeString();
            output.textContent += `[${time}] ${message}\n`;
            output.scrollTop = output.scrollHeight;
        }

        // 页面加载时检查状态
        window.onload = checkStatus;
    </script>
</body>
</html>
```

### 启动 Web 界面

```bash
# 在浏览器中打开
open ai-manager-ui.html

# 或使用 Python 启动本地服务器
python3 -m http.server 8080
# 然后访问 http://localhost:8080/ai-manager-ui.html
```

---

## 方法 5: 最简单 - 直接对话

如果你只是想在 Claude 对话中描述问题，可以这样：

### 在 Claude App 中输入

```
我遇到一个问题：Xcode 编译失败，显示虚拟机检测错误。

请帮我：
1. 分析这个问题
2. 搜索解决方案
3. 给我详细步骤

使用 AI 管理器的网络自动切换功能来确保搜索成功。
```

Claude 会：
1. 理解你的需求
2. 使用合适的搜索引擎
3. 如果遇到网络问题，自动切换
4. 返回详细的解决方案

---

## 📱 推荐设置：创建专用快捷指令

### 快捷指令 1: "AI 状态"

```
操作流程：
1. 运行 Shell 脚本
   curl http://localhost:3456/status

2. 显示结果
   显示通知
```

使用：在任何地方说 "嘿 Siri，AI 状态"

### 快捷指令 2: "AI 修复"

```
操作流程：
1. 请求输入
   提示: "描述问题"

2. 运行 Shell 脚本
   curl -X POST http://localhost:3456/fix \
        -H "Content-Type: application/json" \
        -d "{\"problem\": \"输入的问题\"}"

3. 显示结果
   显示通知（包含解决方案）
```

使用：说 "嘿 Siri，AI 修复"，然后描述问题

### 快捷指令 3: "快速模式"

```
操作流程：
1. 运行 Shell 脚本
   curl -X POST http://localhost:3456/switch \
        -H "Content-Type: application/json" \
        -d "{\"provider\": \"deepseek\"}"

2. 显示结果
   显示通知 "已切换到快速模式"
```

使用：说 "嘿 Siri，快速模式"

---

## 🎮 控制中心小组件（iOS 18+）

如果你使用 iOS 18+，可以添加控制中心小组件：

### 创建 Widget

```swift
import WidgetKit
import SwiftUI

struct AIManagerWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "AIManager", provider: Provider()) { entry in
            AIManagerView(entry: entry)
        }
        .configurationDisplayName("AI 管理器")
        .description("快速查看 AI 状态")
        .supportedFamilies([.systemSmall])
    }
}

struct AIManagerView: View {
    let entry: Provider.Entry

    var body: some View {
        VStack {
            Text("🤖 AI 管理器")
            Text(entry.status)
            Button("刷新") {
                // 刷新状态
            }
        }
    }
}
```

使用：在控制中心滑动即可查看 AI 状态

---

## ⚡ 一键使用脚本

创建 `ai-manager.sh`:

```bash
#!/bin/bash

# AI 管理器一键脚本

case "$1" in
    status)
        curl -s http://localhost:3456/status | jq .
        ;;
    fix)
        if [ -z "$2" ]; then
            echo "用法: ai-manager.sh fix '问题描述'"
            exit 1
        fi
        curl -s -X POST http://localhost:3456/fix \
             -H "Content-Type: application/json" \
             -d "{\"problem\": \"$2\"}" | jq .
        ;;
    switch)
        if [ -z "$2" ]; then
            echo "用法: ai-manager.sh switch [default|deepseek|ollama|gemini]"
            exit 1
        fi
        curl -s -X POST http://localhost:3456/switch \
             -H "Content-Type: application/json" \
             -d "{\"provider\": \"$2\"}" | jq .
        ;;
    *)
        echo "AI 管理器命令行工具"
        echo ""
        echo "用法:"
        echo "  ai-manager.sh status              - 检查状态"
        echo "  ai-manager.sh fix '问题描述'      - 解决问题"
        echo "  ai-manager.sh switch deepseek     - 切换提供商"
        ;;
esac
```

使用：

```bash
chmod +x ai-manager.sh

# 检查状态
./ai-manager.sh status

# 解决问题
./ai-manager.sh fix "Xcode 编译失败"

# 切换提供商
./ai-manager.sh switch deepseek
```

---

## 🎯 最简单的方法（推荐新手）

### 步骤 1: 安装和启动

```bash
# 安装
npm install -g claude-code-router

# 启动
ccr start --daemon
```

### 步骤 2: 在 Claude App 中直接对话

```
你：我的 Xcode 无法编译，提示虚拟机检测失败

Claude：我来帮你解决这个问题。

[自动使用 AI 管理器]
- 检测到问题：虚拟机检测
- 搜索解决方案...
- 找到 3 个方案

最佳解决方案：
1. 使用 VMHide 内核扩展
2. 下载链接：...
3. 安装步骤：...

需要我详细解释某个步骤吗？
```

---

## 📌 小结

**最推荐的方式**：

| 方式 | 适用场景 | 难度 |
|------|---------|------|
| **Siri 快捷指令** | 日常快速使用 | ⭐ 简单 |
| **直接对话** | 详细问题讨论 | ⭐ 简单 |
| **命令行脚本** | 开发者 | ⭐⭐ 中等 |
| **Web 界面** | 可视化控制 | ⭐⭐⭐ 复杂 |

**推荐组合**：
- 日常使用：Siri 快捷指令
- 复杂问题：直接在 Claude 对话
- 开发调试：命令行脚本

---

**现在你可以直接在 Claude App 中使用 AI 管理器了！** 🎉
