import SwiftUI

struct AppSidebarView: View {
    @Binding var selection: AppDestination?
    let messageCount: Int
    let runtimeModelName: String
    let onNewChat: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                onNewChat()
                selection = .chat
            } label: {
                Label("New Chat", systemImage: "plus.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.borderedProminent)

            Divider()
                .opacity(0.35)

            AppSidebarRow(
                title: AppDestination.chat.title,
                subtitle: messageCount == 0 ? "No messages" : "\(messageCount) messages",
                systemImage: AppDestination.chat.systemImage,
                isSelected: selection == .chat,
                action: {
                    selection = .chat
                }
            )

            AppSidebarRow(
                title: AppDestination.modelSettings.title,
                subtitle: runtimeModelName,
                systemImage: AppDestination.modelSettings.systemImage,
                isSelected: selection == .modelSettings,
                action: {
                    selection = .modelSettings
                }
            )

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .navigationTitle("Caice")
    }
}
