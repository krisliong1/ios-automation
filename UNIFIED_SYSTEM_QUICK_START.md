# 🚀 统一系统快速开始指南

## 你现在拥有的完整系统

✅ **跨平台终端自动化** - macOS, Linux, iOS, Windows 真实命令执行
✅ **iOS AI 管理器** - 自动监控和问题解决
✅ **AI Fixer 系统** - 智能错误修复
✅ **iCloud 自动同步** - 所有数据统一存储
✅ **完整历史记录** - 每条命令都有记录

---

## 📥 1. 下载完整系统

```bash
# 克隆仓库
git clone -b claude/ios-automation-shortcuts-gsEpf \
  https://github.com/krisliong1/ios-automation.git
cd ios-automation/
```

---

## 🔧 2. 生成配置（首次使用）

```bash
# 运行配置生成器
python3 generate_unified_config.py

# 这会创建：
# ~/Library/Mobile Documents/com~apple~CloudDocs/kris-server/
#   ├── ios-automation/
#   ├── ai-systems/
#   ├── terminal-sessions/
#   ├── automation-logs/
#   ├── shared-config/
#   └── sync-status/
```

输出示例：
```
======================================================================
Unified System Configuration Generator
======================================================================

iCloud root path [~/Library/Mobile Documents/com~apple~CloudDocs/kris-server]:
# 直接按 Enter 使用默认路径

Creating directory structure...
✅ Created: ~/Library/Mobile Documents/com~apple~CloudDocs/kris-server/ios-automation
✅ Created: ~/Library/Mobile Documents/com~apple~CloudDocs/kris-server/ai-systems
...

Generating configuration files...
✅ Generated: Main Unified Configuration
✅ Generated: iCloud Sync Configuration
✅ Generated: AI Manager Configuration
...

✅ Configuration generation complete!
```

---

## 🚀 3. 启动统一系统

```bash
# 运行主程序
python3 unified_system.py
```

你会看到：
```
╔══════════════════════════════════════════════════════════════════════╗
║                                                                      ║
║              Kris Automation Center - Unified System                ║
║                                                                      ║
║  Cross-platform terminal automation with iCloud integration         ║
║  Supporting: macOS, Linux, iOS, Windows                             ║
║                                                                      ║
╚══════════════════════════════════════════════════════════════════════╝

iCloud Root: ~/Library/Mobile Documents/com~apple~CloudDocs/kris-server
Initializing system...
✅ System initialized successfully!
✅ All commands will be saved to iCloud automatically
✅ Started session: a1b2c3d4-e5f6-7890-1234-567890abcdef

──────────────────────────────────────────────────────────────────────
MAIN MENU
──────────────────────────────────────────────────────────────────────
1. Execute command (current platform)
2. Execute on macOS
3. Execute on Linux
4. Execute on iOS
5. Execute on Windows (PowerShell)

6. View session history
7. View all sessions
8. Search history
9. View statistics

10. Sync to iCloud now
11. View iCloud status
12. System configuration

0. Exit
──────────────────────────────────────────────────────────────────────
Select option:
```

---

## 💡 4. 实际使用示例

### 示例 1: 在 macOS 上执行命令

```
Select option: 2

Enter command: ls -la /Users

Executing: ls -la /Users
Platform: macos

──────────────────────────────────────────────────────────────────────
✅ SUCCESS
Exit Code: 0

Output:
total 0
drwxr-xr-x   5 root  admin  160 Jan 20 10:00 .
drwxr-xr-x  20 root  wheel  640 Jan 20 09:00 ..
drwxr-xr-x+ 25 user  staff  800 Jan 20 10:30 user
...

──────────────────────────────────────────────────────────────────────
✅ Saved to iCloud: ~/Library/Mobile Documents/com~apple~CloudDocs/kris-server/terminal-sessions/
```

### 示例 2: 在 Linux 上执行命令

```
Select option: 3

Enter command: ps aux | grep python

Executing: ps aux | grep python
Platform: linux

──────────────────────────────────────────────────────────────────────
✅ SUCCESS
Exit Code: 0

Output:
user     1234  0.1  0.5  123456  12345 pts/0    S+   10:00   0:00 python3 unified_system.py
...

──────────────────────────────────────────────────────────────────────
✅ Saved to iCloud: ~/Library/Mobile Documents/com~apple~CloudDocs/kris-server/terminal-sessions/
```

### 示例 3: 查看历史

