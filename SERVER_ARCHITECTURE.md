# 服务器架构设计

## 🎯 问题

当前实现假设可以直接在不同平台执行命令，但实际上：
- 在 macOS 上运行 Python 不能直接在远程 Linux 上执行命令
- 需要某种远程执行机制
- **需要服务器架构！**

---

## 🏗️ 解决方案：Server-Agent 架构

### 架构图

```
┌─────────────────────────────────────────────────────────────┐
│                    Kris Server (中央服务器)                   │
│                                                             │
│  - 接收客户端命令请求                                          │
│  - 路由到对应的 Agent                                          │
│  - 收集和存储结果到 iCloud                                      │
│  - 提供 REST API / WebSocket                                │
│                                                             │
│  Location: https://kris-server (你的服务器)                  │
│  或: ~/Library/Mobile Documents/.../kris-server/            │
└─────────────────────────────────────────────────────────────┘
                              ↓
        ┌─────────────────────┼─────────────────────┐
        ↓                     ↓                     ↓
┌──────────────┐      ┌──────────────┐      ┌──────────────┐
│  Mac Agent   │      │ Linux Agent  │      │  iOS Agent   │
│              │      │              │      │              │
│ - 监听命令    │      │ - 监听命令    │      │ - 监听命令    │
│ - 执行本地    │      │ - 执行本地    │      │ - 执行本地    │
│ - 返回结果    │      │ - 返回结果    │      │ - 返回结果    │
└──────────────┘      └──────────────┘      └──────────────┘
   macOS 设备            Linux 服务器          iPhone/iPad
```

---

## 🔧 方案 1: WebSocket Server-Agent（推荐）

### 服务器端 (kris-server)

```python
# server/kris_server.py
"""
Kris Server - 中央命令服务器
运行在你的主服务器上
"""

import asyncio
import json
import websockets
from datetime import datetime
from pathlib import Path

class KrisServer:
    def __init__(self, icloud_root):
        self.icloud_root = Path(icloud_root)
        self.agents = {}  # {platform: websocket}
        self.sessions = {}

    async def register_agent(self, websocket, platform):
        """注册一个 Agent"""
        self.agents[platform] = websocket
        print(f"✅ Agent registered: {platform}")

    async def execute_command(self, platform, command):
        """发送命令到指定平台的 Agent"""
        if platform not in self.agents:
            return {
                "success": False,
                "error": f"No agent available for {platform}"
            }

        agent_ws = self.agents[platform]

        # 发送命令
        request = {
            "type": "execute",
            "command": command,
            "timestamp": datetime.now().isoformat()
        }

        await agent_ws.send(json.dumps(request))

        # 等待结果
        response = await agent_ws.recv()
        result = json.loads(response)

        # 保存到 iCloud
        self.save_to_icloud(platform, command, result)

        return result

    def save_to_icloud(self, platform, command, result):
        """保存结果到 iCloud"""
        session_path = (
            self.icloud_root /
            "terminal-sessions" /
            platform /
            f"{datetime.now().strftime('%Y%m%d')}.json"
        )

        session_path.parent.mkdir(parents=True, exist_ok=True)

        # 追加到今天的会话文件
        entries = []
        if session_path.exists():
            with open(session_path, 'r') as f:
                entries = json.load(f)

        entries.append({
            "timestamp": datetime.now().isoformat(),
            "command": command,
            "result": result
        })

        with open(session_path, 'w') as f:
            json.dump(entries, f, indent=2)

    async def handler(self, websocket, path):
        """处理 WebSocket 连接"""
        try:
            # 第一条消息应该是注册
            register_msg = await websocket.recv()
            register_data = json.loads(register_msg)

            if register_data.get("type") == "register":
                platform = register_data.get("platform")
                await self.register_agent(websocket, platform)

                # 发送确认
                await websocket.send(json.dumps({
                    "type": "registered",
                    "platform": platform
                }))

                # 保持连接
                async for message in websocket:
                    # 处理来自 agent 的消息
                    data = json.loads(message)
                    print(f"Received from {platform}: {data}")

        except websockets.exceptions.ConnectionClosed:
            print(f"Agent disconnected: {platform}")
            if platform in self.agents:
                del self.agents[platform]

    async def start(self, host="0.0.0.0", port=8765):
        """启动服务器"""
        async with websockets.serve(self.handler, host, port):
            print(f"🚀 Kris Server started on ws://{host}:{port}")
            print(f"📂 iCloud Root: {self.icloud_root}")
            await asyncio.Future()  # 永久运行


# 运行服务器
if __name__ == "__main__":
    icloud_root = "~/Library/Mobile Documents/com~apple~CloudDocs/kris-server"
    server = KrisServer(icloud_root)
    asyncio.run(server.start())
```

