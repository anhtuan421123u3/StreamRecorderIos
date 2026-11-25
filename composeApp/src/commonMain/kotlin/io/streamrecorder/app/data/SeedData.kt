package io.streamrecorder.app.data

import io.streamrecorder.app.model.ClipItem
import io.streamrecorder.app.model.RecordingItem
import io.streamrecorder.app.model.RecordingStatus
import io.streamrecorder.app.model.StreamPlatform
import io.streamrecorder.app.model.StreamerProfile

object SeedData {
    // Public, reliable HTTPS HLS & MP4 streams that play & trim natively via AVFoundation on iOS
    const val SAMPLE_HLS_1 = "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8"
    const val SAMPLE_HLS_2 = "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8"
    const val SAMPLE_MP4_1 = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4"
    const val SAMPLE_MP4_2 = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4"
    const val SAMPLE_MP4_3 = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4"

    val defaultStreamers: List<StreamerProfile> = listOf(
        StreamerProfile(
            id = "st_papaplatte",
            displayName = "Papaplatte",
            handle = "papaplatte",
            platform = StreamPlatform.TWITCH,
            avatarColorHex = 0xFF5B6CFF,
            avatarInitials = "PP",
            recordingsCountBadge = "99+",
            isMonitored = true,
            isLiveNow = true,
            isActivelyRecording = true,
            streamUrl = SAMPLE_MP4_1,
            streamTitle = "LATE NIGHT IRL & GAMING MARATHON 🔥",
            viewerCount = "34.8K"
        ),
        StreamerProfile(
            id = "st_papapla",
            displayName = "papapla",
            handle = "papapla",
            platform = StreamPlatform.TWITCH,
            avatarColorHex = 0xFFFF2E88,
            avatarInitials = "PA",
            recordingsCountBadge = null,
            isMonitored = false,
            isLiveNow = false,
            isActivelyRecording = false,
            streamUrl = SAMPLE_HLS_1,
            streamTitle = "Chill Just Chatting Session",
            viewerCount = "2.1K"
        ),
        StreamerProfile(
            id = "st_papameat",
            displayName = "papameat",
            handle = "papameat",
            platform = StreamPlatform.TWITCH,
            avatarColorHex = 0xFFFF2E88,
            avatarInitials = "PM",
            recordingsCountBadge = "14",
            isMonitored = true,
            isLiveNow = false,
            isActivelyRecording = false,
            streamUrl = SAMPLE_MP4_2,
            streamTitle = "Reacting to Wild Internet Mysteries",
            viewerCount = "18.2K"
        ),
        StreamerProfile(
            id = "st_mariacatena",
            displayName = "Mariacatena Pappalar",
            handle = "@mariacatenapap",
            platform = StreamPlatform.TIKTOK,
            avatarColorHex = 0xFFE056FD,
            avatarInitials = "MP",
            recordingsCountBadge = "7",
            isMonitored = true,
            isLiveNow = true,
            isActivelyRecording = false,
            streamUrl = SAMPLE_MP4_3,
            streamTitle = "Live Acoustic Studio Session 🎸",
            viewerCount = "6.9K"
        ),
        StreamerProfile(
            id = "st_napaphat",
            displayName = "NAPAPHAT ✨✨",
            handle = "@baskna",
            platform = StreamPlatform.TIKTOK,
            avatarColorHex = 0xFF00D2D3,
            avatarInitials = "NP",
            recordingsCountBadge = null,
            isMonitored = false,
            isLiveNow = true,
            isActivelyRecording = false,
            streamUrl = SAMPLE_HLS_2,
            streamTitle = "Bangkok Night Market Walk Live",
            viewerCount = "4.3K"
        ),
        StreamerProfile(
            id = "st_xqc_kick",
            displayName = "xQc",
            handle = "xqc",
            platform = StreamPlatform.KICK,
            avatarColorHex = 0xFF53FC18,
            avatarInitials = "XQ",
            recordingsCountBadge = "99+",
            isMonitored = true,
            isLiveNow = true,
            isActivelyRecording = true,
            streamUrl = SAMPLE_MP4_2,
            streamTitle = "24H SUBATHON // VARIETY GAMES & CLIPS",
            viewerCount = "51.0K"
        ),
        StreamerProfile(
            id = "st_mixigaming",
            displayName = "MixiGaming",
            handle = "@MixiGaming3con",
            platform = StreamPlatform.YOUTUBE,
            avatarColorHex = 0xFFFF3355,
            avatarInitials = "MX",
            recordingsCountBadge = "42",
            isMonitored = true,
            isLiveNow = false,
            isActivelyRecording = false,
            streamUrl = SAMPLE_HLS_1,
            streamTitle = "Tâm Sự Đêm Khuya Cùng Bộ Tộc MixiGaming",
            viewerCount = "89.5K"
        ),
        StreamerProfile(
            id = "st_faker_soop",
            displayName = "T1 Faker",
            handle = "faker_t1",
            platform = StreamPlatform.SOOP,
            avatarColorHex = 0xFF2B7FFF,
            avatarInitials = "FK",
            recordingsCountBadge = "28",
            isMonitored = false,
            isLiveNow = false,
            isActivelyRecording = false,
            streamUrl = SAMPLE_MP4_1,
            streamTitle = "Challenger SoloQ Climb KR Server",
            viewerCount = "45.7K"
        ),
        StreamerProfile(
            id = "st_kuzuha_bilibili",
            displayName = "Kuzuha Official",
            handle = "kuzuha_ch",
            platform = StreamPlatform.BILIBILI,
            avatarColorHex = 0xFF00A1D6,
            avatarInitials = "KZ",
            recordingsCountBadge = "1",
            isMonitored = false,
            isLiveNow = true,
            isActivelyRecording = false,
            streamUrl = SAMPLE_MP4_3,
            streamTitle = "Apex Legends Custom Tournament Finals",
            viewerCount = "22.0K"
        )
    )

