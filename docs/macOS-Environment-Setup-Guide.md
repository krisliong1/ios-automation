# macOS 开发环境自动配置指南

## 📖 概述

这是一个**完全自动化的 macOS 开发环境配置系统**，可以：

✅ **自动检测** Mac 型号和系统兼容性
✅ **智能配置** Xcode 开发环境
✅ **自动启用** SSH 远程访问
✅ **内置** Terminal 脚本
✅ **一键完成** 所有配置

---

## 🚀 快速开始

### 方法 1: 一键完整设置（推荐）

```
1. 打开快捷指令 App
2. 搜索"完整 macOS 环境设置"
3. 点击运行
4. 等待完成（约 2-5 分钟）
```

系统会自动：
- ✅ 检测 Mac 型号和系统
- ✅ 配置 Xcode
- ✅ 启用 SSH 服务器
- ✅ 创建 Terminal 脚本

### 方法 2: 分步配置

#### 步骤 1: 检测系统
```
快捷指令: "检测 Mac 系统兼容性"
```

#### 步骤 2: 配置 Xcode
```
快捷指令: "配置 Xcode"
```

#### 步骤 3: 配置 SSH
```
快捷指令: "配置 SSH 服务器"
```

#### 步骤 4: 配置 Terminal
```
快捷指令: "配置内置 Terminal"
```

---

## 📱 支持的设备

### Mac 型号
- ✅ MacBook Pro (所有型号)
- ✅ MacBook Air (所有型号)
- ✅ iMac (所有型号)
- ✅ Mac mini (所有型号)
- ✅ Mac Studio (所有型号)
- ✅ Mac Pro (所有型号)

### 芯片类型
- ✅ Apple Silicon (M1/M2/M3)
- ✅ Intel (所有型号)

### 系统要求
| 项目 | 最低要求 | 推荐 |
|-----|---------|------|
| macOS | 12.0 (Monterey) | 14.0+ (Sonoma) |
| 内存 | 8 GB | 16 GB+ |
| 存储 | 50 GB 可用 | 100 GB+ |

---

## 🔍 系统检测

### 自动检测的信息

系统会检测以下内容：

```
📱 Mac 系统信息

型号: MacBook Pro
芯片: Apple M2
系统: macOS 14.0
内存: 16 GB
存储: 512 GB

✅ 系统完全兼容
```

### 兼容性判断

#### ✅ 完全兼容
- Apple Silicon + macOS 14.0+
- Intel + macOS 13.0+

#### ⚠️ 需要升级
- macOS 版本 < 12.0
- 内存 < 8GB
- 存储 < 50GB 可用

### 推荐版本

| 当前版本 | 推荐升级到 |
|---------|----------|
| < 12.0 | macOS 14.0 Sonoma |
| 12.0-12.x | macOS 13.0 Ventura |
| 13.0+ | 当前版本即可 |

---

## 🔧 Xcode 配置

### 自动配置流程

```
1. 检测 Xcode 是否已安装
   ├─ 已安装 → 获取版本 → 启动
   └─ 未安装 → 打开 App Store 下载页面

2. 验证 Xcode 版本
   └─ 确保版本兼容当前 macOS

3. 启动 Xcode
   └─ 自动打开 Xcode.app
```

### 手动安装 Xcode

如果自动配置失败：

#### 方法 1: App Store（推荐）
```
1. 打开 App Store
2. 搜索 "Xcode"
3. 点击"获取"
4. 等待下载完成（10-15 GB）
```

#### 方法 2: 官网下载
```
1. 访问 https://developer.apple.com/xcode/
2. 下载 Xcode .xip 文件
3. 双击解压
4. 移动到 /Applications/
```

### Xcode 版本对应

| macOS 版本 | 推荐 Xcode |
|-----------|-----------|
| 14.0 Sonoma | Xcode 15+ |
| 13.0 Ventura | Xcode 14+ |
| 12.0 Monterey | Xcode 13+ |

---

## 🔐 SSH 服务器配置

### 功能说明

启用 SSH 后，你可以：
- ✅ 从其他设备远程连接到 Mac
- ✅ 远程执行命令
- ✅ 传输文件（scp/sftp）
- ✅ 运行自动化脚本

### 自动配置

运行快捷指令："配置 SSH 服务器"

系统会：
1. 检测 SSH 服务状态
2. 如未启用，自动启用
3. 显示连接信息

### 连接信息

```
🔐 SSH 连接信息

地址: 192.168.1.100
端口: 22
用户: kris

💡 连接命令:
ssh kris@192.168.1.100
```

