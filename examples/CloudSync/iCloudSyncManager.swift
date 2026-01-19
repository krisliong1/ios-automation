import Foundation
import Combine

/// iCloud 文档同步管理器
/// 支持跨设备无缝读取和同步文档
@MainActor
class iCloudSyncManager: ObservableObject {

    // MARK: - Published Properties

    @Published var iCloudAvailable = false
    @Published var syncStatus: SyncStatus = .idle
    @Published var syncProgress: Double = 0.0
    @Published var lastSyncDate: Date?
    @Published var documentList: [CloudDocument] = []

    // MARK: - Private Properties

    private var ubiquityContainerURL: URL?
    private var metadataQuery: NSMetadataQuery?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {
        checkiCloudAvailability()
        setupMetadataQuery()
    }

    // MARK: - Public Methods

    /// 检查 iCloud 可用性
    func checkiCloudAvailability() {
        // 获取 iCloud 容器 URL
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let containerURL = FileManager.default.url(
                forUbiquityContainerIdentifier: nil
            )

            DispatchQueue.main.async {
                self?.ubiquityContainerURL = containerURL
                self?.iCloudAvailable = containerURL != nil

                if containerURL != nil {
                    print("✅ iCloud 可用")
                } else {
                    print("❌ iCloud 不可用 - 请在设置中登录 iCloud")
                }
            }
        }
    }

    /// 保存文档到 iCloud
    func saveDocument(_ content: String, filename: String) async throws {
        guard let containerURL = ubiquityContainerURL else {
            throw CloudSyncError.iCloudNotAvailable
        }

        syncStatus = .uploading

        // 创建 Documents 目录
        let documentsURL = containerURL.appendingPathComponent("Documents")
        try? FileManager.default.createDirectory(
            at: documentsURL,
            withIntermediateDirectories: true
        )

        // 保存文件
        let fileURL = documentsURL.appendingPathComponent(filename)

        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        // 标记为需要上传
        try (fileURL as NSURL).setResourceValue(
            true,
            forKey: .isUbiquitousItemKey
        )

        syncStatus = .synced
        lastSyncDate = Date()

        print("✅ 文档已保存到 iCloud: \(filename)")
    }

    /// 从 iCloud 读取文档（无需下载）
    func readDocument(filename: String) async throws -> String {
        guard let containerURL = ubiquityContainerURL else {
            throw CloudSyncError.iCloudNotAvailable
        }

        syncStatus = .downloading

        let documentsURL = containerURL.appendingPathComponent("Documents")
        let fileURL = documentsURL.appendingPathComponent(filename)

        // 检查文件是否存在
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw CloudSyncError.fileNotFound
        }

        // 启动下载（如果需要）
        try await startDownloadingFile(at: fileURL)

        // 读取内容
        let content = try String(contentsOf: fileURL, encoding: .utf8)

        syncStatus = .synced
        lastSyncDate = Date()

        print("✅ 文档已从 iCloud 读取: \(filename)")
        return content
    }

    /// 列出所有 iCloud 文档
    func listDocuments() async throws -> [CloudDocument] {
        guard let containerURL = ubiquityContainerURL else {
            throw CloudSyncError.iCloudNotAvailable
        }

        let documentsURL = containerURL.appendingPathComponent("Documents")

        // 确保目录存在
        try? FileManager.default.createDirectory(
            at: documentsURL,
            withIntermediateDirectories: true
        )

        // 获取文件列表
        let fileURLs = try FileManager.default.contentsOfDirectory(
            at: documentsURL,
            includingPropertiesForKeys: [
                .nameKey,
                .fileSizeKey,
                .contentModificationDateKey,
                .ubiquitousItemIsDownloadedKey,
                .ubiquitousItemDownloadingStatusKey
            ]
        )

        var documents: [CloudDocument] = []

        for url in fileURLs {
            let resourceValues = try url.resourceValues(forKeys: [
                .nameKey,
                .fileSizeKey,
                .contentModificationDateKey,
                .ubiquitousItemIsDownloadedKey,
                .ubiquitousItemDownloadingStatusKey
            ])

            let document = CloudDocument(
                name: resourceValues.name ?? "Unknown",
                url: url,
                size: Int64(resourceValues.fileSize ?? 0),
                modifiedDate: resourceValues.contentModificationDate ?? Date(),
                isDownloaded: resourceValues.ubiquitousItemIsDownloaded ?? false,
                downloadStatus: resourceValues.ubiquitousItemDownloadingStatus?.rawValue ?? ""
            )

            documents.append(document)
        }

        documentList = documents
        return documents
    }

    /// 删除 iCloud 文档
    func deleteDocument(filename: String) async throws {
        guard let containerURL = ubiquityContainerURL else {
            throw CloudSyncError.iCloudNotAvailable
        }

        let documentsURL = containerURL.appendingPathComponent("Documents")
        let fileURL = documentsURL.appendingPathComponent(filename)

        try FileManager.default.removeItem(at: fileURL)

        print("✅ 文档已从 iCloud 删除: \(filename)")

        // 刷新文档列表
        _ = try await listDocuments()
    }

    /// 同步所有文档
    func syncAllDocuments() async throws {
        guard iCloudAvailable else {
            throw CloudSyncError.iCloudNotAvailable
        }

        syncStatus = .syncing
        syncProgress = 0.0

        let documents = try await listDocuments()
        let totalCount = documents.count

        for (index, document) in documents.enumerated() {
            if !document.isDownloaded {
                try await startDownloadingFile(at: document.url)
            }

            syncProgress = Double(index + 1) / Double(totalCount)
        }

        syncStatus = .synced
        lastSyncDate = Date()

        print("✅ 所有文档已同步")
    }

    /// 监听 iCloud 文档变化
    func startMonitoringChanges() {
        metadataQuery?.start()
        print("📡 开始监听 iCloud 文档变化")
    }

    /// 停止监听
    func stopMonitoringChanges() {
        metadataQuery?.stop()
        print("📡 停止监听 iCloud 文档变化")
    }

    // MARK: - Private Methods

    private func setupMetadataQuery() {
        guard let containerURL = ubiquityContainerURL else { return }

        let query = NSMetadataQuery()
        query.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
        query.predicate = NSPredicate(value: true)

        // 监听查询结果变化
        NotificationCenter.default.publisher(
            for: NSNotification.Name.NSMetadataQueryDidFinishGathering,
            object: query
        )
        .sink { [weak self] notification in
            self?.handleMetadataQueryUpdate(notification)
        }
        .store(in: &cancellables)

        NotificationCenter.default.publisher(
            for: NSNotification.Name.NSMetadataQueryDidUpdate,
            object: query
        )
        .sink { [weak self] notification in
            self?.handleMetadataQueryUpdate(notification)
        }
        .store(in: &cancellables)

        metadataQuery = query
    }

    private func handleMetadataQueryUpdate(_ notification: Notification) {
        guard let query = notification.object as? NSMetadataQuery else { return }

        query.disableUpdates()
        defer { query.enableUpdates() }

        print("📱 iCloud 文档已更新，共 \(query.resultCount) 个文件")

        // 刷新文档列表
        Task {
            try? await listDocuments()
        }
    }

    private func startDownloadingFile(at url: URL) async throws {
        // 检查下载状态
        let resourceValues = try url.resourceValues(forKeys: [
            .ubiquitousItemIsDownloadedKey,
            .ubiquitousItemDownloadingStatusKey
        ])

        // 如果已下载，直接返回
        if resourceValues.ubiquitousItemIsDownloaded == true {
            return
        }

        // 开始下载
        try FileManager.default.startDownloadingUbiquitousItem(at: url)

        // 等待下载完成
        var isDownloaded = false
        var attempts = 0
        let maxAttempts = 30 // 最多等待 30 秒

        while !isDownloaded && attempts < maxAttempts {
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 秒

            let values = try url.resourceValues(forKeys: [.ubiquitousItemIsDownloadedKey])
            isDownloaded = values.ubiquitousItemIsDownloaded ?? false

            attempts += 1
        }

        if !isDownloaded {
            throw CloudSyncError.downloadTimeout
        }
    }
}

