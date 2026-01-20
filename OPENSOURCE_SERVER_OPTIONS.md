# 🔍 GitHub 开源 Server 方案推荐

## 🎯 你的需求

1. 跨平台命令执行
2. WebSocket 或 REST API
3. 简单易部署
4. 与 iCloud 集成

---

## ⭐ 推荐方案

### 方案 1: Fabric (推荐！) ⭐⭐⭐⭐⭐

**GitHub**: https://github.com/fabric/fabric
**Stars**: 14,000+
**语言**: Python

**为什么推荐**：
- ✅ 专门用于 SSH 远程执行命令
- ✅ Python 编写，易于集成
- ✅ 成熟稳定，广泛使用
- ✅ 不需要在远程机器上运行 Agent

**使用示例**：

```python
# fabric_executor.py
from fabric import Connection
from pathlib import Path
import json
from datetime import datetime

class FabricExecutor:
    """使用 Fabric 执行远程命令"""

    def __init__(self, icloud_root):
        self.icloud_root = Path(icloud_root)
        self.connections = {}

    def add_host(self, name, hostname, username, key_file=None):
        """添加远程主机"""
        connect_kwargs = {}
        if key_file:
            connect_kwargs['key_filename'] = key_file

        self.connections[name] = Connection(
            host=hostname,
            user=username,
            connect_kwargs=connect_kwargs
        )

    def execute(self, host_name, command, save_to_icloud=True):
        """在远程主机执行命令"""
        if host_name not in self.connections:
            return {"success": False, "error": f"Unknown host: {host_name}"}

        conn = self.connections[host_name]

        try:
            # 执行命令
            result = conn.run(command, hide=True, warn=True)

            response = {
                "success": result.ok,
                "output": result.stdout,
                "error": result.stderr,
                "exit_code": result.return_code,
                "host": host_name,
                "timestamp": datetime.now().isoformat()
            }

            # 保存到 iCloud
            if save_to_icloud:
                self.save_to_icloud(host_name, command, response)

            return response

        except Exception as e:
            return {
                "success": False,
                "error": str(e),
                "output": "",
                "exit_code": 1,
                "host": host_name
            }

    def save_to_icloud(self, host, command, result):
        """保存到 iCloud"""
        session_path = (
            self.icloud_root /
            "terminal-sessions" /
            host /
            f"{datetime.now().strftime('%Y%m%d')}.json"
        )

        session_path.parent.mkdir(parents=True, exist_ok=True)

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


# 使用示例
executor = FabricExecutor(
    "~/Library/Mobile Documents/com~apple~CloudDocs/kris-server"
)

# 添加你的服务器
executor.add_host(
    "linux-server",
    hostname="your-server.com",
    username="user",
    key_file="~/.ssh/id_rsa"
)

executor.add_host(
    "mac-mini",
    hostname="192.168.1.100",
    username="user",
    key_file="~/.ssh/id_rsa"
)

# 执行命令
result = executor.execute("linux-server", "ls -la /var/log")
print(result)

result = executor.execute("mac-mini", "df -h")
print(result)

# 所有结果自动保存到 iCloud！
```

**安装**：
```bash
pip install fabric
```

---

### 方案 2: Ansible Runner ⭐⭐⭐⭐

**GitHub**: https://github.com/ansible/ansible-runner
**Stars**: 800+
**语言**: Python

**为什么推荐**：
- ✅ 企业级自动化工具
- ✅ 无需 Agent（SSH）
- ✅ 支持批量执行
- ✅ YAML 配置

**使用示例**：

```python
# ansible_executor.py
import ansible_runner
from pathlib import Path
import json
from datetime import datetime

class AnsibleExecutor:
    """使用 Ansible 执行命令"""

    def __init__(self, icloud_root, inventory_file):
        self.icloud_root = Path(icloud_root)
        self.inventory_file = inventory_file

    def execute_on_host(self, host, command):
        """在主机上执行命令"""
        r = ansible_runner.run(
            private_data_dir=str(self.icloud_root / "ansible"),
            inventory=self.inventory_file,
            module='shell',
            module_args=command,
            host_pattern=host
        )

        result = {
            "success": r.rc == 0,
            "output": r.stdout.read(),
            "error": r.stderr.read(),
            "exit_code": r.rc,
            "host": host
        }

        self.save_to_icloud(host, command, result)
        return result


# inventory.ini
"""
[servers]
linux-server ansible_host=192.168.1.100 ansible_user=user
mac-mini ansible_host=192.168.1.101 ansible_user=user

[all:vars]
ansible_ssh_private_key_file=~/.ssh/id_rsa
"""
```