### 从其他设备连接

#### 从 Mac/Linux:
```bash
ssh username@ip-address
```

#### 从 Windows:
```cmd
ssh username@ip-address
```
或使用 PuTTY

#### 从 iPhone/iPad:
使用 Termius 或 Prompt 等 SSH 客户端

### SSH 安全建议

1. **使用密钥认证**
```bash
# 生成密钥对
ssh-keygen -t ed25519

# 复制公钥到服务器
ssh-copy-id username@ip-address
```

2. **修改默认端口**
```bash
# 编辑 SSH 配置
sudo nano /etc/ssh/sshd_config

# 修改端口（例如改为 2222）
Port 2222
```

3. **禁用密码登录**
```bash
# 在 sshd_config 中设置
PasswordAuthentication no
```

---

## 💻 Terminal 配置

### 内置 Terminal 脚本

系统会创建一个自动化 Terminal 脚本，包含：

```bash
#!/bin/bash

# iOS 自动化开发 Terminal
echo "🚀 iOS 自动化开发环境"

# 设置环境变量
export PATH="/usr/local/bin:/usr/bin:/bin"
export LANG="en_US.UTF-8"

# 显示系统信息
echo "📱 系统: $(sw_vers -productVersion)"
echo "🔨 Xcode: $(xcodebuild -version)"

# 可用命令
echo "💡 可用命令:"
echo "   xcode  - 启动 Xcode"
echo "   build  - 构建项目"
echo "   test   - 运行测试"
```

### 使用 Terminal

#### 方法 1: 快捷指令
```
运行: "启动自动化 Terminal"
```

#### 方法 2: 手动运行
```bash
~/.automation_terminal.sh
```

### Terminal 功能

配置后的 Terminal 包含：

| 命令 | 功能 |
|-----|------|
| `xcode` | 启动 Xcode |
| `build` | 构建当前项目 |
| `test` | 运行测试 |
| `ssh` | 查看 SSH 信息 |
| `help` | 显示帮助 |

---

## 📥 系统升级

### 检查推荐版本

运行快捷指令："下载推荐 macOS 版本"

会显示：
```
📥 推荐升级到 macOS 14.0

当前: macOS 12.5
推荐: macOS 14.0 Sonoma

建议升级以获得最佳开发体验。
```

### 升级方法

#### 方法 1: 系统设置（推荐）
```
1. 打开"系统设置"
2. 点击"通用"
3. 点击"软件更新"
4. 点击"立即升级"
```

#### 方法 2: 完整安装器
```
1. 访问 Apple 官网
2. 下载完整安装器
3. 创建可引导 USB
4. 全新安装
```

### 升级前准备

✅ **必做事项：**
- 备份数据（Time Machine）
- 确保至少 50GB 可用空间
- 关闭所有应用
- 连接电源

⚠️ **注意事项：**
- 升级需要 30-60 分钟
- 期间 Mac 会重启多次
- 不要中断升级过程

---

## 🎯 完整设置流程

### 自动化流程图

```
开始
  │
  ▼
检测 Mac 系统
  ├─ 型号: MacBook Pro
  ├─ 芯片: Apple M2
  ├─ 系统: macOS 14.0
  └─ 兼容性: ✅
  │
  ▼
配置 Xcode
  ├─ 检测: 已安装
  ├─ 版本: Xcode 15.0
  └─ 启动: ✅
  │
  ▼
配置 SSH
  ├─ 启用远程登录
  ├─ 获取 IP: 192.168.1.100
  └─ 显示连接信息
  │
  ▼
配置 Terminal
  ├─ 创建脚本
  ├─ 设置权限
  └─ 就绪: ✅
  │
  ▼
完成 🎉
```

### 执行时间

| 步骤 | 预计时间 |
|-----|---------|
| 系统检测 | 10 秒 |
| Xcode 配置 | 30 秒 |
| SSH 配置 | 20 秒 |
| Terminal 配置 | 10 秒 |
| **总计** | **~2 分钟** |

---

## 📊 配置验证

### 验证 Xcode

```bash
# 检查 Xcode 版本
xcodebuild -version

# 输出示例:
# Xcode 15.0
# Build version 15A240d
```

### 验证 SSH

```bash
# 检查 SSH 服务状态
sudo systemsetup -getremotelogin

# 输出: Remote Login: On
```

### 验证 Terminal

```bash
# 检查脚本是否存在
ls -la ~/.automation_terminal.sh

# 输出: -rwxr-xr-x ... .automation_terminal.sh
```

---

## 🐛 故障排除

### 问题 1: 系统检测失败

