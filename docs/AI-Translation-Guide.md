# AI 翻译系统使用指南

## 📖 简介

Kris AI Fixer 内置了强大的智能翻译系统，能够将搜索结果从**任何语言**自动翻译成中文，同时**保持代码的完整可执行性**。

### 核心特性

✅ **多语言支持** - 自动识别并翻译任何语言
✅ **智能代码翻译** - 翻译注释，保持代码语法
✅ **技术术语保留** - 保留 Xcode、Swift、iOS 等术语
✅ **批量翻译** - 并行处理多个文本
✅ **离线词典** - 常用技术术语快速翻译
✅ **缓存优化** - 避免重复翻译相同内容

---

## 🚀 快速开始

### 自动翻译（默认启用）

AI Fixer 默认启用自动翻译，无需任何配置：

```swift
let fixer = KrisAIFixer()

// 自动翻译搜索结果
let result = try await fixer.fixProblem("Build failed with error")

// 所有解决方案都已翻译成中文
for solution in result.solution.steps {
    print(solution) // 已翻译成中文
}
```

### 手动控制翻译

如果需要禁用自动翻译：

```swift
let fixer = KrisAIFixer()

// 禁用自动翻译
fixer.enableAutoTranslation = false

// 现在搜索结果保持原文
let result = try await fixer.fixProblem("Build failed")
```

### 单独使用翻译器

```swift
let translator = AITranslator()

// 翻译普通文本
let chinese = await translator.translateToChinese("Build failed with error")
print(chinese) // "构建失败并出现错误"

// 智能翻译（保留技术术语）
let smart = await translator.smartTranslate("Xcode failed to build iOS app")
print(smart) // "Xcode 构建 iOS 应用失败"
```

---

## 📝 翻译示例

### 示例 1: 搜索结果翻译

**原文（英文）：**
```
Title: How to fix Xcode virtual machine detection
Summary: This solution uses VMHide kernel extension to bypass VM detection
Steps:
1. Download VMHide from GitHub
2. Install the kernel extension
3. Restart your Mac
4. Verify the installation
```

**翻译后（中文）：**
```
标题: 如何修复 Xcode 虚拟机检测
摘要: 此解决方案使用 VMHide 内核扩展绕过虚拟机检测
步骤:
1. 从 GitHub 下载 VMHide
2. 安装内核扩展
3. 重启你的 Mac
4. 验证安装
```

### 示例 2: 代码翻译（保持语法）

**原文（英文注释）：**
```swift
// This function checks if the device is running in a virtual machine
func isVirtualMachine() -> Bool {
    // Read the kern.hv_vmm_present sysctl value
    var value: Int32 = 0
    var size = MemoryLayout<Int32>.size
    sysctlbyname("kern.hv_vmm_present", &value, &size, nil, 0)

    // Return true if VM is detected
    return value != 0
}
```

**翻译后（中文注释，代码不变）：**
```swift
// 此函数检查设备是否在虚拟机中运行
func isVirtualMachine() -> Bool {
    // 读取 kern.hv_vmm_present sysctl 值
    var value: Int32 = 0
    var size = MemoryLayout<Int32>.size
    sysctlbyname("kern.hv_vmm_present", &value, &size, nil, 0)

    // 如果检测到虚拟机则返回 true
    return value != 0
}
```

**注意：** 代码语法完全保持不变，可以直接运行！✅

### 示例 3: 技术术语保留

**原文：**
```
"Xcode build failed with Swift compiler error in iOS 17 SDK"
```

**智能翻译：**
```
"Xcode 构建失败，Swift 编译器在 iOS 17 SDK 中出现错误"
```

**保留的术语：** Xcode, Swift, iOS, SDK

---

## 🔧 翻译功能详解

### 1. 普通文本翻译

```swift
let translator = AITranslator()

// 基础翻译
let text = "Build failed with error code 1"
let chinese = await translator.translateToChinese(text)
print(chinese) // "构建失败，错误代码 1"
```

### 2. 智能翻译（保留技术术语）

```swift
// 自动保留技术术语
let smart = await translator.smartTranslate(
    "Xcode failed to compile SwiftUI code with error"
)
print(smart) // "Xcode 编译 SwiftUI 代码失败并出现错误"
```

