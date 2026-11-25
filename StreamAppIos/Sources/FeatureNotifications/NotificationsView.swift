import SwiftUI
import LiveVaultCommon
import LiveVaultNetwork
import LiveVaultDesignSystem

public struct NotificationsView: View {
    @State private var viewModel = NotificationsViewModel()
    public let onSelectRecording: (String) -> Void
    public let onOpenStorageSettings: () -> Void
    
    public init(
        onSelectRecording: @escaping (String) -> Void,
        onOpenStorageSettings: @escaping () -> Void
    ) {
        self.onSelectRecording = onSelectRecording
        self.onOpenStorageSettings = onOpenStorageSettings
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                LiveVaultColors.darkBg.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Filter Bar
                    HStack {
                        Toggle(isOn: $viewModel.unreadOnly) {
                            Text("Unread Only")
                                .font(LiveVaultTypography.bodyMedium)
                                .foregroundColor(LiveVaultColors.textPrimary)
                        }
                        .toggleStyle(SwitchToggleStyle(tint: LiveVaultColors.indigoPrimary))
                        .onChange(of: viewModel.unreadOnly) { _, _ in
                            Task {
                                await viewModel.fetchNotifications()
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(LiveVaultColors.darkSurface)
                    
                    if viewModel.notifications.isEmpty && !viewModel.isLoading {
                        EmptyStateView(
                            iconName: "bell.slash",
                            title: "No Notifications",
                            subtitle: "You'll be notified when your streams start recording, complete processing, or approach storage limits."
                        )
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(viewModel.notifications) { notification in
                                    Button(action: {
                                        Task {
                                            await viewModel.markAsRead(id: notification.id)
                                        }
                                        handleNotificationTap(notification)
                                    }) {
                                        notificationCard(notification)
                                    }
                                }
                            }
                            .padding(16)
                        }
                        .refreshable {
                            await viewModel.fetchNotifications()
                        }
                    }
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Mark All Read") {
                        Task {
                            await viewModel.markAllAsRead()
                        }
                    }
                    .font(LiveVaultTypography.caption)
                    .foregroundColor(LiveVaultColors.indigoSecondary)
                    .disabled(viewModel.unreadCount == 0)
                }
            }
            .task {
                await viewModel.fetchNotifications()
            }
        }
    }
    
    private func handleNotificationTap(_ notification: NotificationDTO) {
        if let recId = notification.recordingId, !recId.isEmpty {
            onSelectRecording(recId)
        } else if notification.type == .storageQuotaWarning || notification.type == .storageQuotaExceeded {
            onOpenStorageSettings()
        }
    }
    
    private func notificationCard(_ item: NotificationDTO) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: item.type.sfSymbol)
                .font(.system(size: 20))
                .foregroundColor(iconColor(for: item.type))
                .padding(10)
                .background(iconColor(for: item.type).opacity(0.15))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.title)
                        .font(LiveVaultTypography.bodyLarge)
                        .fontWeight(item.read ? .medium : .bold)
                        .foregroundColor(LiveVaultColors.textPrimary)
                    
                    Spacer()
                    
                    if !item.read {
                        Circle()
                            .fill(LiveVaultColors.primaryRed)
                            .frame(width: 8, height: 8)
                    }
                }
                
                Text(item.body)
                    .font(LiveVaultTypography.bodyMedium)
                    .foregroundColor(LiveVaultColors.textSecondary)
                    .lineLimit(3)
                
                if let date = LiveVaultFormatters.parseISO8601(item.createdAt) {
                    Text(LiveVaultFormatters.formatRelativeTime(date))
                        .font(LiveVaultTypography.caption)
                        .foregroundColor(LiveVaultColors.textMuted)
                        .padding(.top, 2)
                }
            }
        }
        .padding(14)
        .background(item.read ? LiveVaultColors.darkSurface : LiveVaultColors.darkSurfaceVariant)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(LiveVaultColors.darkSurfaceBorder, lineWidth: 1))
    }
    
    private func iconColor(for type: NotificationType) -> Color {
        switch type {
        case .recordingComplete: return LiveVaultColors.emeraldSuccess
        case .recordingFailed: return LiveVaultColors.primaryRed
        case .storageQuotaWarning: return LiveVaultColors.amberWarning
        case .storageQuotaExceeded: return LiveVaultColors.primaryRed
        case .subscriptionExpiring, .subscriptionExpired: return LiveVaultColors.indigoSecondary
        }
    }
}
