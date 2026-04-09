import SwiftUI

struct AppSidebarView: View {
    @Binding var selection: AppDestination?
    let messageCount: Int
    let runtimeModelName: String
    let onNewChat: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()
                .overlay(AppTheme.Surface.stroke)

            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(AppDestination.allCases) { destination in
                        Button {
                            selection = destination
                        } label: {
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: destination.systemImage)
                                    .font(.system(size: 14, weight: .semibold))
                                    .frame(width: 18)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(destination.title)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.primary)
                                    Text(subtitle(for: destination))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(destinationBackground(for: destination))
                            .overlay(alignment: .leading) {
                                if selection == destination {
                                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                                        .fill(Color.accentColor.opacity(0.9))
                                        .frame(width: 3, height: 22)
                                        .padding(.leading, 2)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 11)
                .padding(.bottom, 14)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            ZStack {
                AppTheme.Surface.sidebarGradient

                Circle()
                    .fill(AppTheme.Surface.warmGlow.opacity(0.14))
                    .frame(width: 320, height: 320)
                    .blur(radius: 64)
                    .offset(x: -120, y: -220)

                Circle()
                    .fill(AppTheme.Surface.coolGlow.opacity(0.1))
                    .frame(width: 300, height: 300)
                    .blur(radius: 68)
                    .offset(x: 120, y: 260)

                LinearGradient(
                    colors: [
                        Color.white.opacity(0.2),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottom
                )
            }
        )
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Caice")
                    .font(.title3.weight(.semibold))

                Label("Local chat workspace", systemImage: "lock.shield")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .labelStyle(.titleAndIcon)

                Label(runtimeModelName, systemImage: "cpu")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(AppTheme.Surface.premiumPillGradient)
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(AppTheme.Surface.tileStroke, lineWidth: 1)
                    )
            }

            Spacer(minLength: 0)

            Button {
                onNewChat()
                selection = .chat
            } label: {
                Label("New Chat", systemImage: "plus")
                    .labelStyle(.iconOnly)
                    .frame(width: 32, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(AppTheme.Surface.elevatedFill)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(AppTheme.Surface.emphasisStroke, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .help("New Chat")
        }
        .padding(.horizontal, 15)
        .padding(.top, 15)
        .padding(.bottom, 12)
    }

    private func destinationBackground(for destination: AppDestination) -> some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(selection == destination ? Color.accentColor.opacity(0.14) : AppTheme.Surface.elevatedFill.opacity(0.001))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(selection == destination ? Color.accentColor.opacity(0.25) : AppTheme.Surface.stroke.opacity(0.0), lineWidth: 1)
            )
    }

    private func subtitle(for destination: AppDestination) -> String {
        switch destination {
        case .chat:
            return messageCount == 0 ? "No messages" : "\(messageCount) messages"
        case .modelSettings:
            return runtimeModelName
        }
    }
}
