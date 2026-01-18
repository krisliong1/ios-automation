import Foundation

/// 撤销/重做管理器
/// 记录所有操作，支持撤销和恢复
@available(iOS 16.0, macOS 13.0, *)
class UndoRedoManager: ObservableObject {

    // MARK: - Properties

    @Published var canUndo: Bool = false
    @Published var canRedo: Bool = false

    private var undoStack: [Operation] = []
    private var redoStack: [Operation] = []
    private let maxHistorySize = 50

    // MARK: - Operations

    /// 操作类型
    struct Operation {
        let id: UUID
        let description: String
        let timestamp: Date
        let undo: () async throws -> Void
        let redo: () async throws -> Void
    }

    // MARK: - Register Operation

    /// 注册可撤销操作
    func registerOperation(
        description: String,
        undo: @escaping () async throws -> Void,
        redo: @escaping () async throws -> Void
    ) {
        let operation = Operation(
            id: UUID(),
            description: description,
            timestamp: Date(),
            undo: undo,
            redo: redo
        )

        undoStack.append(operation)
        redoStack.removeAll() // 新操作清空重做栈

        // 限制历史大小
        if undoStack.count > maxHistorySize {
            undoStack.removeFirst()
        }

        updateStates()
        print("✅ 已记录操作: \(description)")
    }

    // MARK: - Undo/Redo

    /// 撤销
    func undo() async throws {
        guard let operation = undoStack.popLast() else {
            throw UndoError.noOperationToUndo
        }

        print("↩️ 撤销: \(operation.description)")

        try await operation.undo()
        redoStack.append(operation)
        updateStates()

        print("✅ 撤销完成")
    }

    /// 重做
    func redo() async throws {
        guard let operation = redoStack.popLast() else {
            throw UndoError.noOperationToRedo
        }

        print("↪️ 重做: \(operation.description)")

        try await operation.redo()
        undoStack.append(operation)
        updateStates()

        print("✅ 重做完成")
    }

    // MARK: - History

    /// 获取操作历史
    func getHistory() -> [String] {
        return undoStack.map { operation in
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            let time = formatter.string(from: operation.timestamp)
            return "[\(time)] \(operation.description)"
        }
    }

    /// 清空历史
    func clearHistory() {
        undoStack.removeAll()
        redoStack.removeAll()
        updateStates()
        print("🗑️ 历史已清空")
    }

    // MARK: - Private

    private func updateStates() {
        canUndo = !undoStack.isEmpty
        canRedo = !redoStack.isEmpty
    }
}

// MARK: - Error

enum UndoError: LocalizedError {
    case noOperationToUndo
    case noOperationToRedo

    var errorDescription: String? {
        switch self {
        case .noOperationToUndo:
            return "没有可撤销的操作"
        case .noOperationToRedo:
            return "没有可重做的操作"
        }
    }
}

// MARK: - 使用示例

extension UndoRedoManager {

    /// 示例：文件操作
    func exampleFileOperation() {
        let filePath = "/path/to/file.txt"
        let oldContent = "旧内容"
        let newContent = "新内容"

        registerOperation(
            description: "修改文件 \(filePath)",
            undo: {
                // 恢复旧内容
                try oldContent.write(toFile: filePath, atomically: true, encoding: .utf8)
            },
            redo: {
                // 应用新内容
                try newContent.write(toFile: filePath, atomically: true, encoding: .utf8)
            }
        )
    }

    /// 示例：配置修改
    func exampleConfigChange(key: String, oldValue: Any, newValue: Any) {
        registerOperation(
            description: "修改配置 \(key)",
            undo: {
                UserDefaults.standard.set(oldValue, forKey: key)
            },
            redo: {
                UserDefaults.standard.set(newValue, forKey: key)
            }
        )
    }
}
