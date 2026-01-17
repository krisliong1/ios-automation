# iOS 自动化开发完整指南

> **版本**: 1.0
> **最后更新**: 2026-01
> **适用系统**: macOS 14+, iOS 17+, Xcode 15+

---

## 📑 目录

- [第一部分：Xcode iOS 项目创建完整指南](#第一部分xcode-ios-项目创建完整指南)
- [第二部分：iOS 快捷指令完整动作参考](#第二部分ios-快捷指令完整动作参考)
- [第三部分：Xcode 与快捷指令集成](#第三部分xcode-与快捷指令集成)
- [第四部分：实战场景示例](#第四部分实战场景示例)
- [第五部分：最佳实践与 FAQ](#第五部分最佳实践与-faq)

---

# 第一部分：Xcode iOS 项目创建完整指南

## 1.1 环境准备

### 1.1.1 系统要求

- **macOS**: 14.0 (Sonoma) 或更高版本
- **Xcode**: 15.0 或更高版本
- **iOS 设备**: iOS 17.0+ (用于测试)
- **Apple Developer 账号**: 免费账号即可（部署到真机需要）

### 1.1.2 安装 Xcode

**方法 1: App Store 安装（推荐）**
```bash
# 1. 打开 App Store
# 2. 搜索 "Xcode"
# 3. 点击 "获取" 或 "下载"
# 4. 等待安装完成（约 12GB）

# 安装命令行工具
xcode-select --install
```

**方法 2: 开发者网站下载**
```bash
# 访问 https://developer.apple.com/download/
# 下载 Xcode.xip
# 解压并拖动到 Applications 文件夹
```

**验证安装**
```bash
xcodebuild -version
# 输出示例:
# Xcode 15.2
# Build version 15C500b
```

---

## 1.2 创建新项目

### 1.2.1 通过 Xcode GUI 创建

**步骤 1: 启动 Xcode**
```bash
open -a Xcode
```

**步骤 2: 创建新项目**
1. 点击 "Create New Project" 或 File → New → Project
2. 选择模板：
   - **iOS** → **App**（最常用）
   - iOS → Game（游戏开发）
   - iOS → Framework（库开发）

**步骤 3: 配置项目信息**
```
Product Name:      AutomationHelper
Team:             [选择你的 Apple ID]
Organization ID:   com.yourname
Bundle Identifier: com.yourname.AutomationHelper
Interface:        SwiftUI (推荐) 或 Storyboard
Language:         Swift
Storage:          SwiftData (或 Core Data)
Include Tests:    ✓ 勾选
```

**步骤 4: 选择保存位置**
```
建议路径: ~/Developer/iOS/AutomationHelper
```

**步骤 5: 初始化 Git**
```
✓ Create Git repository on my Mac
```

### 1.2.2 通过命令行创建（进阶）

```bash
# 创建项目目录
mkdir -p ~/Developer/iOS/AutomationHelper
cd ~/Developer/iOS/AutomationHelper

# 使用 xcodegen（需要先安装）
brew install xcodegen

# 创建 project.yml 配置文件
cat > project.yml << 'EOF'
name: AutomationHelper
options:
  bundleIdPrefix: com.yourname
targets:
  AutomationHelper:
    type: application
    platform: iOS
    deploymentTarget: "17.0"
    sources:
      - AutomationHelper
    settings:
      PRODUCT_BUNDLE_IDENTIFIER: com.yourname.AutomationHelper
      SWIFT_VERSION: "5.9"
EOF

# 生成 Xcode 项目
xcodegen generate
```

---

## 1.3 项目结构详解

创建完成后，你会看到以下结构：

```
AutomationHelper/
├── AutomationHelper.xcodeproj      # Xcode 项目文件
├── AutomationHelper/               # 主代码目录
│   ├── AutomationHelperApp.swift   # App 入口
│   ├── ContentView.swift           # 主界面
│   ├── Assets.xcassets/            # 资源文件
│   ├── Preview Content/            # 预览资源
│   └── Info.plist                  # 配置文件
├── AutomationHelperTests/          # 单元测试
└── AutomationHelperUITests/        # UI 测试
```

### 1.3.1 核心文件说明

**AutomationHelperApp.swift** - App 生命周期
```swift
import SwiftUI

@main
struct AutomationHelperApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

**ContentView.swift** - 主界面
```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
```

---

## 1.4 添加基础功能

### 1.4.1 创建数据模型

在 Xcode 中：File → New → File → Swift File

**创建 `Task.swift`**
```swift
import Foundation
import SwiftData

@Model
class Task {
    var id: UUID
    var title: String
    var isCompleted: Bool
    var createdAt: Date

    init(title: String) {
        self.id = UUID()
        self.title = title
        self.isCompleted = false
        self.createdAt = Date()
    }
}
```

### 1.4.2 更新 App 入口

**修改 `AutomationHelperApp.swift`**
```swift
import SwiftUI
import SwiftData

@main
struct AutomationHelperApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Task.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
```

### 1.4.3 创建任务列表界面

**修改 `ContentView.swift`**
```swift
import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var tasks: [Task]
    @State private var newTaskTitle = ""

    var body: some View {
        NavigationStack {
            VStack {
                // 输入框
                HStack {
                    TextField("新任务", text: $newTaskTitle)
                        .textFieldStyle(.roundedBorder)

                    Button(action: addTask) {
                        Image(systemName: "plus.circle.fill")
                            .imageScale(.large)
                    }
                    .disabled(newTaskTitle.isEmpty)
                }
                .padding()

                // 任务列表
                List {
                    ForEach(tasks) { task in
                        HStack {
                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(task.isCompleted ? .green : .gray)
                                .onTapGesture {
                                    toggleTask(task)
                                }

                            Text(task.title)
                                .strikethrough(task.isCompleted)

                            Spacer()

                            Text(task.createdAt, style: .time)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .onDelete(perform: deleteTasks)
                }
            }
            .navigationTitle("任务列表")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
        }
    }

    private func addTask() {
        withAnimation {
            let newTask = Task(title: newTaskTitle)
            modelContext.insert(newTask)
            newTaskTitle = ""
        }
    }

    private func toggleTask(_ task: Task) {
        withAnimation {
            task.isCompleted.toggle()
        }
    }

    private func deleteTasks(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(tasks[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Task.self, inMemory: true)
}
```

---

## 1.5 运行和测试

### 1.5.1 选择模拟器

在 Xcode 顶部工具栏：
```
AutomationHelper > iPhone 15 Pro
```

点击模拟器选择器，选择设备：
- iPhone 15 Pro（推荐）
- iPhone 15 Pro Max
- iPad Pro (12.9-inch)

### 1.5.2 运行项目

**方法 1: 点击运行按钮**
```
点击左上角的 ▶️ 按钮
```

**方法 2: 快捷键**
```
⌘ + R
```

**方法 3: 命令行**
```bash
xcodebuild -scheme AutomationHelper -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build
```

### 1.5.3 调试技巧

**查看控制台输出**
```swift
// 在代码中添加打印
print("任务已添加: \(task.title)")

// 使用断点调试
// 点击行号左侧，设置断点（蓝色标记）
```

**使用 LLDB 调试器**
```bash
# 在控制台中
po task          # 打印对象
po tasks.count   # 打印任务数量
expr task.isCompleted = true  # 修改值
```

---

## 1.6 部署到真机

### 1.6.1 配置签名

1. 连接 iPhone 到 Mac
2. 在 Xcode 中：
   - 选择项目 → Signing & Capabilities
   - Team: 选择你的 Apple ID
   - Signing Certificate: 自动管理

### 1.6.2 信任开发者证书

在 iPhone 上：
```
设置 → 通用 → VPN与设备管理 → 开发者App → 信任
```

### 1.6.3 运行

```
AutomationHelper > [你的 iPhone 名称]
```

点击运行按钮 ▶️

---

# 第二部分：iOS 快捷指令完整动作参考

## 2.1 动作分类概览

iOS 快捷指令提供了 **100+ 个动作**，分为以下类别：

| 分类 | 数量 | 主要功能 |
|------|------|----------|
| 🤖 AI 与智能 | 5+ | ChatGPT、图像识别、文本生成 |
| 📝 文本处理 | 15+ | 文本操作、格式化、翻译 |
| 📁 文件操作 | 12+ | 读写、压缩、云存储 |
| 📧 通讯 | 10+ | 邮件、短信、电话 |
| 📸 照片相机 | 8+ | 拍照、相册、编辑 |
| 🌐 网络请求 | 6+ | HTTP、API、网页 |
| 📅 日历提醒 | 7+ | 事件、提醒、日程 |
| 🗺️ 地图位置 | 6+ | 定位、导航、地理编码 |
| 📊 数据计算 | 10+ | 数学、统计、转换 |
| 🔧 系统设置 | 20+ | Wi-Fi、蓝牙、音量 |

---

## 2.2 🤖 AI 与智能动作（iOS 17+）

### 2.2.1 ChatGPT 对话

**功能**: 调用 ChatGPT API 进行对话

**参数**:
- **Prompt**: 输入文本
- **Model**: gpt-4, gpt-3.5-turbo
- **Max Tokens**: 最大响应长度
- **Temperature**: 创造性 (0-1)

**使用场景**:
- 智能问答
- 文本生成
- 翻译润色
- 代码解释

**示例配置**:
```
Prompt: "将以下文本翻译成英文: [输入文本]"
Model: gpt-4
Temperature: 0.3
```

### 2.2.2 识别图像中的文本 (OCR)

**功能**: 从图片提取文字

**参数**:
- **Image**: 输入图片
- **Language**: 识别语言（中文、英文等）

**使用场景**:
- 名片识别
- 文档扫描
- 发票提取
- 菜单翻译

**高级用法**:
```
1. 拍照/选择照片
2. 识别图像中的文本
3. 匹配文本 (正则表达式)
   - 金额: ¥[0-9]+\.?[0-9]*
   - 日期: \d{4}-\d{2}-\d{2}
4. 保存到备忘录/表格
```

### 2.2.3 生成图像（AI 绘画）

**功能**: 使用 DALL-E 生成图像

**参数**:
- **Prompt**: 描述文本
- **Size**: 1024x1024, 512x512
- **Style**: vivid, natural

### 2.2.4 语音转文字

**功能**: 转录音频文件

**参数**:
- **Audio**: 音频文件
- **Language**: 识别语言

### 2.2.5 文本转语音

**功能**: 将文本朗读出来

**参数**:
- **Text**: 输入文本
- **Voice**: 语音选择
- **Rate**: 语速
- **Pitch**: 音调

---

## 2.3 📝 文本处理动作

### 2.3.1 文本操作

| 动作 | 功能 | 示例 |
|------|------|------|
| **获取文本** | 输入或传递文本 | "Hello World" |
| **合并文本** | 拼接多个文本 | "Hello" + "World" = "HelloWorld" |
| **拆分文本** | 按分隔符拆分 | "a,b,c" → ["a", "b", "c"] |
| **替换文本** | 查找替换 | "Hello" → "Hi" |
| **修改大小写** | 大写/小写/首字母大写 | hello → HELLO |

### 2.3.2 文本格式化

**动作**: 格式化文本

**格式类型**:
- **Markdown**: 转换为 Markdown 格式
- **HTML**: 转换为 HTML
- **纯文本**: 移除格式

**示例**:
```
输入: # 标题\n这是内容
输出 (HTML): <h1>标题</h1><p>这是内容</p>
```

### 2.3.3 匹配文本（正则表达式）

**功能**: 使用正则提取内容

**常用正则**:
```regex
邮箱: [A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}
手机号: 1[3-9]\d{9}
URL: https?://[^\s]+
日期: \d{4}-\d{2}-\d{2}
金额: ¥?\d+\.?\d*
```

### 2.3.4 文本统计

**功能**: 统计字数、字符数

**返回值**:
- 字数
- 字符数
- 行数
- 段落数

### 2.3.5 翻译文本

**功能**: 多语言翻译

**参数**:
- **Text**: 待翻译文本
- **Target Language**: 目标语言
- **Detect Language**: 自动检测源语言

**支持语言**: 中文、英文、日文、韩文、法文等 100+

### 2.3.6 编码/解码

| 动作 | 功能 | 示例 |
|------|------|------|
| **Base64 编码** | 编码文本 | "Hello" → "SGVsbG8=" |
| **URL 编码** | URL 转义 | "你好" → "%E4%BD%A0%E5%A5%BD" |
| **Hash** | MD5/SHA256 | "password" → "5f4dcc..." |

### 2.3.7 文本转语音

**功能**: 朗读文本

**参数**:
- **Voice**: Siri Female/Male, 英文/中文
- **Rate**: 0.5 - 2.0（语速）
- **Pitch**: 0.5 - 2.0（音调）

### 2.3.8 获取剪贴板

**功能**: 读取剪贴板内容

**返回**: 文本、图片、URL 等

### 2.3.9 设置剪贴板

**功能**: 复制内容到剪贴板

**参数**:
- **Content**: 要复制的内容
- **Local Only**: 仅本地（不同步到其他设备）

### 2.3.10 显示通知

**功能**: 发送系统通知

**参数**:
- **Title**: 标题
- **Body**: 内容
- **Sound**: 是否播放声音

---

## 2.4 📁 文件操作动作

### 2.4.1 文件基础操作

| 动作 | 功能 | 说明 |
|------|------|------|
| **获取文件** | 读取文件内容 | 支持文本、图片、PDF |
| **保存文件** | 写入文件 | 指定路径和文件名 |
| **删除文件** | 删除文件 | ⚠️ 不可恢复 |
| **移动文件** | 移动到其他位置 | iCloud Drive, 本地 |
| **复制文件** | 复制文件 | 创建副本 |
| **重命名文件** | 修改文件名 | 支持批量重命名 |

### 2.4.2 文件信息

**动作**: 获取文件详细信息

**返回值**:
- 文件名
- 大小
- 创建日期
- 修改日期
- 文件类型
- 路径

### 2.4.3 压缩与解压

**压缩文件**
```
输入: [文件列表]
输出: Archive.zip
格式: ZIP
```

**解压文件**
```
输入: Archive.zip
输出: [解压后的文件]
```

### 2.4.4 iCloud 操作

| 动作 | 功能 |
|------|------|
| **保存到 iCloud Drive** | 上传文件 |
| **从 iCloud 获取文件** | 下载文件 |
| **创建文件夹** | 在 iCloud 创建目录 |

### 2.4.5 文件转换

**动作**: 转换文件格式

**支持转换**:
- **图片**: HEIC → JPG, PNG → PDF
- **文档**: DOC → PDF, Markdown → HTML
- **音频**: M4A → MP3

### 2.4.6 创建文本文件

**功能**: 快速创建 .txt 文件

**参数**:
- **Text**: 文件内容
- **Filename**: 文件名
- **Path**: 保存路径

---

## 2.5 📧 通讯动作

### 2.5.1 邮件

**发送邮件**

**参数**:
- **To**: 收件人（支持多个）
- **Subject**: 主题
- **Body**: 正文（支持 HTML）
- **CC/BCC**: 抄送/密送
- **Attachments**: 附件

**示例配置**:
```
To: user@example.com
Subject: 工作日报 - 2026-01-17
Body:
今日完成:
1. 项目 A 开发
2. Bug 修复

附件: [截图], [日志文件]
```

### 2.5.2 短信

**发送信息**

**参数**:
- **Recipients**: 接收者（电话号码或联系人）
- **Message**: 短信内容

**限制**:
- 需要用户确认才能发送
- 不支持 iMessage 特效

### 2.5.3 电话

| 动作 | 功能 | 参数 |
|------|------|------|
| **拨打电话** | 直接拨号 | 电话号码 |
| **FaceTime** | 视频/音频通话 | 联系人 |

### 2.5.4 联系人

**搜索联系人**

**参数**:
- **Filter**: 姓名、公司、邮箱等
- **Sort**: 排序方式

**返回**: 联系人对象（包含所有信息）

**添加到联系人**

**功能**: 创建新联系人或更新现有

**字段**:
- 姓名、电话、邮箱
- 公司、职位
- 地址、生日

---

## 2.6 📸 照片与相机动作

### 2.6.1 拍照

**拍照**

**参数**:
- **Camera**: 前置/后置
- **Show Preview**: 是否显示预览

**拍摄视频**

**参数**:
- **Quality**: 720p, 1080p, 4K
- **Start Recording**: 立即开始

### 2.6.2 相册操作

| 动作 | 功能 |
|------|------|
| **选择照片** | 从相册选择（支持多选）|
| **保存到相册** | 保存图片/视频 |
| **获取最新照片** | 获取最近 N 张照片 |
| **搜索照片** | 按日期、地点、人物搜索 |

### 2.6.3 图片编辑

**调整图像大小**

**参数**:
- **Width/Height**: 指定尺寸
- **Preserve Aspect Ratio**: 保持比例

**旋转图像**

**参数**:
- **Degrees**: 90°, 180°, 270°

**裁剪图像**

**参数**:
- **Position**: 居中、顶部等
- **Aspect Ratio**: 1:1, 16:9, 4:3

### 2.6.4 图片转换

**转换图像格式**

**支持格式**: JPEG, PNG, HEIC, PDF

**优化图像**

**功能**: 压缩图片大小

**参数**:
- **Quality**: 0-100%

### 2.6.5 图片信息

**获取图像详细信息**

**返回值**:
- 分辨率
- 文件大小
- 拍摄日期
- EXIF 信息（相机型号、GPS 等）

---

## 2.7 🌐 网络请求动作

### 2.7.1 HTTP 请求

**获取 URL 内容**

**参数**:
- **URL**: 请求地址
- **Method**: GET, POST, PUT, DELETE
- **Headers**: 请求头
- **Body**: 请求体（JSON, Form）

**示例 - GET 请求**:
```
URL: https://api.github.com/users/octocat
Method: GET
Headers:
  Accept: application/json
```

**示例 - POST 请求**:
```
URL: https://api.example.com/tasks
Method: POST
Headers:
  Content-Type: application/json
  Authorization: Bearer YOUR_TOKEN
Body:
{
  "title": "新任务",
  "completed": false
}
```

### 2.7.2 网页操作

**运行 JavaScript on 网页**

**功能**: 在网页中执行 JS 代码

**示例**:
```javascript
// 获取页面标题
document.title

// 提取所有链接
Array.from(document.querySelectorAll('a'))
  .map(a => a.href)

// 获取表格数据
Array.from(document.querySelectorAll('table tr'))
  .map(tr => Array.from(tr.cells).map(td => td.textContent))
```

**获取网页内容**

**功能**: 下载网页 HTML

**参数**:
- **URL**: 网址
- **User Agent**: 模拟浏览器

### 2.7.3 RSS 订阅

**从 RSS Feed 获取项目**

**参数**:
- **Feed URL**: RSS 地址
- **Number**: 获取数量

**返回**: 文章标题、链接、摘要、日期

### 2.7.4 URL 工具

| 动作 | 功能 | 示例 |
|------|------|------|
| **获取 URL 的组件** | 解析 URL | scheme, host, path, query |
| **展开 URL** | 还原短链接 | bit.ly → 完整 URL |
| **生成二维码** | URL 转二维码 | 扫码跳转 |

---

## 2.8 📅 日历与提醒动作

### 2.8.1 日历事件

**创建日历事件**

**参数**:
- **Title**: 事件标题
- **Location**: 地点
- **Start Date**: 开始时间
- **End Date**: 结束时间
- **Notes**: 备注
- **Alerts**: 提醒时间
- **Calendar**: 指定日历

**示例**:
```
Title: 团队会议
Location: 会议室 A
Start: 今天 14:00
End: 今天 15:00
Alerts: 提前 15 分钟
```

**查找日历事件**

**筛选条件**:
- 日期范围
- 日历名称
- 关键词搜索

### 2.8.2 提醒事项

**添加新提醒**

**参数**:
- **Title**: 提醒内容
- **Notes**: 详细说明
- **Due Date**: 截止日期
- **Priority**: 优先级（高/中/低）
- **List**: 提醒列表
- **Tags**: 标签

**查找提醒**

**筛选**:
- 已完成/未完成
- 列表
- 标签
- 日期范围

**切换提醒完成状态**

**功能**: 标记完成/未完成

---

## 2.9 🗺️ 地图与位置动作

### 2.9.1 位置获取

**获取当前位置**

**返回**:
- 经纬度
- 地址
- 城市、国家
- 海拔

### 2.9.2 地理编码

**从地址获取位置**

**输入**: "北京市朝阳区"
**输出**: 经纬度 + 详细地址

**从位置获取地址**

**输入**: 39.9042, 116.4074
**输出**: "北京市东城区天安门广场"

### 2.9.3 地图导航

**获取路线**

**参数**:
- **Start**: 起点
- **End**: 终点
- **Transport**: 驾车/步行/公交/骑行

**返回**:
- 路线距离
- 预计时间
- 路线指引

**在地图中显示**

**功能**: 在 Apple Maps 打开位置

**参数**:
- **Location**: 位置或地址
- **Zoom**: 缩放级别

### 2.9.4 距离计算

**计算距离**

**输入**: 两个位置
**输出**: 直线距离（米/公里）

---

## 2.10 📊 数据与计算动作

### 2.10.1 数学运算

| 动作 | 功能 | 示例 |
|------|------|------|
| **计算** | 数学表达式 | (123 + 456) * 2 = 1158 |
| **四舍五入** | 取整 | 3.7 → 4 |
| **随机数** | 生成随机数 | 1-100 之间 |
| **统计** | 平均值、总和、最大/最小 | [1,2,3] → 平均 2 |

### 2.10.2 数字格式化

**格式化数字**

**选项**:
- **小数位数**: 保留 2 位
- **千分位分隔**: 1,234,567
- **货币格式**: $1,234.56
- **百分比**: 0.75 → 75%

### 2.10.3 日期计算

**获取当前日期**

**格式**:
- ISO 8601: 2026-01-17T14:30:00Z
- 短日期: 2026/01/17
- 长日期: 2026年1月17日
- 自定义: yyyy-MM-dd HH:mm

**调整日期**

**操作**:
- 添加/减少：天、周、月、年
- 示例: 当前日期 + 7 天

**日期之间的时间**

**输入**: 两个日期
**输出**: 相差天数/小时/分钟

**格式化日期**

**自定义格式**:
```
yyyy-MM-dd        → 2026-01-17
MM/dd/yyyy        → 01/17/2026
EEEE, MMM d, yyyy → Friday, Jan 17, 2026
HH:mm:ss          → 14:30:00
```

### 2.10.4 列表操作

| 动作 | 功能 | 示例 |
|------|------|------|
| **获取列表** | 创建列表 | ["A", "B", "C"] |
| **添加到列表** | 追加元素 | [1,2] + 3 = [1,2,3] |
| **从列表中获取项目** | 索引访问 | list[0] = "A" |
| **筛选列表** | 条件过滤 | 筛选大于 10 的数字 |
| **排序列表** | 升序/降序 | [3,1,2] → [1,2,3] |
| **去重** | 移除重复项 | [1,1,2,3] → [1,2,3] |

### 2.10.5 字典（JSON）操作

**获取字典值**

**输入**: JSON 对象
**键**: "name"
**输出**: 对应的值

**设置字典值**

**功能**: 修改或添加键值对

**示例**:
```json
{
  "name": "张三",
  "age": 25
}

设置 "city" = "北京"

结果:
{
  "name": "张三",
  "age": 25,
  "city": "北京"
}
```

---

## 2.11 🔧 系统设置动作

### 2.11.1 连接设置

| 动作 | 功能 | 参数 |
|------|------|------|
| **设置 Wi-Fi** | 开/关 Wi-Fi | 布尔值 |
| **设置蓝牙** | 开/关蓝牙 | 布尔值 |
| **设置飞行模式** | 开/关飞行模式 | 布尔值 |
| **设置个人热点** | 开/关热点 | 布尔值 |

### 2.11.2 音频设置

| 动作 | 功能 | 参数 |
|------|------|------|
| **设置音量** | 调整音量 | 0-100% |
| **设置亮度** | 调整屏幕亮度 | 0-100% |
| **播放音乐** | 播放/暂停 | - |
| **跳转到下一首** | 切歌 | - |

### 2.11.3 勿扰模式

**设置专注模式**

**选项**:
- 勿扰模式
- 睡眠
- 工作
- 个人
- 自定义专注模式

**参数**:
- **Duration**: 持续时间（分钟）

### 2.11.4 外观设置

**设置外观**

**选项**:
- 浅色模式
- 深色模式
- 自动

### 2.11.5 定位服务

**设置定位服务**

**功能**: 开/关定位

### 2.11.6 屏幕控制

| 动作 | 功能 |
|------|------|
| **锁定屏幕** | 立即锁屏 |
| **截屏** | 截取当前屏幕 |
| **录制屏幕** | 开始/停止录屏 |

---

## 2.12 🎯 应用集成动作

### 2.12.1 备忘录

**创建备忘录**

**参数**:
- **Title**: 标题
- **Body**: 内容
- **Folder**: 文件夹

**追加到备忘录**

**功能**: 在现有备忘录末尾添加内容

### 2.12.2 Safari

**在 Safari 中打开 URL**

**参数**:
- **URL**: 网址
- **In Background**: 后台打开

**运行 Safari JavaScript**

**功能**: 在当前网页执行 JS

### 2.12.3 第三方 App

**打开 App**

**参数**:
- **App**: 应用名称

**URL Scheme**

**示例**:
```
微信: weixin://
支付宝: alipays://
淘宝: taobao://
```

---

# 第三部分：Xcode 与快捷指令集成

## 3.1 集成方式对比

| 方式 | 复杂度 | 功能性 | 适用场景 | iOS 版本 |
|------|--------|--------|----------|----------|
| **App Intents** | 高 | 强 | 复杂交互、参数化 | iOS 16+ |
| **URL Scheme** | 低 | 中 | 简单调用 | 所有版本 |
| **Share Extension** | 中 | 中 | 分享数据 | iOS 8+ |
| **Widget** | 高 | 强 | 桌面交互 | iOS 14+ |

---

## 3.2 方法 1：App Intents（推荐）

### 3.2.1 什么是 App Intents？

App Intents 是 iOS 16 引入的框架，允许你的 App 功能被：
- 快捷指令调用
- Siri 语音控制
- Spotlight 搜索
- 控制中心控件

### 3.2.2 创建简单的 Intent

**步骤 1: 创建 Intent 文件**

File → New → File → Swift File

**创建 `AddTaskIntent.swift`**
```swift
import AppIntents

struct AddTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "添加任务"
    static var description = IntentDescription("快速添加新任务到列表")

    // 参数定义
    @Parameter(title: "任务标题")
    var taskTitle: String

    @Parameter(title: "是否重要", default: false)
    var isImportant: Bool

    // 执行逻辑
    func perform() async throws -> some IntentResult {
        // 这里添加任务到数据库
        // 在实际应用中，你需要访问 SwiftData 上下文

        return .result(dialog: "已添加任务: \(taskTitle)")
    }
}
```

**步骤 2: 注册 Intent**

在 `AutomationHelperApp.swift` 中：
```swift
import AppIntents

@main
struct AutomationHelperApp: App {
    init() {
        // 注册 App Intents
        AppDependencyManager.shared.add(dependency: ModelContainerProvider())
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

// Intent 依赖注入
class ModelContainerProvider: @unchecked Sendable {
    static let shared = ModelContainerProvider()
    var container: ModelContainer?
}
```

**步骤 3: 完整的 Intent 实现**

```swift
import AppIntents
import SwiftData

struct AddTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "添加任务"
    static var description = IntentDescription("添加新任务到任务列表")

    @Parameter(title: "任务标题", requestValueDialog: "这个任务叫什么？")
    var taskTitle: String

    @Parameter(title: "优先级", default: .normal)
    var priority: TaskPriority

    @Parameter(title: "截止日期")
    var dueDate: Date?

    static var parameterSummary: some ParameterSummary {
        Summary("添加任务 \(\.$taskTitle)") {
            \.$priority
            \.$dueDate
        }
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // 获取数据容器
        guard let container = ModelContainerProvider.shared.container else {
            throw IntentError.containerNotAvailable
        }

        let context = ModelContext(container)

        // 创建任务
        let task = Task(title: taskTitle)
        task.priority = priority.rawValue
        task.dueDate = dueDate

        // 保存
        context.insert(task)
        try context.save()

        let message = dueDate != nil
            ? "已添加任务「\(taskTitle)」，截止日期：\(dueDate!.formatted())"
            : "已添加任务「\(taskTitle)」"

        return .result(dialog: message)
    }
}

// 优先级枚举
enum TaskPriority: String, AppEnum {
    case low = "低"
    case normal = "普通"
    case high = "高"

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "优先级")
    static var caseDisplayRepresentations: [TaskPriority: DisplayRepresentation] = [
        .low: "低",
        .normal: "普通",
        .high: "高"
    ]
}

// 错误定义
enum IntentError: Error {
    case containerNotAvailable
}
```

### 3.2.3 带返回值的 Intent

**获取任务列表**
```swift
import AppIntents

struct GetTasksIntent: AppIntent {
    static var title: LocalizedStringResource = "获取任务列表"
    static var description = IntentDescription("获取所有未完成的任务")

    @Parameter(title: "只显示重要任务", default: false)
    var onlyImportant: Bool

    @Parameter(title: "最多显示数量", default: 10)
    var limit: Int

    func perform() async throws -> some IntentResult & ReturnsValue<[TaskEntity]> {
        guard let container = ModelContainerProvider.shared.container else {
            throw IntentError.containerNotAvailable
        }

        let context = ModelContext(container)

        // 查询任务
        var descriptor = FetchDescriptor<Task>(
            predicate: #Predicate { !$0.isCompleted }
        )
        descriptor.fetchLimit = limit

        let tasks = try context.fetch(descriptor)

        // 转换为 Intent 实体
        let taskEntities = tasks.map { task in
            TaskEntity(
                id: task.id.uuidString,
                title: task.title,
                isCompleted: task.isCompleted
            )
        }

        return .result(value: taskEntities)
    }
}

// Intent 实体定义
struct TaskEntity: AppEntity {
    var id: String
    var title: String
    var isCompleted: Bool

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "任务")

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(title)",
            subtitle: isCompleted ? "已完成" : "未完成"
        )
    }
}
```

### 3.2.4 在快捷指令中使用

**测试步骤**:
1. 运行 App（⌘ + R）
2. 打开快捷指令 App
3. 新建快捷指令
4. 搜索你的 App 名称："AutomationHelper"
5. 选择 "添加任务" 动作
6. 配置参数并运行

**快捷指令配置示例**:
```
1. [添加任务] AutomationHelper
   任务标题: "每日站会"
   优先级: 高
   截止日期: 今天 10:00

2. [通知] 显示通知
   标题: "任务已添加"
   正文: 快捷指令结果
```

---

## 3.3 方法 2：URL Scheme（传统方法）

### 3.3.1 配置 URL Scheme

**步骤 1: 注册 URL Scheme**

在 Xcode 中：
1. 选择项目 → Target → Info
2. 展开 "URL Types"
3. 点击 "+" 添加新 URL Type

**配置**:
```
Identifier: com.yourname.automationhelper
URL Schemes: automationhelper
Role: Editor
```

### 3.3.2 处理 URL

**在 App 入口处理**

**修改 `AutomationHelperApp.swift`**
```swift
import SwiftUI

@main
struct AutomationHelperApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onOpenURL { url in
            handleURL(url)
        }
    }

    func handleURL(_ url: URL) {
        // 解析 URL
        // automationhelper://addTask?title=会议&priority=high

        guard url.scheme == "automationhelper" else { return }

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)

        switch url.host {
        case "addTask":
            handleAddTask(components: components)
        case "getTasks":
            handleGetTasks()
        default:
            print("未知的 URL 操作")
        }
    }

    func handleAddTask(components: URLComponents?) {
        guard let queryItems = components?.queryItems else { return }

        var title = ""
        var priority = "normal"

        for item in queryItems {
            switch item.name {
            case "title":
                title = item.value ?? ""
            case "priority":
                priority = item.value ?? "normal"
            default:
                break
            }
        }

        // 创建任务
        print("创建任务: \(title), 优先级: \(priority)")
        // 实际实现需要访问 ModelContext
    }

    func handleGetTasks() {
        print("获取任务列表")
        // 实现获取逻辑
    }
}
```

### 3.3.3 完整的 URL Handler

**创建专门的 URLHandler**

**新建 `URLHandler.swift`**
```swift
import Foundation
import SwiftData

@MainActor
class URLHandler: ObservableObject {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func handle(_ url: URL) {
        guard url.scheme == "automationhelper" else { return }

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)

        switch url.host {
        case "addTask":
            handleAddTask(components: components)
        case "completeTask":
            handleCompleteTask(components: components)
        case "deleteTask":
            handleDeleteTask(components: components)
        default:
            print("未知操作: \(url.host ?? "")")
        }
    }

    private func handleAddTask(components: URLComponents?) {
        guard let queryItems = components?.queryItems,
              let titleItem = queryItems.first(where: { $0.name == "title" }),
              let title = titleItem.value else {
            return
        }

        let task = Task(title: title)

        // 解析其他参数
        if let priorityItem = queryItems.first(where: { $0.name == "priority" }),
           let priorityValue = priorityItem.value {
            task.priority = priorityValue
        }

        modelContext.insert(task)

        do {
            try modelContext.save()
            print("✅ 任务已添加: \(title)")
        } catch {
            print("❌ 保存失败: \(error)")
        }
    }

    private func handleCompleteTask(components: URLComponents?) {
        guard let queryItems = components?.queryItems,
              let idItem = queryItems.first(where: { $0.name == "id" }),
              let idString = idItem.value,
              let id = UUID(uuidString: idString) else {
            return
        }

        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate { $0.id == id }
        )

        do {
            let tasks = try modelContext.fetch(descriptor)
            if let task = tasks.first {
                task.isCompleted = true
                try modelContext.save()
                print("✅ 任务已完成: \(task.title)")
            }
        } catch {
            print("❌ 操作失败: \(error)")
        }
    }

    private func handleDeleteTask(components: URLComponents?) {
        guard let queryItems = components?.queryItems,
              let idItem = queryItems.first(where: { $0.name == "id" }),
              let idString = idItem.value,
              let id = UUID(uuidString: idString) else {
            return
        }

        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate { $0.id == id }
        )

        do {
            let tasks = try modelContext.fetch(descriptor)
            if let task = tasks.first {
                modelContext.delete(task)
                try modelContext.save()
                print("✅ 任务已删除")
            }
        } catch {
            print("❌ 删除失败: \(error)")
        }
    }
}
```

**集成到 App**
```swift
@main
struct AutomationHelperApp: App {
    @StateObject private var urlHandler: URLHandler

