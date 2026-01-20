#!/usr/bin/env python3
"""
Kris Server - Central Command Server
运行在你的服务器上，管理所有 Agent
"""

import asyncio
import json
import logging
from datetime import datetime
from pathlib import Path
from typing import Dict, Optional
import websockets

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class KrisServer:
    """中央命令服务器"""

    def __init__(self, icloud_root: str, host="0.0.0.0", port=8765):
        self.icloud_root = Path(icloud_root).expanduser()
        self.host = host
        self.port = port

        # 已连接的 Agents
        self.agents: Dict[str, websockets.WebSocketServerProtocol] = {}

        # 等待响应的命令
        self.pending_commands: Dict[str, asyncio.Future] = {}

        # 确保 iCloud 目录存在
        self.ensure_directories()

    def ensure_directories(self):
        """确保 iCloud 目录结构存在"""
        directories = [
            "terminal-sessions/macos",
            "terminal-sessions/linux",
            "terminal-sessions/ios",
            "terminal-sessions/windows",
            "automation-logs/server"
        ]

        for directory in directories:
            (self.icloud_root / directory).mkdir(parents=True, exist_ok=True)

    async def register_agent(self, websocket, platform: str):
        """注册一个 Agent"""
        self.agents[platform] = websocket
        logger.info(f"✅ Agent registered: {platform} from {websocket.remote_address}")

        # 保存注册事件
        self.log_event("agent_registered", {"platform": platform})

        return {
            "type": "registered",
            "platform": platform,
            "server_time": datetime.now().isoformat()
        }

    def unregister_agent(self, platform: str):
        """注销 Agent"""
        if platform in self.agents:
            del self.agents[platform]
            logger.info(f"❌ Agent unregistered: {platform}")
            self.log_event("agent_unregistered", {"platform": platform})

    async def execute_command(self, platform: str, command: str, timeout: int = 30) -> Dict:
        """
        发送命令到指定平台的 Agent 并等待结果

        Args:
            platform: 目标平台 (macos, linux, ios, windows)
            command: 要执行的命令
            timeout: 超时时间（秒）

        Returns:
            执行结果字典
        """
        if platform not in self.agents:
            error_msg = f"No agent available for platform: {platform}"
            logger.error(error_msg)
            return {
                "success": False,
                "error": error_msg,
                "output": "",
                "exit_code": -1,
                "platform": platform
            }

        agent_ws = self.agents[platform]

        # 生成命令 ID
        command_id = f"{platform}_{datetime.now().timestamp()}"

        # 创建 Future 等待响应
        future = asyncio.Future()
        self.pending_commands[command_id] = future

        # 发送命令
        request = {
            "type": "execute",
            "command_id": command_id,
            "command": command,
            "timestamp": datetime.now().isoformat()
        }

        try:
            await agent_ws.send(json.dumps(request))
            logger.info(f"📤 Command sent to {platform}: {command[:50]}...")

            # 等待结果（带超时）
            result = await asyncio.wait_for(future, timeout=timeout)

            # 保存到 iCloud
            self.save_to_icloud(platform, command, result)

            logger.info(f"✅ Command completed on {platform}: {result['success']}")
            return result

        except asyncio.TimeoutError:
            error_msg = f"Command timeout after {timeout}s"
            logger.error(f"⏰ {error_msg} on {platform}")
            return {
                "success": False,
                "error": error_msg,
                "output": "",
                "exit_code": -1,
                "platform": platform
            }

        except Exception as e:
            error_msg = f"Command execution failed: {str(e)}"
            logger.error(f"❌ {error_msg}")
            return {
                "success": False,
                "error": error_msg,
                "output": "",
                "exit_code": -1,
                "platform": platform
            }

        finally:
            # 清理
            if command_id in self.pending_commands:
                del self.pending_commands[command_id]

    def save_to_icloud(self, platform: str, command: str, result: Dict):
        """保存命令执行结果到 iCloud"""
        # 今天的会话文件
        today = datetime.now().strftime('%Y%m%d')
        session_file = (
            self.icloud_root /
            "terminal-sessions" /
            platform /
            f"session_{today}.json"
        )

        # 读取现有数据
        entries = []
        if session_file.exists():
            try:
                with open(session_file, 'r') as f:
                    entries = json.load(f)
            except:
                entries = []

        # 添加新条目
        entries.append({
            "timestamp": datetime.now().isoformat(),
            "command": command,
            "result": result
        })

        # 保存
        with open(session_file, 'w') as f:
            json.dump(entries, f, indent=2)

        logger.debug(f"💾 Saved to iCloud: {session_file}")

    def log_event(self, event_type: str, data: Dict):
        """记录事件到日志"""
        log_file = (
            self.icloud_root /
            "automation-logs" /
            "server" /
            f"{datetime.now().strftime('%Y%m%d')}.log"
        )

        log_entry = {
            "timestamp": datetime.now().isoformat(),
            "event_type": event_type,
            "data": data
        }

        with open(log_file, 'a') as f:
            f.write(json.dumps(log_entry) + "\n")

    async def handle_agent_message(self, message: str, platform: str):
        """处理来自 Agent 的消息"""
        try:
            data = json.loads(message)
            msg_type = data.get("type")

            if msg_type == "result":
                # 命令执行结果
                command_id = data.get("command_id")
                result = data.get("result")

                if command_id in self.pending_commands:
                    future = self.pending_commands[command_id]
                    if not future.done():
                        future.set_result(result)

            elif msg_type == "heartbeat":
                # 心跳
                logger.debug(f"💓 Heartbeat from {platform}")

            elif msg_type == "status":
                # 状态更新
                logger.info(f"📊 Status from {platform}: {data.get('status')}")

        except Exception as e:
            logger.error(f"Error handling message from {platform}: {e}")

    async def agent_handler(self, websocket, path):
        """处理 Agent 连接"""
        platform = None

        try:
            # 等待注册消息
            register_msg = await websocket.recv()
            register_data = json.loads(register_msg)

            if register_data.get("type") == "register":
                platform = register_data.get("platform")

                # 注册 Agent
                response = await self.register_agent(websocket, platform)
                await websocket.send(json.dumps(response))

                # 持续监听来自 Agent 的消息
                async for message in websocket:
                    await self.handle_agent_message(message, platform)

        except websockets.exceptions.ConnectionClosed:
            logger.info(f"🔌 Agent disconnected: {platform}")

        except Exception as e:
            logger.error(f"Error in agent handler: {e}")

        finally:
            if platform:
                self.unregister_agent(platform)

    def get_status(self) -> Dict:
        """获取服务器状态"""
        return {
            "connected_agents": list(self.agents.keys()),
            "pending_commands": len(self.pending_commands),
            "icloud_root": str(self.icloud_root),
            "server_time": datetime.now().isoformat()
        }

    async def start(self):
        """启动服务器"""
        logger.info("=" * 70)
        logger.info("🚀 Kris Server Starting...")
        logger.info("=" * 70)
        logger.info(f"📍 Host: {self.host}")
        logger.info(f"📍 Port: {self.port}")
        logger.info(f"📂 iCloud Root: {self.icloud_root}")
        logger.info("=" * 70)

        async with websockets.serve(self.agent_handler, self.host, self.port):
            logger.info(f"✅ Server ready on ws://{self.host}:{self.port}")
            logger.info("⏳ Waiting for agents to connect...")

            # 永久运行
            await asyncio.Future()


async def main():
    """主函数"""
    import sys

    # 获取配置
    icloud_root = sys.argv[1] if len(sys.argv) > 1 else \
        "~/Library/Mobile Documents/com~apple~CloudDocs/kris-server"

    port = int(sys.argv[2]) if len(sys.argv) > 2 else 8765

    # 创建并启动服务器
    server = KrisServer(icloud_root, port=port)

    try:
        await server.start()
    except KeyboardInterrupt:
        logger.info("\n👋 Server shutting down...")
    except Exception as e:
        logger.error(f"❌ Server error: {e}")
        raise


if __name__ == "__main__":
    asyncio.run(main())