**保留的技术术语列表：**
- 开发工具: Xcode, Git, GitHub, Stack Overflow
- 编程语言: Swift, SwiftUI, Objective-C
- 平台: iOS, macOS, iPadOS, watchOS
- 技术: API, SDK, JSON, HTTP, Bluetooth, WiFi
- 关键字: func, var, let, class, struct, enum

### 3. 代码翻译

```swift
let code = """
// Initialize the manager
func setup() {
    // Configure settings
    print("Setup complete")
}
"""

let translatedCode = await translator.translateCode(code, language: "swift")
print(translatedCode)
```

**输出：**
```swift
// 初始化管理器
func setup() {
    // 配置设置
    print("Setup complete")
}
```

### 4. 批量翻译

```swift
let texts = [
    "Build failed",
    "Test passed",
    "Deploy successful"
]

let translated = await translator.batchTranslate(texts)
// ["构建失败", "测试通过", "部署成功"]
```

### 5. 解决方案翻译

```swift
let solution = Solution(
    title: "Fix build error",
    description: "This solution fixes the build error",
    steps: [
        "Open Xcode",
        "Clean build folder",
        "Rebuild project"
    ],
    code: [/* code snippets */]
)

let translatedSolution = await translator.translateSolution(solution)

print(translatedSolution.title) // "修复构建错误"
print(translatedSolution.steps[0]) // "打开 Xcode"
```

---

## 🌐 翻译 API

### 使用的翻译服务

AI 翻译器集成了多个翻译服务，按优先级尝试：

#### 1. MyMemory Translation API（免费）

- ✅ 完全免费
- ✅ 每天 1000 次请求
- ✅ 支持多种语言
- ✅ 无需 API 密钥

**使用示例：**
```swift
// 自动使用 MyMemory API
let translated = await translator.translateToChinese("Hello World")
```

#### 2. LibreTranslate（开源）

- ✅ 开源免费
- ✅ 可自建服务器
- ✅ 隐私保护
- ✅ 支持多种语言

**公共实例：** https://libretranslate.com

#### 3. 离线词典（降级方案）

当在线翻译不可用时，使用内置的技术术语词典：

```swift
let quickTranslate = translator.quickTranslate("build failed")
// 使用离线词典快速翻译
```

### 自定义翻译 API

如果需要使用其他翻译服务（如 Google Translate API、DeepL API），可以扩展翻译器：

```swift
extension AITranslator {
    func translateWithCustomAPI(_ text: String) async throws -> String {
        // 实现你的自定义翻译逻辑
        let urlString = "https://your-api.com/translate"
        // ... API 调用
        return translatedText
    }
}
```

---

## 🎯 使用场景

### 场景 1: Stack Overflow 问题翻译

**问题（英文）：**
```
Q: How to fix Xcode build error "Command PhaseScriptExecution failed"?

A: This error occurs when a build script fails. Try these steps:
1. Check your script for syntax errors
2. Verify file permissions
3. Clean build folder and retry
```

**AI Fixer 自动翻译：**
```
问题: 如何修复 Xcode 构建错误 "Command PhaseScriptExecution failed"?

答案: 此错误发生在构建脚本失败时。尝试以下步骤:
1. 检查脚本的语法错误
2. 验证文件权限
3. 清理构建文件夹并重试
```

### 场景 2: GitHub 代码示例翻译

**原始代码（英文注释）：**
```swift
/// Manages Bluetooth connections
class BluetoothManager {
    // Central manager for BLE operations
    private var centralManager: CBCentralManager!

    // Start scanning for devices
    func startScanning() {
        centralManager.scanForPeripherals(
            withServices: nil,
            options: nil
        )
    }
}
```

**翻译后（中文注释）：**
```swift
/// 管理蓝牙连接
class BluetoothManager {
    // BLE 操作的中央管理器
    private var centralManager: CBCentralManager!

    // 开始扫描设备
    func startScanning() {
        centralManager.scanForPeripherals(
            withServices: nil,
            options: nil
        )
    }
}
```

### 场景 3: 多语言文档翻译

AI Fixer 可以翻译来自不同国家的开发者文档：

