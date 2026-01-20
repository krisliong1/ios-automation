import Foundation
import Translation // iOS 17.4+
import AppIntents

/// 统一翻译管理器
/// iOS 17.4+: 使用 Apple Translation Framework（免费、离线、隐私保护）
/// iOS 16-17.3: 使用 API 降级方案（MyMemory, LibreTranslate）
/// 保留自定义功能：代码翻译、智能术语保留、离线词典
@available(iOS 16.0, macOS 13.0, *)
@MainActor
public class TranslationManager: ObservableObject {

    // MARK: - Properties

    @Published public var translationCache: [String: String] = [:]
    private let session: URLSession

    // MARK: - Initialization

    public init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }

    // MARK: - Main Translation Methods

    /// 翻译文本到中文
    public func translateToChinese(_ text: String) async -> String {
        // 如果文本为空或已经是中文，直接返回
        if text.isEmpty || isChinese(text) {
            return text
        }

        // 检查缓存
        if let cached = translationCache[text] {
            return cached
        }

        // 尝试翻译
        do {
            let translated = try await performTranslation(text, to: "zh-CN")
            translationCache[text] = translated
            return translated
        } catch {
            print("⚠️ 翻译失败: \(error.localizedDescription)")
            return text // 失败则返回原文
        }
    }

    /// 翻译代码（保持代码语法，只翻译注释）
    public func translateCode(_ code: String, language: String = "swift") async -> String {
        let lines = code.components(separatedBy: "\n")
        var translatedLines: [String] = []

        for line in lines {
            let translatedLine = await translateCodeLine(line, language: language)
            translatedLines.append(translatedLine)
        }

        return translatedLines.joined(separator: "\n")
    }

    /// 智能翻译（保留技术术语）
    public func smartTranslate(_ text: String) async -> String {
        // 保留的技术术语列表
        let preservedTerms = [
            "Xcode", "Swift", "SwiftUI", "iOS", "macOS",
            "API", "SDK", "URL", "JSON", "HTTP", "HTTPS",
            "Git", "GitHub", "Stack Overflow",
            "Bluetooth", "WiFi", "USB", "iCloud",
            "CPU", "GPU", "RAM", "SSD",
            "func", "var", "let", "class", "struct", "enum",
            "import", "export", "return", "async", "await"
        ]

        // 替换术语为占位符
        var processedText = text
        var termMap: [String: String] = [:]

        for (index, term) in preservedTerms.enumerated() {
            let placeholder = "__TERM\(index)__"
            if processedText.contains(term) {
                termMap[placeholder] = term
                processedText = processedText.replacingOccurrences(of: term, with: placeholder)
            }
        }

        // 翻译处理后的文本
        var translated = await translateToChinese(processedText)

        // 恢复技术术语
        for (placeholder, term) in termMap {
            translated = translated.replacingOccurrences(of: placeholder, with: term)
        }

        return translated
    }

    /// 批量翻译文本
    public func batchTranslate(_ texts: [String]) async -> [String] {
        await withTaskGroup(of: (Int, String).self) { group in
            for (index, text) in texts.enumerated() {
                group.addTask {
                    let translated = await self.translateToChinese(text)
                    return (index, translated)
                }
            }

            var results: [String] = Array(repeating: "", count: texts.count)

            for await (index, translated) in group {
                results[index] = translated
            }

            return results
        }
    }

    // MARK: - Private Translation Logic

    /// 执行实际翻译
    private func performTranslation(_ text: String, to targetLang: String) async throws -> String {
        #if os(iOS)
        // iOS 17.4+ 优先使用 Apple Translation Framework
        if #available(iOS 17.4, *) {
            if let translated = try? await translateWithAppleFramework(text, to: targetLang) {
                print("✅ 使用 Apple Translation Framework")
                return translated
            }
        }
        #endif

        // 降级方案 1: MyMemory API（免费）
        if let translated = try? await translateWithMyMemory(text, to: targetLang) {
            print("✅ 使用 MyMemory API")
            return translated
        }

        // 降级方案 2: LibreTranslate（开源）
        if let translated = try? await translateWithLibreTranslate(text, to: targetLang) {
            print("✅ 使用 LibreTranslate API")
            return translated
        }

        // 降级方案 3: 离线词典
        print("⚠️ 使用离线词典降级")
        return quickTranslate(text)
    }

    #if os(iOS)
    /// Apple Translation Framework（iOS 17.4+）
    @available(iOS 17.4, *)
    private func translateWithAppleFramework(_ text: String, to targetLang: String) async throws -> String {
        // 配置翻译请求
        let configuration = TranslationSession.Configuration(
            source: nil, // 自动检测源语言
            target: Locale.Language(identifier: "zh-Hans") // 简体中文
        )

        let session = TranslationSession(configuration: configuration)

        // 执行翻译
        let request = TranslationSession.Request(sourceText: text)
        let response = try await session.translate(request)

        return response.targetText
    }
    #endif

    /// MyMemory Translation API（免费，每天 1000 次限制）
    private func translateWithMyMemory(_ text: String, to targetLang: String) async throws -> String {
        let encodedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? text
        let urlString = "https://api.mymemory.translated.net/get?q=\(encodedText)&langpair=en|\(targetLang)"

        guard let url = URL(string: urlString) else {
            throw TranslationError.invalidURL
        }

        let (data, _) = try await session.data(from: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        guard let responseData = json?["responseData"] as? [String: Any],
              let translatedText = responseData["translatedText"] as? String else {
            throw TranslationError.invalidResponse
        }

        return translatedText
    }

    /// LibreTranslate API（开源）
    private func translateWithLibreTranslate(_ text: String, to targetLang: String) async throws -> String {
        let urlString = "https://libretranslate.com/translate"

        guard let url = URL(string: urlString) else {
            throw TranslationError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "q": text,
            "source": "auto",
            "target": "zh",
            "format": "text"
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await session.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        guard let translatedText = json?["translatedText"] as? String else {
            throw TranslationError.invalidResponse
        }

        return translatedText
    }

    // MARK: - Code Translation Helpers（保留自定义实现）

    /// 翻译单行代码（保持语法，只翻译注释）
    private func translateCodeLine(_ line: String, language: String) async -> String {
        // 检测注释
        if let comment = extractComment(from: line, language: language) {
            let translatedComment = await translateToChinese(comment.text)
            return line.replacingOccurrences(of: comment.text, with: translatedComment)
        }

        return line
    }

    /// 提取注释
    private func extractComment(from line: String, language: String) -> (text: String, type: CommentType)? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        // Swift/C-style 单行注释
        if trimmed.hasPrefix("//") {
            let commentText = String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces)
            return (commentText, .singleLine)
        }

        // Swift/C-style 多行注释
        if trimmed.hasPrefix("/*") && trimmed.hasSuffix("*/") {
            let commentText = String(trimmed.dropFirst(2).dropLast(2))
                .trimmingCharacters(in: .whitespaces)
            return (commentText, .multiLine)
        }

        // Python/Shell 注释
        if language == "python" || language == "shell" {
            if trimmed.hasPrefix("#") {
                let commentText = String(trimmed.dropFirst(1)).trimmingCharacters(in: .whitespaces)
                return (commentText, .singleLine)
            }
        }

        return nil
    }

    // MARK: - Language Detection

    /// 检测是否为中文
    private func isChinese(_ text: String) -> Bool {
        let chineseCharacterRange = "\u{4E00}"..."\u{9FFF}"
        let chineseCount = text.unicodeScalars.filter { scalar in
            chineseCharacterRange.contains(String(scalar))
        }.count

        // 如果中文字符超过 30%，认为是中文
        return Double(chineseCount) / Double(text.count) > 0.3
    }

    /// 检测文本语言
    public func detectLanguage(_ text: String) -> String {
        if isChinese(text) {
            return "zh"
        }

        // 使用 NSLinguisticTagger 检测语言
        let tagger = NSLinguisticTagger(tagSchemes: [.language], options: 0)
        tagger.string = text

        if let language = tagger.dominantLanguage {
            return language
        }

        return "en" // 默认英语
    }

    // MARK: - Offline Dictionary（保留自定义实现）

    /// 获取技术术语翻译
    public func getTechTermTranslation(_ term: String) -> String? {
        let dictionary: [String: String] = [
            // 编程概念
            "error": "错误", "warning": "警告", "build": "构建",
            "compile": "编译", "debug": "调试", "release": "发布",
            "deploy": "部署", "install": "安装", "update": "更新",
            "import": "导入", "export": "导出",

            // 问题相关
            "failed": "失败", "success": "成功", "crash": "崩溃",
            "bug": "错误", "fix": "修复", "solution": "解决方案",

            // 网络相关
            "connection": "连接", "timeout": "超时",
            "request": "请求", "response": "响应",
            "server": "服务器", "client": "客户端",

            // 文件操作
            "file": "文件", "folder": "文件夹", "directory": "目录",
            "path": "路径", "create": "创建", "delete": "删除",
            "save": "保存", "load": "加载",

            // 权限相关
            "permission": "权限", "access": "访问",
            "denied": "被拒绝", "allowed": "允许",

            // 设备相关
            "device": "设备", "simulator": "模拟器",
            "virtual machine": "虚拟机",

            // 常见操作
            "run": "运行", "stop": "停止", "start": "启动",
            "restart": "重启", "reset": "重置"
        ]

        return dictionary[term.lowercased()]
    }

    /// 使用词典进行快速翻译
    public func quickTranslate(_ text: String) -> String {
        var result = text

        // 替换已知的术语
        for word in text.components(separatedBy: .whitespaces) {
            if let translation = getTechTermTranslation(word) {
                result = result.replacingOccurrences(
                    of: word,
                    with: translation,
                    options: .caseInsensitive
                )
            }
        }

        return result
    }
}

