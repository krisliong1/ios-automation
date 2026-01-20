# 统一系统架构 - Kris 自动化中心

## 🎯 统一目标

创建一个**完全集成的跨平台自动化系统**，所有组件统一存储在 iCloud，能够真实执行命令。

---

## 📂 统一存储架构

### iCloud Drive 中心路径
```
https://www.icloud.com/iclouddrive/0e7KCurZSjkFkwRT64abohF2g#kris-server

本地映射路径：
~/Library/Mobile Documents/com~apple~CloudDocs/kris-server/
```

### 目录结构
```
kris-server/                                 # iCloud 根目录
├── ios-automation/                          # 主项目（本仓库）
│   ├── Sources/                             # Swift 核心模块
│   ├── src/                                 # Python 终端系统
│   ├── examples/                            # 示例和工具
│   ├── data/                                # 运行时数据
│   └── config/                              # 配置文件
│
├── ai-systems/                              # AI 系统集合
│   ├── ai-manager/                          # AI 管理器运行时
│   ├── ai-fixer/                            # AI Fixer 数据
│   ├── claude-router/                       # Claude 路由配置
│   └── models/                              # AI 模型缓存
│
├── terminal-sessions/                       # 终端会话存储
│   ├── macos/                               # macOS 会话
│   ├── linux/                               # Linux 会话
│   ├── ios/                                 # iOS 会话
│   └── windows/                             # Windows 会话
│
├── automation-logs/                         # 自动化日志
│   ├── execution-history/                   # 执行历史
│   ├── error-logs/                          # 错误日志
│   └── performance/                         # 性能监控
│
├── shared-config/                           # 共享配置
│   ├── global-settings.json                 # 全局设置
│   ├── credentials.encrypted.json           # 加密凭证
│   ├── api-keys.encrypted.json              # API 密钥
│   └── preferences.json                     # 用户偏好
│
└── sync-status/                             # 同步状态
    ├── last-sync.json                       # 最后同步时间
    ├── conflicts/                           # 冲突处理
    └── version-control.json                 # 版本控制
```

---

## 🏗️ 系统架构

### 1. 核心层 (Core Layer)
```
统一配置管理 (Unified Config Manager)
    ↓
iCloud 同步引擎 (iCloud Sync Engine)
    ↓
数据存储层 (Data Storage Layer)
```

### 2. 功能层 (Function Layer)
```
┌─────────────────────────────────────────────────┐
│  iOS AI 管理器 (Swift)                           │
│  - AIManager                                    │
│  - SecurityManager                              │
│  - NetworkManager                               │
│  - TranslationManager                           │
└─────────────────────────────────────────────────┘
           ↓
┌─────────────────────────────────────────────────┐
│  跨平台终端系统 (Python)                         │
│  - macOS Terminal                               │
│  - Linux Terminal                               │
│  - iOS Terminal                                 │
│  - PowerShell Terminal                          │
└─────────────────────────────────────────────────┘
           ↓
┌─────────────────────────────────────────────────┐
│  AI Fixer 系统                                   │
│  - Kris AI Fixer                                │
│  - AI Learning                                  │
│  - Claude Code Router                           │
└─────────────────────────────────────────────────┘
```

### 3. 执行层 (Execution Layer)
```
实时终端执行器 → 命令队列 → 结果收集器 → iCloud 存储
```

---

## 🔧 核心配置文件

### 1. 主配置文件 (`config/unified-config.json`)
```json
{
  "version": "1.0.0",
  "system_name": "Kris Automation Center",
  "icloud": {
    "enabled": true,
    "root_path": "~/Library/Mobile Documents/com~apple~CloudDocs/kris-server",
    "sync_interval": 300,
    "auto_sync": true,
    "conflict_resolution": "keep_both"
  },
  "storage": {
    "primary": "icloud",
    "fallback": "local",
    "cache_enabled": true,
    "cache_size_mb": 500
  },
  "terminals": {
    "macos": {
      "enabled": true,
      "shell": "/bin/zsh",
      "working_dir": "${ICLOUD_ROOT}/terminal-sessions/macos"
    },
    "linux": {
      "enabled": true,
      "shell": "/bin/bash",
      "working_dir": "${ICLOUD_ROOT}/terminal-sessions/linux"
    },
    "ios": {
      "enabled": true,
      "working_dir": "${ICLOUD_ROOT}/terminal-sessions/ios",
      "device_auto_detect": true
    },
    "windows": {
      "enabled": true,
      "shell": "powershell.exe",
      "working_dir": "${ICLOUD_ROOT}/terminal-sessions/windows"
    }
  },
  "ai_systems": {
    "ai_manager": {
      "enabled": true,
      "config_path": "${ICLOUD_ROOT}/ai-systems/ai-manager/config.json",
      "log_path": "${ICLOUD_ROOT}/automation-logs/ai-manager"
    },
    "ai_fixer": {
      "enabled": true,
      "config_path": "${ICLOUD_ROOT}/ai-systems/ai-fixer/config.json",
      "learning_data": "${ICLOUD_ROOT}/ai-systems/ai-fixer/learning"
    },
    "claude_router": {
      "enabled": true,
      "config_path": "${ICLOUD_ROOT}/ai-systems/claude-router/config.json",
      "providers": ["anthropic", "openrouter", "deepseek", "ollama", "gemini"]
    }
  },
  "logging": {
    "enabled": true,
    "level": "INFO",
    "path": "${ICLOUD_ROOT}/automation-logs",
    "max_size_mb": 100,
    "rotation": "daily"
  },
  "security": {
    "encryption_enabled": true,
    "credentials_path": "${ICLOUD_ROOT}/shared-config/credentials.encrypted.json",
    "api_keys_path": "${ICLOUD_ROOT}/shared-config/api-keys.encrypted.json"
  }
}
```

