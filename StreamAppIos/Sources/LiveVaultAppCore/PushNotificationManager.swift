import Foundation
import UserNotifications
import UIKit
import LiveVaultCommon
import LiveVaultNetwork

public final class PushNotificationManager: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    public static let shared = PushNotificationManager()
    
    public var onNavigateToRecording: ((String) -> Void)?
    public var onNavigateToStorageSettings: (() -> Void)?
    
    private let apiClient: APIClientProtocol
    
    public init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
        super.init()
    }
    
    public func requestAuthorization() {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    public func registerDeviceToken(_ deviceTokenData: Data) {
        let token = deviceTokenData.map { String(format: "%02.2hhx", $0) }.joined()
        Task {
            let body = RegisterDeviceTokenRequest(platform: "ios", token: token)
            _ = try? await apiClient.request(
                path: "/api/v1/devices/token",
                method: "PUT",
                queryItems: nil,
                body: body,
                requiresAuth: true
            ) as EmptyResponse
        }
    }
    
    // MARK: - Foreground Push Delivery
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show banner and sound even when foregrounded
        completionHandler([.banner, .sound, .badge])
    }
    
    // MARK: - Tap Action Handling (Background & Cold Start)
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        handlePushPayload(userInfo)
        completionHandler()
    }
    
    public func handlePushPayload(_ userInfo: [AnyHashable: Any]) {
        if let typeString = userInfo["type"] as? String, let type = NotificationType(rawValue: typeString) {
            switch type {
            case .recordingComplete, .recordingFailed:
                if let recordingId = userInfo["recordingId"] as? String {
                    onNavigateToRecording?(recordingId)
                }
            case .storageQuotaWarning, .storageQuotaExceeded:
                onNavigateToStorageSettings?()
            default:
                break
            }
        } else if let recordingId = userInfo["recordingId"] as? String {
            onNavigateToRecording?(recordingId)
        }
    }
}
