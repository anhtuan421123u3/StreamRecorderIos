import SwiftUI
import LiveVaultCommon

public enum LiveVaultColors {
    // Primary Branding & Accents
    public static let primaryRed = Color(hex: 0xE50914)        // Streaming live red
    public static let primaryRedDark = Color(hex: 0xB81D24)
    public static let livePulseRed = Color(hex: 0xFF2A37)

    public static let indigoPrimary = Color(hex: 0x6366F1)     // Accent violet-indigo
    public static let indigoSecondary = Color(hex: 0x818CF8)
    public static let electricCyan = Color(hex: 0x06B6D4)
    public static let emeraldSuccess = Color(hex: 0x10B981)
    public static let amberWarning = Color(hex: 0xF59E0B)

    // Dark Theme Surfaces
    public static let darkBg = Color(hex: 0x0B0E14)            // Root background deep obsidian
    public static let darkSurface = Color(hex: 0x151922)       // Card / Container surface
    public static let darkSurfaceVariant = Color(hex: 0x1E2330)// Elevated element surface
    public static let darkSurfaceBorder = Color(hex: 0x2B3245) // Subtle card border
    public static let darkSurfaceElevated = Color(hex: 0x252D3D)

    // Text Colors
    public static let textPrimary = Color(hex: 0xF8FAFC)
    public static let textSecondary = Color(hex: 0x94A3B8)
    public static let textMuted = Color(hex: 0x64748B)

    // Platform Specific Colors
    public static let platformYouTube = Color(hex: 0xFF0000)
    public static let platformTwitch = Color(hex: 0x9146FF)
    public static let platformKick = Color(hex: 0x53FC18)
    public static let platformTikTok = Color(hex: 0x00F2FE)
    public static let platformCustom = Color(hex: 0x6366F1)
    
    public static func colorFor(platform: Platform) -> Color {
        switch platform {
        case .youtube: return platformYouTube
        case .twitch: return platformTwitch
        case .kick: return platformKick
        case .tiktok: return platformTikTok
        case .customRtmp: return platformCustom
        }
    }
}

public extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: alpha
        )
    }
}