```
Select option: 6

══════════════════════════════════════════════════════════════════════
SESSION: a1b2c3d4-e5f6-7890-1234-567890abcdef
══════════════════════════════════════════════════════════════════════
Platform: linux
Created: 2026-01-20T10:00:00
Commands: 5

1. 2026-01-20T10:01:00
   Command: echo 'Hello World'
   Status: ✅ Success

2. 2026-01-20T10:02:00
   Command: pwd
   Status: ✅ Success

3. 2026-01-20T10:03:00
   Command: ls -la
   Status: ✅ Success

4. 2026-01-20T10:04:00
   Command: ps aux | grep python
   Status: ✅ Success

5. 2026-01-20T10:05:00
   Command: df -h
   Status: ✅ Success
```

### 示例 4: 搜索历史

```
Select option: 8

Search query: python

Searching for: python

✅ Found 3 results
══════════════════════════════════════════════════════════════════════

1. 2026-01-20T10:04:00
   Platform: linux
   Command: ps aux | grep python
   Session: a1b2c3d4-e5f6-7890-1234-567890abcdef

2. 2026-01-20T09:30:00
   Platform: macos
   Command: which python3
   Session: xyz123...

3. 2026-01-20T08:15:00
   Platform: linux
   Command: python3 --version
   Session: abc456...
```

### 示例 5: 查看统计

```
Select option: 9

══════════════════════════════════════════════════════════════════════
SYSTEM STATISTICS
══════════════════════════════════════════════════════════════════════
Total Sessions: 12
Total Commands: 47

Platform Distribution:
  macos: 5 sessions
  linux: 4 sessions
  ios: 2 sessions
  powershell: 1 sessions

iCloud Root: ~/Library/Mobile Documents/com~apple~CloudDocs/kris-server
```

---

## 📂 5. 查看 iCloud 中的数据

```bash
# 打开 Finder 查看 iCloud 数据
open ~/Library/Mobile\ Documents/com~apple~CloudDocs/kris-server/

# 查看终端会话
open ~/Library/Mobile\ Documents/com~apple~CloudDocs/kris-server/terminal-sessions/

# 查看配置
open ~/Library/Mobile\ Documents/com~apple~CloudDocs/kris-server/shared-config/
```

你会看到：
```
kris-server/
├── terminal-sessions/
│   ├── macos/
│   │   ├── a1b2c3d4-e5f6-7890-1234-567890abcdef.json
│   │   └── ...
│   ├── linux/
│   │   └── ...
│   ├── ios/
│   └── windows/
├── shared-config/
│   ├── unified-config.json
│   └── icloud-sync.json
└── automation-logs/
```

### 会话文件示例 (JSON)

```json
{
  "session_id": "a1b2c3d4-e5f6-7890-1234-567890abcdef",
  "platform": "macos",
  "created_at": "2026-01-20T10:00:00",
  "commands": [
    {
      "timestamp": "2026-01-20T10:01:00",
      "command": "ls -la /Users",
      "result": {
        "success": true,
        "output": "total 0\ndrwxr-xr-x   5 root  admin  160...",
        "error": "",
        "exit_code": 0,
        "platform": "macos",
        "session_id": "a1b2c3d4-e5f6-7890-1234-567890abcdef"
      }
    }
  ],
  "last_updated": "2026-01-20T10:01:00"
}
```

---

## 🔧 6. 高级使用

### 6.1 编程方式使用

```python
#!/usr/bin/env python3
from src.unified_terminal import UnifiedTerminalSystem

# 初始化系统
system = UnifiedTerminalSystem(
    icloud_root="~/Library/Mobile Documents/com~apple~CloudDocs/kris-server"
)

# 在不同平台执行命令
result = system.execute_on_macos("ls -la /Users")
print(f"macOS: {result['output']}")

result = system.execute_on_linux("ps aux | grep python")
print(f"Linux: {result['output']}")

result = system.execute_on_ios("ls /var/mobile")
print(f"iOS: {result['output']}")

# 查看历史
history = system.get_session_history()
print(f"Executed {len(history['commands'])} commands")

# 搜索
results = system.search_history("python")
print(f"Found {len(results)} commands with 'python'")
```

### 6.2 自动化脚本