// MARK: - Supporting Types

/// 注释类型
public enum CommentType {
    case singleLine
    case multiLine
    case documentation
}

/// 翻译错误
public enum TranslationError: LocalizedError {
    case invalidURL
    case invalidResponse
    case networkError
    case quotaExceeded

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的翻译 API URL"
        case .invalidResponse:
            return "翻译 API 返回无效响应"
        case .networkError:
            return "网络连接错误"
        case .quotaExceeded:
            return "翻译配额已用尽"
        }
    }
}

// MARK: - App Intents

/// 翻译文本 Intent
public struct TranslateTextIntent: AppIntent {
    public static var title: LocalizedStringResource = "翻译文本"
    public static var description = IntentDescription("将任何语言翻译成中文")

    @Parameter(title: "要翻译的文本")
    public var text: String

    public init() {}

    public init(text: String) {
        self.text = text
    }

    public func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let manager = TranslationManager()
        let translated = await manager.translateToChinese(text)

        return .result(
            value: translated,
            dialog: "翻译完成"
        )
    }
}

/// 智能翻译 Intent（保留技术术语）
public struct SmartTranslateIntent: AppIntent {
    public static var title: LocalizedStringResource = "智能翻译"
    public static var description = IntentDescription("翻译文本并保留技术术语")

    @Parameter(title: "要翻译的文本")
    public var text: String

    public init() {}

    public init(text: String) {
        self.text = text
    }

    public func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let manager = TranslationManager()
        let translated = await manager.smartTranslate(text)

        return .result(
            value: translated,
            dialog: "智能翻译完成"
        )
    }
}

/// 翻译代码 Intent
public struct TranslateCodeIntent: AppIntent {
    public static var title: LocalizedStringResource = "翻译代码注释"
    public static var description = IntentDescription("翻译代码中的注释，保留代码语法")

    @Parameter(title: "代码")
    public var code: String

    @Parameter(title: "编程语言", default: "swift")
    public var language: String

    public init() {}

    public init(code: String, language: String = "swift") {
        self.code = code
        self.language = language
    }

    public func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let manager = TranslationManager()
        let translated = await manager.translateCode(code, language: language)

        return .result(
            value: translated,
            dialog: "代码注释翻译完成"
        )
    }
}