### 2. iCloud 同步配置 (`config/icloud-sync.json`)
```json
{
  "sync_rules": {
    "Sources/": {
      "priority": "high",
      "bidirectional": true,
      "conflict_resolution": "manual"
    },
    "src/": {
      "priority": "high",
      "bidirectional": true,
      "conflict_resolution": "manual"
    },
    "data/": {
      "priority": "medium",
      "bidirectional": true,
      "conflict_resolution": "latest"
    },
    "automation-logs/": {
      "priority": "low",
      "bidirectional": false,
      "upload_only": true
    },
    "terminal-sessions/": {
      "priority": "high",
      "bidirectional": true,
      "conflict_resolution": "timestamp"
    }
  },
  "exclude": [
    ".git/",
    "node_modules/",
    "__pycache__/",
    ".DS_Store",
    "*.pyc",
    "build/",
    ".build/"
  ],
  "bandwidth": {
    "max_upload_mbps": 10,
    "max_download_mbps": 20,
    "throttle_on_mobile": true
  }
}
```

---

## 🚀 可执行终端系统

### 架构设计

```python
# unified_terminal.py - 统一可执行终端系统

class UnifiedTerminalSystem:
    """统一终端系统 - 真实可执行"""

    def __init__(self, icloud_root):
        self.icloud_root = Path(icloud_root)
        self.config = self.load_config()
        self.terminals = self.init_terminals()
        self.session_manager = SessionManager(self.icloud_root)
        self.sync_engine = iCloudSyncEngine(self.icloud_root)

    def execute_command(self, command, platform="auto"):
        """真实执行命令并记录到 iCloud"""

        # 1. 选择目标平台
        terminal = self.select_terminal(platform)

        # 2. 记录命令到会话
        session_id = self.session_manager.create_session(platform)

        # 3. 执行命令
        result = terminal.execute(command)

        # 4. 保存结果到 iCloud
        self.save_to_icloud(session_id, command, result)

        # 5. 触发同步
        self.sync_engine.sync_now()

        return result

    def save_to_icloud(self, session_id, command, result):
        """保存到 iCloud"""
        session_path = (
            self.icloud_root /
            f"terminal-sessions/{result['platform']}/{session_id}.json"
        )

        session_data = {
            "session_id": session_id,
            "timestamp": datetime.now().isoformat(),
            "command": command,
            "result": result,
            "platform": result['platform']
        }

        with open(session_path, 'w') as f:
            json.dump(session_data, f, indent=2)
```

### 实际使用示例

```python
from unified_terminal import UnifiedTerminalSystem

# 初始化系统（指向 iCloud）
system = UnifiedTerminalSystem(
    icloud_root="~/Library/Mobile Documents/com~apple~CloudDocs/kris-server"
)

# 在 macOS 上执行命令 - 真实执行！
result = system.execute_command("ls -la /Users", platform="macos")
# 结果自动保存到 iCloud

# 在 Linux 上执行命令 - 真实执行！
result = system.execute_command("ps aux | grep python", platform="linux")
# 结果自动保存到 iCloud

# 在 iOS 设备上执行 - 真实执行！
result = system.execute_command("ls /var/mobile", platform="ios")
# 结果自动保存到 iCloud

# 查看所有历史
history = system.session_manager.get_all_sessions()
# 从 iCloud 读取
```

---

## 🔗 组件集成

### 1. Swift iOS 工具 ↔ Python 终端系统

