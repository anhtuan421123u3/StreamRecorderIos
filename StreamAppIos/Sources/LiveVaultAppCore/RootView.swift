import SwiftUI
import LiveVaultCommon
import LiveVaultDesignSystem
import FeatureAuth
import FeatureBrowser
import FeatureHome
import FeatureChannel
import FeatureLibrary
import FeaturePlayer
import FeatureRecordingDetail
import FeatureNotifications
import FeatureSettings
import FeaturePaywall

public struct RootView: View {
    @State private var authViewModel = AuthViewModel()
    @State private var hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "has_completed_onboarding")
    @State private var showRegister = false
    @State private var deepLinkManager = DeepLinkManager.shared
    
    // Global Navigation Presentation States
    @State private var playingRecordingId: String? = nil
    @State private var selectedRecordingDetailId: String? = nil
    @State private var showAddChannel = false
    @State private var showPaywall = false
    @State private var selectedTab = 0
    
    public init() {}
    
    public var body: some View {
        Group {
            if !hasCompletedOnboarding {
                SplashView(onGetStarted: {
                    UserDefaults.standard.set(true, forKey: "has_completed_onboarding")
                    hasCompletedOnboarding = true
                })
            } else if !authViewModel.isAuthenticated {
                if showRegister {
                    RegisterView(
                        viewModel: authViewModel,
                        onBackToLogin: { showRegister = false }
                    )
                } else {
                    LoginView(
                        viewModel: authViewModel,
                        onNavigateToRegister: { showRegister = true }
                    )
                }
            } else {
                mainTabInterface
            }
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(item: Binding(
            get: { playingRecordingId.map { IdentifiableString(id: $0) } },
            set: { playingRecordingId = $0?.id }
        )) { item in
            PlayerView(recordingId: item.id)
        }
        .sheet(item: Binding(
            get: { selectedRecordingDetailId.map { IdentifiableString(id: $0) } },
            set: { selectedRecordingDetailId = $0?.id }
        )) { item in
            NavigationStack {
                RecordingDetailView(
                    recordingId: item.id,
                    onPlay: { recId in
                        selectedRecordingDetailId = nil
                        playingRecordingId = recId
                    },
                    onStartDownload: { recId, title, url in
                        DownloadManager.shared.startDownload(recordingId: recId, title: title, channelName: "Livestream", urlString: url)
                    },
                    onNavigateToPaywall: {
                        selectedRecordingDetailId = nil
                        showPaywall = true
                    }
                )
            }
        }
        .sheet(isPresented: $showAddChannel) {
            AddChannelView(onChannelAdded: {
                showAddChannel = false
            })
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(onPurchased: {
                showPaywall = false
            })
        }
        .onOpenURL { url in
            deepLinkManager.handleURL(url)
        }
        .onChange(of: deepLinkManager.activeDestination) { _, destination in
            guard let dest = destination else { return }
            switch dest {
            case .recording(let id):
                playingRecordingId = id
            case .storageSettings:
                selectedTab = 4
            case .paywall:
                showPaywall = true
            }
            deepLinkManager.activeDestination = nil
        }
        .onAppear {
            setupPushNotificationRouting()
        }
    }
    
    private var mainTabInterface: some View {
        TabView(selection: $selectedTab) {
            HomeView(
                onSelectRecording: { recId in
                    playingRecordingId = recId
                },
                onSelectChannel: { _ in
                    selectedTab = 2
                },
                onAddChannel: {
                    showAddChannel = true
                },
                onNavigateToPaywall: {
                    showPaywall = true
                }
            )
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)
            
            BrowserView(onStartDownloadStream: { stream in
                HLSDownloadSessionManager.shared.startHLSDownload(
                    recordingId: UUID().uuidString,
                    title: stream.title,
                    hlsURL: stream.url
                )
            })
            .tabItem {
                Label("Browser", systemImage: "globe")
            }
            .tag(1)
            
            LibraryView(
                onSelectRecording: { recId in
                    selectedRecordingDetailId = recId
                }
            )
            .tabItem {
                Label("Library", systemImage: "play.square.stack.fill")
            }
            .tag(2)
            
            NotificationsView(
                onSelectRecording: { recId in
                    playingRecordingId = recId
                },
                onOpenStorageSettings: {
                    selectedTab = 4
                }
            )
            .tabItem {
                Label("Notifications", systemImage: "bell.fill")
            }
            .tag(3)
            
            SettingsView(
                onNavigateToPaywall: {
                    showPaywall = true
                },
                onLogout: {
                    authViewModel.isAuthenticated = false
                }
            )
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
            .tag(4)
        }
        .tint(LiveVaultColors.primaryRed)
    }
    
    private func setupPushNotificationRouting() {
        PushNotificationManager.shared.onNavigateToRecording = { recId in
            DispatchQueue.main.async {
                self.playingRecordingId = recId
            }
        }
        PushNotificationManager.shared.onNavigateToStorageSettings = {
            DispatchQueue.main.async {
                self.selectedTab = 4
            }
        }
        PushNotificationManager.shared.requestAuthorization()
    }
}

private struct IdentifiableString: Identifiable {
    let id: String
}