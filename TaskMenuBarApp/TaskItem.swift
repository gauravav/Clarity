import Foundation
import SwiftData

@Model
class TaskItem: Identifiable {
    @Attribute(.unique) var id: UUID
    @Attribute var title: String
    @Attribute var timestamp: Date
    @Attribute var isCompleted: Bool

    init(title: String, timestamp: Date = Date(), isCompleted: Bool = false) {
        self.id = UUID()
        self.title = title
        self.timestamp = timestamp
        self.isCompleted = isCompleted
    }
}
