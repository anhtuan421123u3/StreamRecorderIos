import SwiftUI
import AuthenticationServices
import LiveVaultCommon
import LiveVaultDesignSystem

// MARK: - Splash & Onboarding View
public struct SplashView: View {
    public let onGetStarted: () -> Void
    
    public init(onGetStarted: @escaping () -> Void) {
        self.onGetStarted = onGetStarted
    }
    
    public var body: some View {
        ZStack {
            LiveVaultColors.darkBg.ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Branding Logo Icon
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [LiveVaultColors.primaryRed.opacity(0.3), Color.clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: 100
                            )
                        )
                        .frame(width: 160, height: 160)
                    
                    Image(systemName: "dot.radiowaves.left.and.right")
                        .font(.system(size: 64, weight: .bold))
                        .foregroundColor(LiveVaultColors.primaryRed)
                }
                
                VStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Text("Live")
                            .font(.system(size: 38, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        Text("Vault")
                            .font(.system(size: 38, weight: .black, design: .rounded))
                            .foregroundColor(LiveVaultColors.primaryRed)
                    }
                    
                    Text("Automated 24/7 Livestream Recording &\nCloud Archival for Content Creators")
                        .font(LiveVaultTypography.bodyMedium)
                        .foregroundColor(LiveVaultColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                
                Spacer()
                
                // Features bullets
                VStack(alignment: .leading, spacing: 14) {
                    featureRow(icon: "bolt.badge.clock.fill", title: "Never Miss a Stream", subtitle: "Auto-detects live status and records in background")
                    featureRow(icon: "lock.shield.fill", title: "Compliant & Legal", subtitle: "Strict authorization & owner consent verification")
                    featureRow(icon: "play.tv.fill", title: "Seamless Playback", subtitle: "HLS streaming with Picture-in-Picture & auto-refresh")
                }
                .padding(.horizontal, 28)
                
                Spacer()
                
                Button(action: onGetStarted) {
                    HStack {
                        Text("Get Started")
                            .font(LiveVaultTypography.titleMedium)
                            .foregroundColor(.white)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(LiveVaultColors.primaryRed)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }
    
    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(LiveVaultColors.primaryRed)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(LiveVaultTypography.bodyLarge)
                    .fontWeight(.semibold)
                    .foregroundColor(LiveVaultColors.textPrimary)
                Text(subtitle)
                    .font(LiveVaultTypography.caption)
                    .foregroundColor(LiveVaultColors.textSecondary)
            }
        }
    }
}

// MARK: - Login View
public struct LoginView: View {
    @Bindable var viewModel: AuthViewModel
    public let onNavigateToRegister: () -> Void
    
    public init(viewModel: AuthViewModel, onNavigateToRegister: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onNavigateToRegister = onNavigateToRegister
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                LiveVaultColors.darkBg.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Text("Welcome Back")
                                .font(LiveVaultTypography.displayLarge)
                                .foregroundColor(LiveVaultColors.textPrimary)
                            Text("Log in to access your monitored streams and recordings")
                                .font(LiveVaultTypography.bodyMedium)
                                .foregroundColor(LiveVaultColors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 40)
                        
                        // Error Alert
                        if let error = viewModel.errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.circle.fill")
                                Text(error)
                                    .font(LiveVaultTypography.bodyMedium)
                            }
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(LiveVaultColors.primaryRed.opacity(0.8))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        
                        // Input Fields
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Email Address")
                                    .font(LiveVaultTypography.labelMedium)
                                    .foregroundColor(LiveVaultColors.textSecondary)
                                TextField("", text: $viewModel.email)
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .padding()
                                    .background(LiveVaultColors.darkSurface)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(LiveVaultColors.darkSurfaceBorder, lineWidth: 1))
                                    .foregroundColor(LiveVaultColors.textPrimary)
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Password")
                                    .font(LiveVaultTypography.labelMedium)
                                    .foregroundColor(LiveVaultColors.textSecondary)
                                SecureField("", text: $viewModel.password)
                                    .padding()
                                    .background(LiveVaultColors.darkSurface)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(LiveVaultColors.darkSurfaceBorder, lineWidth: 1))
                                    .foregroundColor(LiveVaultColors.textPrimary)
                            }
                        }
                        .padding(.top, 12)
                        
                        // Login Button
                        Button(action: {
                            Task {
                                await viewModel.login()
                            }
                        }) {
                            ZStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Log In")
                                        .font(LiveVaultTypography.titleMedium)
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(LiveVaultColors.primaryRed)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(viewModel.isLoading)
                        
                        // Divider
                        HStack {
                            Rectangle().fill(LiveVaultColors.darkSurfaceBorder).frame(height: 1)
                            Text("OR")
                                .font(LiveVaultTypography.caption)
                                .foregroundColor(LiveVaultColors.textMuted)
                                .padding(.horizontal, 8)
                            Rectangle().fill(LiveVaultColors.darkSurfaceBorder).frame(height: 1)
                        }
                        .padding(.vertical, 8)
                        
                        // Sign in with Apple Button
                        SignInWithAppleButton(
                            .signIn,
                            onRequest: { request in
                                request.requestedScopes = [.fullName, .email]
                            },
                            onCompletion: { result in
                                switch result {
                                case .success(let authorization):
                                    if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                                       let identityTokenData = appleIDCredential.identityToken,
                                       let identityToken = String(data: identityTokenData, encoding: .utf8) {
                                        let fullName = appleIDCredential.fullName?.formatted()
                                        Task {
                                            await viewModel.handleAppleSignIn(identityToken: identityToken, fullName: fullName)
                                        }
                                    }
                                case .failure(let error):
                                    viewModel.errorMessage = error.localizedDescription
                                }
                            }
                        )
                        .signInWithAppleButtonStyle(.white)
                        .frame(height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        
                        // Sign in with Google (Fallback / Button)
                        Button(action: {
                            // Trigger Google Sign In flow
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "g.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                Text("Sign in with Google")
                                    .font(LiveVaultTypography.bodyLarge)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(LiveVaultColors.darkSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(LiveVaultColors.darkSurfaceBorder, lineWidth: 1))
                        }
                        
                        // Register Link
                        Button(action: onNavigateToRegister) {
                            HStack(spacing: 4) {
                                Text("Don't have an account?")
                                    .foregroundColor(LiveVaultColors.textSecondary)
                                Text("Register")
                                    .fontWeight(.bold)
                                    .foregroundColor(LiveVaultColors.primaryRed)
                            }
                            .font(LiveVaultTypography.bodyMedium)
                        }
                        .padding(.top, 16)
                    }
                    .padding(24)
                }
            }
        }
    }
}

