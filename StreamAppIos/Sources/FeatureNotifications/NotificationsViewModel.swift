import SwiftUI
import LiveVaultCommon
import LiveVaultNetwork
import LiveVaultDatabase

@Observable
public final class NotificationsViewModel {
    public var notifications: [NotificationDTO] = []
    public var unreadOnly = false
    public var unreadCount = 0
    public var isLoading = false
    public var errorMessage: String? = nil
    
    private let apiClient: APIClientProtocol
    
    public init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }
    
    @MainActor
    public func fetchNotifications() async {
        isLoading = true
        errorMessage = nil
        
        let queryItems = [
            URLQueryItem(name: "unreadOnly", value: unreadOnly ? "true" : "false"),
            URLQueryItem(name: "limit", value: "30")
        ]
        
        do {
            let res: NotificationListDTO = try await apiClient.request(
                path: "/api/v1/notifications",
                method: "GET",
                queryItems: queryItems,
                body: nil,
                requiresAuth: true
            )
            self.notifications = res.notifications
            self.unreadCount = res.unreadCount
            self.isLoading = false
        } catch {
            self.isLoading = false
            self.errorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    public func markAsRead(id: String) async {
        do {
            let _: EmptyResponse = try await apiClient.request(
                path: "/api/v1/notifications/\(id)/read",
                method: "PATCH",
                queryItems: nil,
                body: nil,
                requiresAuth: true
            )
            if let idx = notifications.firstIndex(where: { $0.id == id }) {
                notifications[idx].read = true
                unreadCount = max(0, unreadCount - 1)
            }
        } catch {
            print("Failed to mark notification as read: \(error)")
        }
    }
    
    @MainActor
    public func markAllAsRead() async {
        do {
            let _: MarkAllReadResponse = try await apiClient.request(
                path: "/api/v1/notifications/mark-all-read",
                method: "POST",
                queryItems: nil,
                body: nil,
                requiresAuth: true
            )
            for i in 0..<notifications.count {
                notifications[i].read = true
            }
            unreadCount = 0
        } catch {
            print("Failed to mark all as read: \(error)")
        }
    }
}
