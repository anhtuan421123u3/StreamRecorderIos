import SwiftUI
import LiveVaultCommon
import LiveVaultDesignSystem

public struct AddChannelView: View {
    @State private var viewModel = ChannelViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showConsentSheet = false
    public let onChannelAdded: () -> Void
    
    public init(onChannelAdded: @escaping () -> Void) {
        self.onChannelAdded = onChannelAdded
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                LiveVaultColors.darkBg.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header info
                        VStack(spacing: 8) {
                            Text("Add Channel to Monitor")
                                .font(LiveVaultTypography.titleLarge)
                                .foregroundColor(LiveVaultColors.textPrimary)
                            Text("Select your platform and enter channel details. LiveVault will automatically capture live sessions.")
                                .font(LiveVaultTypography.bodyMedium)
                                .foregroundColor(LiveVaultColors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 16)
                        
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
                        
                        // Platform Selector
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Select Platform")
                                .font(LiveVaultTypography.labelMedium)
                                .foregroundColor(LiveVaultColors.textSecondary)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(Platform.allCases, id: \.self) { platform in
                                        Button(action: { viewModel.selectedPlatform = platform }) {
                                            HStack(spacing: 8) {
                                                Image(systemName: platform.sfSymbol)
                                                    .foregroundColor(viewModel.selectedPlatform == platform ? .white : LiveVaultColors.colorFor(platform: platform))
                                                Text(platform.displayName)
                                                    .font(LiveVaultTypography.bodyMedium)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(viewModel.selectedPlatform == platform ? .white : LiveVaultColors.textPrimary)
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                            .background(viewModel.selectedPlatform == platform ? LiveVaultColors.indigoPrimary : LiveVaultColors.darkSurface)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(viewModel.selectedPlatform == platform ? LiveVaultColors.indigoSecondary : LiveVaultColors.darkSurfaceBorder, lineWidth: 1))
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Inputs
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Channel Display Name *")
                                    .font(LiveVaultTypography.labelMedium)
                                    .foregroundColor(LiveVaultColors.textSecondary)
                                TextField("e.g. My Gaming Channel", text: $viewModel.displayName)
                                    .padding()
                                    .background(LiveVaultColors.darkSurface)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(LiveVaultColors.darkSurfaceBorder, lineWidth: 1))
                                    .foregroundColor(LiveVaultColors.textPrimary)
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Channel URL *")
                                    .font(LiveVaultTypography.labelMedium)
                                    .foregroundColor(LiveVaultColors.textSecondary)
                                TextField("https://youtube.com/@mychannel", text: $viewModel.channelUrl)
                                    .keyboardType(.URL)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .padding()
                                    .background(LiveVaultColors.darkSurface)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(LiveVaultColors.darkSurfaceBorder, lineWidth: 1))
                                    .foregroundColor(LiveVaultColors.textPrimary)
                            }
                            
                            if viewModel.selectedPlatform == .customRtmp {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Custom RTMP Stream URL")
                                        .font(LiveVaultTypography.labelMedium)
                                        .foregroundColor(LiveVaultColors.textSecondary)
                                    TextField("rtmp://stream.example.com/live/key", text: $viewModel.rtmpStreamUrl)
                                        .keyboardType(.URL)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled()
                                        .padding()
                                        .background(LiveVaultColors.darkSurface)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(LiveVaultColors.darkSurfaceBorder, lineWidth: 1))
                                        .foregroundColor(LiveVaultColors.textPrimary)
                                }
                            }
                        }
                        
                        // Legal / Consent Note Banner
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 20))
                                .foregroundColor(LiveVaultColors.indigoSecondary)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Owner Consent Requirement")
                                    .font(LiveVaultTypography.labelMedium)
                                    .foregroundColor(LiveVaultColors.textPrimary)
                                Text("Under App Store guidelines and terms of service, you must verify ownership or have written authorization before monitoring a stream.")
                                    .font(LiveVaultTypography.caption)
                                    .foregroundColor(LiveVaultColors.textSecondary)
                            }
                        }
                        .padding(14)
                        .background(LiveVaultColors.indigoPrimary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(LiveVaultColors.indigoPrimary.opacity(0.3), lineWidth: 1))
                        
                        // Continue to Consent & Confirm Button
                        Button(action: {
                            if viewModel.displayName.isEmpty || viewModel.channelUrl.isEmpty {
                                viewModel.errorMessage = "Please enter channel name and URL."
                            } else {
                                viewModel.errorMessage = nil
                                showConsentSheet = true
                            }
                        }) {
                            HStack {
                                Text("Verify Consent & Add Channel")
                                    .font(LiveVaultTypography.titleMedium)
                                    .foregroundColor(.white)
                                Image(systemName: "arrow.right")
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(LiveVaultColors.primaryRed)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(.top, 12)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Add Channel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(LiveVaultColors.textSecondary)
                }
            }
            .sheet(isPresented: $showConsentSheet) {
                ChannelConsentView(
                    viewModel: viewModel,
                    onConfirmed: {
                        Task {
                            let success = await viewModel.addChannel()
                            if success {
                                showConsentSheet = false
                                onChannelAdded()
                                dismiss()
                            }
                        }
                    }
                )
            }
        }
    }
}

