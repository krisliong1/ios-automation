import Foundation
import SwiftData

/// URL Scheme 处理器
///
/// 支持的 URL 格式：
/// - automationhelper://addTask?title=任务标题&priority=高
/// - automationhelper://completeTask?id=UUID
/// - automationhelper://deleteTask?id=UUID
/// - automationhelper://getTasks?limit=10
@MainActor
class URLHandler: ObservableObject {
    private let modelContext: ModelContext

    /// 初始化
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// 处理 URL
    func handle(_ url: URL) {
        // 验证 scheme
        guard url.scheme == "automationhelper" else {
            print("❌ 无效的 URL Scheme: \(url.scheme ?? "nil")")
            return
        }

        // 解析组件
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)

        // 根据 host 路由到不同的处理方法
        switch url.host {
        case "addTask":
            handleAddTask(components: components)
        case "completeTask":
            handleCompleteTask(components: components)
        case "deleteTask":
            handleDeleteTask(components: components)
        case "getTasks":
            handleGetTasks(components: components)
        case "updateTask":
            handleUpdateTask(components: components)
        default:
            print("❌ 未知操作: \(url.host ?? "")")
        }
    }

    // MARK: - 添加任务

    private func handleAddTask(components: URLComponents?) {
        guard let queryItems = components?.queryItems,
              let titleItem = queryItems.first(where: { $0.name == "title" }),
              let title = titleItem.value?.removingPercentEncoding else {
            print("❌ 缺少必需参数: title")
            return
        }

        let task = Task(title: title)

        // 解析优先级
        if let priorityItem = queryItems.first(where: { $0.name == "priority" }),
           let priorityValue = priorityItem.value?.removingPercentEncoding {
            task.priority = priorityValue
        }

        // 解析截止日期
        if let dueDateItem = queryItems.first(where: { $0.name == "dueDate" }),
           let dueDateString = dueDateItem.value,
           let timestamp = Double(dueDateString) {
            task.dueDate = Date(timeIntervalSince1970: timestamp)
        }

        // 解析标签
        if let tagsItem = queryItems.first(where: { $0.name == "tags" }),
           let tagsString = tagsItem.value?.removingPercentEncoding {
            task.tags = tagsString.split(separator: ",").map { String($0) }
        }

        // 解析备注
        if let notesItem = queryItems.first(where: { $0.name == "notes" }),
           let notes = notesItem.value?.removingPercentEncoding {
            task.notes = notes
        }

        // 保存
        modelContext.insert(task)

        do {
            try modelContext.save()
            print("✅ 任务已添加: \(title)")

            // 发送通知
            sendNotification(title: "任务已添加", body: title)
        } catch {
            print("❌ 保存失败: \(error.localizedDescription)")
        }
    }

    // MARK: - 完成任务

    private func handleCompleteTask(components: URLComponents?) {
        guard let queryItems = components?.queryItems,
              let idItem = queryItems.first(where: { $0.name == "id" }),
              let idString = idItem.value,
              let id = UUID(uuidString: idString) else {
            print("❌ 缺少或无效的参数: id")
            return
        }

        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate { $0.id == id }
        )

        do {
            let tasks = try modelContext.fetch(descriptor)

            if let task = tasks.first {
                task.markAsCompleted()
                try modelContext.save()

                print("✅ 任务已完成: \(task.title)")
                sendNotification(title: "任务已完成", body: task.title)
            } else {
                print("❌ 未找到任务: \(idString)")
            }
        } catch {
            print("❌ 操作失败: \(error.localizedDescription)")
        }
    }

    // MARK: - 删除任务

    private func handleDeleteTask(components: URLComponents?) {
        guard let queryItems = components?.queryItems,
              let idItem = queryItems.first(where: { $0.name == "id" }),
              let idString = idItem.value,
              let id = UUID(uuidString: idString) else {
            print("❌ 缺少或无效的参数: id")
            return
        }

        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate { $0.id == id }
        )

        do {
            let tasks = try modelContext.fetch(descriptor)

            if let task = tasks.first {
                let title = task.title
                modelContext.delete(task)
                try modelContext.save()

                print("✅ 任务已删除: \(title)")
                sendNotification(title: "任务已删除", body: title)
            } else {
                print("❌ 未找到任务: \(idString)")
            }
        } catch {
            print("❌ 删除失败: \(error.localizedDescription)")
        }
    }

    // MARK: - 获取任务列表

    private func handleGetTasks(components: URLComponents?) {
        let queryItems = components?.queryItems

        // 解析限制数量
        var limit = 10
        if let limitItem = queryItems?.first(where: { $0.name == "limit" }),
           let limitValue = limitItem.value,
           let limitInt = Int(limitValue) {
            limit = limitInt
        }

        // 解析是否只显示未完成
        var onlyIncomplete = true
        if let incompleteItem = queryItems?.first(where: { $0.name == "onlyIncomplete" }),
           let incompleteValue = incompleteItem.value {
            onlyIncomplete = incompleteValue.lowercased() != "false"
        }

        // 构建查询
        var descriptor = FetchDescriptor<Task>()

        if onlyIncomplete {
            descriptor.predicate = #Predicate { !$0.isCompleted }
        }

        descriptor.sortBy = [SortDescriptor(\.createdAt, order: .reverse)]
        descriptor.fetchLimit = limit

        do {
            let tasks = try modelContext.fetch(descriptor)

            let taskList = tasks.map { task in
                "• \(task.title) [\(task.priority ?? "普通")]"
            }.joined(separator: "\n")

            print("📋 任务列表 (\(tasks.count) 项):\n\(taskList)")

            // 这里可以将结果保存到剪贴板或发送通知
            sendNotification(
                title: "任务列表",
                body: "共 \(tasks.count) 个任务"
            )
        } catch {
            print("❌ 查询失败: \(error.localizedDescription)")
        }
    }

    // MARK: - 更新任务

    private func handleUpdateTask(components: URLComponents?) {
        guard let queryItems = components?.queryItems,
              let idItem = queryItems.first(where: { $0.name == "id" }),
              let idString = idItem.value,
              let id = UUID(uuidString: idString) else {
            print("❌ 缺少或无效的参数: id")
            return
        }

        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate { $0.id == id }
        )

        do {
            let tasks = try modelContext.fetch(descriptor)

            guard let task = tasks.first else {
                print("❌ 未找到任务: \(idString)")
                return
            }

            var updated = false

            // 更新标题
            if let titleItem = queryItems.first(where: { $0.name == "title" }),
               let title = titleItem.value?.removingPercentEncoding {
                task.title = title
                updated = true
            }

            // 更新优先级
            if let priorityItem = queryItems.first(where: { $0.name == "priority" }),
               let priority = priorityItem.value?.removingPercentEncoding {
                task.priority = priority
                updated = true
            }

            // 更新备注
            if let notesItem = queryItems.first(where: { $0.name == "notes" }),
               let notes = notesItem.value?.removingPercentEncoding {
                task.notes = notes
                updated = true
            }

            if updated {
                try modelContext.save()
                print("✅ 任务已更新: \(task.title)")
                sendNotification(title: "任务已更新", body: task.title)
            }
        } catch {
            print("❌ 更新失败: \(error.localizedDescription)")
        }
    }

    // MARK: - 辅助方法

    private func sendNotification(title: String, body: String) {
        #if os(iOS)
        // iOS 通知实现
        // 需要 import UserNotifications
        // 实际使用时需要请求通知权限
        print("📬 通知: \(title) - \(body)")
        #endif
    }
}

// MARK: - URL 构建辅助

extension URLHandler {
    /// 构建添加任务的 URL
    static func buildAddTaskURL(title: String, priority: String? = nil, dueDate: Date? = nil, tags: [String]? = nil) -> URL? {
        var components = URLComponents()
        components.scheme = "automationhelper"
        components.host = "addTask"

        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "title", value: title)
        ]

        if let priority = priority {
            queryItems.append(URLQueryItem(name: "priority", value: priority))
        }

        if let dueDate = dueDate {
            queryItems.append(URLQueryItem(name: "dueDate", value: "\(dueDate.timeIntervalSince1970)"))
        }

        if let tags = tags, !tags.isEmpty {
            queryItems.append(URLQueryItem(name: "tags", value: tags.joined(separator: ",")))
        }

        components.queryItems = queryItems
        return components.url
    }

    /// 构建完成任务的 URL
    static func buildCompleteTaskURL(taskID: UUID) -> URL? {
        var components = URLComponents()
        components.scheme = "automationhelper"
        components.host = "completeTask"
        components.queryItems = [
            URLQueryItem(name: "id", value: taskID.uuidString)
        ]
        return components.url
    }
}
