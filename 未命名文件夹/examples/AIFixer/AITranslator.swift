import Foundation

/// AI 翻译引擎
/// 自动将搜索结果从任何语言翻译成中文，同时保持代码可执行性
@available(iOS 16.0, macOS 13.0, *)
class AITranslator {

    // MARK: - Properties

    private let session: URLSession
    private var translationCache: [String: String] = [:]

    // MARK: - Initialization

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }

    // MARK: - Main Translation Methods

    /// 翻译文本到中文
    func translateToChinese(_ text: String) async -> String {
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
    func translateCode(_ code: String, language: String = "swift") async -> String {
        var lines = code.components(separatedBy: "\n")
        var translatedLines: [String] = []

        for line in lines {
            let translatedLine = await translateCodeLine(line, language: language)
            translatedLines.append(translatedLine)
        }

        return translatedLines.joined(separator: "\n")
    }

    /// 翻译解决方案步骤
    func translateSteps(_ steps: [String]) async -> [String] {
        var translatedSteps: [String] = []

        for step in steps {
            let translated = await translateToChinese(step)
            translatedSteps.append(translated)
        }

        return translatedSteps
    }

    /// 翻译搜索结果
    func translateSearchResult(_ result: SearchResult) async -> SearchResult {
        async let translatedTitle = translateToChinese(result.title)
        async let translatedSummary = translateToChinese(result.summary)
        async let translatedContent = translateToChinese(result.content)

        let title = await translatedTitle
        let summary = await translatedSummary
        let content = await translatedContent

        return SearchResult(
            title: title,
            url: result.url,
            summary: summary,
            content: content,
            relevanceScore: result.relevanceScore
        )
    }

    /// 翻译代码片段
    func translateCodeSnippet(_ snippet: CodeSnippet) async -> CodeSnippet {
        let translatedCode = await translateCode(snippet.code, language: snippet.language)
        let translatedDescription = await translateToChinese(snippet.description)

        return CodeSnippet(
            language: snippet.language,
            code: translatedCode,
            description: translatedDescription
        )
    }

    // MARK: - Private Translation Logic

    /// 执行实际翻译
    private func performTranslation(_ text: String, to targetLang: String) async throws -> String {
        // 方法 1: 使用 MyMemory Translation API（免费，无需 API key）
        if let translated = try? await translateWithMyMemory(text, to: targetLang) {
            return translated
        }

        // 方法 2: 使用 LibreTranslate（开源，可自建）
        if let translated = try? await translateWithLibreTranslate(text, to: targetLang) {
            return translated
        }

        // 方法 3: 使用简单的本地翻译（降级方案）
        return text
    }

    /// MyMemory Translation API（免费）
    private func translateWithMyMemory(_ text: String, to targetLang: String) async throws -> String {
        // MyMemory 免费 API，每天 1000 次请求限制
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
        // 使用公共 LibreTranslate 实例
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

    // MARK: - Code Translation Helpers

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
    func detectLanguage(_ text: String) -> String {
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

    // MARK: - Batch Translation

    /// 批量翻译文本
    func batchTranslate(_ texts: [String]) async -> [String] {
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

    // MARK: - Smart Translation

    /// 智能翻译（保留技术术语）
    func smartTranslate(_ text: String) async -> String {
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
}

// MARK: - Supporting Types

/// 注释类型
enum CommentType {
    case singleLine
    case multiLine
    case documentation
}

/// 翻译错误
enum TranslationError: LocalizedError {
    case invalidURL
    case invalidResponse
    case networkError
    case quotaExceeded

    var errorDescription: String? {
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

// MARK: - Translation Extensions

@available(iOS 16.0, macOS 13.0, *)
extension AITranslator {

    /// 翻译完整的解决方案
    func translateSolution(_ solution: Solution) async -> Solution {
        async let translatedTitle = translateToChinese(solution.title)
        async let translatedDescription = translateToChinese(solution.description)
        async let translatedSteps = translateSteps(solution.steps)

        var translatedCodeSnippets: [CodeSnippet] = []
        for snippet in solution.code {
            let translated = await translateCodeSnippet(snippet)
            translatedCodeSnippets.append(translated)
        }

        let title = await translatedTitle
        let description = await translatedDescription
        let steps = await translatedSteps

        return Solution(
            id: solution.id,
            title: title,
            description: description,
            steps: steps,
            code: translatedCodeSnippets,
            source: solution.source,
            confidence: solution.confidence,
            estimatedTime: solution.estimatedTime,
            requiresManualIntervention: solution.requiresManualIntervention
        )
    }

    /// 翻译问题描述
    func translateProblem(_ problem: Problem) async -> Problem {
        let translatedDescription = await translateToChinese(problem.description)

        return Problem(
            id: problem.id,
            description: translatedDescription,
            category: problem.category,
            severity: problem.severity,
            keywords: problem.keywords,
            requiresCustomCode: problem.requiresCustomCode,
            detectedAt: problem.detectedAt,
            context: problem.context
        )
    }
}

// MARK: - Offline Translation Dictionary

/// 离线翻译词典（常用技术术语）
@available(iOS 16.0, macOS 13.0, *)
extension AITranslator {

    /// 获取技术术语翻译
    func getTechTermTranslation(_ term: String) -> String? {
        let dictionary: [String: String] = [
            // 编程概念
            "error": "错误",
            "warning": "警告",
            "build": "构建",
            "compile": "编译",
            "debug": "调试",
            "release": "发布",
            "deploy": "部署",
            "install": "安装",
            "uninstall": "卸载",
            "update": "更新",
            "upgrade": "升级",
            "download": "下载",
            "upload": "上传",
            "import": "导入",
            "export": "导出",

            // 问题相关
            "failed": "失败",
            "success": "成功",
            "crash": "崩溃",
            "freeze": "冻结",
            "slow": "缓慢",
            "bug": "错误",
            "fix": "修复",
            "solution": "解决方案",
            "workaround": "变通方法",

            // 网络相关
            "connection": "连接",
            "timeout": "超时",
            "request": "请求",
            "response": "响应",
            "server": "服务器",
            "client": "客户端",

            // 文件操作
            "file": "文件",
            "folder": "文件夹",
            "directory": "目录",
            "path": "路径",
            "create": "创建",
            "delete": "删除",
            "rename": "重命名",
            "copy": "复制",
            "move": "移动",
            "save": "保存",
            "load": "加载",

            // 权限相关
            "permission": "权限",
            "access": "访问",
            "denied": "被拒绝",
            "allowed": "允许",
            "authorized": "已授权",
            "unauthorized": "未授权",

            // 设备相关
            "device": "设备",
            "simulator": "模拟器",
            "emulator": "仿真器",
            "virtual machine": "虚拟机",
            "physical device": "真机",

            // 常见操作
            "run": "运行",
            "stop": "停止",
            "start": "启动",
            "restart": "重启",
            "reset": "重置",
            "clear": "清除",
            "clean": "清理",
            "refresh": "刷新",

            // Xcode 特定
            "workspace": "工作空间",
            "project": "项目",
            "scheme": "方案",
            "target": "目标",
            "archive": "归档",
            "certificate": "证书",
            "provisioning profile": "配置文件",
            "signing": "签名",
            "entitlements": "权限配置"
        ]

        return dictionary[term.lowercased()]
    }

    /// 使用词典进行快速翻译
    func quickTranslate(_ text: String) -> String {
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

// MARK: - Usage Examples

#if DEBUG

@available(iOS 16.0, macOS 13.0, *)
class TranslationExamples {

    func example1_BasicTranslation() async {
        let translator = AITranslator()

        let englishText = "Build failed with error code 1"
        let chinese = await translator.translateToChinese(englishText)

        print("原文: \(englishText)")
        print("译文: \(chinese)")
    }

    func example2_CodeTranslation() async {
        let translator = AITranslator()

        let code = """
        // This function checks if the device is a virtual machine
        func isVirtualMachine() -> Bool {
            var value: Int32 = 0
            var size = MemoryLayout<Int32>.size
            sysctlbyname("kern.hv_vmm_present", &value, &size, nil, 0)
            return value != 0
        }
        """

        let translatedCode = await translator.translateCode(code)

        print("翻译后的代码:")
        print(translatedCode)
    }

    func example3_SmartTranslation() async {
        let translator = AITranslator()

        let text = "Xcode failed to build the iOS app with Swift compiler error"
        let smart = await translator.smartTranslate(text)

        print("智能翻译: \(smart)")
        // 预期: "Xcode 构建 iOS 应用失败，Swift 编译器错误"
    }
}

#endif