### Agent 端 (各个平台)

```python
# agent/kris_agent.py
"""
Kris Agent - 在各个平台上运行
连接到中央服务器并执行命令
"""

import asyncio
import json
import subprocess
import platform
import websockets

class KrisAgent:
    def __init__(self, server_url, platform_name=None):
        self.server_url = server_url
        self.platform_name = platform_name or self.detect_platform()

    def detect_platform(self):
        """自动检测平台"""
        system = platform.system().lower()
        if system == "darwin":
            return "macos"
        elif system == "linux":
            return "linux"
        elif system == "windows":
            return "windows"
        else:
            return "unknown"

    def execute_command(self, command):
        """在本地执行命令"""
        try:
            result = subprocess.run(
                command,
                shell=True,
                capture_output=True,
                text=True,
                timeout=30
            )

            return {
                "success": result.returncode == 0,
                "output": result.stdout,
                "error": result.stderr,
                "exit_code": result.returncode,
                "platform": self.platform_name
            }

        except Exception as e:
            return {
                "success": False,
                "output": "",
                "error": str(e),
                "exit_code": 1,
                "platform": self.platform_name
            }

    async def connect_and_run(self):
        """连接到服务器并运行"""
        async with websockets.connect(self.server_url) as websocket:
            # 注册到服务器
            register_msg = {
                "type": "register",
                "platform": self.platform_name
            }

            await websocket.send(json.dumps(register_msg))

            # 等待确认
            response = await websocket.recv()
            print(f"✅ Connected to server: {response}")

            # 监听命令
            async for message in websocket:
                data = json.loads(message)

                if data.get("type") == "execute":
                    command = data.get("command")
                    print(f"📝 Executing: {command}")

                    # 执行命令
                    result = self.execute_command(command)

                    # 返回结果
                    await websocket.send(json.dumps(result))
                    print(f"✅ Result sent: {result['success']}")


# 运行 Agent
if __name__ == "__main__":
    import sys

    server_url = sys.argv[1] if len(sys.argv) > 1 else "ws://kris-server:8765"

    agent = KrisAgent(server_url)
    print(f"🤖 Starting agent for {agent.platform_name}")
    print(f"🔗 Connecting to {server_url}")

    asyncio.run(agent.connect_and_run())
```

### 客户端 (统一接口)

```python
# client/kris_client.py
"""
Kris Client - 用户界面
发送命令到服务器
"""

import asyncio
import json
import websockets

class KrisClient:
    def __init__(self, server_url):
        self.server_url = server_url
        self.server_ws = None

    async def connect(self):
        """连接到服务器"""
        # 这里需要一个不同的端点，用于客户端
        # 或者使用 HTTP REST API
        pass

    async def execute_command(self, platform, command):
        """执行命令"""
        # 通过 REST API 发送命令到服务器
        import aiohttp

        api_url = f"http://kris-server:8080/api/execute"

        async with aiohttp.ClientSession() as session:
            async with session.post(api_url, json={
                "platform": platform,
                "command": command
            }) as response:
                return await response.json()


# 使用示例
async def main():
    client = KrisClient("http://kris-server:8080")

    # 在 macOS 上执行
    result = await client.execute_command("macos", "ls -la")
    print(result)

    # 在 Linux 上执行
    result = await client.execute_command("linux", "ps aux")
    print(result)

if __name__ == "__main__":
    asyncio.run(main())
```

