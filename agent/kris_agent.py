#!/usr/bin/env python3
"""
Kris Agent - 平台执行代理
在各个平台上运行，连接到中央服务器并执行命令
"""

import asyncio
import json
import logging
import platform
import subprocess
import sys
from datetime import datetime
from typing import Dict
import websockets

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class KrisAgent:
    """平台执行代理"""

    def __init__(self, server_url: str, platform_name: str = None):
        self.server_url = server_url
        self.platform_name = platform_name or self.detect_platform()
        self.websocket = None
        self.running = False

    def detect_platform(self) -> str:
        """自动检测平台"""
        system = platform.system().lower()

        if system == "darwin":
            return "macos"
        elif system == "linux":
            # 检测是否是 iOS
            try:
                import os
                if os.path.exists("/var/mobile"):
                    return "ios"
            except:
                pass
            return "linux"
        elif system == "windows":
            return "windows"
        else:
            return "unknown"

    def execute_command(self, command: str, timeout: int = 30) -> Dict:
        """
        在本地执行命令

        Args:
            command: 要执行的命令
            timeout: 超时时间（秒）

        Returns:
            执行结果字典
        """
        logger.info(f"📝 Executing: {command}")

        try:
            # 根据平台选择 shell
            if self.platform_name == "windows":
                # Windows 使用 PowerShell
                shell_cmd = ["powershell.exe", "-NoProfile", "-Command", command]
                use_shell = False
            else:
                # Unix-like 系统使用 shell
                shell_cmd = command
                use_shell = True

            # 执行命令
            result = subprocess.run(
                shell_cmd,
                shell=use_shell,
                capture_output=True,
                text=True,
                timeout=timeout,
                cwd=None
            )

            response = {
                "success": result.returncode == 0,
                "output": result.stdout,
                "error": result.stderr,
                "exit_code": result.returncode,
                "platform": self.platform_name,
                "timestamp": datetime.now().isoformat()
            }

            if response["success"]:
                logger.info(f"✅ Command succeeded (exit code: {result.returncode})")
            else:
                logger.warning(f"❌ Command failed (exit code: {result.returncode})")

            return response

        except subprocess.TimeoutExpired:
            logger.error(f"⏰ Command timeout after {timeout}s")
            return {
                "success": False,
                "output": "",
                "error": f"Command timeout after {timeout}s",
                "exit_code": -1,
                "platform": self.platform_name,
                "timestamp": datetime.now().isoformat()
            }

        except Exception as e:
            logger.error(f"❌ Command execution error: {e}")
            return {
                "success": False,
                "output": "",
                "error": str(e),
                "exit_code": -1,
                "platform": self.platform_name,
                "timestamp": datetime.now().isoformat()
            }

    async def send_heartbeat(self):
        """发送心跳"""
        while self.running:
            try:
                if self.websocket:
                    heartbeat = {
                        "type": "heartbeat",
                        "platform": self.platform_name,
                        "timestamp": datetime.now().isoformat()
                    }
                    await self.websocket.send(json.dumps(heartbeat))
                    logger.debug("💓 Heartbeat sent")

                await asyncio.sleep(30)  # 每 30 秒一次心跳

            except Exception as e:
                logger.error(f"Heartbeat error: {e}")
                await asyncio.sleep(5)

    async def handle_message(self, message: str):
        """处理来自服务器的消息"""
        try:
            data = json.loads(message)
            msg_type = data.get("type")

            if msg_type == "execute":
                # 执行命令
                command_id = data.get("command_id")
                command = data.get("command")
                timeout = data.get("timeout", 30)

                logger.info(f"📥 Received command (ID: {command_id})")

                # 执行
                result = self.execute_command(command, timeout)

                # 发送结果
                response = {
                    "type": "result",
                    "command_id": command_id,
                    "result": result
                }

                await self.websocket.send(json.dumps(response))
                logger.info(f"📤 Result sent (ID: {command_id})")

            elif msg_type == "ping":
                # 响应 ping
                pong = {
                    "type": "pong",
                    "timestamp": datetime.now().isoformat()
                }
                await self.websocket.send(json.dumps(pong))

            elif msg_type == "shutdown":
                # 关闭 Agent
                logger.info("🛑 Shutdown command received")
                self.running = False

        except Exception as e:
            logger.error(f"Error handling message: {e}")

    async def connect_and_run(self):
        """连接到服务器并运行"""
        logger.info("=" * 70)
        logger.info(f"🤖 Kris Agent Starting...")
        logger.info("=" * 70)
        logger.info(f"📍 Platform: {self.platform_name}")
        logger.info(f"🔗 Server: {self.server_url}")
        logger.info("=" * 70)

        retry_count = 0
        max_retries = 10
        retry_delay = 5

        while retry_count < max_retries:
            try:
                logger.info(f"🔌 Connecting to server... (attempt {retry_count + 1}/{max_retries})")

                async with websockets.connect(self.server_url) as websocket:
                    self.websocket = websocket
                    self.running = True

                    # 注册到服务器
                    register_msg = {
                        "type": "register",
                        "platform": self.platform_name,
                        "hostname": platform.node(),
                        "system": platform.system(),
                        "version": platform.version(),
                        "timestamp": datetime.now().isoformat()
                    }

                    await websocket.send(json.dumps(register_msg))
                    logger.info("📤 Registration sent")

                    # 等待确认
                    response = await websocket.recv()
                    response_data = json.loads(response)

                    if response_data.get("type") == "registered":
                        logger.info("✅ Registered with server")
                        logger.info("⏳ Waiting for commands...")
                        retry_count = 0  # 重置重试计数

                        # 启动心跳任务
                        heartbeat_task = asyncio.create_task(self.send_heartbeat())

                        try:
                            # 监听命令
                            async for message in websocket:
                                await self.handle_message(message)

                                if not self.running:
                                    break

                        finally:
                            # 取消心跳
                            heartbeat_task.cancel()
                            try:
                                await heartbeat_task
                            except asyncio.CancelledError:
                                pass

            except websockets.exceptions.ConnectionClosed:
                logger.warning("🔌 Connection closed")

            except Exception as e:
                logger.error(f"❌ Connection error: {e}")

            finally:
                self.websocket = None
                self.running = False

            # 重试
            if retry_count < max_retries - 1:
                logger.info(f"⏳ Retrying in {retry_delay} seconds...")
                await asyncio.sleep(retry_delay)
                retry_count += 1
            else:
                logger.error("❌ Max retries reached. Giving up.")
                break

    async def run(self):
        """运行 Agent"""
        try:
            await self.connect_and_run()
        except KeyboardInterrupt:
            logger.info("\n👋 Agent shutting down...")
            self.running = False
        except Exception as e:
            logger.error(f"❌ Agent error: {e}")
            raise


async def main():
    """主函数"""
    if len(sys.argv) < 2:
        print("Usage: python kris_agent.py <server_url> [platform_name]")
        print()
        print("Examples:")
        print("  python kris_agent.py ws://localhost:8765")
        print("  python kris_agent.py ws://192.168.1.100:8765")
        print("  python kris_agent.py ws://kris-server:8765 macos")
        sys.exit(1)

    server_url = sys.argv[1]
    platform_name = sys.argv[2] if len(sys.argv) > 2 else None

    agent = KrisAgent(server_url, platform_name)
    await agent.run()


if __name__ == "__main__":
    asyncio.run(main())
