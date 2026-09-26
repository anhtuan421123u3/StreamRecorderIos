import SwiftUI
import LiveVaultCommon
import LiveVaultDesignSystem

public struct PaywallView: View {
    @State private var viewModel = PaywallViewModel()
    @Environment(\.dismiss) private var dismiss
    public let onPurchased: () -> Void
    
    public init(onPurchased: @escaping () -> Void) {
        self.onPurchased = onPurchased
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                LiveVaultColors.darkBg.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header Badge & Title
                        VStack(spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "crown.fill")
                                    .foregroundColor(LiveVaultColors.amberWarning)
                                Text("LIVEVAULT PREMIUM")
                                    .font(.system(size: 12, weight: .black))
                                    .foregroundColor(LiveVaultColors.amberWarning)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(LiveVaultColors.amberWarning.opacity(0.15))
                            .clipShape(Capsule())
                            
                            Text("Upgrade Your Vault")
                                .font(LiveVaultTypography.displayLarge)
                                .foregroundColor(LiveVaultColors.textPrimary)
                            
                            Text("Unlock unlimited channels, extended cloud storage,\nand high-speed video downloads.")
                                .font(LiveVaultTypography.bodyMedium)
                                .foregroundColor(LiveVaultColors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 16)
                        
                        // Tier Comparison Cards
                        VStack(spacing: 12) {
                            tierCard(
                                tier: .pro,
                                price: "$9.99/mo",
                                channels: "5 Channels",
                                storage: "50 GB Cloud Storage",
                                retention: "30 Days Retention",
                                download: "Full 1080p Downloads",
                                isPopular: true
                            )
                            
                            tierCard(
                                tier: .premium,
                                price: "$24.99/mo",
                                channels: "20 Channels",
                                storage: "200 GB Cloud Storage",
                                retention: "90 Days Retention",
                                download: "Priority High-Speed Downloads",
                                isPopular: false
                            )
                        }
                        
                        // Comparison Matrix Table
                        comparisonTable
                        
                        // Subscribe Button
                        Button(action: {
                            Task {
                                let ok = await viewModel.purchaseSelectedTier()
                                if ok {
                                    onPurchased()
                                    dismiss()
                                }
                            }
                        }) {
                            ZStack {
                                if viewModel.isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Upgrade to \(viewModel.selectedTier.displayName)")
                                        .font(LiveVaultTypography.titleMedium)
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                LinearGradient(
                                    colors: [LiveVaultColors.primaryRed, LiveVaultColors.primaryRedDark],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(.top, 8)
                        
                        // Restore Purchases Link
                        Button(action: {
                            Task {
                                await viewModel.restorePurchases()
                            }
                        }) {
                            Text("Restore Purchases")
                                .font(LiveVaultTypography.caption)
                                .foregroundColor(LiveVaultColors.textSecondary)
                        }
                        .padding(.bottom, 24)
                    }
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(LiveVaultColors.textSecondary)
                }
            }
        }
    }
    
    private func tierCard(
        tier: SubscriptionTier,
        price: String,
        channels: String,
        storage: String,
        retention: String,
        download: String,
        isPopular: Bool
    ) -> some View {
        let isSelected = viewModel.selectedTier == tier
        
        return Button(action: { viewModel.selectedTier = tier }) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 8) {
                            Text(tier.displayName)
                                .font(LiveVaultTypography.titleMedium)
                                .foregroundColor(LiveVaultColors.textPrimary)
                            if isPopular {
                                Text("MOST POPULAR")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(LiveVaultColors.indigoPrimary)
                                    .clipShape(Capsule())
                            }
                        }
                        Text(price)
                            .font(LiveVaultTypography.bodyLarge)
                            .fontWeight(.bold)
                            .foregroundColor(LiveVaultColors.indigoSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22))
                        .foregroundColor(isSelected ? LiveVaultColors.primaryRed : LiveVaultColors.textMuted)
                }
                
                Divider().background(LiveVaultColors.darkSurfaceBorder)
                
                VStack(alignment: .leading, spacing: 6) {
                    featureBullet(text: channels)
                    featureBullet(text: storage)
                    featureBullet(text: retention)
                    featureBullet(text: download)
                }
            }
            .padding(16)
            .background(isSelected ? LiveVaultColors.darkSurfaceVariant : LiveVaultColors.darkSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? LiveVaultColors.primaryRed : LiveVaultColors.darkSurfaceBorder, lineWidth: isSelected ? 2 : 1)
            )
        }
    }
    
    private func featureBullet(text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(LiveVaultColors.emeraldSuccess)
            Text(text)
                .font(LiveVaultTypography.caption)
                .foregroundColor(LiveVaultColors.textSecondary)
        }
    }
    
    private var comparisonTable: some View {
        VStack(spacing: 0) {
            tableHeader
            Divider().background(LiveVaultColors.darkSurfaceBorder)
            tableRow(feature: "Monitored Channels", free: "1", pro: "5", premium: "20")
            Divider().background(LiveVaultColors.darkSurfaceBorder)
            tableRow(feature: "Storage Quota", free: "5 GB", pro: "50 GB", premium: "200 GB")
            Divider().background(LiveVaultColors.darkSurfaceBorder)
            tableRow(feature: "Recording Retention", free: "3 Days", pro: "30 Days", premium: "90 Days")
            Divider().background(LiveVaultColors.darkSurfaceBorder)
            tableRow(feature: "Offline Video Downloads", free: "No", pro: "Yes", premium: "Yes")
        }
        .background(LiveVaultColors.darkSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(LiveVaultColors.darkSurfaceBorder, lineWidth: 1))
    }
    
    private var tableHeader: some View {
        HStack {
            Text("Features")
                .font(LiveVaultTypography.caption)
                .fontWeight(.bold)
                .foregroundColor(LiveVaultColors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Free")
                .font(LiveVaultTypography.caption)
                .fontWeight(.bold)
                .foregroundColor(LiveVaultColors.textSecondary)
                .frame(width: 45)
            Text("Pro")
                .font(LiveVaultTypography.caption)
                .fontWeight(.bold)
                .foregroundColor(LiveVaultColors.indigoSecondary)
                .frame(width: 50)
            Text("Premium")
                .font(LiveVaultTypography.caption)
                .fontWeight(.bold)
                .foregroundColor(LiveVaultColors.amberWarning)
                .frame(width: 60)
        }
        .padding(12)
    }
    
    private func tableRow(feature: String, free: String, pro: String, premium: String) -> some View {
        HStack {
            Text(feature)
                .font(LiveVaultTypography.caption)
                .foregroundColor(LiveVaultColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(free)
                .font(LiveVaultTypography.caption)
                .foregroundColor(LiveVaultColors.textSecondary)
                .frame(width: 45)
            Text(pro)
                .font(LiveVaultTypography.caption)
                .fontWeight(.semibold)
                .foregroundColor(LiveVaultColors.indigoSecondary)
                .frame(width: 50)
            Text(premium)
                .font(LiveVaultTypography.caption)
                .fontWeight(.bold)
                .foregroundColor(LiveVaultColors.amberWarning)
                .frame(width: 60)
        }
        .padding(12)
    }
}