    init() {
        let container = ... // ModelContainer
        let context = ModelContext(container)
        _urlHandler = StateObject(wrappedValue: URLHandler(modelContext: context))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(urlHandler)
        }
        .onOpenURL { url in
            urlHandler.handle(url)
        }
    }
}
```

### 3.3.4 在快捷指令中使用 URL

**快捷指令配置**:
```
1. [文本] "买菜"

2. [URL] automationhelper://addTask?title=买菜&priority=high

3. [打开 URL]
   URL: [上一步的 URL]
```

**带编码的高级用法**:
```
1. [文本] 输入任务标题

2. [URL 编码] 文本

3. [文本] automationhelper://addTask?title={已编码文本}

4. [打开 URL]
```

---

## 3.4 实战：完整集成示例

### 3.4.1 场景：智能任务管理

**功能需求**:
1. 快捷指令添加任务
2. 语音添加任务
3. 自动提醒
4. 统计报表

**Xcode 代码**

**`TaskManagementIntents.swift`**
```swift
import AppIntents
import SwiftData

// Intent 1: 添加任务
struct AddTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "添加任务"

    @Parameter(title: "任务标题")
    var title: String

    @Parameter(title: "截止日期")
    var dueDate: Date?

    @Parameter(title: "标签")
    var tags: [String]?

    func perform() async throws -> some IntentResult {
        let container = ModelContainerProvider.shared.container!
        let context = ModelContext(container)

        let task = Task(title: title)
        task.dueDate = dueDate
        task.tags = tags ?? []

        context.insert(task)
        try context.save()

        return .result(dialog: "已添加任务「\(title)」")
    }
}

