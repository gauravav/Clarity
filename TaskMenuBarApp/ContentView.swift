import SwiftUI
import SwiftData
import Combine
import ConfettiSwiftUI


class UndoState: ObservableObject {
    var lastDeleted: TaskItem? = nil
    var undoTimer: AnyCancellable? = nil
}

struct ContentView: View {
    @ObservedObject var settings: AppSettings
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme
    @Query(sort: [SortDescriptor(\TaskItem.timestamp, order: .reverse)]) var items: [TaskItem]

    @State private var newTask = ""
    @State private var draggingItem: TaskItem?
    @State private var potentialDropTargetID: UUID?
    @StateObject private var undoState = UndoState()
    @State private var showDeleteAllConfirmation = false
    @State private var animateCheckmark = false
    @State private var hoveredDeleteID: UUID? = nil
    @State private var recentlyDeletedID: UUID? = nil
    @State private var trigger: Int = 0


    var sortedItems: [TaskItem] {
        items.sorted {
            if $0.isCompleted == $1.isCompleted {
                return $0.timestamp > $1.timestamp
            }
            return !$0.isCompleted && $1.isCompleted
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Section 1: Add Task (pinned at top)
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    TextField("Add Task", text: $newTask, onCommit: addTask)
                        .textFieldStyle(.roundedBorder)
                        .padding(.vertical, 6)
                    Button(action: addTask) {
                        ZStack {
                            if animateCheckmark {
                                Image(systemName: "checkmark.circle.fill")
                                    .transition(.scale)
                                    .foregroundColor(.green)
                            } else {
                                Image(systemName: "arrowshape.forward.circle.fill")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .font(.title2)
                        .scaleEffect(animateCheckmark ? 1.3 : 1.0)
                        .animation(.interpolatingSpring(stiffness: 200, damping: 10), value: animateCheckmark)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)

            Divider()

            // Section 2: Task List + Delete All
            VStack(alignment: .leading, spacing: 8) {
                if !items.isEmpty {
                    HStack {
                        Spacer()
                        if showDeleteAllConfirmation {
                            HStack(spacing: 8) {
                                Text("Delete all tasks?").font(.caption)
                                Button("Yes") {
                                    deleteAllTasks()
                                    showDeleteAllConfirmation = false
                                }.foregroundColor(.red)
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

                if sortedItems.isEmpty {
                    Spacer()
                    Text("No tasks found.")
                        .foregroundColor(.secondary)
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 6) {
                            ForEach(sortedItems) { item in
                                if potentialDropTargetID == item.id {
                                    Spacer()
                                        .frame(height: 20)
                                        .transition(.opacity)
                                        .animation(.easeInOut(duration: 0.2), value: potentialDropTargetID)
                                }
                                let isDragging = draggingItem?.id == item.id
                                HStack(spacing: 6) {
                                    Button(action: {
                                        item.isCompleted.toggle()
                                        try? modelContext.save()
                                        if shouldTriggerConfetti(tasks: sortedItems, settings: settings) {
                                            trigger += 1
                                        }
                                    }) {
                                        Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(item.isCompleted ? .green : .gray)
                                    }.buttonStyle(.plain)

                                    Text(item.title)
                                        .strikethrough(item.isCompleted)
                                        .foregroundColor(item.isCompleted ? .gray : .primary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .lineLimit(1)

                                    Button(role: .destructive) {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                            handleDelete(item: item, modelContext: modelContext, undoState: undoState, settings: settings)
                                            recentlyDeletedID = item.id
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                                recentlyDeletedID = nil
                                            }
                                        }
                                    } label: {
                                        Group {
                                            if recentlyDeletedID == item.id {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.red)
                                                    .transition(.scale)
                                            } else {
                                                Image(systemName: "trash")
                                                    .foregroundColor(hoveredDeleteID == item.id ? .red : .gray)
                                            }
                                        }
                                        .font(.callout) // smaller size
                                    }
                                    .buttonStyle(.plain)
                                    .onHover { hovering in
                                        hoveredDeleteID = hovering ? item.id : nil
                                    }
                                }
                                .padding(.vertical, 4)
                                .padding(.leading, 8)
                                .padding(.trailing, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.05))
                                )
                                .scaleEffect(isDragging ? 1.05 : 1.0)
                                .opacity(isDragging ? 0.8 : 1.0)
                                .shadow(color: .black.opacity(isDragging ? 0.2 : 0), radius: 6, x: 0, y: 3)
                                .animation(.default, value: isDragging)
                                .onDrag {
                                    if settings.enableHaptics {
                                        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
                                    }
                                    draggingItem = item
                                    return NSItemProvider(object: item.title as NSString)
                                }
                                .onDrop(of: [.text], delegate: SimpleDropDelegate(
                                    item: item,
                                    draggingItem: $draggingItem,
                                    onMove: reorderItems
                                ))
                            }
                        }
                        .padding(.horizontal, 12)
                    }
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 12)
            .confettiCannon(trigger: $trigger, num: 50, openingAngle: Angle(degrees: 0), closingAngle: Angle(degrees: 360), radius: 200)}
        .frame(width: 375, height: 500) // ✅ Fixed popup size
    }

    private func addTask() {
        guard !newTask.isEmpty else { return }

        let task = TaskItem(title: newTask, timestamp: Date(), isCompleted: false)
        modelContext.insert(task)
        try? modelContext.save()
//        trigger += 1

        DispatchQueue.main.async {
            newTask = "" // ✅ Reset AFTER current runloop to trigger re-render
            animateCheckmark = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                animateCheckmark = false
            }
        }
    }

