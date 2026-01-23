import SwiftUI
import SwiftData

/// App 入口点
///
/// 这是 iOS App 的主入口，配置了：
/// - SwiftData 数据持久化
/// - App Intents 支持
/// - URL Scheme 处理
@main
struct AutomationHelperApp: App {
    // MARK: - Properties

    /// 共享的数据容器
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Task.self,
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            let container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )

            // 将容器设置到全局提供者（供 App Intents 使用）
            ModelContainerProvider.shared.container = container

            return container
        } catch {
            fatalError("无法创建 ModelContainer: \(error)")
        }
    }()

    /// URL 处理器
    @StateObject private var urlHandler: URLHandler

    // MARK: - Initialization

    init() {
        // 初始化 URL 处理器
        let context = ModelContext(sharedModelContainer)
        _urlHandler = StateObject(wrappedValue: URLHandler(modelContext: context))

        // 配置 App Intents
        setupAppIntents()
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(urlHandler)
        }
        .modelContainer(sharedModelContainer)
        .onOpenURL { url in
            // 处理 URL Scheme
            urlHandler.handle(url)
        }
    }

    // MARK: - Setup

    private func setupAppIntents() {
        // App Intents 会自动注册
        // 这里可以添加额外的配置
        print("📱 App Intents 已配置")
    }
}

/// 主界面视图
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Task.createdAt, order: .reverse) private var tasks: [Task]

    @State private var newTaskTitle = ""
    @State private var showingAddSheet = false

    var body: some View {
        NavigationStack {
            VStack {
                // 统计信息
                statsSection

                // 任务列表
                if tasks.isEmpty {
                    emptyStateView
                } else {
                    taskListView
                }
            }
            .navigationTitle("任务管理")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .imageScale(.large)
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddTaskView()
            }
        }
    }

    // MARK: - Subviews

    private var statsSection: some View {
        HStack(spacing: 20) {
            StatCard(
                title: "总计",
                count: tasks.count,
                color: .blue
            )

            StatCard(
                title: "待办",
                count: tasks.filter { !$0.isCompleted }.count,
                color: .orange
            )

            StatCard(
                title: "已完成",
                count: tasks.filter { $0.isCompleted }.count,
                color: .green
            )
        }
        .padding()
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("暂无任务")
                .font(.title2)
                .foregroundColor(.secondary)

            Text("点击右上角的 + 添加新任务")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxHeight: .infinity)
    }

    private var taskListView: some View {
        List {
            ForEach(tasks) { task in
                TaskRow(task: task)
            }
            .onDelete(perform: deleteTasks)
        }
    }

    // MARK: - Actions

    private func deleteTasks(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(tasks[index])
            }
        }
    }
}

/// 统计卡片
struct StatCard: View {
    let title: String
    let count: Int
    let color: Color

    var body: some View {
        VStack {
            Text("\(count)")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

/// 任务行视图
struct TaskRow: View {
    @Bindable var task: Task

    var body: some View {
        HStack {
            // 完成状态图标
            Button {
                withAnimation {
                    if task.isCompleted {
                        task.markAsIncomplete()
                    } else {
                        task.markAsCompleted()
                    }
                }
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
                    .imageScale(.large)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                // 任务标题
                Text(task.title)
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)

                // 详细信息
                HStack(spacing: 8) {
                    // 优先级
                    if let priority = task.priority {
                        Text(priority)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(priorityColor(priority).opacity(0.2))
                            .foregroundColor(priorityColor(priority))
                            .cornerRadius(4)
                    }

                    // 截止日期
                    if let dueDate = task.dueDate {
                        Label(
                            dueDate.formatted(date: .abbreviated, time: .omitted),
                            systemImage: "calendar"
                        )
                        .font(.caption)
                        .foregroundColor(task.isOverdue ? .red : .secondary)
                    }

                    // 标签
                    if !task.tags.isEmpty {
                        Label("\(task.tags.count)", systemImage: "tag")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // 逾期标记
            if task.isOverdue {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }

    private func priorityColor(_ priority: String) -> Color {
        switch priority {
        case "紧急": return .red
        case "高": return .orange
        case "普通": return .blue
        case "低": return .gray
        default: return .blue
        }
    }
}

/// 添加任务视图
struct AddTaskView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var priority = "普通"
    @State private var dueDate = Date()
    @State private var hasDueDate = false
    @State private var tags: [String] = []
    @State private var newTag = ""

    let priorities = ["低", "普通", "高", "紧急"]

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("任务标题", text: $title)

                    Picker("优先级", selection: $priority) {
                        ForEach(priorities, id: \.self) { priority in
                            Text(priority).tag(priority)
                        }
                    }
                }

                Section("截止日期") {
                    Toggle("设置截止日期", isOn: $hasDueDate)

                    if hasDueDate {
                        DatePicker(
                            "日期",
                            selection: $dueDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }
                }

                Section("标签") {
                    HStack {
                        TextField("添加标签", text: $newTag)
                        Button("添加") {
                            if !newTag.isEmpty {
                                tags.append(newTag)
                                newTag = ""
                            }
                        }
                        .disabled(newTag.isEmpty)
                    }

                    ForEach(tags, id: \.self) { tag in
                        Text(tag)
                    }
                    .onDelete { offsets in
                        tags.remove(atOffsets: offsets)
                    }
                }
            }
            .navigationTitle("新建任务")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveTask()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }

    private func saveTask() {
        let task = Task(
            title: title,
            priority: priority,
            dueDate: hasDueDate ? dueDate : nil,
            tags: tags
        )

        modelContext.insert(task)
        dismiss()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Task.self, inMemory: true)
}