- 🇺🇸 英语 → 中文
- 🇯🇵 日语 → 中文
- 🇰🇷 韩语 → 中文
- 🇩🇪 德语 → 中文
- 🇫🇷 法语 → 中文
- 🇷🇺 俄语 → 中文

---

## ⚙️ 配置选项

### 启用/禁用翻译

```swift
let fixer = KrisAIFixer()

// 启用自动翻译（默认）
fixer.enableAutoTranslation = true

// 禁用自动翻译
fixer.enableAutoTranslation = false
```

### 语言检测

```swift
let translator = AITranslator()

// 检测文本语言
let language = translator.detectLanguage("Hello World")
print(language) // "en"

let language2 = translator.detectLanguage("你好世界")
print(language2) // "zh"
```

### 缓存管理

翻译器自动缓存翻译结果，避免重复翻译：

```swift
// 第一次翻译（调用 API）
let text1 = await translator.translateToChinese("Build failed")

// 第二次翻译（使用缓存）
let text2 = await translator.translateToChinese("Build failed")
// 立即返回，无需 API 调用
```

---

## 📊 翻译质量

### 技术术语准确性

AI 翻译器内置了 **150+ 常用技术术语**的准确翻译：

| 英文 | 中文 | 类别 |
|------|------|------|
| build | 构建 | 编译 |
| compile | 编译 | 编译 |
| error | 错误 | 调试 |
| warning | 警告 | 调试 |
| crash | 崩溃 | 运行 |
| permission | 权限 | 系统 |
| certificate | 证书 | 签名 |
| deployment | 部署 | 发布 |
| simulator | 模拟器 | 设备 |
| virtual machine | 虚拟机 | 设备 |

### 代码完整性保证

翻译器确保代码**100% 可执行**：

✅ **保持的元素：**
- 函数名
- 变量名
- 类名和结构体名
- 关键字（func, var, let, class, etc.）
- 字符串字面量（除非明确要求翻译）
- 数字和符号

🔄 **翻译的元素：**
- 单行注释（// comment）
- 多行注释（/* comment */）
- 文档注释（/// documentation）
- print 语句中的中文字符串

---

## 🔍 语言检测

### 自动检测

翻译器使用 `NSLinguisticTagger` 自动检测文本语言：

```swift
let text = "This is an English sentence"
let language = translator.detectLanguage(text)
// 返回: "en"
```

### 中文检测

特别优化了中文检测算法：

```swift
let chineseText = "这是中文文本"
let isChinese = translator.isChinese(chineseText)
// 返回: true
```

**检测规则：**
- 如果中文字符 > 30%，识别为中文
- 自动跳过已经是中文的文本

---

## 💡 最佳实践

### 1. 始终启用自动翻译

```swift
// ✅ 推荐
let fixer = KrisAIFixer()
fixer.enableAutoTranslation = true // 默认启用
```

### 2. 使用智能翻译处理技术文本

```swift
// ✅ 推荐 - 保留技术术语
let smart = await translator.smartTranslate(text)

// ❌ 不推荐 - 可能翻译技术术语
let basic = await translator.translateToChinese(text)
```

### 3. 批量翻译提高性能

```swift
// ✅ 推荐 - 并行处理
let translated = await translator.batchTranslate([text1, text2, text3])

// ❌ 不推荐 - 顺序处理
let t1 = await translator.translateToChinese(text1)
let t2 = await translator.translateToChinese(text2)
let t3 = await translator.translateToChinese(text3)
```

### 4. 代码翻译使用专用方法

```swift
// ✅ 推荐 - 保持代码语法
let code = await translator.translateCode(sourceCode, language: "swift")

// ❌ 不推荐 - 可能破坏代码
let code = await translator.translateToChinese(sourceCode)
```

---

## 🐛 故障排除

### 问题 1: 翻译失败

**症状：** 返回原文而不是翻译

**原因：**
- 网络连接问题
- API 配额用尽
- 翻译服务暂时不可用

**解决方法：**
```swift
do {
    let translated = try await translator.performTranslation(text, to: "zh-CN")
    print(translated)
} catch {
    print("翻译错误: \(error)")
    // 使用离线词典作为降级方案
    let offline = translator.quickTranslate(text)
}
```

### 问题 2: 技术术语被错误翻译

**症状：** "Xcode" 被翻译成 "X代码"

