import SwiftUI
import LiveVaultCommon

// MARK: - LiveBadge
public struct LiveBadge: View {
    @State private var isPulsing = false
    
    public init() {}
    
    public var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(LiveVaultColors.livePulseRed)
                .frame(width: 7, height: 7)
                .scaleEffect(isPulsing ? 1.3 : 0.8)
                .opacity(isPulsing ? 1.0 : 0.5)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isPulsing)
            
            Text("LIVE")
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(LiveVaultColors.primaryRed.opacity(0.85))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(LiveVaultColors.livePulseRed.opacity(0.6), lineWidth: 1)
        )
        .onAppear {
            isPulsing = true
        }
    }
}

// MARK: - Shimmer Loading Effect
public struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1
    
    public func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .clear, location: 0.0),
                            .init(color: Color.white.opacity(0.15), location: 0.5),
                            .init(color: .clear, location: 1.0)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 2)
                    .offset(x: phase * geo.size.width)
                    .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: phase)
                }
            )
            .mask(content)
            .onAppear {
                phase = 1.5
            }
    }
}

public extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

public struct SkeletonBox: View {
    var width: CGFloat? = nil
    var height: CGFloat = 16
    var cornerRadius: CGFloat = 6
    
    public init(width: CGFloat? = nil, height: CGFloat = 16, cornerRadius: CGFloat = 6) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }
    
    public var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(LiveVaultColors.darkSurfaceVariant)
            .frame(width: width, height: height)
            .shimmer()
    }
}

// MARK: - Storage Usage Bar
public struct StorageUsageBar: View {
    public let usedBytes: Int64
    public let quotaBytes: Int64
    public let usedPercent: Int
    
    public init(usedBytes: Int64, quotaBytes: Int64, usedPercent: Int) {
        self.usedBytes = usedBytes
        self.quotaBytes = quotaBytes
        self.usedPercent = max(0, min(100, usedPercent))
    }
    
    private var isWarning: Bool {
        usedPercent >= LiveVaultConstants.storageQuotaWarningPercent
    }
    
    private var barColor: Color {
        if usedPercent >= 95 {
            return LiveVaultColors.primaryRed
        } else if usedPercent >= 80 {
            return LiveVaultColors.amberWarning
        } else {
            return LiveVaultColors.indigoPrimary
        }
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "internaldrive.fill")
                        .foregroundColor(barColor)
                        .font(.system(size: 14))
                    Text("Storage Usage")
                        .font(LiveVaultTypography.titleMedium)
                        .foregroundColor(LiveVaultColors.textPrimary)
                }
                
                Spacer()
                
                Text("\(usedPercent)%")
                    .font(LiveVaultTypography.labelMedium)
                    .foregroundColor(barColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(barColor.opacity(0.15))
                    .clipShape(Capsule())
            }
            
            // Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(LiveVaultColors.darkSurfaceVariant)
                        .frame(height: 10)
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [barColor.opacity(0.8), barColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, geo.size.width * CGFloat(usedPercent) / 100.0), height: 10)
                }
            }
            .frame(height: 10)
            
            HStack {
                Text("\(LiveVaultFormatters.formatBytes(usedBytes)) used of \(LiveVaultFormatters.formatBytes(quotaBytes))")
                    .font(LiveVaultTypography.caption)
                    .foregroundColor(LiveVaultColors.textSecondary)
                
                Spacer()
                
                if isWarning {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 10))
                        Text("Low storage")
                            .font(LiveVaultTypography.caption)
                    }
                    .foregroundColor(LiveVaultColors.amberWarning)
                }
            }
        }
        .padding(16)
        .background(LiveVaultColors.darkSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isWarning ? LiveVaultColors.amberWarning.opacity(0.4) : LiveVaultColors.darkSurfaceBorder, lineWidth: 1)
        )
    }
}

// MARK: - Empty State View
public struct EmptyStateView: View {
    public let iconName: String
    public let title: String
    public let subtitle: String
    public var actionTitle: String? = nil
    public var action: (() -> Void)? = nil
    
    public init(
        iconName: String,
        title: String,
        subtitle: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.iconName = iconName
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.action = action
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            Image(systemName: iconName)
                .font(.system(size: 50))
                .foregroundColor(LiveVaultColors.textMuted)
                .padding(.bottom, 4)
            
            Text(title)
                .font(LiveVaultTypography.titleMedium)
                .foregroundColor(LiveVaultColors.textPrimary)
                .multilineTextAlignment(.center)
            
            Text(subtitle)
                .font(LiveVaultTypography.bodyMedium)
                .foregroundColor(LiveVaultColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(LiveVaultTypography.labelMedium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(LiveVaultColors.indigoPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.top, 8)
            }
        }
        .padding(24)
    }
}

// MARK: - Channel Avatar
public struct ChannelAvatar: View {
    public let displayName: String
    public let avatarUrl: String?
    public let platform: Platform
    public var size: CGFloat = 48
    
    public init(displayName: String, avatarUrl: String?, platform: Platform, size: CGFloat = 48) {
        self.displayName = displayName
        self.avatarUrl = avatarUrl
        self.platform = platform
        self.size = size
    }
    
    public var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if let urlStr = avatarUrl, let url = URL(string: urlStr) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        default:
                            fallbackAvatar
                        }
                    }
                } else {
                    fallbackAvatar
                }
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(Circle().stroke(LiveVaultColors.darkSurfaceBorder, lineWidth: 1.5))
            
            // Platform mini badge
            Image(systemName: platform.sfSymbol)
                .font(.system(size: size * 0.28))
                .foregroundColor(.white)
                .padding(3)
                .background(LiveVaultColors.colorFor(platform: platform))
                .clipShape(Circle())
                .offset(x: 2, y: 2)
        }
    }
    
    private var fallbackAvatar: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [LiveVaultColors.indigoPrimary.opacity(0.8), LiveVaultColors.indigoSecondary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                Text(String(displayName.prefix(1).uppercased()))
                    .font(.system(size: size * 0.45, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            )
    }
}

// MARK: - Glass Card Container
public struct GlassCard<Content: View>: View {
    public let content: Content
    
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    public var body: some View {
        content
            .background(LiveVaultColors.darkSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(LiveVaultColors.darkSurfaceBorder, lineWidth: 1)
            )
    }
}