**症状：** 无法获取系统信息

**解决方法：**
```bash
# 手动检查系统版本
sw_vers

# 手动检查硬件信息
system_profiler SPHardwareDataType
```

### 问题 2: Xcode 无法启动

**症状：** 运行快捷指令后 Xcode 未打开

**解决方法：**
```bash
# 手动打开 Xcode
open -a Xcode

# 或重置 Xcode
sudo xcode-select --reset
```

### 问题 3: SSH 启用失败

**症状：** SSH 服务无法启用

**可能原因：**
- 权限不足
- 防火墙阻止

**解决方法：**
```bash
# 手动启用 SSH
sudo systemsetup -setremotelogin on

# 检查防火墙
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate
```

### 问题 4: Terminal 脚本无法执行

**症状：** Permission denied

**解决方法：**
```bash
# 添加执行权限
chmod +x ~/.automation_terminal.sh

# 然后运行
~/.automation_terminal.sh
```

---

## 💡 高级配置

### 自定义 Terminal 脚本

编辑脚本：
```bash
nano ~/.automation_terminal.sh
```

添加自定义命令：
```bash
# 自定义函数
function mycommand() {
    echo "执行自定义命令"
}

# 添加别名
alias ll='ls -la'
alias gs='git status'
```

### 配置 SSH 密钥

```bash
# 1. 生成密钥
ssh-keygen -t ed25519 -C "your_email@example.com"

# 2. 复制公钥
cat ~/.ssh/id_ed25519.pub | pbcopy

# 3. 添加到服务器
ssh-copy-id username@server
```

### Xcode 命令行工具

```bash
# 安装命令行工具
xcode-select --install

# 设置默认 Xcode
sudo xcode-select -s /Applications/Xcode.app

# 验证
xcode-select -p
```

---

## 📚 快捷指令列表

| 快捷指令 | 功能 |
|---------|------|
| 完整 macOS 环境设置 | 一键配置所有功能 |
| 检测 Mac 系统兼容性 | 检测系统信息 |
| 配置 Xcode | 安装并配置 Xcode |
| 启动 Xcode | 快速启动 Xcode |
| 配置 SSH 服务器 | 启用 SSH 访问 |
| 获取 SSH 连接信息 | 查看连接地址 |
| 配置内置 Terminal | 创建自动化脚本 |
| 启动自动化 Terminal | 打开配置好的 Terminal |
| 下载推荐 macOS 版本 | 检查系统升级 |

---

## 🌟 使用场景

### 场景 1: 新 Mac 初始化

```
1. 打开快捷指令
2. 运行"完整 macOS 环境设置"
3. 等待 2 分钟
4. 开始开发！
```

### 场景 2: 远程开发

```
1. 配置 SSH 服务器
2. 获取连接信息
3. 从其他设备连接
4. 远程执行命令
```

### 场景 3: 团队协作

```
1. 所有成员运行相同配置
2. 统一开发环境
3. 减少环境差异问题
```

---

## 🔐 安全建议

### 1. SSH 安全
- ✅ 使用密钥认证
- ✅ 修改默认端口
- ✅ 禁用 root 登录
- ✅ 配置防火墙

### 2. 系统安全
- ✅ 启用 FileVault 磁盘加密
- ✅ 使用强密码
- ✅ 启用双因素认证
- ✅ 定期更新系统

### 3. 开发安全
- ✅ 不提交敏感信息到 Git
- ✅ 使用环境变量存储密钥
- ✅ 定期备份项目
- ✅ 使用版本控制

---

## 📖 代码示例

### 完整配置示例

```swift
import Foundation

let manager = MacOSEnvironmentManager()

Task {
    // 完整设置
    try await manager.completeSetup()

    print("✅ 环境配置完成")
}
```

### 单独配置示例

```swift
// 只配置 Xcode
try await manager.setupXcode()

// 只配置 SSH
try await manager.setupSSHServer()

// 只配置 Terminal
try await manager.setupTerminal()
```

---

## 🎉 总结

macOS 开发环境自动配置系统为你提供：

✅ **一键配置** - 2 分钟完成所有设置
✅ **智能检测** - 自动识别 Mac 型号和系统
✅ **完整功能** - Xcode + SSH + Terminal
✅ **易于使用** - 快捷指令，无需命令行
✅ **安全可靠** - 遵循最佳实践

现在就试试：

```
打开快捷指令 → 搜索"完整 macOS 环境设置" → 运行
```

**2 分钟后，你的 Mac 就准备好开发 iOS 应用了！** 🚀

---

**Happy Coding! 🎉**
