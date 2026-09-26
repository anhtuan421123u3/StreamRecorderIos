import SwiftUI
import LiveVaultCommon
import LiveVaultDesignSystem

public struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @State private var isWebDAVRunning: Bool = false
    @State private var webDAVIP: String? = nil
    @State private var showLogoutAlert = false
    @State private var showDRMDisclaimer = false
    
    public var onNavigateToPaywall: () -> Void
    public var onLogout: () -> Void
    
    public init(onNavigateToPaywall: @escaping () -> Void, onLogout: @escaping () -> Void) {
        self.onNavigateToPaywall = onNavigateToPaywall
        self.onLogout = onLogout
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                LiveVaultColors.darkBg.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        userProfileHeader
                        subscriptionPlanCard
                        transferToComputerSection
                        preferencesSection
                        legalSection
                        
                        // Logout Button
                        Button(action: { showLogoutAlert = true }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Log Out")
                                    .font(LiveVaultTypography.bodyLarge)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(LiveVaultColors.primaryRed)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(LiveVaultColors.darkSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(LiveVaultColors.primaryRed.opacity(0.3), lineWidth: 1))
                        }
                        .padding(.top, 12)
                        
                        // App Version & Build
                        Text("LiveVault for iOS v1.0.0 (Build 101)")
                            .font(LiveVaultTypography.caption)
                            .foregroundColor(LiveVaultColors.textMuted)
                            .padding(.bottom, 24)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.loadSettings()
            }
            .alert("Log Out?", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Log Out", role: .destructive) {
                    Task {
                        await viewModel.logout()
                        onLogout()
                    }
                }
            } message: {
                Text("Are you sure you want to log out of LiveVault?")
            }
            .sheet(isPresented: $showDRMDisclaimer) {
                drmDisclaimerSheet
            }
        }
    }
    
    private var userProfileHeader: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [LiveVaultColors.indigoPrimary, LiveVaultColors.indigoSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 60, height: 60)
                .overlay(
                    Text(String(viewModel.userProfile?.displayName.prefix(1).uppercased() ?? "U"))
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.userProfile?.displayName ?? "LiveVault User")
                    .font(LiveVaultTypography.titleMedium)
                    .foregroundColor(LiveVaultColors.textPrimary)
                
                Text(viewModel.userProfile?.email ?? "user@livevault.app")
                    .font(LiveVaultTypography.bodyMedium)
                    .foregroundColor(LiveVaultColors.textSecondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(LiveVaultColors.darkSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(LiveVaultColors.darkSurfaceBorder, lineWidth: 1))
    }
    
    private var subscriptionPlanCard: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .foregroundColor(LiveVaultColors.amberWarning)
                    Text("Plan: \(viewModel.userProfile?.subscriptionTier.displayName ?? "Free")")
                        .font(LiveVaultTypography.titleMedium)
                        .foregroundColor(LiveVaultColors.textPrimary)
                }
                
                Spacer()
                
                Button("Upgrade", action: onNavigateToPaywall)
                    .font(LiveVaultTypography.labelMedium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(LiveVaultColors.indigoPrimary)
                    .clipShape(Capsule())
            }
            
            Divider().background(LiveVaultColors.darkSurfaceBorder)
            
            HStack {
                Text("Channels: \(viewModel.userProfile?.subscriptionTier.maxChannels ?? 1) max")
                    .font(LiveVaultTypography.caption)
                    .foregroundColor(LiveVaultColors.textSecondary)
                Spacer()
                Text("Retention: \(viewModel.userProfile?.subscriptionTier.retentionDays ?? 3) days")
                    .font(LiveVaultTypography.caption)
                    .foregroundColor(LiveVaultColors.textSecondary)
                Spacer()
                Text("Downloads: \(viewModel.userProfile?.subscriptionTier.downloadEnabled == true ? "Enabled" : "Locked")")
                    .font(LiveVaultTypography.caption)
                    .foregroundColor(LiveVaultColors.textSecondary)
            }
        }
        .padding(16)
        .background(LiveVaultColors.darkSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(LiveVaultColors.darkSurfaceBorder, lineWidth: 1))
    }
    
    private var transferToComputerSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "wifi.router.fill")
                    .foregroundColor(LiveVaultColors.indigoSecondary)
                Text("Transfer to Computer")
                    .font(LiveVaultTypography.titleMedium)
                    .foregroundColor(LiveVaultColors.textPrimary)
            }
            
            Toggle("Enable Wi-Fi WebDAV Server", isOn: $isWebDAVRunning)
                .toggleStyle(SwitchToggleStyle(tint: LiveVaultColors.indigoPrimary))
                .onChange(of: isWebDAVRunning) { _, enabled in
                    if enabled {
                        self.webDAVIP = "http://192.168.1.15:8080/"
                    } else {
                        self.webDAVIP = nil
                    }
                }
            
            if isWebDAVRunning, let ip = webDAVIP {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Connect at:")
                            .font(LiveVaultTypography.caption)
                            .foregroundColor(LiveVaultColors.textSecondary)
                        Spacer()
                        Text(ip)
                            .font(.system(.subheadline, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(LiveVaultColors.indigoSecondary)
                    }
                    Divider().background(LiveVaultColors.darkSurfaceBorder)
                    Text("• macOS: Finder > Cmd + K > Enter address > Connect.")
                        .font(LiveVaultTypography.caption)
                        .foregroundColor(LiveVaultColors.textMuted)
                    Text("• Windows: File Explorer > Map Network Drive > Enter address.")
                        .font(LiveVaultTypography.caption)
                        .foregroundColor(LiveVaultColors.textMuted)
                }
                .padding(12)
                .background(LiveVaultColors.darkSurfaceVariant)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            
            Divider().background(LiveVaultColors.darkSurfaceBorder)
            
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "cable.connector")
                    .foregroundColor(LiveVaultColors.amberWarning)
                VStack(alignment: .leading, spacing: 2) {
                    Text("iTunes / Finder File Sharing Active")
                        .font(LiveVaultTypography.labelMedium)
                        .foregroundColor(LiveVaultColors.textPrimary)
                    Text("Connect via USB cable to Mac (Finder) or PC (iTunes) to access the Recordings directory directly.")
                        .font(LiveVaultTypography.caption)
                        .foregroundColor(LiveVaultColors.textMuted)
                }
            }
        }
        .padding(16)
        .background(LiveVaultColors.darkSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(LiveVaultColors.darkSurfaceBorder, lineWidth: 1))
    }
    
    private var preferencesSection: some View {
        VStack(spacing: 0) {
            Toggle(isOn: $viewModel.pushEnabled) {
                HStack(spacing: 12) {
                    Image(systemName: "bell.badge.fill")
                        .foregroundColor(LiveVaultColors.indigoSecondary)
                    Text("Push Notifications")
                        .font(LiveVaultTypography.bodyLarge)
                        .foregroundColor(LiveVaultColors.textPrimary)
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: LiveVaultColors.indigoPrimary))
            .padding(16)
        }
        .background(LiveVaultColors.darkSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(LiveVaultColors.darkSurfaceBorder, lineWidth: 1))
    }
    
    private var legalSection: some View {
        VStack(spacing: 0) {
            legalRow(icon: "shield.lefthalf.filled", title: "Privacy Policy (Nutrition Label)") {
                if let url = URL(string: "https://livevault.app/privacy") {
                    UIApplication.shared.open(url)
                }
            }
            
            Divider().background(LiveVaultColors.darkSurfaceBorder)
            
            legalRow(icon: "doc.text.fill", title: "Terms of Service") {
                if let url = URL(string: "https://livevault.app/terms") {
                    UIApplication.shared.open(url)
                }
            }
            
            Divider().background(LiveVaultColors.darkSurfaceBorder)
            
            legalRow(icon: "lock.shield.fill", title: "Copyright & DRM Protection Policy") {
                showDRMDisclaimer = true
            }
        }
        .background(LiveVaultColors.darkSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(LiveVaultColors.darkSurfaceBorder, lineWidth: 1))
    }
    
    private var drmDisclaimerSheet: some View {
        NavigationStack {
            ZStack {
                LiveVaultColors.darkBg.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Copyright & Fair Use Notice")
                            .font(LiveVaultTypography.titleLarge)
                            .foregroundColor(LiveVaultColors.textPrimary)
                        Text("LiveVault is built for archiving authorized personal streams and educational review. The application strictly respects Digital Rights Management (DRM) and does NOT bypass FairPlay or Widevine encryption.")
                            .font(LiveVaultTypography.bodyMedium)
                            .foregroundColor(LiveVaultColors.textSecondary)
                        Text("Users must possess appropriate licenses or authorization before capturing any copyrighted public broadcasts.")
                            .font(LiveVaultTypography.bodyMedium)
                            .foregroundColor(LiveVaultColors.textSecondary)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Legal Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Dismiss") { showDRMDisclaimer = false }
                        .foregroundColor(LiveVaultColors.indigoSecondary)
                }
            }
        }
    }
    
    private func legalRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(LiveVaultColors.textSecondary)
                    .frame(width: 24)
                Text(title)
                    .font(LiveVaultTypography.bodyMedium)
                    .foregroundColor(LiveVaultColors.textPrimary)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12))
                    .foregroundColor(LiveVaultColors.textMuted)
            }
            .padding(16)
        }
    }
}