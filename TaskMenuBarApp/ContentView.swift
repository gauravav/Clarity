import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme
    @Query(sort: [SortDescriptor(\TaskItem.timestamp, order: .reverse)]) var items: [TaskItem]

    @State private var newTask = ""
    @State private var searchText = ""
    @State private var draggingItem: TaskItem?
    @State private var showDeleteAllConfirmation = false

    var sortedItems: [TaskItem] {
        items
            .filter { searchText.isEmpty || $0.title.localizedCaseInsensitiveContains(searchText) }
            .sorted {
                if $0.isCompleted == $1.isCompleted {
                    return $0.timestamp > $1.timestamp
                }
                return !$0.isCompleted && $1.isCompleted
            }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Search bar
            TextField("Search", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding(.vertical, 4)

            // Add task field
            HStack(spacing: 8) {
                TextField("Add Task", text: $newTask, onCommit: addTask)
                    .textFieldStyle(.roundedBorder)
                    .padding(.vertical, 6)

                Button(action: addTask) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
            }

            // Inline delete all confirmation
            if !items.isEmpty {
                HStack {
                    Spacer()
                    if showDeleteAllConfirmation {
                        HStack(spacing: 8) {
                            Text("Delete all tasks?")
                                .font(.caption)
                            Button("Yes") {
                                deleteAllTasks()
                                showDeleteAllConfirmation = false
                            }
                            .foregroundColor(.red)

                            Button("No") {
                                showDeleteAllConfirmation = false
                            }
                        }
                    } else {
                        Button(role: .destructive) {
                            showDeleteAllConfirmation = true
                        } label: {
                            Label("Delete All", systemImage: "trash")
                                .font(.caption)
                        }
                        .buttonStyle(.borderless)
                        .padding(.trailing, 4)
                    }
                }
            }

            // Scrollable task list
            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(sortedItems) { item in
                        HStack(spacing: 6) {
                            Button(action: {
                                item.isCompleted.toggle()
                                try? modelContext.save()
                            }) {
                                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(item.isCompleted ? .green : .gray)
                            }
                            .buttonStyle(.plain)

                            Text(item.title)
                                .strikethrough(item.isCompleted)
                                .foregroundColor(item.isCompleted ? .gray : .primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .lineLimit(1)

                            Button(role: .destructive) {
                                modelContext.delete(item)
                                try? modelContext.save()
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 4)
                        .padding(.leading, 8)
                        .padding(.trailing, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.05))
                        )
                        .onDrag {
                            draggingItem = item
                            return NSItemProvider(object: item.title as NSString)
                        }
                        .onDrop(of: [.text], delegate: TaskDropDelegate(
                            item: item,
                            draggingItem: $draggingItem,
                            onMove: reorderItems
                        ))
                    }
                }
            }
            .frame(
                minHeight: CGFloat(min(sortedItems.count, 3)) * 32,
                maxHeight: CGFloat(min(sortedItems.count, 20)) * 32
            )
        }
        .padding(12)
        .frame(width: 375)
    }

    private func addTask() {
        guard !newTask.isEmpty else { return }
        let task = TaskItem(title: newTask, timestamp: Date(), isCompleted: false)
        modelContext.insert(task)
        try? modelContext.save()
        newTask = "" // ✅ Clear text field
    }

    private func deleteAllTasks() {
        for item in items {
            modelContext.delete(item)
        }
        try? modelContext.save()
    }

    private func reorderItems(from dragging: TaskItem, to target: TaskItem) {
        guard let fromIndex = sortedItems.firstIndex(of: dragging),
              let toIndex = sortedItems.firstIndex(of: target),
              fromIndex != toIndex else { return }

        let reordered = sortedItems
        let updated = reordered.enumerated().map { index, item in
            item.timestamp = Date().addingTimeInterval(Double(-index))
            return item
        }

        updated.forEach { modelContext.insert($0) }
        try? modelContext.save()
    }
}

struct TaskDropDelegate: DropDelegate {
    let item: TaskItem
    @Binding var draggingItem: TaskItem?
    let onMove: (TaskItem, TaskItem) -> Void

    func performDrop(info: DropInfo) -> Bool {
        guard let dragging = draggingItem else { return false }
        onMove(dragging, item)
        draggingItem = nil
        return true
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}
