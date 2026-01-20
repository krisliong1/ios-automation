#!/usr/bin/env python3
"""
Fabric Glue - 胶水编程版本的跨平台命令执行
使用 Fabric (14K+ stars) 作为核心，只写最少的胶水代码

Fabric: https://github.com/fabric/fabric
作用：SSH 远程执行命令的成熟库
"""

from fabric import Connection, Config
from pathlib import Path
import json
from datetime import datetime
from typing import Dict, List, Optional
import logging

logger = logging.getLogger(__name__)


class FabricGlue:
    """
    胶水编程 - Fabric 集成

    核心功能来自 Fabric (14K+ stars)
    我们只写：
    1. iCloud 集成的胶水代码
    2. 配置管理的胶水代码
    3. 统一接口的胶水代码

    代码量：~200 行（vs 自己写 1000+ 行）
    """

    def __init__(self, icloud_root: str, config_file: Optional[str] = None):
        """
        初始化 Fabric 胶水层

        Args:
            icloud_root: iCloud 根目录
            config_file: 主机配置文件（可选）
        """
        self.icloud_root = Path(icloud_root).expanduser()
        self.connections: Dict[str, Connection] = {}
        self.config = self._load_config(config_file)

        # 确保目录存在
        self._ensure_directories()

        # 从配置加载主机
        self._load_hosts_from_config()

    def _load_config(self, config_file: Optional[str]) -> Dict:
        """加载配置（如果存在）"""
        if config_file and Path(config_file).exists():
            with open(config_file, 'r') as f:
                return json.load(f)

        # 尝试从 iCloud 加载
        icloud_config = self.icloud_root / "shared-config" / "fabric-hosts.json"
        if icloud_config.exists():
            with open(icloud_config, 'r') as f:
                return json.load(f)

        return {"hosts": {}}

    def _ensure_directories(self):
        """确保 iCloud 目录存在"""
        dirs = [
            "terminal-sessions",
            "shared-config",
            "automation-logs"
        ]
        for d in dirs:
            (self.icloud_root / d).mkdir(parents=True, exist_ok=True)

    def _load_hosts_from_config(self):
        """从配置加载主机连接"""
        for name, host_config in self.config.get("hosts", {}).items():
            self.add_host(
                name=name,
                hostname=host_config.get("hostname"),
                username=host_config.get("username"),
                key_file=host_config.get("key_file"),
                port=host_config.get("port", 22)
            )

    def add_host(self, name: str, hostname: str, username: str,
                 key_file: Optional[str] = None, port: int = 22):
        """
        添加主机（胶水代码：连接 Fabric 和我们的系统）

        这里只是简单调用 Fabric 的 Connection
        核心 SSH 功能都是 Fabric 提供的！
        """
        connect_kwargs = {}
        if key_file:
            connect_kwargs['key_filename'] = str(Path(key_file).expanduser())

        # 使用 Fabric 的 Connection（成熟的 SSH 实现）
        self.connections[name] = Connection(
            host=hostname,
            user=username,
            port=port,
            connect_kwargs=connect_kwargs
        )

        logger.info(f"✅ Added host: {name} ({username}@{hostname}:{port})")

    def execute(self, host: str, command: str,
                timeout: int = 30, save_to_icloud: bool = True) -> Dict:
        """
        执行命令（胶水代码：连接 Fabric 执行和 iCloud 存储）

        Args:
            host: 主机名
            command: 要执行的命令
            timeout: 超时时间
            save_to_icloud: 是否保存到 iCloud

        Returns:
            执行结果字典
        """
        if host not in self.connections:
            return {
                "success": False,
                "error": f"Unknown host: {host}",
                "output": "",
                "exit_code": -1
            }

        conn = self.connections[host]

        try:
            # 核心功能：使用 Fabric 执行命令（我们不写 SSH 代码！）
            result = conn.run(command, hide=True, warn=True, timeout=timeout)

            # 胶水代码：格式化结果
            response = {
                "success": result.ok,
                "output": result.stdout,
                "error": result.stderr,
                "exit_code": result.return_code,
                "host": host,
                "command": command,
                "timestamp": datetime.now().isoformat()
            }

            logger.info(f"{'✅' if result.ok else '❌'} {host}: {command[:50]}...")

            # 胶水代码：保存到 iCloud
            if save_to_icloud:
                self._save_to_icloud(host, command, response)

            return response

        except Exception as e:
            logger.error(f"❌ Execution failed on {host}: {e}")
            return {
                "success": False,
                "output": "",
                "error": str(e),
                "exit_code": -1,
                "host": host,
                "command": command,
                "timestamp": datetime.now().isoformat()
            }

    def _save_to_icloud(self, host: str, command: str, result: Dict):
        """
        保存到 iCloud（胶水代码：连接执行结果和 iCloud 存储）

        这是我们自己写的，因为这是业务逻辑
        但核心的文件操作都是 Python 标准库提供的
        """
        # 今天的会话文件
        today = datetime.now().strftime('%Y%m%d')
        session_dir = self.icloud_root / "terminal-sessions" / host
        session_dir.mkdir(parents=True, exist_ok=True)

        session_file = session_dir / f"session_{today}.json"

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

    def execute_on_all(self, command: str) -> Dict[str, Dict]:
        """
        在所有主机上执行命令（胶水代码：批量调用）
        """
        results = {}
        for host_name in self.connections.keys():
            results[host_name] = self.execute(host_name, command)
        return results

    def get_history(self, host: Optional[str] = None,
                   date: Optional[str] = None) -> List[Dict]:
        """
        从 iCloud 获取历史（胶水代码：读取存储的数据）

        Args:
            host: 主机名（None = 所有主机）
            date: 日期 YYYYMMDD（None = 今天）
        """
        if date is None:
            date = datetime.now().strftime('%Y%m%d')

        history = []

        # 确定要查询的主机
        hosts_to_query = [host] if host else self.connections.keys()

        for h in hosts_to_query:
            session_file = (
                self.icloud_root /
                "terminal-sessions" /
                h /
                f"session_{date}.json"
            )

            if session_file.exists():
                try:
                    with open(session_file, 'r') as f:
                        entries = json.load(f)
                        for entry in entries:
                            entry['host'] = h
                            history.append(entry)
                except Exception as e:
                    logger.error(f"Error reading history for {h}: {e}")

        # 按时间排序
        history.sort(key=lambda x: x.get('timestamp', ''), reverse=True)
        return history

    def search_history(self, query: str,
                      host: Optional[str] = None) -> List[Dict]:
        """搜索历史（胶水代码：简单的文本搜索）"""
        all_history = self.get_history(host=host)

        results = []
        for entry in all_history:
            command = entry.get('command', '')
            output = entry.get('result', {}).get('output', '')

            if query.lower() in command.lower() or query.lower() in output.lower():
                results.append(entry)

        return results

    def save_config(self):
        """保存当前配置到 iCloud（胶水代码：持久化配置）"""
        config_file = self.icloud_root / "shared-config" / "fabric-hosts.json"

        hosts_config = {}
        for name, conn in self.connections.items():
            hosts_config[name] = {
                "hostname": conn.host,
                "username": conn.user,
                "port": conn.port,
                # 注意：不保存密钥路径，使用默认
            }

        config = {
            "version": "1.0.0",
            "hosts": hosts_config,
            "last_updated": datetime.now().isoformat()
        }

        with open(config_file, 'w') as f:
            json.dump(config, f, indent=2)

        logger.info(f"💾 Config saved to {config_file}")


