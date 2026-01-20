# 🚀 Fabric Glue 快速开始指南

## 5 分钟开始使用 Fabric Glue

**Fabric Glue** 是使用 Fabric (14K+ stars GitHub 库) 实现的跨平台命令执行系统，只需几行代码就能在远程服务器上执行命令并自动同步到 iCloud。

---

## 前置要求

### 1. 安装依赖

```bash
# 进入项目目录
cd ~/ios-automation

# 安装 Fabric
pip3 install fabric

# 或者安装所有依赖
pip3 install -r requirements.txt
```

### 2. 配置 SSH 访问

确保你可以 SSH 到目标服务器：

```bash
# 测试 SSH 连接
ssh user@your-server.com

# 如果需要生成 SSH 密钥
ssh-keygen -t rsa -b 4096
ssh-copy-id user@your-server.com
```

### 3. 确认 iCloud 同步

确保 iCloud Drive 已启用：
```bash
# macOS 上检查 iCloud 目录
ls ~/Library/Mobile\ Documents/com~apple~CloudDocs/
```

---

## 快速开始

### 方式 1: 一行代码执行命令

```python
from src.fabric_glue import quick_execute

# 一行代码在远程服务器执行命令
result = quick_execute("my-server", "ls -la")
print(result['output'])

# ✅ 命令已执行
# ✅ 结果已保存到 iCloud
# ✅ 可以在任何设备查看历史
```

### 方式 2: 完整用法

```python
from src.fabric_glue import FabricGlue

# 1. 创建实例
glue = FabricGlue(
    icloud_root="~/Library/Mobile Documents/com~apple~CloudDocs/kris-server"
)

# 2. 添加服务器
glue.add_host(
    name="production",
    hostname="prod.example.com",
    username="deploy",
    key_file="~/.ssh/prod_key"
)

glue.add_host(
    name="staging",
    hostname="staging.example.com",
    username="deploy",
    key_file="~/.ssh/staging_key"
)

# 3. 执行命令
result = glue.execute("production", "df -h")
print(f"磁盘使用: {result['output']}")

# 4. 在所有服务器执行
results = glue.execute_on_all("uptime")
for host, result in results.items():
    print(f"{host}: {result['output']}")

# 5. 保存配置（下次自动加载）
glue.save_config()
```

---

## 实际使用场景

### 场景 1: 检查服务器状态

```python
from src.fabric_glue import FabricGlue

glue = FabricGlue("~/Library/Mobile Documents/com~apple~CloudDocs/kris-server")

# 添加你的服务器
glue.add_host("web-server", "192.168.1.100", "admin", "~/.ssh/id_rsa")

# 检查各种状态
commands = [
    ("CPU", "top -bn1 | head -5"),
    ("内存", "free -h"),
    ("磁盘", "df -h"),
    ("网络", "netstat -tuln | head -10"),
]

for name, cmd in commands:
    result = glue.execute("web-server", cmd)
    print(f"\n=== {name} ===")
    print(result['output'])
```

### 场景 2: 部署应用

```python
from src.fabric_glue import FabricGlue

glue = FabricGlue("~/Library/Mobile Documents/com~apple~CloudDocs/kris-server")
glue.add_host("production", "prod.example.com", "deploy", "~/.ssh/deploy_key")

# 部署步骤
deploy_commands = [
    "cd /var/www/app",
    "git pull origin main",
    "npm install",
    "npm run build",
    "pm2 restart app"
]

for cmd in deploy_commands:
    print(f"执行: {cmd}")
    result = glue.execute("production", cmd)

    if not result['success']:
        print(f"❌ 失败: {result['error']}")
        break

    print(f"✅ 完成")

print("\n🎉 部署完成！")
```

### 场景 3: 批量管理多台服务器

```python
from src.fabric_glue import FabricGlue

glue = FabricGlue("~/Library/Mobile Documents/com~apple~CloudDocs/kris-server")

# 添加多台服务器
servers = {
    "web-1": "192.168.1.101",
    "web-2": "192.168.1.102",
    "web-3": "192.168.1.103",
}

for name, ip in servers.items():
    glue.add_host(name, ip, "admin", "~/.ssh/id_rsa")

# 在所有服务器更新软件包
results = glue.execute_on_all("apt-get update && apt-get upgrade -y")

for host, result in results.items():
    status = "✅" if result['success'] else "❌"
    print(f"{status} {host}: {result['exit_code']}")
```

