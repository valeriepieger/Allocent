import Foundation

enum MessageRole {
    case user
    case assistant
    case system
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: MessageRole
    let content: String
    let timestamp = Date()
}