// Intent 2: 获取今日任务
struct GetTodayTasksIntent: AppIntent {
    static var title: LocalizedStringResource = "获取今日任务"

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = ModelContainerProvider.shared.container!
        let context = ModelContext(container)

        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate { task in
                task.dueDate >= today && task.dueDate < tomorrow && !task.isCompleted
            }
        )

        let tasks = try context.fetch(descriptor)

        if tasks.isEmpty {
            return .result(dialog: "今天没有待办任务")
        }

        let taskList = tasks.map { "• \($0.title)" }.joined(separator: "\n")
        let message = "今日待办 (\(tasks.count) 项):\n\(taskList)"

        return .result(dialog: message)
    }
}

// Intent 3: 完成任务
struct CompleteTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "完成任务"

    @Parameter(title: "任务")
    var task: TaskEntity

    func perform() async throws -> some IntentResult {
        let container = ModelContainerProvider.shared.container!
        let context = ModelContext(container)

        guard let uuid = UUID(uuidString: task.id) else {
            throw IntentError.invalidTaskID
        }

        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate { $0.id == uuid }
        )

        let tasks = try context.fetch(descriptor)
        guard let taskToComplete = tasks.first else {
            throw IntentError.taskNotFound
        }

        taskToComplete.isCompleted = true
        taskToComplete.completedAt = Date()

        try context.save()

        return .result(dialog: "已完成任务「\(taskToComplete.title)」")
    }
}

