import SwiftUI

struct ChatBubble: View {
    let message: ChatMessage

    private var isUser: Bool {
        message.role == .user
    }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 60) }

            switch message.role {
            case .system:
                Text(message.content)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .accessibilityLabel("System message: \(message.content)")
            case .user, .assistant:
                Text(message.content)
                    .font(.body)
                    .foregroundStyle(isUser ? Color("PrimaryButtonText") : .primary)
                    .padding(12)
                    .background(isUser ? Color("PrimaryButton") : Color("CardBackground"))
                    .cornerRadius(16)
                    .shadow(
                        color: Color.black.opacity(isUser ? 0 : 0.05),
                        radius: 4, x: 0, y: 2
                    )
                    .accessibilityLabel(
                        isUser
                            ? "You said: \(message.content)"
                            : "Advisor said: \(message.content)"
                    )
            }

            if !isUser { Spacer(minLength: 60) }
        }
        .padding(.horizontal)
    }
}

#Preview {
    VStack(spacing: 12) {
        ChatBubble(message: ChatMessage(role: .assistant, content: "Hi! I'm your budget advisor."))
        ChatBubble(message: ChatMessage(role: .user, content: "How am I doing this month?"))
        ChatBubble(message: ChatMessage(role: .system, content: "Session reset."))
    }
    .padding(.vertical)
    .background(Color("Background"))
}