# 便捷函数（胶水代码：简化常见操作）
def quick_execute(host: str, command: str,
                 icloud_root: str = "~/Library/Mobile Documents/com~apple~CloudDocs/kris-server") -> Dict:
    """
    快速执行命令（一行代码搞定）

    示例:
        result = quick_execute("my-server", "ls -la")
    """
    glue = FabricGlue(icloud_root)
    return glue.execute(host, command)


# 使用示例
if __name__ == "__main__":
    import sys

    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s'
    )

    print("=" * 70)
    print("Fabric Glue - 胶水编程演示")
    print("=" * 70)
    print()

    # 创建实例
    glue = FabricGlue(
        icloud_root="~/Library/Mobile Documents/com~apple~CloudDocs/kris-server"
    )

    # 添加主机（示例）
    print("添加主机配置...")
    print("请修改下面的配置为你的实际服务器信息：")
    print()
    print("glue.add_host(")
    print("    name='linux-server',")
    print("    hostname='192.168.1.100',")
    print("    username='your-user',")
    print("    key_file='~/.ssh/id_rsa'")
    print(")")
    print()
    print("然后执行：")
    print("result = glue.execute('linux-server', 'ls -la')")
    print()

    # 如果提供了命令行参数，执行演示
    if len(sys.argv) > 3:
        host = sys.argv[1]
        hostname = sys.argv[2]
        command = sys.argv[3]

        glue.add_host(host, hostname, "user", "~/.ssh/id_rsa")
        result = glue.execute(host, command)

        print(f"\n结果:")
        print(f"  成功: {result['success']}")
        print(f"  输出: {result['output'][:200]}...")
        print(f"  已保存到 iCloud ✅")