// MARK: - Register View
public struct RegisterView: View {
    @Bindable var viewModel: AuthViewModel
    public let onBackToLogin: () -> Void
    
    public init(viewModel: AuthViewModel, onBackToLogin: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onBackToLogin = onBackToLogin
    }
    
    public var body: some View {
        ZStack {
            LiveVaultColors.darkBg.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("Create Account")
                            .font(LiveVaultTypography.displayLarge)
                            .foregroundColor(LiveVaultColors.textPrimary)
                        Text("Start automated livestream archiving in minutes")
                            .font(LiveVaultTypography.bodyMedium)
                            .foregroundColor(LiveVaultColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    
                    if let error = viewModel.errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill")
                            Text(error)
                                .font(LiveVaultTypography.bodyMedium)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(LiveVaultColors.primaryRed.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Display Name")
                                .font(LiveVaultTypography.labelMedium)
                                .foregroundColor(LiveVaultColors.textSecondary)
                            TextField("", text: $viewModel.displayName)
                                .padding()
                                .background(LiveVaultColors.darkSurface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(LiveVaultColors.darkSurfaceBorder, lineWidth: 1))
                                .foregroundColor(LiveVaultColors.textPrimary)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email Address")
                                .font(LiveVaultTypography.labelMedium)
                                .foregroundColor(LiveVaultColors.textSecondary)
                            TextField("", text: $viewModel.email)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .padding()
                                .background(LiveVaultColors.darkSurface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(LiveVaultColors.darkSurfaceBorder, lineWidth: 1))
                                .foregroundColor(LiveVaultColors.textPrimary)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Password (min 8 characters)")
                                .font(LiveVaultTypography.labelMedium)
                                .foregroundColor(LiveVaultColors.textSecondary)
                            SecureField("", text: $viewModel.password)
                                .padding()
                                .background(LiveVaultColors.darkSurface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(LiveVaultColors.darkSurfaceBorder, lineWidth: 1))
                                .foregroundColor(LiveVaultColors.textPrimary)
                        }
                    }
                    
                    Button(action: {
                        Task {
                            await viewModel.register()
                        }
                    }) {
                        ZStack {
                            if viewModel.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Create Account")
                                    .font(LiveVaultTypography.titleMedium)
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(LiveVaultColors.primaryRed)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(viewModel.isLoading)
                    
                    Button(action: onBackToLogin) {
                        HStack(spacing: 4) {
                            Text("Already have an account?")
                                .foregroundColor(LiveVaultColors.textSecondary)
                            Text("Log In")
                                .fontWeight(.bold)
                                .foregroundColor(LiveVaultColors.primaryRed)
                        }
                        .font(LiveVaultTypography.bodyMedium)
                    }
                    .padding(.top, 8)
                }
                .padding(24)
            }
        }
    }
}
