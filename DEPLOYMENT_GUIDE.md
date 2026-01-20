# 🚀 部署指南 - 完整 Server-Agent 系统

## 重要说明

**iCloud 的角色**：
- ✅ **只用于存储数据**（配置、历史、日志）
- ❌ **不能运行代码**
- ❌ **不能作为服务器**

**需要真实服务器**来运行 `kris_server.py`！

---

## 📐 系统架构

```
┌──────────────────────────────────────────┐
│  真实服务器（必须！）                       │
│  你的 Mac / Linux 服务器 / 云服务器         │
│                                          │
│  运行: python3 server/kris_server.py     │
│                                          │
│  功能：                                   │
│  - 接收命令请求                           │
│  - 分发到各平台 Agent                     │
│  - 收集执行结果                           │
│  - 保存数据到 iCloud                      │
└──────────────────────────────────────────┘
         ↓ 保存                  ↓ 通信
┌──────────────────┐    ┌───────────────────┐
│   iCloud Drive   │    │  平台 Agents      │
│   (数据存储)      │    │                   │
│                  │    │  Mac Agent        │
│  kris-server/    │    │  Linux Agent      │
│  ├─ configs/     │    │  iOS Agent        │
│  ├─ sessions/    │    │  Windows Agent    │
│  └─ logs/        │    └───────────────────┘
└──────────────────┘
```

---

## 🎯 3 种部署方案

### 方案 A: Mac 作为服务器（推荐）⭐⭐⭐⭐⭐

**适合**：
- 你有一台 Mac 可以长时间运行
- 主要在家里/办公室使用
- 最简单的设置

**部署步骤**：

#### 1. 在你的 Mac 上启动服务器

```bash
cd ~/ios-automation

# 启动服务器（在后台运行）
nohup python3 server/kris_server.py \
  ~/Library/Mobile\ Documents/com~apple~CloudDocs/kris-server \
  8765 > server.log 2>&1 &

# 查看日志
tail -f server.log
```

你会看到：
```
======================================================================
🚀 Kris Server Starting...
======================================================================
📍 Host: 0.0.0.0
📍 Port: 8765
📂 iCloud Root: ~/Library/Mobile Documents/com~apple~CloudDocs/kris-server
======================================================================
✅ Server ready on ws://0.0.0.0:8765
⏳ Waiting for agents to connect...
```

#### 2. 在同一台 Mac 上启动 Agent

```bash
# 新终端窗口
python3 agent/kris_agent.py ws://localhost:8765
```

输出：
```
======================================================================
🤖 Kris Agent Starting...
======================================================================
📍 Platform: macos
🔗 Server: ws://localhost:8765
======================================================================
🔌 Connecting to server...
📤 Registration sent
✅ Registered with server
⏳ Waiting for commands...
```

#### 3. 在 Linux 服务器上启动 Agent

```bash
# SSH 到你的 Linux 服务器
ssh user@linux-server

# 下载 agent
scp ~/ios-automation/agent/kris_agent.py user@linux-server:~/

# 启动 agent（替换为你 Mac 的 IP）
python3 kris_agent.py ws://你的Mac的IP:8765
```

#### 4. 在 iPhone 上启动 Agent（可选）

需要在 iPhone 上安装 Python（通过 Pythonista 或 a-Shell）：

```bash
# 在 Pythonista 或 a-Shell 中
python3 kris_agent.py ws://你的Mac的IP:8765 ios
```

---

### 方案 B: 专门的 24/7 服务器 ⭐⭐⭐⭐

**适合**：
- 你有云服务器（AWS, Azure, DigitalOcean）
- 需要随时随地访问
- 需要高可用性

**部署步骤**：

#### 1. 在云服务器上部署

```bash
# SSH 到服务器
ssh user@your-server.com

# 克隆代码
git clone -b claude/ios-automation-shortcuts-gsEpf \
  https://github.com/krisliong1/ios-automation.git
cd ios-automation/

# 安装依赖
pip3 install websockets

# 使用 systemd 创建服务
sudo nano /etc/systemd/system/kris-server.service
```

服务文件内容：
```ini
[Unit]
Description=Kris Server
After=network.target

[Service]
Type=simple
User=your-user
WorkingDirectory=/home/your-user/ios-automation
ExecStart=/usr/bin/python3 server/kris_server.py /path/to/icloud 8765
Restart=always

[Install]
WantedBy=multi-user.target
```

启动服务：
```bash
sudo systemctl daemon-reload
sudo systemctl enable kris-server
sudo systemctl start kris-server

# 查看状态
sudo systemctl status kris-server
```

#### 2. 配置 iCloud 同步

在服务器上挂载 iCloud Drive（如果可能），或使用 rsync/rclone 定期同步：

```bash
# 使用 rclone 同步到 iCloud
rclone sync /var/kris-server icloud:kris-server --progress
```

#### 3. 在各设备上启动 Agent

```bash
# Mac
python3 agent/kris_agent.py ws://your-server.com:8765

# Linux
python3 agent/kris_agent.py ws://your-server.com:8765

# Windows
python agent/kris_agent.py ws://your-server.com:8765
```

---

### 方案 C: 无服务器模式（最简单，功能受限）⭐⭐⭐

**适合**：
- 不想运行服务器
- 只需要在当前设备执行命令
- 只需要共享历史记录