---

## 🔧 方案 2: SSH-Based（简单方案）

如果你的设备可以通过 SSH 连接：

```python
# ssh_executor.py
"""
基于 SSH 的简单方案
不需要运行 Agent，直接通过 SSH 执行
"""

import paramiko
from pathlib import Path

class SSHExecutor:
    def __init__(self, icloud_root):
        self.icloud_root = Path(icloud_root)
        self.connections = {}

    def add_host(self, name, hostname, username, key_file=None):
        """添加 SSH 主机"""
        self.connections[name] = {
            "hostname": hostname,
            "username": username,
            "key_file": key_file
        }

    def execute_on_host(self, host_name, command):
        """通过 SSH 在远程主机执行命令"""
        host_info = self.connections.get(host_name)

        if not host_info:
            return {"success": False, "error": f"Unknown host: {host_name}"}

        try:
            # 创建 SSH 客户端
            client = paramiko.SSHClient()
            client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

            # 连接
            if host_info.get("key_file"):
                key = paramiko.RSAKey.from_private_key_file(host_info["key_file"])
                client.connect(
                    host_info["hostname"],
                    username=host_info["username"],
                    pkey=key
                )
            else:
                client.connect(
                    host_info["hostname"],
                    username=host_info["username"]
                )

            # 执行命令
            stdin, stdout, stderr = client.exec_command(command)

            result = {
                "success": stdout.channel.recv_exit_status() == 0,
                "output": stdout.read().decode(),
                "error": stderr.read().decode(),
                "exit_code": stdout.channel.recv_exit_status()
            }

            client.close()

            # 保存到 iCloud
            self.save_to_icloud(host_name, command, result)

            return result

        except Exception as e:
            return {
                "success": False,
                "error": str(e),
                "output": "",
                "exit_code": 1
            }


# 使用示例
executor = SSHExecutor(
    icloud_root="~/Library/Mobile Documents/com~apple~CloudDocs/kris-server"
)

# 添加你的服务器
executor.add_host(
    "linux-server",
    hostname="your-linux-server.com",
    username="user",
    key_file="~/.ssh/id_rsa"
)

# 执行命令
result = executor.execute_on_host("linux-server", "ls -la")
print(result)
```

---

## 🚀 部署方案

### 在你的 kris-server 上部署

```bash
# 1. 在服务器上运行中央服务器
python3 server/kris_server.py

# 2. 在 macOS 上运行 Agent
python3 agent/kris_agent.py ws://kris-server:8765

# 3. 在 Linux 上运行 Agent
python3 agent/kris_agent.py ws://kris-server:8765

# 4. 在本地使用客户端
python3 unified_system.py
```

---

## 📊 架构对比

| 方案 | 优点 | 缺点 | 推荐度 |
|------|------|------|--------|
| **WebSocket Server-Agent** | 实时通信，双向，灵活 | 需要运行多个进程 | ⭐⭐⭐⭐⭐ |
| **SSH-Based** | 简单，不需要 Agent | 只适用于 Linux/macOS | ⭐⭐⭐ |
| **HTTP REST API** | 简单，标准 | 轮询开销 | ⭐⭐⭐⭐ |
| **本地执行** | 最简单 | 只能管理当前设备 | ⭐⭐ |

---

## 💡 我的建议

使用 **WebSocket Server-Agent** 架构：

1. **服务器** - 运行在你的 kris-server 上
2. **Agents** - 在每个设备上运行（Mac, Linux, iOS）
3. **客户端** - 你的 unified_system.py 连接到服务器

这样：
- ✅ 真正的跨平台执行
- ✅ 实时通信
- ✅ 所有数据保存到 iCloud
- ✅ 多设备同步

要实现吗？
