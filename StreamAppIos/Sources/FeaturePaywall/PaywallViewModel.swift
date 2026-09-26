import SwiftUI
import StoreKit
import LiveVaultCommon
import LiveVaultNetwork

@Observable
public final class PaywallViewModel {
    public var selectedTier: SubscriptionTier = .pro
    public var isAnnual = true
    public var isLoading = false
    public var isSuccess = false
    public var errorMessage: String? = nil
    
    private let apiClient: APIClientProtocol
    
    public init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }
    
    @MainActor
    public func purchaseSelectedTier() async -> Bool {
        isLoading = true
        errorMessage = nil
        
        // In production, execute StoreKit 2 / RevenueCat purchase here
        // e.g. let result = try await Product.purchase(...)
        // Then link with backend:
        do {
            let mockRevenueCatId = "rc_user_\(UUID().uuidString.prefix(8))"
            let body = LinkRevenueCatRequest(revenuecatId: mockRevenueCatId)
            let _: EmptyResponse = try await apiClient.request(
                path: "/api/v1/subscription/link-revenuecat",
                method: "POST",
                queryItems: nil,
                body: body,
                requiresAuth: true
            )
            self.isLoading = false
            self.isSuccess = true
            return true
        } catch {
            self.isLoading = false
            self.errorMessage = error.localizedDescription
            return false
        }
    }
    
    @MainActor
    public func restorePurchases() async {
        isLoading = true
        do {
            try await AppStore.sync()
            self.isLoading = false
        } catch {
            self.isLoading = false
            self.errorMessage = error.localizedDescription
        }
    }
}