// MARK: - Data Models

/// 同步状态
enum SyncStatus {
    case idle
    case syncing
    case uploading
    case downloading
    case synced
    case error(String)

    var description: String {
        switch self {
        case .idle: return "空闲"
        case .syncing: return "同步中..."
        case .uploading: return "上传中..."
        case .downloading: return "下载中..."
        case .synced: return "已同步"
        case .error(let message): return "错误: \(message)"
        }
    }
}

/// 云端文档
struct CloudDocument: Identifiable {
    let id = UUID()
    let name: String
    let url: URL
    let size: Int64
    let modifiedDate: Date
    let isDownloaded: Bool
    let downloadStatus: String

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    var statusIcon: String {
        if isDownloaded {
            return "✅"
        } else if downloadStatus == "NSMetadataUbiquitousItemDownloadingStatusCurrent" {
            return "⬇️"
        } else {
            return "☁️"
        }
    }
}

/// 云同步错误
enum CloudSyncError: LocalizedError {
    case iCloudNotAvailable
    case fileNotFound
    case downloadTimeout
    case uploadFailed

    var errorDescription: String? {
        switch self {
        case .iCloudNotAvailable:
            return "iCloud 不可用 - 请在设置中登录 iCloud"
        case .fileNotFound:
            return "文件不存在"
        case .downloadTimeout:
            return "下载超时"
        case .uploadFailed:
            return "上传失败"
        }
    }
}

