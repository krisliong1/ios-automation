# iOS Automation - 跨平台终端系统

一个强大的跨平台终端自动化系统，支持 macOS、Linux、iOS 和 PowerShell (Windows) 系统间的命令转换和执行。

## 🌟 核心功能

### 1. **多系统支持**
- ✅ **macOS Terminal** (bash/zsh)
- ✅ **Linux Terminal** (bash)
- ✅ **iOS Terminal** (libimobiledevice)
- ✅ **PowerShell** (Windows)

### 2. **智能命令转换**
- 自动在不同操作系统之间转换命令
- 支持常用命令的跨平台翻译
- 示例：`ls -la` (Linux) ↔ `Get-ChildItem -Force` (PowerShell)

### 3. **路径管理**
- 跨系统路径转换
- 统一路径管理接口
- 支持 Unix 路径和 Windows 路径互转

### 4. **命令历史**
- 记录每个系统的命令历史
- 支持历史查询和清除

## 📦 项目结构

```
ios-automation/
├── src/
│   ├── __init__.py              # 包初始化
│   ├── terminal_base.py         # 终端基类
│   ├── macos_terminal.py        # macOS 终端实现
│   ├── linux_terminal.py        # Linux 终端实现
│   ├── ios_terminal.py          # iOS 终端实现
│   ├── powershell_terminal.py   # PowerShell 终端实现
│   ├── command_translator.py    # 命令翻译器
│   ├── path_manager.py          # 路径管理器
│   └── terminal_manager.py      # 终端管理器（主接口）
├── examples/
│   ├── basic_usage.py           # 基本使用示例
│   └── advanced_usage.py        # 高级使用示例
├── main.py                      # 主程序入口（交互式模式）
├── requirements.txt             # Python 依赖
└── README.md                    # 项目文档
```

## 🚀 快速开始

### 安装

```bash
# 克隆项目
git clone <repository-url>
cd ios-automation

# 安装依赖（可选）
pip install -r requirements.txt
```

### 运行交互式界面

```bash
python3 main.py
```

### 使用示例

```bash
# 运行基本示例
cd examples
python3 basic_usage.py

# 运行高级示例
python3 advanced_usage.py
```

## 💻 使用方法

### 1. 基本命令执行

```python
from src.terminal_manager import TerminalManager

# 创建管理器
manager = TerminalManager()

# 设置当前系统
manager.set_current_terminal('linux')

# 执行命令
result = manager.execute('ls -la')
print(result['output'])
```

### 2. 跨系统命令转换

```python
# 将 Linux 命令转换为 PowerShell 并执行
result = manager.translate_and_execute(
    command='ls -la',
    source='linux',
    target='powershell'
)

print(f"原始命令: {result['original_command']}")
print(f"转换后: {result['translated_command']}")
```

### 3. 在所有系统上执行

```python
# 在所有支持的系统上执行命令
results = manager.execute_on_all('ls', source='linux')

for system, result in results.items():
    print(f"{system}: {result['success']}")
```

### 4. 路径管理

```python
# 更改目录
manager.change_directory('/tmp')

# 获取当前路径
current_path = manager.get_current_path()
print(f"当前路径: {current_path}")

# 同步所有系统的路径
manager.sync_paths()
```

### 5. 查看命令转换建议

```python
# 获取命令在各系统的转换
suggestions = manager.get_translation_suggestions('ls -la', 'linux')

for system, translated in suggestions.items():
    print(f"{system}: {translated}")
```

## 📋 命令转换示例

### Linux/macOS → PowerShell

| Linux/macOS | PowerShell |
|-------------|------------|
| `ls -la` | `Get-ChildItem -Force` |
| `cd /path` | `Set-Location /path` |
| `rm -rf file` | `Remove-Item -Recurse -Force file` |
| `cp -r src dst` | `Copy-Item -Recurse src dst` |
| `cat file` | `Get-Content file` |
| `ps aux` | `Get-Process` |
| `kill -9 pid` | `Stop-Process -Force -Id pid` |