```swift
// Swift 调用 Python 终端
import Foundation

class SwiftPythonBridge {
    func executeTerminalCommand(_ command: String, platform: String) async -> Result {
        let python = Process()
        python.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        python.arguments = [
            "unified_terminal.py",
            "--command", command,
            "--platform", platform,
            "--icloud-root", "~/Library/Mobile Documents/com~apple~CloudDocs/kris-server"
        ]

        // 执行并获取结果
        let result = try await python.run()

        // 结果已自动保存到 iCloud
        return result
    }
}
```

### 2. AI Manager ↔ 终端系统

```python
# AI Manager 可以调用终端执行命令
from ai_manager import AIManager
from unified_terminal import UnifiedTerminalSystem

ai = AIManager()
terminal = UnifiedTerminalSystem(icloud_root="...")

# AI 决定需要执行什么命令
command = ai.decide_command()

# 执行命令
result = terminal.execute_command(command, platform="auto")

# AI 分析结果
ai.analyze_result(result)

# 所有数据都在 iCloud
```

### 3. 所有组件共享配置

```
所有组件都从 iCloud 读取配置：
${ICLOUD_ROOT}/shared-config/global-settings.json

这样：
- Swift iOS 工具
- Python 终端系统
- AI Manager
- AI Fixer
- Claude Router

都使用相同的配置，完全统一！
```

---

## 📊 数据流

```
用户输入命令
    ↓
统一终端系统
    ↓
选择平台 (macOS/Linux/iOS/Windows)
    ↓
真实执行命令
    ↓
捕获结果
    ↓
保存到 iCloud (kris-server/terminal-sessions/)
    ↓
触发同步
    ↓
AI Manager 分析 (可选)
    ↓
日志记录到 iCloud (kris-server/automation-logs/)
    ↓
完成
```

---

## 🔐 安全和权限

### 凭证管理
```json
// ${ICLOUD_ROOT}/shared-config/credentials.encrypted.json
{
  "version": "1.0.0",
  "encryption": "AES-256-GCM",
  "credentials": {
    "anthropic_api_key": "encrypted_value",
    "openrouter_api_key": "encrypted_value",
    "icloud_auth": "encrypted_value",
    "ssh_keys": {
      "linux_server": "encrypted_value",
      "ios_device": "encrypted_value"
    }
  }
}
```

### 访问控制
- iCloud 账户认证
- 本地 Keychain 集成
- 双因素认证支持
- 设备授权管理

---

## 🎯 实现步骤

### 阶段 1: iCloud 集成 (1-2 天)
- [x] 创建 iCloud 目录结构
- [ ] 实现 iCloud 同步引擎
- [ ] 配置文件迁移
- [ ] 测试同步功能

### 阶段 2: 统一配置 (1 天)
- [ ] 创建全局配置文件
- [ ] 所有组件读取统一配置
- [ ] 凭证加密存储
- [ ] 配置验证和测试

### 阶段 3: 可执行终端系统 (2-3 天)
- [ ] 实现 UnifiedTerminalSystem
- [ ] 真实命令执行
- [ ] 会话管理
- [ ] 结果持久化到 iCloud

### 阶段 4: 组件集成 (2-3 天)
- [ ] Swift ↔ Python 桥接
- [ ] AI Manager 集成
- [ ] AI Fixer 集成
- [ ] Claude Router 集成

### 阶段 5: 测试和优化 (1-2 天)
- [ ] 端到端测试
- [ ] 性能优化
- [ ] 错误处理
- [ ] 文档完善

---

## 📝 下一步行动

### 立即开始：

1. **创建 iCloud 目录结构**
   ```bash
   mkdir -p ~/Library/Mobile\ Documents/com~apple~CloudDocs/kris-server/{ios-automation,ai-systems,terminal-sessions,automation-logs,shared-config,sync-status}
   ```

2. **生成配置文件**
   ```bash
   python generate_unified_config.py
   ```

3. **实现同步引擎**
   ```bash
   python implement_icloud_sync.py
   ```

4. **测试系统**
   ```bash
   python test_unified_system.py
   ```

---

## 🎉 最终效果

用户可以：
1. **统一入口**：一个命令行或 GUI 界面控制所有
2. **真实执行**：不只是代码，而是真的能执行命令
3. **跨平台**：macOS、Linux、iOS、Windows 统一管理
4. **iCloud 同步**：所有数据、配置、日志都在 iCloud
5. **AI 集成**：AI Manager、AI Fixer、Claude Router 协同工作
6. **历史追踪**：所有操作都有记录，可随时查看
7. **多设备**：Mac、iPhone、iPad 都能访问和控制

**一个真正统一的自动化中心！** 🚀