### 场景 4: 查看历史和搜索

```python
from src.fabric_glue import FabricGlue

glue = FabricGlue("~/Library/Mobile Documents/com~apple~CloudDocs/kris-server")

# 查看今天的命令历史
history = glue.get_history()
print(f"今天执行了 {len(history)} 条命令\n")

for entry in history[:10]:  # 显示最近 10 条
    print(f"[{entry['timestamp']}] {entry['command']}")
    if entry['result']['success']:
        print(f"  ✅ 成功")
    else:
        print(f"  ❌ 失败: {entry['result']['error']}")
    print()

# 搜索特定命令
git_commands = glue.search_history("git")
print(f"\n包含 'git' 的命令: {len(git_commands)} 条")

for entry in git_commands:
    print(f"  {entry['command']}")
```

---

## 配置文件自动加载

### 第一次使用：手动配置

```python
from src.fabric_glue import FabricGlue

glue = FabricGlue("~/Library/Mobile Documents/com~apple~CloudDocs/kris-server")

# 添加所有服务器
glue.add_host("production", "prod.example.com", "deploy", "~/.ssh/prod_key")
glue.add_host("staging", "staging.example.com", "deploy", "~/.ssh/staging_key")
glue.add_host("development", "dev.example.com", "deploy", "~/.ssh/dev_key")

# 保存配置到 iCloud
glue.save_config()
print("✅ 配置已保存")
```

配置文件保存在：
```
~/Library/Mobile Documents/com~apple~CloudDocs/kris-server/
  └── shared-config/
      └── fabric-hosts.json
```

### 之后使用：自动加载

```python
from src.fabric_glue import FabricGlue

# 配置自动从 iCloud 加载！
glue = FabricGlue("~/Library/Mobile Documents/com~apple~CloudDocs/kris-server")

# 所有之前配置的服务器都已经加载
result = glue.execute("production", "ls -la")  # 直接使用！
```

### 配置文件格式

`fabric-hosts.json`:
```json
{
  "version": "1.0.0",
  "hosts": {
    "production": {
      "hostname": "prod.example.com",
      "username": "deploy",
      "port": 22
    },
    "staging": {
      "hostname": "staging.example.com",
      "username": "deploy",
      "port": 22
    }
  },
  "last_updated": "2025-01-20T10:30:00"
}
```

---

## iCloud 数据存储

### 目录结构

```
~/Library/Mobile Documents/com~apple~CloudDocs/kris-server/
├── shared-config/
│   └── fabric-hosts.json          # 服务器配置
├── terminal-sessions/
│   ├── production/
│   │   ├── session_20250120.json  # 今天的命令历史
│   │   └── session_20250119.json  # 昨天的历史
│   └── staging/
│       └── session_20250120.json
└── automation-logs/
    └── fabric-glue.log            # 执行日志
```

### 会话文件格式

`session_20250120.json`:
```json
[
  {
    "timestamp": "2025-01-20T10:30:00",
    "command": "ls -la",
    "result": {
      "success": true,
      "output": "total 48\ndrwxr-xr-x  12 user  staff   384 Jan 20 10:30 .\n...",
      "error": "",
      "exit_code": 0,
      "host": "production",
      "timestamp": "2025-01-20T10:30:00"
    }
  }
]
```

---

## 运行示例

### 交互式示例

```bash
# 运行交互式示例程序
python3 examples/fabric_glue_example.py
```

你会看到菜单：
```
======================================================================
Fabric Glue Examples - 胶水编程示例
======================================================================

请选择一个示例运行:

1. 基础用法 - 执行远程命令
2. 管理多个主机
3. 使用配置文件
4. 查看命令历史
5. 一行代码执行命令

0. 退出

选择 (0-5):
```

### 命令行使用

```bash
# 创建一个简单的脚本
cat > test_fabric.py << 'EOF'
from src.fabric_glue import quick_execute
import sys

if len(sys.argv) < 3:
    print("Usage: python test_fabric.py <host> <command>")
    sys.exit(1)

host = sys.argv[1]
command = " ".join(sys.argv[2:])

result = quick_execute(host, command)
print(result['output'])
EOF

# 使用脚本
python3 test_fabric.py my-server "ls -la"
python3 test_fabric.py my-server "df -h"
```

