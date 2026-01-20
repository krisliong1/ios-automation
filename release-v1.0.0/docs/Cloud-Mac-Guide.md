# 云端 Mac 使用指南 - 在 iPad Pro 上开发

## 🎯 推荐服务

### 1. MacStadium（最佳）
- **价格**: $79/月
- **优势**: 真实 Mac，完整 Xcode
- **网址**: https://www.macstadium.com

### 2. AWS Mac Instances
- **价格**: $1.08/小时
- **优势**: 按需付费
- **网址**: https://aws.amazon.com/ec2/instance-types/mac/

### 3. Flow（免费试用）
- **价格**: 免费 20 小时/月
- **优势**: 专为移动开发设计
- **网址**: https://www.flow.swiss

---

## 🚀 快速开始（MacStadium 示例）

### 步骤 1: 注册账号
```
1. 访问 macstadium.com
2. 选择 "Mini" 套餐（$79/月）
3. 注册并付款
4. 等待服务器配置（~1 小时）
```

### 步骤 2: 从 iPad 连接

#### 使用 Jump Desktop（推荐）
```
1. 在 iPad 安装 "Jump Desktop" App
2. 添加新连接：
   - 类型：VNC 或 RDP
   - 地址：MacStadium 提供的 IP
   - 用户名：admin
   - 密码：MacStadium 提供
3. 连接成功！
```

### 步骤 3: 克隆项目
```bash
# 在云端 Mac 的 Terminal 运行
git clone https://github.com/krisliong1/ios-automation.git
cd ios-automation
```

### 步骤 4: 打开 Xcode
```
双击 .xcodeproj 文件
或
xed .
```

### 步骤 5: 运行项目
```
Cmd + R
```

---

## 💰 价格对比

| 服务 | 价格 | 适合场景 |
|-----|------|---------|
| MacStadium Mini | $79/月 | 长期使用 |
| AWS Mac | $1/小时 | 临时使用 |
| Flow | 免费 20h | 测试尝试 |

---

## 📱 iPad 远程工具

### Jump Desktop（推荐）
- **价格**: $14.99（一次性）
- **优势**: 流畅，支持手势
- **下载**: App Store

### Microsoft Remote Desktop（免费）
- **价格**: 免费
- **优势**: 稳定
- **下载**: App Store

---

## ⚡ 使用技巧

### 1. iPad 上的快捷键
```
- Cmd + Tab: 切换应用
- Cmd + C/V: 复制粘贴
- Cmd + R: 运行 Xcode
```

### 2. 优化网络
```
- 使用 WiFi（不要用蜂窝网络）
- 低延迟模式：降低画质
```

### 3. 文件传输
```
- 使用 iCloud Drive
- 或 Git 同步
```

---

## 🎯 完整工作流

```
iPad Pro
  ↓ (远程桌面)
云端 Mac
  ↓
运行 Xcode
  ↓
编译项目
  ↓
生成 App
  ↓
通过 TestFlight 安装到 iPad
```

---

## 💡 省钱技巧

1. **只在需要时开机**
   - AWS 可以随时停止
   - 只为使用时间付费

2. **使用 Flow 免费额度**
   - 每月 20 小时
   - 足够学习和测试

3. **与朋友分摊**
   - MacStadium 支持多用户

---

**想要详细的某个服务的设置教程？告诉我！**
