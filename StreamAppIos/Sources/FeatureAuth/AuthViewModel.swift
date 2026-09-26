import SwiftUI
import AuthenticationServices
import LiveVaultCommon
import LiveVaultNetwork
import LiveVaultDesignSystem

@Observable
public final class AuthViewModel {
    public var email = ""
    public var password = ""
    public var displayName = ""
    public var isLoading = false
    public var errorMessage: String? = nil
    public var isAuthenticated = false
    public var currentUser: UserProfile? = nil
    
    private let apiClient: APIClientProtocol
    private let tokenStorage: TokenStorageProtocol
    
    public init(
        apiClient: APIClientProtocol = APIClient.shared,
        tokenStorage: TokenStorageProtocol = KeychainTokenStorage.shared
    ) {
        self.apiClient = apiClient
        self.tokenStorage = tokenStorage
        checkAuthState()
    }
    
    public func checkAuthState() {
        if let token = tokenStorage.getAccessToken(), !token.isEmpty {
            self.isAuthenticated = true
            self.currentUser = tokenStorage.getUserProfile()
            Task {
                await fetchCurrentUserProfile()
            }
        } else {
            self.isAuthenticated = false
            self.currentUser = nil
        }
    }
    
    @MainActor
    public func login() async {
        guard !email.isEmpty, !password.isEmpty else {
            self.errorMessage = "Please enter both email and password."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let body = LoginRequest(email: email.trimmingCharacters(in: .whitespacesAndNewlines), password: password)
            let result: AuthResult = try await apiClient.request(
                path: "/api/v1/auth/login",
                method: "POST",
                queryItems: nil,
                body: body,
                requiresAuth: false
            )
            
            try tokenStorage.saveTokens(accessToken: result.accessToken, refreshToken: result.refreshToken)
            try tokenStorage.saveUserProfile(result.user)
            
            self.currentUser = result.user
            self.isAuthenticated = true
            self.isLoading = false
        } catch {
            self.isLoading = false
            self.errorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    public func register() async {
        guard !email.isEmpty, !password.isEmpty, !displayName.isEmpty else {
            self.errorMessage = "Please fill in all required fields."
            return
        }
        
        if password.count < 8 {
            self.errorMessage = "Password must be at least 8 characters."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let body = RegisterRequest(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password,
                displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            let result: AuthResult = try await apiClient.request(
                path: "/api/v1/auth/register",
                method: "POST",
                queryItems: nil,
                body: body,
                requiresAuth: false
            )
            
            try tokenStorage.saveTokens(accessToken: result.accessToken, refreshToken: result.refreshToken)
            try tokenStorage.saveUserProfile(result.user)
            
            self.currentUser = result.user
            self.isAuthenticated = true
            self.isLoading = false
        } catch {
            self.isLoading = false
            self.errorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    public func handleAppleSignIn(identityToken: String, fullName: String?) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let body = AppleAuthRequest(identityToken: identityToken, displayName: fullName)
            let result: AuthResult = try await apiClient.request(
                path: "/api/v1/auth/apple",
                method: "POST",
                queryItems: nil,
                body: body,
                requiresAuth: false
            )
            
            try tokenStorage.saveTokens(accessToken: result.accessToken, refreshToken: result.refreshToken)
            try tokenStorage.saveUserProfile(result.user)
            
            self.currentUser = result.user
            self.isAuthenticated = true
            self.isLoading = false
        } catch {
            self.isLoading = false
            self.errorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    public func handleGoogleSignIn(idToken: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let body = GoogleAuthRequest(idToken: idToken)
            let result: AuthResult = try await apiClient.request(
                path: "/api/v1/auth/google",
                method: "POST",
                queryItems: nil,
                body: body,
                requiresAuth: false
            )
            
            try tokenStorage.saveTokens(accessToken: result.accessToken, refreshToken: result.refreshToken)
            try tokenStorage.saveUserProfile(result.user)
            
            self.currentUser = result.user
            self.isAuthenticated = true
            self.isLoading = false
        } catch {
            self.isLoading = false
            self.errorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    public func fetchCurrentUserProfile() async {
        do {
            let user: UserProfile = try await apiClient.request(
                path: "/api/v1/auth/me",
                method: "GET",
                queryItems: nil,
                body: nil,
                requiresAuth: true
            )
            try? tokenStorage.saveUserProfile(user)
            self.currentUser = user
        } catch {
            // Silently ignore or refresh
        }
    }
    
    @MainActor
    public func logout() async {
        if let refreshToken = tokenStorage.getRefreshToken() {
            let body = RefreshTokenRequest(refreshToken: refreshToken)
            _ = try? await apiClient.request(
                path: "/api/v1/auth/logout",
                method: "POST",
                queryItems: nil,
                body: body,
                requiresAuth: true
            ) as EmptyResponse
        }
        
        tokenStorage.clearAll()
        self.isAuthenticated = false
        self.currentUser = nil
    }
}