---

## 故障排查

### 问题 1: 连接失败

```python
# 错误: "Unknown host: my-server"

# 原因：主机未添加到配置
# 解决：
glue.add_host("my-server", "192.168.1.100", "user", "~/.ssh/id_rsa")
```

### 问题 2: SSH 认证失败

```python
# 错误: "Authentication failed"

# 原因：SSH 密钥权限问题或路径错误
# 解决：
# 1. 检查密钥权限
chmod 600 ~/.ssh/id_rsa

# 2. 检查密钥路径
glue.add_host("my-server", "192.168.1.100", "user",
              key_file="/Users/yourname/.ssh/id_rsa")  # 使用绝对路径
```

### 问题 3: 命令超时

```python
# 错误: "Command timeout after 30s"

# 原因：命令执行时间太长
# 解决：增加超时时间
result = glue.execute("my-server", "long-running-command", timeout=300)  # 5分钟
```

### 问题 4: iCloud 未同步

```bash
# 原因：iCloud 目录不存在或未启用
# 解决：
# 1. 确认 iCloud Drive 已启用
ls ~/Library/Mobile\ Documents/com~apple~CloudDocs/

# 2. 创建目录
mkdir -p ~/Library/Mobile\ Documents/com~apple~CloudDocs/kris-server
```

---

## 与其他方式的对比

### vs 直接 SSH

**直接 SSH**:
```bash
ssh user@server1 "ls -la"
ssh user@server2 "ls -la"
ssh user@server3 "ls -la"

# ❌ 需要手动记录输出
# ❌ 没有历史记录
# ❌ 多服务器管理困难
```

**Fabric Glue**:
```python
results = glue.execute_on_all("ls -la")

# ✅ 自动记录所有输出
# ✅ 保存到 iCloud
# ✅ 可搜索历史
# ✅ 批量管理简单
```

### vs Ansible

**Ansible**:
```yaml
# 需要写 YAML
---
- hosts: all
  tasks:
    - name: List files
      shell: ls -la

# ❌ 需要学习 YAML
# ❌ 配置复杂
# ❌ 简单任务也需要创建 playbook
```

**Fabric Glue**:
```python
# 简单的 Python 代码
results = glue.execute_on_all("ls -la")

# ✅ 纯 Python，无需学习新语法
# ✅ 简单任务简单代码
# ✅ 灵活的编程能力
```

---

## 下一步

### 1. 集成到现有项目

```python
# 在你的项目中导入
from src.fabric_glue import FabricGlue

# 添加到你的工具链
class MyAutomation:
    def __init__(self):
        self.fabric = FabricGlue("~/Library/Mobile Documents/com~apple~CloudDocs/kris-server")

    def deploy(self):
        self.fabric.execute("production", "deploy.sh")
```

### 2. 扩展功能

```python
# 继承 FabricGlue 添加自定义功能
class MyFabricGlue(FabricGlue):
    def deploy_app(self, host: str, app_name: str):
        commands = [
            f"cd /var/www/{app_name}",
            "git pull",
            "npm install",
            "npm run build",
            "pm2 restart app"
        ]

        for cmd in commands:
            result = self.execute(host, cmd)
            if not result['success']:
                return False
        return True
```

### 3. 创建自动化脚本

```python
#!/usr/bin/env python3
"""
每日健康检查脚本
"""
from src.fabric_glue import FabricGlue

glue = FabricGlue("~/Library/Mobile Documents/com~apple~CloudDocs/kris-server")

# 检查所有服务器
checks = [
    ("磁盘空间", "df -h | grep -v tmpfs"),
    ("内存使用", "free -h"),
    ("负载", "uptime"),
]

for check_name, command in checks:
    print(f"\n=== {check_name} ===")
    results = glue.execute_on_all(command)

    for host, result in results.items():
        print(f"{host}:")
        print(result['output'])
```

---

## 总结

**Fabric Glue** 让远程命令执行变得简单：

✅ **3 行代码**就能开始使用
✅ **自动保存**到 iCloud
✅ **多设备同步**
✅ **历史可搜索**
✅ **批量管理**多台服务器
✅ **基于成熟库** (Fabric 14K+ stars)

**立即开始**：
```bash
pip3 install fabric
python3 examples/fabric_glue_example.py
```
