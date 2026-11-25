package io.streamrecorder.app.model

import kotlinx.serialization.Serializable

@Serializable
enum class StreamPlatform(
    val displayName: String,
    val shortTag: String,
    val domainHint: String,
    val brandColorHex: Long
) {
    TWITCH("Twitch", "TW", "twitch.tv", 0xFF9146FF),
    KICK("Kick", "K", "kick.com", 0xFF53FC18),
    TIKTOK("TikTok", "TT", "tiktok.com", 0xFFFE2C55),
    YOUTUBE("YouTube", "YT", "youtube.com", 0xFFFF0033),
    SOOP("SOOP", "SP", "sooplive.co.kr", 0xFF2B7FFF),
    BILIBILI("BiliBili", "BB", "bilibili.com", 0xFF00A1D6),
    CHZZK("Chzzk", "CZ", "chzzk.naver.com", 0xFF00FFA3),
    CUSTOM("Direct URL", "HLS", "m3u8", 0xFF5B6CFF);

    companion object {
        fun detectFromInput(input: String): StreamPlatform {
            val lower = input.lowercase()
            return when {
                "twitch.tv" in lower -> TWITCH
                "kick.com" in lower -> KICK
                "tiktok.com" in lower || "douyin.com" in lower -> TIKTOK
                "youtube.com" in lower || "youtu.be" in lower -> YOUTUBE
                "sooplive" in lower || "afreecatv" in lower || "flextv" in lower || "pandatv" in lower -> SOOP
                "bilibili" in lower -> BILIBILI
                "chzzk" in lower -> CHZZK
                ".m3u8" in lower || ".mp4" in lower || lower.startsWith("http") -> CUSTOM
                else -> TWITCH
            }
        }
    }
}

@Serializable
data class StreamerProfile(
    val id: String,
    val displayName: String,
    val handle: String,
    val platform: StreamPlatform,
    val avatarColorHex: Long,
    val avatarInitials: String,
    val recordingsCountBadge: String? = null,
    val isMonitored: Boolean = false,
    val isLiveNow: Boolean = false,
    val isActivelyRecording: Boolean = false,
    val streamUrl: String,
    val streamTitle: String,
    val viewerCount: String = "12.4K"
)

@Serializable
enum class RecordingStatus {
    LIVE_RECORDING,
    READY,
    DOWNLOADING,
    FAILED
}

@Serializable
data class RecordingItem(
    val id: String,
    val streamerId: String,
    val streamerName: String,
    val streamerHandle: String,
    val platform: StreamPlatform,
    val avatarColorHex: Long,
    val avatarInitials: String,
    val title: String,
    val streamUrl: String,
    val localFilePath: String? = null,
    val durationSeconds: Int,
    val sizeLabel: String,
    val recordedAtLabel: String,
    val resolutionLabel: String = "1080p60 HD",
    val status: RecordingStatus = RecordingStatus.READY,
    val downloadProgress: Float = 0f,
    val thumbnailAccentHex: Long = 0xFF5B6CFF
) {
    val effectivePlayablePath: String
        get() = localFilePath?.takeIf { it.isNotBlank() } ?: streamUrl

    val isDownloaded: Boolean
        get() = !localFilePath.isNullOrBlank()
}

@Serializable
data class ClipItem(
    val id: String,
    val sourceRecordingId: String,
    val streamerName: String,
    val streamerHandle: String,
    val platform: StreamPlatform,
    val avatarColorHex: Long,
    val avatarInitials: String,
    val title: String,
    val videoUrlOrPath: String,
    val startSec: Double,
    val endSec: Double,
    val durationSeconds: Int,
    val createdAtLabel: String,
    val thumbnailAccentHex: Long = 0xFF5B6CFF,
    val savedToPhotos: Boolean = false
)

@Serializable
data class AppSettings(
    val autoRecordWhenLive: Boolean = true,
    val offlineCloudBackup: Boolean = true,
    val preferredQuality: String = "1080p60 HD (Source)",
    val wifiOnlyDownload: Boolean = false,
    val pushNotificationsEnabled: Boolean = true,
    val hasDismissedHeroBanner: Boolean = false
)

data class DetectedWebStream(
    val url: String,
    val typeLabel: String,
    val pageTitle: String
)

enum class LayoutViewMode {
    LIST,
    GRID
}

enum class AppTab(val label: String) {
    SEARCH("Search"),
    RECORDINGS("Recordings"),
    CLIPS("Your clips"),
    SETTINGS("Settings")
}
