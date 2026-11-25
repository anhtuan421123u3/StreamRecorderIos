package io.streamrecorder.app

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import io.streamrecorder.app.data.StreamRepository
import io.streamrecorder.app.model.AppTab
import io.streamrecorder.app.model.RecordingItem
import io.streamrecorder.app.model.RecordingStatus
import io.streamrecorder.app.theme.SRColors
import io.streamrecorder.app.theme.StreamRecorderTheme
import io.streamrecorder.app.theme.cosmicStarfieldBackground
import io.streamrecorder.app.ui.components.ScissorsVectorIcon
import io.streamrecorder.app.ui.screens.PlayerClipScreen
import io.streamrecorder.app.ui.screens.RecordingsScreen
import io.streamrecorder.app.ui.screens.SearchMonitorScreen
import io.streamrecorder.app.ui.screens.SettingsScreen
import io.streamrecorder.app.ui.screens.WebSnifferModal
import io.streamrecorder.app.ui.screens.YourClipsScreen

@Composable
fun StreamRecorderApp() {
    val repository = remember { StreamRepository() }

    val streamers by repository.streamers.collectAsState()
    val recordings by repository.recordings.collectAsState()
    val clips by repository.clips.collectAsState()
    val settings by repository.settings.collectAsState()
    val recordingsViewMode by repository.recordingsViewMode.collectAsState()
    val clipsViewMode by repository.clipsViewMode.collectAsState()
    val toastMessage by repository.toastMessage.collectAsState()
    val detectedStreams by repository.detectedStreams.collectAsState()

    var activeTab by remember { mutableStateOf(AppTab.SEARCH) }
    var activePlayerRecording by remember { mutableStateOf<RecordingItem?>(null) }
    var showWebSniffer by remember { mutableStateOf(false) }

    StreamRecorderTheme {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .cosmicStarfieldBackground()
                .windowInsetsPadding(WindowInsets.statusBars)
        ) {
            when {
                showWebSniffer -> {
                    WebSnifferModal(
                        detectedStreams = detectedStreams,
                        onStreamDetected = { repository.onWebStreamSniffed(it) },
                        onRecordStream = { detected ->
                            val created = repository.addCustomStreamOrChannel(
                                nameInput = detected.pageTitle,
                                urlOrHandleInput = detected.url,
                                selectedPlatform = null
                            )
                            showWebSniffer = false
                            activeTab = AppTab.RECORDINGS
                            if (created != null) {
                                activePlayerRecording = created
                            }
                        },
                        onClose = { showWebSniffer = false }
                    )
                }

                activePlayerRecording != null -> {
                    val rec = activePlayerRecording!!
                    PlayerClipScreen(
                        recording = rec,
                        onClose = { activePlayerRecording = null },
                        onExportClip = { title, startSec, endSec, onDone ->
                            repository.createClipFromRecording(
                                recording = rec,
                                clipTitle = title,
                                startSec = startSec,
                                endSec = endSec
                            ) { _, _ ->
                                onDone()
                                activePlayerRecording = null
                                activeTab = AppTab.CLIPS
                            }
                        },
                        onDownloadFullVideo = {
                            repository.downloadRecordingToDevice(rec.id)
                        }
                    )
                }

                else -> {
                    when (activeTab) {
                        AppTab.SEARCH -> {
                            SearchMonitorScreen(
                                streamers = streamers,
                                showHeroBanner = !settings.hasDismissedHeroBanner,
                                onDismissHeroBanner = {
                                    repository.updateSettings { it.copy(hasDismissedHeroBanner = true) }
                                },
                                onToggleMonitor = { repository.toggleMonitorStreamer(it) },
                                onAddCustomStream = { name, url, platform ->
                                    val rec = repository.addCustomStreamOrChannel(name, url, platform)
                                    if (rec != null) {
                                        activeTab = AppTab.RECORDINGS
                                    }
                                    rec
                                },
                                onOpenWebSniffer = {
                                    repository.clearSniffedStreams()
                                    showWebSniffer = true
                                },
                                onOpenRecordingForStreamer = { streamerId ->
                                    val matched = recordings.firstOrNull { it.streamerId == streamerId }
                                    if (matched != null) {
                                        activePlayerRecording = matched
                                    } else {
                                        repository.toggleMonitorStreamer(streamerId)
                                        activeTab = AppTab.RECORDINGS
                                    }
                                }
                            )
                        }

                        AppTab.RECORDINGS -> {
                            RecordingsScreen(
                                recordings = recordings,
                                viewMode = recordingsViewMode,
                                onViewModeChange = { repository.setRecordingsViewMode(it) },
                                onPlayAndClip = { activePlayerRecording = it },
                                onDownloadRecording = { repository.downloadRecordingToDevice(it) },
                                onStopLiveRecording = { repository.stopLiveRecording(it) },
                                onDeleteRecording = { repository.deleteRecording(it) }
                            )
                        }

                        AppTab.CLIPS -> {
                            YourClipsScreen(
                                clips = clips,
                                viewMode = clipsViewMode,
                                onViewModeChange = { repository.setClipsViewMode(it) },
                                onPlayClip = { clip ->
                                    activePlayerRecording = RecordingItem(
                                        id = clip.id,
                                        streamerId = clip.sourceRecordingId,
                                        streamerName = clip.streamerName,
                                        streamerHandle = clip.streamerHandle,
                                        platform = clip.platform,
                                        avatarColorHex = clip.avatarColorHex,
                                        avatarInitials = clip.avatarInitials,
                                        title = clip.title,
                                        streamUrl = clip.videoUrlOrPath,
                                        localFilePath = clip.videoUrlOrPath.takeIf { !it.startsWith("http") },
                                        durationSeconds = clip.durationSeconds,
                                        sizeLabel = "MP4 Clip",
                                        recordedAtLabel = clip.createdAtLabel,
                                        status = RecordingStatus.READY,
                                        thumbnailAccentHex = clip.thumbnailAccentHex
                                    )
                                },
                                onSaveClipToPhotos = { repository.saveClipToPhotosLibrary(it) },
                                onShareClip = { repository.shareClip(it) },
                                onRenameClip = { id, title -> repository.renameClip(id, title) },
                                onDeleteClip = { repository.deleteClip(it) }
                            )
                        }

                        AppTab.SETTINGS -> {
                            SettingsScreen(
                                settings = settings,
                                monitoredCount = streamers.count { it.isMonitored },
                                recordingsCount = recordings.size,
                                clipsCount = clips.size,
                                onUpdateSettings = { repository.updateSettings(it) },
                                onClearCache = { repository.clearOfflineStorage() }
                            )
                        }
                    }

                    // Bottom Glass Navigation Bar
                    BottomGlassNavBar(
                        activeTab = activeTab,
                        liveCount = recordings.count { it.status == RecordingStatus.LIVE_RECORDING },
                        clipsCount = clips.size,
                        onSelectTab = { activeTab = it },
                        modifier = Modifier.align(Alignment.BottomCenter)
                    )
                }
            }

            // Floating Toast Banner
            toastMessage?.let { msg ->
                Box(
                    modifier = Modifier
                        .align(Alignment.TopCenter)
                        .padding(horizontal = 20.dp, vertical = 10.dp)
                        .clip(RoundedCornerShape(50))
                        .background(Color(0xF01C183B))
                        .border(1.dp, SRColors.ElectricBlue, RoundedCornerShape(50))
                        .padding(horizontal = 18.dp, vertical = 10.dp)
                ) {
                    Text(
                        text = msg,
                        color = Color.White,
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Bold
                    )
                }
            }
        }
    }
}

