import SwiftUI
import SwiftData

@main
struct TaskMenuBarApp: App {
    var body: some Scene {
        MenuBarExtra("Tasks", systemImage: "list.bullet") {
            ContentView()
                .frame(width: 400, height: 600) // ✅ Set fixed size here
                .modelContainer(for: TaskItem.self)
        }
        .menuBarExtraStyle(.window)
    }
}