**安装**：
```bash
pip install ansible-runner
```

---

### 方案 3: Celery + Redis ⭐⭐⭐⭐⭐

**GitHub**: https://github.com/celery/celery
**Stars**: 23,000+
**语言**: Python

**为什么推荐**：
- ✅ 分布式任务队列
- ✅ 实时任务执行
- ✅ 支持多 Worker
- ✅ 强大的监控

**架构**：
```
Mac (Celery Client)
    ↓ 提交任务
Redis (消息队列)
    ↓ 分发任务
Celery Workers (各个平台)
    - macOS Worker
    - Linux Worker
    - iOS Worker
    ↓ 执行命令
结果保存到 iCloud
```

**实现**：

```python
# celery_tasks.py
from celery import Celery
import subprocess
from pathlib import Path
import json
from datetime import datetime

# 配置 Celery
app = Celery('kris_automation', broker='redis://localhost:6379/0')

icloud_root = Path.home() / "Library/Mobile Documents/com~apple~CloudDocs/kris-server"

@app.task(name='execute_command')
def execute_command(command, platform):
    """执行命令任务"""
    result = subprocess.run(
        command,
        shell=True,
        capture_output=True,
        text=True,
        timeout=30
    )

    response = {
        "success": result.returncode == 0,
        "output": result.stdout,
        "error": result.stderr,
        "exit_code": result.returncode,
        "platform": platform,
        "timestamp": datetime.now().isoformat()
    }

    # 保存到 iCloud
    session_file = (
        icloud_root /
        "terminal-sessions" /
        platform /
        f"{datetime.now().strftime('%Y%m%d')}.json"
    )

    session_file.parent.mkdir(parents=True, exist_ok=True)

    entries = []
    if session_file.exists():
        with open(session_file, 'r') as f:
            entries = json.load(f)

    entries.append({
        "timestamp": datetime.now().isoformat(),
        "command": command,
        "result": response
    })

    with open(session_file, 'w') as f:
        json.dump(entries, f, indent=2)

    return response


# client.py - 在任何地方调用
from celery_tasks import execute_command

# 提交任务到 macOS worker
result = execute_command.delay("ls -la", "macos")
print(result.get())  # 等待结果

# 提交任务到 Linux worker
result = execute_command.delay("ps aux", "linux")
print(result.get())
```

**部署**：

```bash
# 安装 Redis
brew install redis  # macOS
apt-get install redis  # Linux

# 启动 Redis
redis-server

# 在 macOS 上启动 Worker
celery -A celery_tasks worker --loglevel=info -Q macos

# 在 Linux 上启动 Worker
celery -A celery_tasks worker --loglevel=info -Q linux
```

**安装**：
```bash
pip install celery redis
```

---

### 方案 4: Flask + Paramiko (自建) ⭐⭐⭐

**GitHub (Paramiko)**: https://github.com/paramiko/paramiko
**Stars**: 8,800+
**语言**: Python

**简单的 REST API Server**：