// Intent 4: 任务统计
struct TaskStatsIntent: AppIntent {
    static var title: LocalizedStringResource = "任务统计"

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = ModelContainerProvider.shared.container!
        let context = ModelContext(container)

        // 总任务数
        let allDescriptor = FetchDescriptor<Task>()
        let allTasks = try context.fetch(allDescriptor)

        // 已完成
        let completedTasks = allTasks.filter { $0.isCompleted }

        // 今日完成
        let today = Calendar.current.startOfDay(for: Date())
        let todayCompleted = completedTasks.filter {
            guard let completedAt = $0.completedAt else { return false }
            return completedAt >= today
        }

        // 逾期
        let overdue = allTasks.filter {
            guard let dueDate = $0.dueDate else { return false }
            return dueDate < Date() && !$0.isCompleted
        }

        let message = """
        📊 任务统计

        总任务: \(allTasks.count)
        已完成: \(completedTasks.count)
        今日完成: \(todayCompleted.count)
        逾期: \(overdue.count)

        完成率: \(Int(Double(completedTasks.count) / Double(allTasks.count) * 100))%
        """

        return .result(dialog: message)
    }
}

enum IntentError: Error, CustomLocalizedStringResourceConvertible {
    case invalidTaskID
    case taskNotFound

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .invalidTaskID:
            return "无效的任务 ID"
        case .taskNotFound:
            return "未找到该任务"
        }
    }
}
```

### 3.4.2 快捷指令配置

**快捷指令 1: 快速添加任务**
```
名称: 快速添加任务

