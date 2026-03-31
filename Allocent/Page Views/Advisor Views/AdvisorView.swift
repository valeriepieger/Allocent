//
//  AdvisorView.swift
//  Allocent
//
//  Created by Valerie on 3/28/26.
//

import SwiftUI
import FoundationModels

struct AdvisorView: View {
    @State private var viewModel = AdvisorViewModel()

    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()

            VStack(spacing: 0) {
                Header(categoryName: "Advisor")

                if viewModel.isModelAvailable {
                    ChatContentView(viewModel: viewModel)
                } else {
                    AdvisorUnavailableView()
                }
            }
        }
        .task {
            await viewModel.setup()
        }
    }
}


struct ChatContentView: View {
    @Bindable var viewModel: AdvisorViewModel
    @FocusState private var isTextFieldFocused: Bool
    
    //user won't be able to send a message they typed if view model still loading (AI still crafting response)
    private var canSend: Bool {
        !viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !viewModel.isLoading
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            ChatBubble(message: message)
                                .id(message.id)
                        }

                        if viewModel.isLoading {
                            //if AI coming up with response (loading), typing indicator on left side
                            HStack {
                                TypingIndicator()
                                Spacer()
                            }
                            .padding(.horizontal)
                            .id("loading")
                        }
                    }
                    .padding(.vertical, 12)
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    scrollToBottom(proxy: proxy)
                }
                .onChange(of: viewModel.isLoading) { _, isLoading in
                    if isLoading {
                        withAnimation {
                            proxy.scrollTo("loading", anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            //Text field for user to query
            HStack(spacing: 12) {
                TextField("Ask about your budget...", text: $viewModel.inputText, axis: .vertical)
                    .lineLimit(1...4)
                    .padding(12)
                    .background(Color("CardBackground"))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    .onSubmit { sendMessage() }
                    .focused($isTextFieldFocused)

                Button("Send message", systemImage: "arrow.up.circle.fill", action: sendMessage)
                    .labelStyle(.iconOnly)
                    .font(.system(size: 32))
                    .foregroundStyle(canSend ? Color("OliveGreen") : Color("OliveGreen").opacity(0.4))
                    .disabled(!canSend)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color("Background"))

        }
        .onTapGesture { //to get keyboard out of the way on tap outside of keyboard
            isTextFieldFocused = false
        }
    }

    private func sendMessage() {
        guard canSend else { return }
        Task { await viewModel.sendMessage() }
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastId = viewModel.messages.last?.id {
            withAnimation(.easeOut(duration: 0.3)) {
                proxy.scrollTo(lastId, anchor: .bottom)
            }
        }
    }
}

////for user to query
//struct ChatInputBar: View {
//    @Bindable var viewModel: AdvisorViewModel
//
//    
//}

//for when on simulator or device doesn't have apple intelligence, show unavail screen
struct AdvisorUnavailableView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "bubble.left.and.exclamationmark.bubble.right")
                .font(.system(size: 48))
                .foregroundStyle(Color("OliveGreen").opacity(0.6))

            Text("Advisor Unavailable")
                .font(.title3)
                .fontWeight(.medium)

            Text("The budget advisor requires Apple Intelligence, which is not available on this device.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()
        }
    }
}

struct TypingIndicator: View {
    @State private var phase: Int = 0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color("OliveGreen"))
                    .frame(width: 8, height: 8)
                    .opacity(index <= phase ? 1.0 : 0.3)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color("CardBackground"))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .accessibilityLabel("Advisor is thinking")
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(400))
                phase = (phase + 1) % 3
            }
        }
    }
}

#Preview {
    AdvisorView()
}