// MARK: - App Intents Integration

import AppIntents

/// 保存到 iCloud Intent
struct SaveToiCloudIntent: AppIntent {
    static var title: LocalizedStringResource = "保存到 iCloud"
    static var description = IntentDescription("将内容保存到 iCloud，跨设备自动同步")

    @Parameter(title: "文件名")
    var filename: String

    @Parameter(title: "内容")
    var content: String

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let manager = iCloudSyncManager()

        // 等待 iCloud 初始化
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 秒

        guard manager.iCloudAvailable else {
            return .result(dialog: "❌ iCloud 不可用，请在设置中登录")
        }

        try await manager.saveDocument(content, filename: filename)

        return .result(dialog: "✅ 已保存到 iCloud: \(filename)")
    }
}

/// 从 iCloud 读取 Intent
struct ReadFromiCloudIntent: AppIntent {
    static var title: LocalizedStringResource = "从 iCloud 读取"
    static var description = IntentDescription("从 iCloud 读取文档，无需下载")

    @Parameter(title: "文件名")
    var filename: String

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let manager = iCloudSyncManager()

        try await Task.sleep(nanoseconds: 500_000_000)

        guard manager.iCloudAvailable else {
            throw CloudSyncError.iCloudNotAvailable
        }

        let content = try await manager.readDocument(filename: filename)

        return .result(
            value: content,
            dialog: "✅ 已读取: \(filename) (\(content.count) 字符)"
        )
    }
}

/// 列出 iCloud 文档 Intent
struct ListiCloudDocumentsIntent: AppIntent {
    static var title: LocalizedStringResource = "列出 iCloud 文档"
    static var description = IntentDescription("获取所有 iCloud 文档列表")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let manager = iCloudSyncManager()

        try await Task.sleep(nanoseconds: 500_000_000)

        guard manager.iCloudAvailable else {
            return .result(dialog: "❌ iCloud 不可用")
        }

        let documents = try await manager.listDocuments()

        if documents.isEmpty {
            return .result(dialog: "📁 iCloud 文档为空")
        }

        let list = documents.map { document in
            "\(document.statusIcon) \(document.name) (\(document.formattedSize))"
        }.joined(separator: "\n")

        let message = """
        📁 iCloud 文档 (\(documents.count) 个)

        \(list)
        """

        return .result(dialog: message)
    }
}