@Composable
private fun BottomGlassNavBar(
    activeTab: AppTab,
    liveCount: Int,
    clipsCount: Int,
    onSelectTab: (AppTab) -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .background(Color(0xEB0B091B))
            .border(width = 1.dp, color = SRColors.BorderSubtle)
            .windowInsetsPadding(WindowInsets.navigationBars)
            .padding(horizontal = 10.dp, vertical = 8.dp),
        horizontalArrangement = Arrangement.SpaceAround,
        verticalAlignment = Alignment.CenterVertically
    ) {
        AppTab.entries.forEach { tab ->
            val selected = activeTab == tab
            val tint = if (selected) SRColors.ElectricBlue else SRColors.TextSecondary

            Column(
                modifier = Modifier
                    .clip(RoundedCornerShape(12.dp))
                    .background(if (selected) SRColors.ElectricBlue.copy(alpha = 0.14f) else Color.Transparent)
                    .clickable { onSelectTab(tab) }
                    .padding(horizontal = 14.dp, vertical = 6.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Box {
                    when (tab) {
                        AppTab.SEARCH -> Text("🔍", fontSize = 16.sp)
                        AppTab.RECORDINGS -> {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Box(
                                    modifier = Modifier
                                        .size(11.dp)
                                        .clip(CircleShape)
                                        .background(if (liveCount > 0) SRColors.HotPink else tint)
                                )
                            }
                        }
                        AppTab.CLIPS -> ScissorsVectorIcon(size = 17.dp, color = tint)
                        AppTab.SETTINGS -> Text("⚙", color = tint, fontSize = 16.sp)
                    }
                }
                Spacer(Modifier.height(3.dp))
                Text(
                    text = when (tab) {
                        AppTab.RECORDINGS -> if (liveCount > 0) "Streams ($liveCount)" else "Streams"
                        AppTab.CLIPS -> "Clips ($clipsCount)"
                        else -> tab.label
                    },
                    color = if (selected) Color.White else SRColors.TextSecondary,
                    fontSize = 11.sp,
                    fontWeight = if (selected) FontWeight.ExtraBold else FontWeight.Medium
                )
            }
        }
    }
}