步骤:
1. [询问输入]
   提示: "输入任务内容"
   输入类型: 文本

2. [询问输入]
   提示: "是否设置截止日期？"
   输入类型: 日期和时间
   允许无响应: 是

3. [添加任务] AutomationHelper
   任务标题: [步骤1的结果]
   截止日期: [步骤2的结果]

4. [显示通知]
   标题: "✅ 任务已添加"
   正文: [步骤1的结果]
```

**快捷指令 2: 早晨任务播报**
```
名称: 早晨任务播报

自动化触发: 每天 8:00

步骤:
1. [获取今日任务] AutomationHelper

2. [朗读文本]
   文本: [步骤1的结果]
   语速: 1.0

3. [显示通知]
   标题: "☀️ 早安"
   正文: [步骤1的结果]
```

**快捷指令 3: 每周统计报告**
```
名称: 每周统计

自动化触发: 每周日 20:00

步骤:
1. [任务统计] AutomationHelper

2. [发送邮件]
   收件人: me@example.com
   主题: "本周任务统计报告"
   正文: [步骤1的结果]
```

---

# 第四部分：实战场景示例

## 4.1 场景 1：批量发送生日祝福

### 4.1.1 需求分析

**目标**: 自动检测今天生日的联系人，发送个性化祝福

**功能**:
- 读取联系人生日信息
- 过滤今天生日的人
- 生成个性化祝福语（使用 ChatGPT）
- 发送短信或微信

### 4.1.2 快捷指令实现

```
名称: 生日祝福助手

步骤:
1. [查找联系人]
   筛选: 全部联系人

2. [重复操作] 对于 [联系人列表] 中的每个项目

   3. [获取联系人详细信息]
      联系人: [重复项目]

   4. [如果] [生日] 是 [今天]

      5. [文本]
         生成祝福语提示词:
         "为 [姓名] 生成一条温馨的生日祝福，
          考虑到我们的关系是 [关系（朋友/同事等）]，
          风格：简洁、真诚、不超过50字"

      6. [ChatGPT 对话]
         Prompt: [步骤5的文本]
         Model: gpt-3.5-turbo

      7. [发送信息]
         收件人: [联系人]
         信息: [步骤6的结果]

   [结束如果]

[结束重复]

8. [显示通知]
   标题: "🎂 生日祝福已发送"
   正文: "今日共 {计数} 人生日"
```

### 4.1.3 进阶：集成到 Xcode App

**创建 Intent**
```swift
import AppIntents
import Contacts

struct SendBirthdayGreetingsIntent: AppIntent {
    static var title: LocalizedStringResource = "发送生日祝福"

    @Parameter(title: "使用 AI 生成", default: true)
    var useAI: Bool

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // 1. 获取联系人权限
        let store = CNContactStore()
        try await store.requestAccess(for: .contacts)

        // 2. 查询今天生日的联系人
        let contacts = try fetchBirthdayContacts()

        if contacts.isEmpty {
            return .result(dialog: "今天没有联系人生日")
        }

        // 3. 发送祝福
        var sentCount = 0
        for contact in contacts {
            let message = useAI
                ? try await generateAIGreeting(for: contact)
                : "生日快乐！祝你开心每一天！🎂"

            // 这里需要集成短信发送（需要用户确认）
            print("发送给 \(contact.givenName): \(message)")
            sentCount += 1
        }

        return .result(dialog: "已为 \(sentCount) 位联系人准备生日祝福")
    }

    private func fetchBirthdayContacts() throws -> [CNContact] {
        let store = CNContactStore()
        let keys = [
            CNContactGivenNameKey,
            CNContactFamilyNameKey,
            CNContactBirthdayKey,
            CNContactPhoneNumbersKey
        ] as [CNKeyDescriptor]

        let request = CNContactFetchRequest(keysToFetch: keys)

        var birthdayContacts: [CNContact] = []
        let today = Calendar.current.dateComponents([.month, .day], from: Date())

        try store.enumerateContacts(with: request) { contact, _ in
            guard let birthday = contact.birthday else { return }

            if birthday.month == today.month && birthday.day == today.day {
                birthdayContacts.append(contact)
            }
        }

        return birthdayContacts
    }

    private func generateAIGreeting(for contact: CNContact) async throws -> String {
        // 调用 ChatGPT API
        let prompt = "为 \(contact.givenName) 生成一条简洁温馨的生日祝福（不超过50字）"

        // 实际实现需要 API key
        return "生日快乐，\(contact.givenName)！愿你拥有美好的一天！🎉"
    }
}
```

---

## 4.2 场景 2：工作日自动签到

### 4.2.1 需求

**目标**: 工作日早上到公司自动打卡签到

**条件**:
- 周一至周五
- 8:00 - 9:30 之间
- 到达公司位置（GPS 触发）

### 4.2.2 快捷指令实现

```
名称: 自动签到

自动化触发:
- 时间: 8:00
- 位置: 到达 [公司地址]

步骤:
1. [获取当前日期]

2. [格式化日期]
   格式: EEEE

3. [如果] [星期] 是 [周一] 到 [周五]

   4. [获取当前位置]

   5. [如果] [距离公司] < 100米

      6. [URL] https://api.company.com/attendance/checkin

      7. [获取 URL 内容]
         URL: [上一步]
         Method: POST
         Headers:
           Authorization: Bearer {token}
           Content-Type: application/json
         Body:
         {
           "userId": "12345",
           "location": {
             "lat": [纬度],
             "lng": [经度]
           },
           "timestamp": "[当前时间]"
         }

      8. [显示通知]
         标题: "✅ 签到成功"
         正文: "打卡时间: [当前时间]"

   [否则]

      9. [显示通知]
         标题: "⚠️ 签到失败"
         正文: "不在公司范围内"

   [结束如果]