**特点**：
- ✅ 每个设备独立运行
- ✅ 所有历史保存到 iCloud
- ✅ 可以在任何设备查看所有历史
- ❌ 不能跨平台执行命令

**使用方法**：

```python
# 在任何设备上
python3 unified_system.py

# 或使用编程接口
from src.unified_terminal import UnifiedTerminalSystem

system = UnifiedTerminalSystem(
    icloud_root="~/Library/Mobile Documents/com~apple~CloudDocs/kris-server"
)

# 只能执行本地命令
if platform.system() == "Darwin":
    result = system.execute_on_macos("ls -la")
elif platform.system() == "Linux":
    result = system.execute_on_linux("ps aux")

# 但可以查看所有平台的历史
all_sessions = system.get_all_sessions()  # 从 iCloud 读取
```

---

## 🔧 网络配置

### 防火墙设置

#### Mac (方案 A)

```bash
# 允许端口 8765
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /usr/bin/python3
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --unblockapp /usr/bin/python3
```

#### Linux (方案 B)

```bash
# Ubuntu/Debian
sudo ufw allow 8765/tcp

# CentOS/RHEL
sudo firewall-cmd --permanent --add-port=8765/tcp
sudo firewall-cmd --reload
```

### 获取 Mac 的 IP 地址

```bash
# 查看所有网络接口
ifconfig | grep "inet "

# 或者
ipconfig getifaddr en0  # Wi-Fi
ipconfig getifaddr en1  # 以太网
```

---

## 📊 验证部署

### 1. 检查服务器状态

```bash
# 查看进程
ps aux | grep kris_server

# 查看日志
tail -f server.log

# 测试连接
nc -zv localhost 8765
```

### 2. 检查 Agent 连接

在服务器日志中应该看到：
```
✅ Agent registered: macos from ('192.168.1.100', 54321)
✅ Agent registered: linux from ('192.168.1.200', 54322)
```

### 3. 测试命令执行

创建测试脚本：
```python
# test_system.py
import asyncio
import sys
sys.path.insert(0, 'server')

from kris_server import KrisServer

async def test():
    server = KrisServer(
        "~/Library/Mobile Documents/com~apple~CloudDocs/kris-server"
    )

    # 等待 Agents 连接（手动启动 Agent）
    await asyncio.sleep(5)

    # 测试执行
    result = await server.execute_command("macos", "echo 'Hello from Mac'")
    print(f"Mac result: {result}")

    result = await server.execute_command("linux", "echo 'Hello from Linux'")
    print(f"Linux result: {result}")

asyncio.run(test())
```

---

## 🔐 安全建议

### 1. 使用 SSL/TLS

```python
# 在生产环境中，使用 wss:// 而不是 ws://
import ssl

ssl_context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
ssl_context.load_cert_chain('cert.pem', 'key.pem')

async with websockets.serve(handler, host, port, ssl=ssl_context):
    ...
```

### 2. 添加认证

在 Agent 注册时要求密钥：
```python
register_msg = {
    "type": "register",
    "platform": "macos",
    "auth_key": "your-secret-key"
}
```

### 3. 限制来源 IP

只允许特定 IP 连接到服务器。

---

## 📱 在 iPhone 上运行 Agent

### 使用 Pythonista

1. 安装 Pythonista (App Store)
2. 下载 `kris_agent.py`
3. 安装 websockets:
   ```python
   import pip
   pip.main(['install', 'websockets'])
   ```
4. 运行 agent

### 使用 a-Shell

1. 安装 a-Shell (App Store)
2. 下载代码
3. 运行 agent

---

## 🎯 推荐部署

### 对于个人使用
**方案 A**（Mac 作为服务器）+ iCloud 存储

### 对于团队使用
**方案 B**（云服务器）+ 集中存储

### 对于轻度使用
**方案 C**（无服务器）+ iCloud 共享历史

---

## 📝 快速部署命令

### 一键启动（方案 A）

```bash
#!/bin/bash
# deploy.sh - 一键部署脚本

echo "🚀 Starting Kris Server System..."

# 启动服务器
echo "Starting server..."
nohup python3 server/kris_server.py \
  ~/Library/Mobile\ Documents/com~apple~CloudDocs/kris-server \
  8765 > server.log 2>&1 &

SERVER_PID=$!
echo "✅ Server started (PID: $SERVER_PID)"

# 等待服务器启动
sleep 2

# 启动本地 Agent
echo "Starting local agent..."
nohup python3 agent/kris_agent.py ws://localhost:8765 > agent.log 2>&1 &

AGENT_PID=$!
echo "✅ Agent started (PID: $AGENT_PID)"

echo ""
echo "=" * 70
echo "🎉 System is ready!"
echo "=" * 70
echo "Server PID: $SERVER_PID"
echo "Agent PID: $AGENT_PID"
echo ""
echo "View logs:"
echo "  Server: tail -f server.log"
echo "  Agent: tail -f agent.log"
echo ""
echo "Stop system:"
echo "  kill $SERVER_PID $AGENT_PID"
```

使用：
```bash
chmod +x deploy.sh
./deploy.sh
```

---

## 🎉 部署完成！

现在你可以：
1. ✅ 在任何设备上执行命令
2. ✅ 所有历史自动保存到 iCloud
3. ✅ 多设备查看和同步
4. ✅ 实时命令执行

**测试一下**：
```python
python3 unified_system.py
# 选择 "2. Execute on macOS"
# 输入: ls -la
# 命令会发送到 Mac Agent 执行！
```
