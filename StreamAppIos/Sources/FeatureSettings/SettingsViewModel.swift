import SwiftUI
import LiveVaultCommon
import LiveVaultNetwork

@Observable
public final class SettingsViewModel {
    public var userProfile: UserProfile? = nil
    public var subscriptionStatus: SubscriptionStatusDTO? = nil
    public var storageUsage: StorageUsageDTO? = nil
    public var pushEnabled = true
    public var isLoading = false
    public var errorMessage: String? = nil
    
    private let apiClient: APIClientProtocol
    private let tokenStorage: TokenStorageProtocol
    
    public init(
        apiClient: APIClientProtocol = APIClient.shared,
        tokenStorage: TokenStorageProtocol = KeychainTokenStorage.shared
    ) {
        self.apiClient = apiClient
        self.tokenStorage = tokenStorage
        self.userProfile = tokenStorage.getUserProfile()
    }
    
    @MainActor
    public func loadSettings() async {
        isLoading = true
        errorMessage = nil
        
        async let subTask: SubscriptionStatusDTO = apiClient.request(path: "/api/v1/subscription/status", method: "GET", queryItems: nil, body: nil, requiresAuth: true)
        async let storageTask: StorageUsageDTO = apiClient.request(path: "/api/v1/recordings/storage-usage", method: "GET", queryItems: nil, body: nil, requiresAuth: true)
        async let meTask: UserProfile = apiClient.request(path: "/api/v1/auth/me", method: "GET", queryItems: nil, body: nil, requiresAuth: true)
        
        do {
            let (sub, storage, user) = try await (subTask, storageTask, meTask)
            self.subscriptionStatus = sub
            self.storageUsage = storage
            self.userProfile = user
            try? tokenStorage.saveUserProfile(user)
            self.isLoading = false
        } catch {
            self.isLoading = false
            self.errorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    public func logout() async {
        tokenStorage.clearAll()
    }
}