[结束如果]
```

### 4.2.3 Xcode App 实现

**签到 Intent**
```swift
import AppIntents
import CoreLocation

struct CheckInIntent: AppIntent {
    static var title: LocalizedStringResource = "签到打卡"

    @Dependency
    private var locationService: LocationService

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // 1. 检查是否工作日
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())

        guard (2...6).contains(weekday) else { // 周一到周五
            return .result(dialog: "今天是休息日，无需打卡")
        }

        // 2. 检查时间
        let hour = calendar.component(.hour, from: Date())
        let minute = calendar.component(.minute, from: Date())
        let timeInMinutes = hour * 60 + minute

        guard (8*60...9*60+30).contains(timeInMinutes) else {
            return .result(dialog: "不在打卡时间范围内（8:00-9:30）")
        }

        // 3. 获取位置
        let location = try await locationService.getCurrentLocation()

        // 4. 检查是否在公司范围
        let companyLocation = CLLocation(latitude: 39.9042, longitude: 116.4074)
        let distance = location.distance(from: companyLocation)

        guard distance < 100 else {
            return .result(dialog: "距离公司 \(Int(distance)) 米，不在打卡范围内")
        }

        // 5. 调用打卡 API
        let result = try await checkInAPI(location: location)

        let lateMinutes = max(0, timeInMinutes - 9*60) // 迟到分钟数
        let status = lateMinutes > 0 ? "迟到 \(lateMinutes) 分钟" : "准时"

        return .result(dialog: "打卡成功！\(status)")
    }

    private func checkInAPI(location: CLLocation) async throws -> Bool {
        // API 调用实现
        let url = URL(string: "https://api.company.com/attendance/checkin")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer YOUR_TOKEN", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "userId": "12345",
            "location": [
                "lat": location.coordinate.latitude,
                "lng": location.coordinate.longitude
            ],
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw CheckInError.networkError
        }

        return true
    }
}

// 位置服务
@MainActor
class LocationService: ObservableObject {
    private let locationManager = CLLocationManager()

    func getCurrentLocation() async throws -> CLLocation {
        // 请求定位权限
        locationManager.requestWhenInUseAuthorization()

        // 获取当前位置
        // 实际实现需要使用 CLLocationManagerDelegate
        return CLLocation(latitude: 39.9042, longitude: 116.4074)
    }
}

enum CheckInError: Error {
    case networkError
    case notInRange
}
```

**Info.plist 配置**
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>需要您的位置信息来完成签到打卡</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>需要您的位置信息来自动触发签到</string>
```

---

## 4.3 场景 3：智能费用记录

### 4.3.1 需求

**目标**: 拍照发票/收据，自动识别金额和类别，记录到表格

**流程**:
1. 拍照/选择照片
2. OCR 识别文本
3. 提取金额、日期、商家
4. AI 分类（餐饮/交通/购物等）
5. 保存到 Numbers/Excel

### 4.3.2 快捷指令实现

```
名称: 智能记账

步骤:
1. [拍照] 或 [选择照片]

2. [识别图像中的文本]
   图像: [步骤1的照片]

3. [匹配文本]
   模式: 正则表达式
   模式内容: ¥?[0-9]+\.?[0-9]*
   输入: [步骤2的文本]

4. [从列表中获取项目]
   列表: [匹配结果]
   获取: 第一项

5. [文本]
   内容:
   分析以下发票内容，提取信息并分类：

   文本内容:
   [步骤2的识别文本]

   请以 JSON 格式返回：
   {
     "amount": "金额",
     "merchant": "商家名称",
     "category": "类别（餐饮/交通/购物/娱乐/其他）",
     "date": "日期"
   }

6. [ChatGPT 对话]
   Prompt: [步骤5的文本]
   Model: gpt-4
   Temperature: 0.2

7. [从输入获取字典值]
   键: amount
   字典: [步骤6的 JSON 结果]

8. [从输入获取字典值]
   键: category
   字典: [步骤6的 JSON 结果]

9. [从输入获取字典值]
   键: merchant
   字典: [步骤6的 JSON 结果]

10. [添加新行到表格]
    文件: iCloud Drive/费用记录.numbers
    表格: 支出明细
    行内容:
      - 日期: [当前日期]
      - 金额: [步骤7]
      - 类别: [步骤8]
      - 商家: [步骤9]
      - 备注: -

11. [显示通知]
    标题: "💰 记账成功"
    正文: "[类别] ¥[金额] - [商家]"
```

### 4.3.3 Xcode App 实现

**费用记录 Intent**
```swift
import AppIntents
import Vision
import UIKit

struct RecordExpenseIntent: AppIntent {
    static var title: LocalizedStringResource = "记录费用"

    @Parameter(title: "发票照片")
    var image: IntentFile

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // 1. OCR 识别
        guard let uiImage = UIImage(contentsOfFile: image.fileURL!.path) else {
            throw ExpenseError.invalidImage
        }

        let recognizedText = try await recognizeText(in: uiImage)

        // 2. 提取金额
        let amount = extractAmount(from: recognizedText)

        // 3. AI 分类
        let expenseInfo = try await analyzeExpense(text: recognizedText)

        // 4. 保存到数据库
        let expense = Expense(
            amount: amount,
            category: expenseInfo.category,
            merchant: expenseInfo.merchant,
            date: Date(),
            imageData: uiImage.jpegData(compressionQuality: 0.8)
        )

        // 保存逻辑...

        let message = """
        记账成功

        金额: ¥\(amount)
        类别: \(expenseInfo.category)
        商家: \(expenseInfo.merchant)
        """

        return .result(dialog: message)
    }

    private func recognizeText(in image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw ExpenseError.invalidImage
        }

        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest()
        request.recognitionLanguages = ["zh-Hans", "en-US"]
        request.recognitionLevel = .accurate

        try requestHandler.perform([request])

        guard let observations = request.results else {
            throw ExpenseError.ocrFailed
        }

        let recognizedText = observations.compactMap { observation in
            observation.topCandidates(1).first?.string
        }.joined(separator: "\n")

        return recognizedText
    }

    private func extractAmount(from text: String) -> Double {
        // 正则提取金额
        let pattern = "¥?([0-9]+\\.?[0-9]*)"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text) else {
            return 0.0
        }

        return Double(text[range]) ?? 0.0
    }

    private func analyzeExpense(text: String) async throws -> ExpenseInfo {
        // 调用 ChatGPT API 分析
        let prompt = """
        分析以下发票内容，提取信息并分类：

        \(text)

        返回 JSON 格式：
        {
          "category": "类别（餐饮/交通/购物/娱乐/其他）",
          "merchant": "商家名称"
        }
        """

        // 实际实现需要调用 OpenAI API
        // 这里返回模拟数据
        return ExpenseInfo(category: "餐饮", merchant: "某某餐厅")
    }
}

struct ExpenseInfo {
    let category: String
    let merchant: String
}

enum ExpenseError: Error {
    case invalidImage
    case ocrFailed
}

// 数据模型
@Model
class Expense {
    var id: UUID
    var amount: Double
    var category: String
    var merchant: String
    var date: Date
    var imageData: Data?

    init(amount: Double, category: String, merchant: String, date: Date, imageData: Data? = nil) {
        self.id = UUID()
        self.amount = amount
        self.category = category
        self.merchant = merchant
        self.date = date
        self.imageData = imageData
    }
}
```

---

## 4.4 场景 4：健康数据云端同步

### 4.4.1 需求

**目标**: 每天自动同步健康数据到云端（步数、睡眠、心率）

**数据源**: HealthKit

**目标**: 上传到个人服务器 / Google Sheets

### 4.4.2 快捷指令实现

```
名称: 健康数据同步

自动化触发: 每天 23:00

步骤:
1. [查找健康样本]
   类型: 步数
   时间范围: 今天

2. [获取详细信息]
   获取: 求和

3. [查找健康样本]
   类型: 睡眠分析
   时间范围: 昨晚

4. [获取详细信息]
   获取: 总时长

5. [查找健康样本]
   类型: 心率
   时间范围: 今天

6. [获取详细信息]
   获取: 平均值

7. [文本]
   今日健康数据:
   - 步数: [步骤2] 步
   - 睡眠: [步骤4] 小时
   - 平均心率: [步骤6] bpm

8. [获取 URL 内容]
   URL: https://api.yourserver.com/health/sync
   Method: POST
   Headers:
     Authorization: Bearer {token}
     Content-Type: application/json
   Body:
   {
     "date": "[今天日期]",
     "steps": [步骤2],
     "sleep": [步骤4],
     "heartRate": [步骤6]
   }

9. [如果] [HTTP 状态码] 等于 200

   10. [显示通知]
       标题: "☁️ 同步成功"
       正文: [步骤7的文本]

   [否则]

   11. [显示通知]
       标题: "❌ 同步失败"
       正文: "请检查网络连接"

   [结束如果]
```

### 4.4.3 Xcode App 实现

