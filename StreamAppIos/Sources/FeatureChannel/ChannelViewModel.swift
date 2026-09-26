import SwiftUI
import LiveVaultCommon
import LiveVaultNetwork

@Observable
public final class ChannelViewModel {
    public var selectedPlatform: Platform = .youtube
    public var channelUrl = ""
    public var displayName = ""
    public var platformId = ""
    public var avatarUrl = ""
    public var rtmpStreamUrl = ""
    public var consentConfirmed = false
    
    public var isLoading = false
    public var isSuccess = false
    public var errorMessage: String? = nil
    
    private let apiClient: APIClientProtocol
    
    public init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }
    
    @MainActor
    public func addChannel() async -> Bool {
        guard !channelUrl.isEmpty, !displayName.isEmpty else {
            self.errorMessage = "Please enter channel name and URL."
            return false
        }
        
        guard consentConfirmed else {
            self.errorMessage = "You must confirm ownership or recording authorization before adding a channel."
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        let body = AddChannelRequest(
            platform: selectedPlatform,
            platformId: platformId.isEmpty ? nil : platformId,
            channelUrl: channelUrl.trimmingCharacters(in: .whitespacesAndNewlines),
            displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines),
            avatarUrl: avatarUrl.isEmpty ? nil : avatarUrl,
            rtmpStreamUrl: rtmpStreamUrl.isEmpty ? nil : rtmpStreamUrl,
            consentConfirmed: true
        )
        
        do {
            let _: ChannelDTO = try await apiClient.request(
                path: "/api/v1/channels",
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
    public func deleteChannel(id: String) async -> Bool {
        isLoading = true
        do {
            let _: EmptyResponse = try await apiClient.request(
                path: "/api/v1/channels/\(id)",
                method: "DELETE",
                queryItems: nil,
                body: nil,
                requiresAuth: true
            )
            isLoading = false
            return true
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            return false
        }
    }
}