// MARK: - Channel Consent View (Required for Legal Audit Trail)
public struct ChannelConsentView: View {
    @Bindable var viewModel: ChannelViewModel
    @Environment(\.dismiss) private var dismiss
    public let onConfirmed: () -> Void
    
    public init(viewModel: ChannelViewModel, onConfirmed: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onConfirmed = onConfirmed
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                LiveVaultColors.darkBg.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 44))
                            .foregroundColor(LiveVaultColors.indigoSecondary)
                        
                        Text("Channel Ownership Consent")
                            .font(LiveVaultTypography.titleLarge)
                            .foregroundColor(LiveVaultColors.textPrimary)
                        
                        Text("Mandatory legal verification for automated recording")
                            .font(LiveVaultTypography.caption)
                            .foregroundColor(LiveVaultColors.textSecondary)
                    }
                    .padding(.top, 20)
                    
                    // Detailed Legal text box
                    ScrollView {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("By adding '\(viewModel.displayName)' (\(viewModel.selectedPlatform.displayName)), you certify and agree that:")
                                .font(LiveVaultTypography.bodyMedium)
                                .fontWeight(.semibold)
                                .foregroundColor(LiveVaultColors.textPrimary)
                            
                            bulletPoint(number: "1.", text: "You are the legitimate owner of this channel, OR you possess explicit, written permission from the copyright holder to record, archive, and process broadcasts from this stream.")
                            bulletPoint(number: "2.", text: "You understand that this consent confirmation timestamp and your account identity are permanently logged in the LiveVault audit trail.")
                            bulletPoint(number: "3.", text: "Unauthorized recording or distribution of third-party content without permission is strictly prohibited and subject to immediate account termination.")
                        }
                        .padding(16)
                        .background(LiveVaultColors.darkSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(LiveVaultColors.darkSurfaceBorder, lineWidth: 1))
                    }
                    .frame(maxHeight: 220)
                    
                    // Checkbox
                    Button(action: { viewModel.consentConfirmed.toggle() }) {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: viewModel.consentConfirmed ? "checkmark.square.fill" : "square")
                                .font(.system(size: 22))
                                .foregroundColor(viewModel.consentConfirmed ? LiveVaultColors.emeraldSuccess : LiveVaultColors.textSecondary)
                            
                            Text("I certify under penalty of terms violation that I have full authorization to record this livestream.")
                                .font(LiveVaultTypography.bodyMedium)
                                .foregroundColor(LiveVaultColors.textPrimary)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .padding(.horizontal, 4)
                    
                    Spacer()
                    
                    // Confirm and Add Button
                    Button(action: onConfirmed) {
                        ZStack {
                            if viewModel.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("I Agree & Add Channel")
                                    .font(LiveVaultTypography.titleMedium)
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(viewModel.consentConfirmed ? LiveVaultColors.emeraldSuccess : LiveVaultColors.darkSurfaceVariant)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(!viewModel.consentConfirmed || viewModel.isLoading)
                    .padding(.bottom, 16)
                }
                .padding(24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                    .foregroundColor(LiveVaultColors.textSecondary)
                }
            }
        }
    }
    
    private func bulletPoint(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(number)
                .font(LiveVaultTypography.bodyMedium)
                .fontWeight(.bold)
                .foregroundColor(LiveVaultColors.indigoSecondary)
            Text(text)
                .font(LiveVaultTypography.bodyMedium)
                .foregroundColor(LiveVaultColors.textSecondary)
        }
    }
}