**需要配置**:
1. 添加 HealthKit Capability
2. Info.plist 添加健康数据权限说明

**HealthSyncIntent.swift**
```swift
import AppIntents
import HealthKit

struct HealthSyncIntent: AppIntent {
    static var title: LocalizedStringResource = "同步健康数据"

    @Dependency
    private var healthService: HealthService

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // 1. 请求健康数据权限
        try await healthService.requestAuthorization()

        // 2. 获取今日数据
        let steps = try await healthService.getStepsToday()
        let sleep = try await healthService.getSleepLastNight()
        let heartRate = try await healthService.getAverageHeartRateToday()

        // 3. 上传到服务器
        let syncData = HealthData(
            date: Date(),
            steps: steps,
            sleepHours: sleep,
            averageHeartRate: heartRate
        )

        try await uploadToServer(data: syncData)

        let message = """
        健康数据同步成功

        📊 步数: \(Int(steps)) 步
        😴 睡眠: \(String(format: "%.1f", sleep)) 小时
        ❤️ 心率: \(Int(heartRate)) bpm
        """

        return .result(dialog: message)
    }

    private func uploadToServer(data: HealthData) async throws {
        let url = URL(string: "https://api.yourserver.com/health/sync")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer YOUR_TOKEN", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(data)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw HealthError.uploadFailed
        }
    }
}

// 健康服务类
@MainActor
class HealthService: ObservableObject {
    private let healthStore = HKHealthStore()

    func requestAuthorization() async throws {
        let typesToRead: Set<HKSampleType> = [
            HKQuantityType(.stepCount),
            HKQuantityType(.heartRate),
            HKCategoryType(.sleepAnalysis)
        ]

        try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
    }

    func getStepsToday() async throws -> Double {
        let type = HKQuantityType(.stepCount)
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)

        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: now,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let steps = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                continuation.resume(returning: steps)
            }

            healthStore.execute(query)
        }
    }

    func getSleepLastNight() async throws -> Double {
        let type = HKCategoryType(.sleepAnalysis)
        let now = Date()
        let startOfYesterday = Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: now))!

        let predicate = HKQuery.predicateForSamples(
            withStart: startOfYesterday,
            end: now,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let samples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: 0)
                    return
                }

                let sleepSamples = samples.filter { $0.value == HKCategoryValueSleepAnalysis.asleep.rawValue }
                let totalSeconds = sleepSamples.reduce(0.0) { total, sample in
                    total + sample.endDate.timeIntervalSince(sample.startDate)
                }

                let hours = totalSeconds / 3600
                continuation.resume(returning: hours)
            }

            healthStore.execute(query)
        }
    }

    func getAverageHeartRateToday() async throws -> Double {
        let type = HKQuantityType(.heartRate)
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)

        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: now,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let bpm = result?.averageQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: .minute())) ?? 0
                continuation.resume(returning: bpm)
            }

            healthStore.execute(query)
        }
    }
}

struct HealthData: Codable {
    let date: Date
    let steps: Double
    let sleepHours: Double
    let averageHeartRate: Double
}

enum HealthError: Error {
    case uploadFailed
    case authorizationFailed
}
```

**Info.plist 配置**
```xml
<key>NSHealthShareUsageDescription</key>
<string>需要读取您的健康数据以进行云端同步</string>

<key>NSHealthUpdateUsageDescription</key>
<string>需要更新您的健康数据</string>
```

---

## 4.5 场景 5：会议笔记自动整理

### 4.5.1 需求

**目标**: 录音会议，转文字，AI 总结要点，发送邮件

**流程**:
1. 录制会议音频
2. 语音转文字
3. ChatGPT 总结要点
4. 生成 Markdown 文档
5. 发送给参会人员

### 4.5.2 快捷指令实现

```
名称: 会议助手

步骤:
1. [录制音频]
   质量: 高
   完成时: 点击完成

2. [语音转文字]
   音频: [步骤1的录音]
   语言: 中文

3. [文本]
   请分析以下会议内容，总结要点：

   会议内容:
   [步骤2的转录文本]

   请以以下格式输出：

   # 会议纪要

   ## 📅 基本信息
   - 会议时间: [自动提取]
   - 参会人员: [从内容提取]

   ## 📝 讨论要点
   [3-5条要点]

   ## ✅ 行动项
   [待办事项列表]

   ## 📌 重要决议
   [关键决定]

4. [ChatGPT 对话]
   Prompt: [步骤3的文本]
   Model: gpt-4
   Temperature: 0.3
   Max Tokens: 2000

5. [格式化日期]
   日期: [当前日期]
   格式: yyyy-MM-dd

6. [文本]
   会议纪要-[步骤5的日期].md

7. [保存文件]
   文件名: [步骤6]
   内容: [步骤4的总结]
   位置: iCloud Drive/会议纪要/

8. [询问]
   提示: "发送会议纪要给谁？"
   输入类型: 联系人
   允许多个: 是

9. [发送邮件]
   收件人: [步骤8的联系人]
   主题: "会议纪要 - [步骤5的日期]"
   正文: [步骤4的总结]
   附件: [步骤7的文件]

10. [显示通知]
    标题: "✅ 会议纪要已发送"
    正文: "已发送给 [人数] 位参会人员"
```

### 4.5.3 Xcode App 实现

**MeetingNotesIntent.swift**
```swift
import AppIntents
import Speech

struct ProcessMeetingIntent: AppIntent {
    static var title: LocalizedStringResource = "处理会议录音"

    @Parameter(title: "录音文件")
    var audioFile: IntentFile

    @Parameter(title: "参会人员邮箱")
    var attendeeEmails: [String]

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        // 1. 语音转文字
        let transcription = try await transcribeAudio(fileURL: audioFile.fileURL!)

        // 2. AI 总结
        let summary = try await summarizeMeeting(transcription: transcription)

        // 3. 保存 Markdown
        let fileName = "会议纪要-\(Date().formatted(date: .numeric, time: .omitted)).md"
        try summary.write(to: getDocumentsDirectory().appendingPathComponent(fileName), atomically: true, encoding: .utf8)

        // 4. 发送邮件
        // 邮件发送需要用户交互，这里返回总结内容

        return .result(value: summary, dialog: "会议纪要已生成")
    }

    private func transcribeAudio(fileURL: URL) async throws -> String {
        // 请求语音识别权限
        let authStatus = SFSpeechRecognizer.authorizationStatus()
        guard authStatus == .authorized else {
            throw MeetingError.authorizationDenied
        }

        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))!
        let request = SFSpeechURLRecognitionRequest(url: fileURL)
        request.shouldReportPartialResults = false

        return try await withCheckedThrowingContinuation { continuation in
            recognizer.recognitionTask(with: request) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                if let result = result, result.isFinal {
                    continuation.resume(returning: result.bestTranscription.formattedString)
                }
            }
        }
    }

    private func summarizeMeeting(transcription: String) async throws -> String {
        let prompt = """
        请分析以下会议内容，总结要点：

        会议内容:
        \(transcription)

        请以以下格式输出：

        # 会议纪要

        ## 📅 基本信息
        - 会议时间: [自动提取]
        - 参会人员: [从内容提取]

        ## 📝 讨论要点
        [3-5条要点]

        ## ✅ 行动项
        [待办事项列表]

        ## 📌 重要决议
        [关键决定]
        """

        // 调用 ChatGPT API
        // 实际实现需要 API key

        // 模拟返回
        return """
        # 会议纪要

        ## 📅 基本信息
        - 会议时间: \(Date().formatted())
        - 参会人员: 张三、李四、王五

        ## 📝 讨论要点
        1. 项目进度符合预期
        2. 需要增加资源投入
        3. 下周进行用户测试

        ## ✅ 行动项
        - [ ] 张三：完成文档编写（截止：周五）
        - [ ] 李四：准备测试环境（截止：周三）
        - [ ] 王五：联系测试用户（截止：周四）

        ## 📌 重要决议
        - 同意增加 2 名开发人员
        - 推迟发布日期至下月 15 日
        """
    }

    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

enum MeetingError: Error {
    case authorizationDenied
    case transcriptionFailed
}
```

**Info.plist 配置**
```xml
<key>NSSpeechRecognitionUsageDescription</key>
<string>需要语音识别权限来转录会议内容</string>

<key>NSMicrophoneUsageDescription</key>
<string>需要麦克风权限来录制会议</string>
```

---

# 第五部分：最佳实践与 FAQ

## 5.1 开发最佳实践

### 5.1.1 Xcode 开发技巧

**1. 使用 SwiftData 而不是 Core Data**
```swift
// ✅ 推荐：SwiftData（iOS 17+）
@Model
class Task {
    var title: String
    var isCompleted: Bool
}

// ❌ 避免：Core Data（除非需要兼容旧版本）
```

**2. 合理使用异步**
```swift
// ✅ 推荐：async/await
func fetchData() async throws -> Data {
    let (data, _) = try await URLSession.shared.data(from: url)
    return data
}

// ❌ 避免：回调地狱
func fetchData(completion: @escaping (Data?) -> Void) {
    URLSession.shared.dataTask(with: url) { data, _, _ in
        completion(data)
    }.resume()
}
```

