import SwiftUI

struct AppSidebarView: View {
    @Binding var selection: AppDestination?
    let messageCount: Int
    let runtimeModelName: String
    let onNewChat: () -> Void

    private var sidebarItems: [(destination: AppDestination, subtitle: String)] {
        [
            (.chat, messageCount == 0 ? "No messages" : "\(messageCount) messages"),
            (.modelSettings, runtimeModelName)
        ]
    }

    var body: some View {
        List(selection: $selection) {
            ForEach(sidebarItems, id: \.destination) { item in
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.destination.title)
                            .font(.subheadline.weight(.semibold))
                        Text(item.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: item.destination.systemImage)
                }
                .tag(item.destination as AppDestination?)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Caice")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    onNewChat()
                    selection = .chat
                } label: {
                    Label("New Chat", systemImage: "plus")
                }
            }
        }
    }
}
