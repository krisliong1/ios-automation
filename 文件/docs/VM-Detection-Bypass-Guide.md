# 虚拟机检测绕过完整指南

> ⚠️ **重要警告**
> 本指南仅用于**合法的开发和测试目的**
> 请遵守软件许可协议，了解并承担相关风险

**更新日期**: 2026-01-17
**适用系统**: macOS 12.0+ (Monterey, Ventura, Sonoma, Sequoia)

---

## 📑 目录

- [问题说明](#问题说明)
- [检测原理](#检测原理)
- [解决方案](#解决方案)
- [方法 1：VMHide 内核扩展](#方法-1vmhide-内核扩展推荐)
- [方法 2：Tart 虚拟化工具](#方法-2tart-虚拟化工具)
- [方法 3：手动配置](#方法-3手动配置)
- [验证方法](#验证方法)
- [常见问题](#常见问题)

---

## 问题说明

### Xcode 为什么会检测虚拟机？

**主要原因**:
1. ✅ **防止滥用** - 防止在未授权的虚拟环境中运行
2. ✅ **性能保证** - 确保在最佳环境中开发
3. ✅ **功能限制** - 某些功能在虚拟机中不可用

### 检测后的影响

如果 Xcode 检测到虚拟机：
- ❌ **App Store 无法登录** - 无法使用 Apple ID
- ❌ **某些功能受限** - 模拟器可能无法正常工作
- ❌ **性能警告** - 提示虚拟环境性能问题
- ⚠️ **可能拒绝运行** - 部分版本完全拒绝在 VM 中运行

---

## 检测原理

### macOS 如何检测虚拟机？

#### 1. kern.hv_vmm_present（主要方法）

这是 **Xcode 使用的主要检测方式**：

```bash
# 检查虚拟机存在标志
sysctl kern.hv_vmm_present

# 输出:
# kern.hv_vmm_present: 1  → 虚拟机
# kern.hv_vmm_present: 0  → 物理机
```

**技术原理**:
- macOS 内核维护一个 Hypervisor 存在标志
- 当系统在虚拟机中运行时，这个值为 1
- Xcode 会检查这个值

#### 2. 硬件模型检测

```bash
# 查看硬件模型
sysctl hw.model

# 虚拟机输出示例:
# hw.model: VMware7,1
# hw.model: VirtualBox
# hw.model: QEMU Virtual Machine
```

#### 3. CPU 特性检测

```bash
# 查看 CPU 特性
sysctl machdep.cpu.features
sysctl machdep.cpu.extfeatures
```

虚拟机中某些 CPU 特性会缺失或不同。

#### 4. 系统信息检测

通过 IOKit 检查：
- 制造商信息（QEMU、VMware等）
- 设备名称（包含 Virtual、VM 等关键词）
- BIOS 信息

#### 5. 网络接口检测

虚拟机通常有特定的网络接口名称：
- `vmnet0`、`vmnet1` - VMware
- `vboxnet0` - VirtualBox
- `virbr0` - QEMU

---

## 解决方案

### 方法对比

| 方法 | 难度 | 效果 | 推荐度 | 需要 SIP |
|------|------|------|--------|----------|
| VMHide | 中等 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 是 |
| Tart | 简单 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | 否 |
| 手动配置 | 困难 | ⭐⭐⭐ | ⭐⭐⭐ | 是 |

---

## 方法 1：VMHide 内核扩展（推荐）

### 什么是 VMHide？

[VMHide](https://github.com/Carnations-Botanica/VMHide) 是一个开源内核扩展，专门用于隐藏 `kern.hv_vmm_present` 检测。

**优点**:
- ✅ 最有效 - 直接修改内核返回值
- ✅ 稳定可靠 - 专门针对 macOS 15 Sequoia 开发
- ✅ 开源免费 - GitHub 上公开源代码
- ✅ 持续更新 - 支持最新 macOS 版本

**缺点**:
- ⚠️ 需要禁用 SIP
- ⚠️ 需要管理员权限
- ⚠️ 系统更新后需要重新加载

### 安装步骤

#### 步骤 1：禁用 SIP

1. **重启 Mac 进入恢复模式**:
   - Intel Mac: 开机时按住 `⌘ + R`
   - Apple Silicon: 按住电源键直到看到"选项"

2. **打开终端**:
   - 菜单栏 → 实用工具 → 终端

3. **禁用 SIP**:
   ```bash
   csrutil disable
   ```

4. **重启进入正常模式**:
   ```bash
   reboot
   ```

5. **验证 SIP 状态**:
   ```bash
   csrutil status
   # 输出: System Integrity Protection status: disabled
   ```

#### 步骤 2：下载 VMHide

```bash
# 克隆仓库
git clone https://github.com/Carnations-Botanica/VMHide.git
cd VMHide

# 或者直接下载 Release
# https://github.com/Carnations-Botanica/VMHide/releases
```

#### 步骤 3：编译（如果需要）

```bash
# 如果下载的是源代码
xcodebuild -project VMHide.xcodeproj -scheme VMHide

# 编译后的 kext 在 build/ 目录
```

#### 步骤 4：安装内核扩展

```bash
# 复制到系统扩展目录
sudo cp -R VMHide.kext /Library/Extensions/

# 设置权限
sudo chown -R root:wheel /Library/Extensions/VMHide.kext
sudo chmod -R 755 /Library/Extensions/VMHide.kext

# 重建内核扩展缓存
sudo kextcache -i /

# 加载扩展
sudo kextload /Library/Extensions/VMHide.kext
```

#### 步骤 5：配置（可选）

VMHide 允许你配置哪些进程看到真实值：

```bash
# 编辑配置文件
sudo nano /Library/Extensions/VMHide.kext/Contents/Info.plist

# 添加进程白名单（示例）
<key>FilteredProcesses</key>
<array>
    <string>Xcode</string>
    <string>App Store</string>
</array>
```

#### 步骤 6：验证

```bash
# 检查扩展是否加载
kextstat | grep VMHide
# 输出: com.carnations.VMHide (1.0.0)

# 检查 kern.hv_vmm_present
sysctl kern.hv_vmm_present
# 输出: kern.hv_vmm_present: 0 ✅
```

### 设置开机自动加载

创建 LaunchDaemon：

```bash
# 创建 plist 文件
sudo nano /Library/LaunchDaemons/com.vmhide.load.plist
```

内容：
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
"http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.vmhide.load</string>
    <key>ProgramArguments</key>
    <array>
        <string>/sbin/kextload</string>
        <string>/Library/Extensions/VMHide.kext</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
</dict>
</plist>
```

加载：
```bash
sudo launchctl load /Library/LaunchDaemons/com.vmhide.load.plist
```

---

## 方法 2：Tart 虚拟化工具

### 什么是 Tart？

[Tart](https://tart.run/) 是一个使用 Apple Virtualization.framework 的虚拟机工具，天然更难被检测。

**优点**:
- ✅ 不需要禁用 SIP
- ✅ 使用 Apple 原生框架
- ✅ 性能接近原生
- ✅ 易于使用

**缺点**:
- ⚠️ 仅支持 Apple Silicon
- ⚠️ 需要 macOS 12+
- ⚠️ 可能仍被部分检测

### 安装和使用

#### 安装 Tart

```bash
# 使用 Homebrew
brew install cirruslabs/cli/tart

# 验证安装
tart --version
```

#### 创建虚拟机

```bash
# 从 IPSW 创建
tart create macos-sonoma --from-ipsw=~/Downloads/macOS-Sonoma.ipsw

# 或者从预构建镜像
tart clone ghcr.io/cirruslabs/macos-sonoma:latest macos-sonoma
```

#### 运行虚拟机

```bash
# 启动虚拟机
tart run macos-sonoma

# 带 VNC 访问
tart run --vnc macos-sonoma
```

#### 配置虚拟机

```bash
# 设置 CPU 核心数
tart set macos-sonoma --cpu 8

# 设置内存
tart set macos-sonoma --memory 16

# 设置磁盘大小
tart set macos-sonoma --disk-size 100
```

### Tart 的检测规避

Tart 使用 Apple 的 Virtualization.framework，检测特征较少：
- ✅ 不会修改硬件模型
- ✅ 网络接口命名标准
- ⚠️ 但 `kern.hv_vmm_present` 仍可能为 1

**组合使用**:
```bash
# 1. 使用 Tart 创建虚拟机
# 2. 在虚拟机内安装 VMHide
# 3. 达到最佳隐藏效果
```

---

## 方法 3：手动配置

### QEMU 配置（高级）

如果你使用 QEMU，可以手动配置：

```bash
qemu-system-x86_64 \
  -cpu host,kvm=off,hv_vendor_id=null \
  -smbios type=0,vendor="Apple Inc." \
  -smbios type=1,manufacturer="Apple Inc.",product="MacBookPro18,1" \
  -device virtio-net-pci,netdev=net0,mac=AA:BB:CC:DD:EE:FF \
  -netdev user,id=net0 \
  ...
```

**关键参数**:
- `kvm=off` - 隐藏 KVM
- `hv_vendor_id=null` - 隐藏 Hypervisor 厂商
- `smbios` - 模拟真实硬件信息

### UTM 配置

UTM 是 macOS 上的 QEMU 图形界面：

1. 打开 UTM → 编辑虚拟机
2. QEMU → 取消勾选 "UEFI Boot"
3. QEMU → 添加参数:
   ```
   -cpu host,kvm=off
   ```
4. 系统 → 修改硬件型号为真实 Mac 型号

---

## 验证方法

### 检测列表

运行以下命令验证是否成功绕过：

```bash
# 1. 主要检测（最重要）
sysctl kern.hv_vmm_present
# ✅ 应该返回 0

# 2. 硬件模型
sysctl hw.model
# ✅ 不应包含 VM、Virtual 等关键词

# 3. 系统信息
system_profiler SPHardwareDataType
# ✅ 检查制造商和型号

# 4. 网络接口
ifconfig -a
# ✅ 不应有 vmnet、vnet 等虚拟接口
```

### 使用检测工具

```bash
# 使用我们的检测管理器
# 在快捷指令中运行 "检测虚拟机" Intent

# 或者运行我们的 Swift 代码
swift run VMDetectionManager
```

### Xcode 功能测试

1. **启动 Xcode**
   ```bash
   open -a Xcode
   ```

2. **尝试登录 Apple ID**
   - Xcode → Preferences → Accounts
   - 添加 Apple ID
   - ✅ 应该能成功登录

3. **运行模拟器**
   - 创建新项目
   - 选择模拟器
   - 运行（⌘ + R）
   - ✅ 应该能正常运行

4. **App Store 测试**
   - 打开 App Store
   - 尝试登录
   - ✅ 应该能正常使用

---

## 常见问题

### Q1: VMHide 加载失败？

**可能原因**:
- SIP 未禁用
- 权限设置不正确
- macOS 版本不兼容

**解决方法**:
```bash
# 检查 SIP 状态
csrutil status

# 重新设置权限
sudo chown -R root:wheel /Library/Extensions/VMHide.kext
sudo chmod -R 755 /Library/Extensions/VMHide.kext

# 查看加载错误
sudo kextload -v 6 /Library/Extensions/VMHide.kext
```

### Q2: 禁用 SIP 安全吗？

**风险**:
- ⚠️ 降低系统安全性
- ⚠️ 恶意软件可能利用

**建议**:
- 仅在开发虚拟机中禁用
- 物理机保持启用
- 了解风险并小心操作

### Q3: 系统更新后 VMHide 失效？

**原因**:
- 系统更新重建了内核缓存
- 内核扩展被移除

**解决**:
```bash
# 重新加载
sudo kextload /Library/Extensions/VMHide.kext

# 重建缓存
sudo kextcache -i /
```

### Q4: Tart 虚拟机仍被检测？

**组合方案**:
1. 使用 Tart 创建虚拟机
2. 在虚拟机内安装 VMHide
3. 配置虚拟机参数

### Q5: 合法性问题？

**说明**:
- ✅ 用于开发测试 - 合法
- ✅ 学习研究目的 - 合法
- ❌ 绕过软件授权 - 违法
- ❌ 商业滥用 - 违法

**建议**: 遵守软件许可协议

---

## 参考资源

### 官方文档
- [Apple Virtualization Framework](https://developer.apple.com/documentation/virtualization)
- [macOS Security Guide](https://support.apple.com/guide/security/welcome/web)

### 开源工具
- [VMHide](https://github.com/Carnations-Botanica/VMHide) - 内核扩展隐藏检测
- [Tart](https://tart.run/) - Apple Silicon 虚拟化
- [UTM](https://mac.getutm.app/) - QEMU 图形界面
- [macosvm](https://github.com/s-u/macosvm) - macOS VM 工具

### 技术文章
- [VM Detection Bypass Guide](https://guidedhacking.com/threads/how-to-bypass-virtual-machine-detection.13737/)
- [VMAware](https://github.com/kernelwernel/VMAware) - VM 检测库

---

## 总结

### 推荐方案

**场景 1: 日常开发（推荐）**
```
使用 Tart + 简单配置
→ 不需要禁用 SIP
→ 性能好，易用
```

**场景 2: 需要完美隐藏**
```
使用 VMHide 内核扩展
→ 完全隐藏虚拟机特征
→ Xcode、App Store 正常使用
```

**场景 3: 学习研究**
```
手动配置 + 多种方法组合
→ 深入理解检测原理
→ 自定义配置
```

### 最佳实践

1. ✅ **先验证检测** - 使用检测工具确认问题
2. ✅ **选择合适方案** - 根据需求选择方法
3. ✅ **测试验证** - 确保绕过成功
4. ✅ **文档记录** - 记录配置步骤
5. ✅ **定期更新** - 跟进 macOS 更新

---

**最后更新**: 2026-01-17
**文档版本**: 2.0
**作者**: iOS Automation Team

---

⚠️ **免责声明**: 本文档仅供学习和研究使用。使用者需自行承担相关风险，并遵守所有适用的法律法规。