**3. 错误处理**
```swift
// ✅ 推荐：自定义错误类型
enum AppError: Error, LocalizedError {
    case networkError
    case dataCorrupted

    var errorDescription: String? {
        switch self {
        case .networkError: return "网络连接失败"
        case .dataCorrupted: return "数据已损坏"
        }
    }
}
```

### 5.1.2 App Intents 最佳实践

**1. 参数命名清晰**
```swift
// ✅ 推荐
@Parameter(title: "任务标题", requestValueDialog: "这个任务叫什么？")
var taskTitle: String

// ❌ 避免
@Parameter(title: "Title")
var t: String
```

**2. 提供有意义的返回值**
```swift
// ✅ 推荐：返回详细信息
return .result(dialog: "已添加任务「\(title)」，截止日期：\(dueDate.formatted())")

// ❌ 避免：简单确认
return .result(dialog: "Done")
```

**3. 使用 ParameterSummary**
```swift
static var parameterSummary: some ParameterSummary {
    Summary("添加任务 \(\.$title)") {
        \.$dueDate
        \.$priority
    }
}
```

### 5.1.3 快捷指令设计原则

**1. 单一职责**
```
❌ 不好：一个快捷指令做太多事
"超级助手" - 包含签到、记账、发邮件等

✅ 好：每个快捷指令专注一个任务
"自动签到"
"智能记账"
"会议纪要"
```

**2. 错误处理**
```
1. [获取 URL 内容]

2. [如果] [HTTP 状态码] 不等于 200

   3. [显示通知]
      标题: "操作失败"
      正文: "错误码: [HTTP 状态码]"

   4. [退出快捷指令]

[结束如果]
```

**3. 用户反馈**
```
// 每个关键步骤都应该有反馈

✅ 好的做法:
- 开始时显示加载提示
- 完成时显示成功通知
- 失败时显示错误信息
```

---

## 5.2 性能优化

### 5.2.1 Xcode 性能优化

**1. 减少不必要的 UI 刷新**
```swift
// ✅ 推荐：使用 @Query 的排序和过滤
@Query(
    filter: #Predicate<Task> { !$0.isCompleted },
    sort: \.createdAt,
    order: .reverse
)
private var tasks: [Task]

// ❌ 避免：在视图中过滤和排序
@Query private var allTasks: [Task]
var incompleteTasks: [Task] {
    allTasks.filter { !$0.isCompleted }.sorted { $0.createdAt > $1.createdAt }
}
```

**2. 图片优化**
```swift
// ✅ 压缩图片
if let imageData = image.jpegData(compressionQuality: 0.7) {
    // 使用压缩后的数据
}

// ✅ 使用缩略图
let thumbnailSize = CGSize(width: 200, height: 200)
let thumbnail = image.preparingThumbnail(of: thumbnailSize)
```

**3. 懒加载**
```swift
// ✅ 推荐：LazyVStack
ScrollView {
    LazyVStack {
        ForEach(items) { item in
            ItemRow(item: item)
        }
    }
}

// ❌ 避免：VStack 一次性加载所有
VStack {
    ForEach(items) { item in
        ItemRow(item: item)
    }
}
```

### 5.2.2 快捷指令性能优化

**1. 减少 API 调用**
```
❌ 不好：在循环中调用 API
重复操作 对于每个 [项目]
    获取 URL 内容

✅ 好：批量处理
收集所有项目
调用一次批量 API
```

**2. 缓存结果**
```
1. [从文件获取]
   文件: cache.json

2. [如果] 缓存有效（时间 < 1小时）
   使用缓存
[否则]
   重新获取数据
   保存到缓存
[结束如果]
```

---

## 5.3 调试技巧

### 5.3.1 Xcode 调试

**1. 使用断点**
```
- 点击行号左侧设置断点
- 右键断点 → Edit Breakpoint
- 添加条件：task.title == "重要任务"
- 添加 Action：po task
```

**2. LLDB 命令**
```bash
# 打印对象
po task

# 打印类型
p type(of: task)

# 执行代码
expr task.isCompleted = true

# 继续执行
c

# 下一步
n

# 进入函数
s
```

**3. 日志输出**
```swift
// 基础日志
print("任务数量: \(tasks.count)")

// OSLog（推荐）
import OSLog

let logger = Logger(subsystem: "com.yourapp", category: "Task")
logger.info("添加任务: \(task.title)")
logger.error("保存失败: \(error.localizedDescription)")
```

### 5.3.2 快捷指令调试

**1. 显示变量值**
```
1. [获取变量]

2. [显示通知]
   标题: "调试"
   正文: [变量的值]

3. [暂停] 10 秒
```

**2. 日志记录**
```
1. [文本]
   [当前时间] - 步骤X完成 - 值: [变量]

2. [追加到文件]
   文件: debug.log
   内容: [上一步的文本]
```

---

## 5.4 常见问题 FAQ

### Q1: App Intents 不显示在快捷指令中？

**A**: 检查以下几点：
1. 确保 App 在真机或模拟器上运行过至少一次
2. 重启快捷指令 App
3. 检查 Intent 是否正确实现 `AppIntent` 协议
4. 查看控制台是否有错误日志

**解决方案**:
```swift
// 确保 Intent 是 public
public struct MyIntent: AppIntent {
    public init() {}
    // ...
}
```

### Q2: URL Scheme 打开 App 但没有响应？

**A**: 检查 URL 处理逻辑

```swift
// 确保实现了 onOpenURL
.onOpenURL { url in
    print("收到 URL: \(url)") // 添加日志
    handleURL(url)
}
```

### Q3: 快捷指令无法访问文件？

**A**: 检查权限和路径

```
❌ 错误：使用相对路径
文件: Documents/data.json

✅ 正确：使用 iCloud Drive 或完整路径
文件: iCloud Drive/MyApp/data.json
```

### Q4: 健康数据无法读取？

**A**: 确认权限配置

1. Info.plist 添加权限说明
2. 代码中请求授权
3. 在系统设置中检查权限是否已授予

### Q5: ChatGPT API 调用失败？

**A**: 常见原因：

1. **API Key 错误**
```swift
// 检查 API key 是否正确
let apiKey = "sk-..."  // 以 sk- 开头
```

2. **网络问题**
```swift
// 添加超时和重试
var request = URLRequest(url: url)
request.timeoutInterval = 30

// 捕获错误
do {
    let (data, _) = try await URLSession.shared.data(for: request)
} catch {
    print("网络错误: \(error)")
}
```

3. **请求格式错误**
```json
// 正确的请求体
{
  "model": "gpt-4",
  "messages": [
    {
      "role": "user",
      "content": "Hello"
    }
  ]
}
```

### Q6: 定位服务不工作？

**A**: 检查权限和配置

```xml
<!-- Info.plist -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>需要定位权限</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>需要后台定位权限（用于自动化）</string>
```

```swift
// 请求权限
locationManager.requestWhenInUseAuthorization()
// 或
locationManager.requestAlwaysAuthorization()
```

### Q7: 快捷指令运行很慢？

**A**: 优化建议：

1. **减少不必要的步骤**
2. **并行处理独立任务**
3. **缓存频繁访问的数据**
4. **避免在循环中调用 API**

### Q8: 如何分享快捷指令？

**A**: 导出方法：

1. 打开快捷指令
2. 点击 "···" → "共享"
3. 选择 "拷贝 iCloud 链接" 或 "导出文件"

**注意**:
- 删除敏感信息（API key、密码等）
- 使用注释说明配置步骤

---

## 5.5 学习资源

### 官方文档

- [Apple Developer - Shortcuts](https://developer.apple.com/documentation/shortcuts)
- [App Intents 文档](https://developer.apple.com/documentation/appintents)
- [SwiftUI 教程](https://developer.apple.com/tutorials/swiftui)
- [HealthKit 文档](https://developer.apple.com/documentation/healthkit)

### 推荐工具

- **Xcodegen**: 用代码生成 Xcode 项目
- **SwiftLint**: 代码规范检查
- **Proxyman**: HTTP 请求调试
- **SF Symbols**: 系统图标库

### 社区

- [Swift Forums](https://forums.swift.org/)
- [r/shortcuts](https://www.reddit.com/r/shortcuts/)
- [Stack Overflow - ios](https://stackoverflow.com/questions/tagged/ios)

---

## 📌 总结

这份指南涵盖了：

✅ **Xcode 项目创建** - 从零开始构建 iOS 应用
✅ **快捷指令动作参考** - 100+ 个动作详解
✅ **集成方法** - App Intents 和 URL Scheme
✅ **实战案例** - 5 个完整的自动化场景
✅ **最佳实践** - 性能优化、调试技巧、FAQ

**下一步建议**:

1. 从简单的 Intent 开始实践
2. 创建自己的第一个快捷指令
3. 尝试组合多个动作实现复杂功能
4. 分享你的创作，获取反馈

祝你在 iOS 自动化开发之路上顺利！🚀

---

**版权声明**: 本文档仅供学习交流使用。

**最后更新**: 2026-01-17