```python
# flask_server.py
from flask import Flask, request, jsonify
import paramiko
from pathlib import Path
import json
from datetime import datetime

app = Flask(__name__)
icloud_root = Path.home() / "Library/Mobile Documents/com~apple~CloudDocs/kris-server"

hosts = {
    "linux-server": {
        "hostname": "192.168.1.100",
        "username": "user",
        "key_file": "~/.ssh/id_rsa"
    }
}

@app.route('/execute', methods=['POST'])
def execute_command():
    """执行命令 API"""
    data = request.json
    host_name = data.get('host')
    command = data.get('command')

    if host_name not in hosts:
        return jsonify({"error": "Unknown host"}), 404

    host_info = hosts[host_name]

    try:
        # SSH 连接
        client = paramiko.SSHClient()
        client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

        key = paramiko.RSAKey.from_private_key_file(
            Path(host_info["key_file"]).expanduser()
        )

        client.connect(
            host_info["hostname"],
            username=host_info["username"],
            pkey=key
        )

        # 执行命令
        stdin, stdout, stderr = client.exec_command(command)

        result = {
            "success": stdout.channel.recv_exit_status() == 0,
            "output": stdout.read().decode(),
            "error": stderr.read().decode(),
            "exit_code": stdout.channel.recv_exit_status(),
            "host": host_name
        }

        client.close()

        # 保存到 iCloud
        save_to_icloud(host_name, command, result)

        return jsonify(result)

    except Exception as e:
        return jsonify({"error": str(e)}), 500

def save_to_icloud(host, command, result):
    # 同上...
    pass

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

**使用**：
```bash
# 启动服务器
python flask_server.py

# 调用 API
curl -X POST http://localhost:5000/execute \
  -H "Content-Type: application/json" \
  -d '{"host": "linux-server", "command": "ls -la"}'
```

---

## 📊 方案对比

| 方案 | 复杂度 | 需要 Agent | 实时性 | 推荐度 |
|------|--------|-----------|--------|--------|
| **Fabric** | 低 | ❌ (SSH) | 高 | ⭐⭐⭐⭐⭐ |
| **Ansible** | 中 | ❌ (SSH) | 中 | ⭐⭐⭐⭐ |
| **Celery** | 高 | ✅ (Worker) | 非常高 | ⭐⭐⭐⭐⭐ |
| **Flask + Paramiko** | 低 | ❌ (SSH) | 高 | ⭐⭐⭐ |
| **我们的 WebSocket** | 中 | ✅ | 非常高 | ⭐⭐⭐⭐ |

---

## 💡 我的推荐

### 对于你的场景，我强烈推荐 **Fabric**：

**原因**：
1. ✅ **最简单** - 几行代码就能用
2. ✅ **无需 Agent** - 只需要 SSH 访问
3. ✅ **成熟稳定** - 14K+ stars
4. ✅ **易于集成** - Python，直接导入
5. ✅ **完美配合 iCloud** - 结果保存到 iCloud

### 立即使用 Fabric：

```bash
# 安装
pip install fabric

# 创建集成文件
cat > fabric_integration.py << 'EOF'
#!/usr/bin/env python3
from fabric import Connection
from pathlib import Path
import json
from datetime import datetime

class KrisFabricExecutor:
    def __init__(self):
        self.icloud_root = Path.home() / "Library/Mobile Documents/com~apple~CloudDocs/kris-server"
        self.hosts = {}

    def add_host(self, name, hostname, username, key_file=None):
        self.hosts[name] = Connection(
            host=hostname,
            user=username,
            connect_kwargs={'key_filename': key_file} if key_file else {}
        )

    def execute(self, host_name, command):
        if host_name not in self.hosts:
            return {"error": "Unknown host"}

        result = self.hosts[host_name].run(command, hide=True, warn=True)

        response = {
            "success": result.ok,
            "output": result.stdout,
            "error": result.stderr,
            "exit_code": result.return_code,
            "timestamp": datetime.now().isoformat()
        }

        # 保存到 iCloud
        session_file = self.icloud_root / "terminal-sessions" / host_name / f"{datetime.now().strftime('%Y%m%d')}.json"
        session_file.parent.mkdir(parents=True, exist_ok=True)

        entries = json.load(open(session_file)) if session_file.exists() else []
        entries.append({"timestamp": datetime.now().isoformat(), "command": command, "result": response})
        json.dump(entries, open(session_file, 'w'), indent=2)

        return response

# 使用
executor = KrisFabricExecutor()
executor.add_host("linux", "192.168.1.100", "user", "~/.ssh/id_rsa")
print(executor.execute("linux", "ls -la"))
EOF

python3 fabric_integration.py
```

---

## 🚀 下一步

选择一个方案，我帮你完整集成到系统中！

推荐：**Fabric** (最简单，最适合你的需求)