### PowerShell → Linux/macOS

| PowerShell | Linux/macOS |
|------------|-------------|
| `Get-ChildItem` | `ls` |
| `Set-Location` | `cd` |
| `Remove-Item` | `rm` |
| `Copy-Item` | `cp` |
| `Get-Content` | `cat` |
| `Clear-Host` | `clear` |
| `Get-Process` | `ps aux` |

## 🎯 主要特性

### 1. TerminalManager
核心管理类，提供统一接口：

```python
manager = TerminalManager()

# 系统管理
manager.set_current_terminal('linux')
manager.list_systems()

# 命令执行
manager.execute(command)
manager.translate_and_execute(command, source, target)
manager.execute_on_all(command, source)

# 路径管理
manager.change_directory(path)
manager.get_current_path()
manager.sync_paths()

# 信息查询
manager.get_status()
manager.get_terminal_info()
manager.get_command_history()
```

### 2. CommandTranslator
智能命令转换：

```python
translator = CommandTranslator()

# 翻译命令
translated = translator.translate('ls -la', 'linux', 'powershell')

# 获取常用命令
common_commands = translator.get_common_commands()

# 获取翻译建议
suggestions = translator.suggest_translation('ls', 'linux')
```

### 3. PathManager
跨平台路径管理：

```python
path_manager = PathManager()

# 路径转换
unix_path = "/mnt/c/Users/name"
win_path = path_manager.convert_path(unix_path, 'linux', 'powershell')
# 结果: "C:\Users\name"

# 路径规范化
normalized = path_manager.normalize_path(path, 'powershell')

# 路径同步
path_manager.sync_paths(base_path, base_system)
```

## 📱 iOS 支持

iOS 终端支持需要 libimobiledevice 工具集：

```bash
# macOS 安装
brew install libimobiledevice

# Linux 安装
sudo apt-get install libimobiledevice-utils
```

iOS 相关命令：
- `ideviceinfo` - 获取设备信息
- `idevicefs ls` - 列出文件
- `idevicefs cat` - 读取文件

## 🔧 交互式模式功能

运行 `python3 main.py` 启动交互式模式，提供以下功能：

1. **执行命令** - 在当前系统执行命令
2. **翻译并执行** - 跨系统翻译和执行
3. **全系统执行** - 在所有系统上执行
4. **更改目录** - 改变工作目录
5. **切换系统** - 切换当前终端系统
6. **查看翻译建议** - 显示命令的所有翻译
7. **查看常用命令** - 显示跨平台常用命令
8. **系统信息** - 查看终端系统信息
9. **命令历史** - 查看历史命令
10. **状态查看** - 查看整体状态

## 🌐 支持的命令类别

- **文件操作**: ls, cat, rm, cp, mv, touch, mkdir
- **目录操作**: cd, pwd
- **系统信息**: ps, kill, uname, system_profiler
- **包管理**: apt-get, brew, yum, choco
- **其他**: clear, echo, grep, find

## 🛠️ 扩展开发

### 添加新的终端系统

1. 继承 `TerminalSystem` 基类
2. 实现 `execute_command()` 方法
3. 实现 `translate_from()` 方法
4. 在 `TerminalManager` 中注册

```python
from src.terminal_base import TerminalSystem

class CustomTerminal(TerminalSystem):
    def __init__(self):
        super().__init__("Custom", "custom_platform")

    def execute_command(self, command: str):
        # 实现命令执行
        pass

    def translate_from(self, command: str, source_system: str):
        # 实现命令翻译
        pass
```

### 添加新的命令翻译

编辑 `src/command_translator.py`，在翻译映射中添加新的规则。

## 📄 许可证

本项目为示例项目，可自由使用和修改。

## 👨‍💻 贡献

欢迎提交 Issue 和 Pull Request！

## 📞 联系方式

如有问题或建议，请创建 Issue。

---

**注意**: 这是一个自动化工具，执行命令前请确保理解命令的作用。某些命令可能需要管理员权限。