    val defaultRecordings: List<RecordingItem> = listOf(
        RecordingItem(
            id = "rec_live_1",
            streamerId = "st_papaplatte",
            streamerName = "Papaplatte",
            streamerHandle = "papaplatte",
            platform = StreamPlatform.TWITCH,
            avatarColorHex = 0xFF5B6CFF,
            avatarInitials = "PP",
            title = "LATE NIGHT IRL & GAMING MARATHON 🔥",
            streamUrl = SAMPLE_MP4_1,
            durationSeconds = 914,
            sizeLabel = "412 MB",
            recordedAtLabel = "LIVE • Auto-Recording",
            resolutionLabel = "1080p60 HD",
            status = RecordingStatus.LIVE_RECORDING,
            thumbnailAccentHex = 0xFF5B6CFF
        ),
        RecordingItem(
            id = "rec_ready_1",
            streamerId = "st_xqc_kick",
            streamerName = "xQc",
            streamerHandle = "xqc",
            platform = StreamPlatform.KICK,
            avatarColorHex = 0xFF53FC18,
            avatarInitials = "XQ",
            title = "Insane Endgame Clutch & Chat Reactions",
            streamUrl = SAMPLE_MP4_2,
            durationSeconds = 600,
            sizeLabel = "285 MB",
            recordedAtLabel = "11:40AM",
            resolutionLabel = "1080p60 HD",
            status = RecordingStatus.READY,
            thumbnailAccentHex = 0xFF6C5CE7
        ),
        RecordingItem(
            id = "rec_ready_2",
            streamerId = "st_mixigaming",
            streamerName = "MixiGaming",
            streamerHandle = "@MixiGaming3con",
            platform = StreamPlatform.YOUTUBE,
            avatarColorHex = 0xFFFF3355,
            avatarInitials = "MX",
            title = "Full Buổi Stream Giao Lưu Cuối Tuần (HD Archive)",
            streamUrl = SAMPLE_HLS_1,
            durationSeconds = 596,
            sizeLabel = "1.2 GB",
            recordedAtLabel = "Yesterday • 10:15PM",
            resolutionLabel = "1080p HD",
            status = RecordingStatus.READY,
            thumbnailAccentHex = 0xFFFF2E88
        ),
        RecordingItem(
            id = "rec_ready_3",
            streamerId = "st_mariacatena",
            streamerName = "Mariacatena Pappalar",
            streamerHandle = "@mariacatenapap",
            platform = StreamPlatform.TIKTOK,
            avatarColorHex = 0xFFE056FD,
            avatarInitials = "MP",
            title = "Live Acoustic Guitar Set & Song Requests",
            streamUrl = SAMPLE_MP4_3,
            durationSeconds = 420,
            sizeLabel = "198 MB",
            recordedAtLabel = "9:20PM",
            resolutionLabel = "1080p HD",
            status = RecordingStatus.READY,
            thumbnailAccentHex = 0xFF9B59B6
        )
    )

    val defaultClips: List<ClipItem> = listOf(
        ClipItem(
            id = "clip_1",
            sourceRecordingId = "rec_live_1",
            streamerName = "Papaplatte",
            streamerHandle = "papaplatte",
            platform = StreamPlatform.TWITCH,
            avatarColorHex = 0xFF5B6CFF,
            avatarInitials = "PP",
            title = "Highlight Moment - Desk Setup Reaction",
            videoUrlOrPath = SAMPLE_MP4_1,
            startSec = 2.0,
            endSec = 14.0,
            durationSeconds = 12,
            createdAtLabel = "11:40AM",
            thumbnailAccentHex = 0xFF5B6CFF
        ),
        ClipItem(
            id = "clip_2",
            sourceRecordingId = "rec_ready_3",
            streamerName = "Mariacatena Pappalar",
            streamerHandle = "@mariacatenapap",
            platform = StreamPlatform.YOUTUBE,
            avatarColorHex = 0xFFFF2E88,
            avatarInitials = "MP",
            title = "Best Chorus Drop Live Cut",
            videoUrlOrPath = SAMPLE_MP4_2,
            startSec = 3.0,
            endSec = 15.0,
            durationSeconds = 12,
            createdAtLabel = "10:05AM",
            thumbnailAccentHex = 0xFFFF2E88
        )
    )
}