```python
#!/usr/bin/env python3
"""自动化巡检脚本"""

from src.unified_terminal import UnifiedTerminalSystem

system = UnifiedTerminalSystem(
    icloud_root="~/Library/Mobile Documents/com~apple~CloudDocs/kris-server"
)

# 巡检所有平台
platforms = ["macos", "linux"]
checks = [
    ("磁盘空间", "df -h"),
    ("内存使用", "free -m"),
    ("进程数量", "ps aux | wc -l"),
    ("网络连接", "netstat -an | grep ESTABLISHED | wc -l")
]

for platform in platforms:
    print(f"\n=== {platform.upper()} 巡检 ===")

    for name, command in checks:
        result = system.execute_command(command, platform)
        print(f"{name}: {result['output'].strip()}")

# 所有结果自动保存到 iCloud！
print("\n✅ 巡检完成，结果已保存到 iCloud")
```

---

## 📱 7. 多设备同步

### 在 Mac 上执行命令
```bash
# Mac 1
python3 unified_system.py
# 执行一些命令...
```

### 在另一台 Mac 或 iPhone 上查看
```bash
# Mac 2 或 iPhone (通过 iCloud Drive)
# 所有会话自动同步！

python3 unified_system.py
# 选择 "7. View all sessions"
# 你会看到来自 Mac 1 的所有命令历史
```

---

## 🎯 8. 常见使用场景

### 场景 1: 多平台部署
```python
# 部署脚本到所有平台
commands = [
    "git pull origin main",
    "pip install -r requirements.txt",
    "python manage.py migrate"
]

for cmd in commands:
    for platform in ["macos", "linux"]:
        result = system.execute_command(cmd, platform)
        print(f"{platform}: {cmd} - {'✅' if result['success'] else '❌'}")
```

### 场景 2: 健康监控
```python
# 定期检查系统健康
import schedule
import time

def health_check():
    result = system.execute_on_linux("uptime")
    print(f"系统负载: {result['output']}")
    # 自动保存到 iCloud

schedule.every(5).minutes.do(health_check)

while True:
    schedule.run_pending()
    time.sleep(1)
```

### 场景 3: iOS 设备管理
```python
# 管理连接的 iOS 设备
result = system.execute_on_ios("ls -la /var/mobile/Applications")

# 安装 app
result = system.execute_on_ios("ideviceinstaller -i app.ipa")

# 所有操作保存到 iCloud
```

---

## ⚙️ 9. 配置自定义

### 修改 iCloud 路径
```bash
# 编辑配置
nano ~/Library/Mobile\ Documents/com~apple~CloudDocs/kris-server/shared-config/unified-config.json

# 或设置环境变量
export ICLOUD_ROOT="/path/to/your/icloud"
python3 unified_system.py
```

### 添加自定义平台
```python
# 在 unified-config.json 中添加
{
  "terminals": {
    "raspberry-pi": {
      "enabled": true,
      "shell": "/bin/bash",
      "working_dir": "${ICLOUD_ROOT}/terminal-sessions/raspberry-pi"
    }
  }
}
```

---

## 🔍 10. 故障排查

### 问题：iCloud 同步失败
```bash
# 检查 iCloud 状态
ls -la ~/Library/Mobile\ Documents/com~apple~CloudDocs/

# 查看同步状态
python3 unified_system.py
# 选择 "11. View iCloud status"
```

### 问题：命令执行失败
```python
# 查看详细日志
tail -f unified_system.log

# 或在代码中启用 DEBUG 日志
import logging
logging.basicConfig(level=logging.DEBUG)
```

### 问题：找不到会话
```bash
# 检查会话文件
ls -la ~/Library/Mobile\ Documents/com~apple~CloudDocs/kris-server/terminal-sessions/*/
```

---

## 📚 11. 下一步

1. **集成 AI Manager** - 让 AI 自动管理命令执行
2. **设置自动化脚本** - 定期巡检、备份等
3. **多设备协同** - 在 Mac、iPhone、iPad 上同步使用
4. **扩展到更多平台** - 添加 Raspberry Pi、Android 等

---

## 🎉 总结

现在你有了一个**完全统一的跨平台自动化系统**：

✅ 在 macOS、Linux、iOS、Windows 上执行真实命令
✅ 所有历史记录自动保存到 iCloud
✅ 多设备自动同步
✅ 完整的搜索和统计功能
✅ 可编程接口，可以写自动化脚本

**一个命令行，管理所有平台！** 🚀

---

## 🔗 相关文档

- [完整架构文档](UNIFIED_SYSTEM_ARCHITECTURE.md)
- [平台支持清单](PLATFORM_SUPPORT_CHECKLIST.md)
- [Release 说明](RELEASE_NOTES.md)
- [下载安装指南](DOWNLOAD_AND_INSTALL.md)

**开始使用**: `python3 unified_system.py` 🎊