    private func deleteAllTasks() {
        for item in items {
            modelContext.delete(item)
        }
        try? modelContext.save()
    }

    private func reorderItems(from dragging: TaskItem, to target: TaskItem) {
        guard let fromIndex = items.firstIndex(of: dragging),
              let toIndex = items.firstIndex(of: target),
              fromIndex != toIndex else { return }

        var newOrder = items

        let movedItem = newOrder.remove(at: fromIndex)
        newOrder.insert(movedItem, at: toIndex)

        // Animate timestamp update to visually reorder
        withAnimation(.easeInOut(duration: 0.3)) {
            for (index, item) in newOrder.enumerated() {
                item.timestamp = Date().addingTimeInterval(Double(-index))
                modelContext.insert(item)
            }

            try? modelContext.save()
        }
    }

    private func reorderWithoutAnimation(from dragging: TaskItem, to target: TaskItem) {
        guard let fromIndex = items.firstIndex(of: dragging),
              let toIndex = items.firstIndex(of: target),
              fromIndex != toIndex else { return }

        var newOrder = items

        // Remove dragging item and insert at new location
        let movedItem = newOrder.remove(at: fromIndex)
        newOrder.insert(movedItem, at: toIndex)

        // Update timestamps to reflect new order
        for (index, item) in newOrder.enumerated() {
            item.timestamp = Date().addingTimeInterval(Double(-index))
            modelContext.insert(item)
        }

        try? modelContext.save()
    }

}


struct SimpleDropDelegate: DropDelegate {
    let item: TaskItem
    @Binding var draggingItem: TaskItem?
    let onMove: (TaskItem, TaskItem) -> Void

    func performDrop(info: DropInfo) -> Bool {
        guard let dragging = draggingItem else { return false }
        onMove(dragging, item)
        draggingItem = nil
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let dragging = draggingItem, dragging != item else { return }
        onMove(dragging, item)
    }
}

func handleDelete(item: TaskItem, modelContext: ModelContext, undoState: UndoState, settings: AppSettings) {
    if settings.enableUndoDelete {
        undoState.lastDeleted = item
        modelContext.delete(item)
        try? modelContext.save()

        undoState.undoTimer?.cancel()
        undoState.undoTimer = Just(())
            .delay(for: .seconds(5), scheduler: DispatchQueue.main)
            .sink { _ in
                undoState.lastDeleted = nil
            }
    } else {
        modelContext.delete(item)
        try? modelContext.save()
    }
}

func shouldTriggerConfetti(tasks: [TaskItem], settings: AppSettings) -> Bool {
    settings.showConfetti && !tasks.isEmpty && tasks.allSatisfy { $0.isCompleted }
}