**解决方法：**
```swift
// 使用智能翻译而不是基础翻译
let smart = await translator.smartTranslate(text)
```

### 问题 3: 代码被破坏

**症状：** 翻译后的代码无法编译

**原因：** 使用了错误的翻译方法

**解决方法：**
```swift
// ✅ 正确 - 使用代码翻译方法
let code = await translator.translateCode(sourceCode, language: "swift")

// ❌ 错误 - 不要对代码使用普通翻译
// let code = await translator.translateToChinese(sourceCode)
```

### 问题 4: 翻译速度慢

**原因：**
- 大量文本需要翻译
- 网络延迟

**解决方法：**
```swift
// 使用批量翻译
let texts = [text1, text2, text3, text4, text5]
let translated = await translator.batchTranslate(texts)
// 并行处理，速度更快
```

---

## 📈 性能优化

### 缓存策略

```swift
// 翻译器自动缓存结果
let translator = AITranslator()

// 第一次 - 调用 API (慢)
let result1 = await translator.translateToChinese("Build failed")

// 第二次 - 使用缓存 (快)
let result2 = await translator.translateToChinese("Build failed")
```

### 并行翻译

```swift
// 并行翻译多个文本
async let title = translator.translateToChinese(solution.title)
async let description = translator.translateToChinese(solution.description)
async let step1 = translator.translateToChinese(solution.steps[0])

let translatedTitle = await title
let translatedDesc = await description
let translatedStep = await step1
```

---

## 🔐 隐私和安全

### 数据隐私

- ✅ 使用免费的开源翻译服务
- ✅ 本地缓存翻译结果
- ✅ 可选择自建翻译服务器
- ✅ 敏感信息可禁用在线翻译

### 离线模式

```swift
// 完全离线翻译（仅技术术语）
let offline = translator.quickTranslate(text)
```

---

## 📚 完整示例

### 完整的翻译工作流

```swift
import Foundation

// 1. 创建 AI Fixer（自动翻译已启用）
let fixer = KrisAIFixer()

// 2. 使用英文问题描述
let englishProblem = "Xcode build failed with Swift compiler error"

// 3. 自动搜索和翻译
Task {
    do {
        let result = try await fixer.fixProblem(englishProblem)

        // 4. 所有结果已翻译成中文
        print("解决方案: \(result.solution.title)")

        for (index, step) in result.solution.steps.enumerated() {
            print("\(index + 1). \(step)")
        }

        // 5. 代码保持可执行性
        for code in result.solution.code {
            print("\n代码:")
            print(code.code) // 注释已翻译，代码未变
        }

    } catch {
        print("错误: \(error)")
    }
}
```

---

## 🎓 高级用法

### 自定义翻译规则

```swift
extension AITranslator {
    /// 翻译但保留特定字符串
    func translateWithPreserve(
        _ text: String,
        preserve: [String]
    ) async -> String {
        var processed = text
        var placeholders: [String: String] = [:]

        // 替换需要保留的字符串
        for (index, term) in preserve.enumerated() {
            let placeholder = "__PRESERVE\(index)__"
            placeholders[placeholder] = term
            processed = processed.replacingOccurrences(of: term, with: placeholder)
        }

        // 翻译
        var translated = await translateToChinese(processed)

        // 恢复保留的字符串
        for (placeholder, term) in placeholders {
            translated = translated.replacingOccurrences(of: placeholder, with: term)
        }

        return translated
    }
}

// 使用
let result = await translator.translateWithPreserve(
    "Fix the MyCustomClass error",
    preserve: ["MyCustomClass"]
)
// 结果: "修复 MyCustomClass 错误"
```

---

## 🌟 总结

AI 翻译系统为 Kris AI Fixer 带来了强大的多语言支持：

✅ **自动化** - 无需手动翻译，全自动处理
✅ **智能化** - 保留技术术语，保持代码可执行
✅ **高效率** - 缓存 + 并行处理
✅ **高质量** - 150+ 技术术语精准翻译
✅ **多源集成** - MyMemory + LibreTranslate
✅ **隐私保护** - 支持离线词典和自建服务

现在，无论搜索结果来自哪个国家、哪种语言，AI Fixer 都能自动翻译成中文，让你专注于解决问题！🚀

---

**Happy Coding! 🎉**
