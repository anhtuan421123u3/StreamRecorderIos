package io.streamrecorder.app.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import io.streamrecorder.app.model.LayoutViewMode
import io.streamrecorder.app.model.RecordingItem
import io.streamrecorder.app.model.RecordingStatus
import io.streamrecorder.app.theme.SRColors
import io.streamrecorder.app.theme.formatDurationClock
import io.streamrecorder.app.ui.components.BlueDownloadSquareButton
import io.streamrecorder.app.ui.components.ListGridModeSwitcher
import io.streamrecorder.app.ui.components.PlatformGlyphBadge
import io.streamrecorder.app.ui.components.PulsingRecBadge
import io.streamrecorder.app.ui.components.ScissorsVectorIcon

@Composable
fun RecordingsScreen(
    recordings: List<RecordingItem>,
    viewMode: LayoutViewMode,
    onViewModeChange: (LayoutViewMode) -> Unit,
    onPlayAndClip: (RecordingItem) -> Unit,
    onDownloadRecording: (String) -> Unit,
    onStopLiveRecording: (String) -> Unit,
    onDeleteRecording: (String) -> Unit
) {
    var filterTab by remember { mutableStateOf(0) } // 0=All, 1=Live, 2=Downloaded

    val displayed = remember(recordings, filterTab) {
        when (filterTab) {
            1 -> recordings.filter { it.status == RecordingStatus.LIVE_RECORDING }
            2 -> recordings.filter { it.isDownloaded }
            else -> recordings
        }
    }

    Column(modifier = Modifier.fillMaxSize()) {
        // Header Row
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 18.dp, vertical = 14.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column {
                Text(
                    text = "Recordings",
                    color = Color.White,
                    fontSize = 26.sp,
                    fontWeight = FontWeight.ExtraBold
                )
                Text(
                    text = "Watch anytime, pause, replay or cut HD clips.",
                    color = SRColors.TextSecondary,
                    fontSize = 12.sp
                )
            }
            ListGridModeSwitcher(mode = viewMode, onModeChange = onViewModeChange)
        }

        // Filter Pills
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 18.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            val labels = listOf(
                "All (${recordings.size})",
                "Live (${recordings.count { it.status == RecordingStatus.LIVE_RECORDING }})",
                "Saved (${recordings.count { it.isDownloaded }})"
            )
            labels.forEachIndexed { idx, title ->
                val active = filterTab == idx
                Box(
                    modifier = Modifier
                        .clip(RoundedCornerShape(50))
                        .background(if (active) SRColors.ElectricBlue else SRColors.BgCardElevated)
                        .border(
                            1.dp,
                            if (active) SRColors.ElectricBlueLight else SRColors.BorderSubtle,
                            RoundedCornerShape(50)
                        )
                        .clickable { filterTab = idx }
                        .padding(horizontal = 14.dp, vertical = 7.dp)
                ) {
                    Text(
                        text = title,
                        color = if (active) Color.White else SRColors.TextSecondary,
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold
                    )
                }
            }
        }

        Spacer(Modifier.height(12.dp))

        if (displayed.isEmpty()) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(32.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "No recordings in this filter yet.\nMonitor a streamer or paste an HLS .m3u8 URL in Search!",
                    color = SRColors.TextSecondary,
                    fontSize = 14.sp
                )
            }
        } else if (viewMode == LayoutViewMode.LIST) {
            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(horizontal = 18.dp, vertical = 6.dp),
                verticalArrangement = Arrangement.spacedBy(14.dp)
            ) {
                items(displayed, key = { it.id }) { item ->
                    RecordingShowcaseCard(
                        item = item,
                        compact = false,
                        onPlayAndClip = { onPlayAndClip(item) },
                        onDownload = { onDownloadRecording(item.id) },
                        onStopLive = { onStopLiveRecording(item.id) },
                        onDelete = { onDeleteRecording(item.id) }
                    )
                }
                item { Spacer(Modifier.height(84.dp)) }
            }
        } else {
            LazyVerticalGrid(
                columns = GridCells.Fixed(2),
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(start = 18.dp, end = 18.dp, top = 6.dp, bottom = 92.dp),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                items(displayed, key = { it.id }) { item ->
                    RecordingShowcaseCard(
                        item = item,
                        compact = true,
                        onPlayAndClip = { onPlayAndClip(item) },
                        onDownload = { onDownloadRecording(item.id) },
                        onStopLive = { onStopLiveRecording(item.id) },
                        onDelete = { onDeleteRecording(item.id) }
                    )
                }
            }
        }
    }
}

@Composable
private fun RecordingShowcaseCard(
    item: RecordingItem,
    compact: Boolean,
    onPlayAndClip: () -> Unit,
    onDownload: () -> Unit,
    onStopLive: () -> Unit,
    onDelete: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(SRColors.BgCard)
            .border(
                width = 1.dp,
                color = if (item.status == RecordingStatus.LIVE_RECORDING)
                    SRColors.HotPink.copy(alpha = 0.6f)
                else
                    SRColors.BorderSubtle,
                shape = RoundedCornerShape(16.dp)
            )
            .clickable(onClick = onPlayAndClip)
    ) {
        // 16:9 Thumbnail Preview matching Screenshot #3 card layout
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .aspectRatio(16f / 9f)
                .background(
                    Brush.linearGradient(
                        colors = listOf(
                            Color(item.thumbnailAccentHex).copy(alpha = 0.42f),
                            Color(0xFF14112B),
                            Color(0xFF0A0818)
                        )
                    )
                )
        ) {
            // Top-Left: Live Recording or Resolution Pill
            Box(modifier = Modifier.align(Alignment.TopStart).padding(10.dp)) {
                if (item.status == RecordingStatus.LIVE_RECORDING) {
                    PulsingRecBadge("REC • ${formatDurationClock(item.durationSeconds)}")
                } else {
                    Box(
                        modifier = Modifier
                            .clip(RoundedCornerShape(6.dp))
                            .background(Color.Black.copy(alpha = 0.65f))
                            .padding(horizontal = 7.dp, vertical = 3.dp)
                    ) {
                        Text(
                            text = "${item.resolutionLabel} • ${formatDurationClock(item.durationSeconds)}",
                            color = Color.White,
                            fontSize = 10.sp,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }
            }

            // Top-Right: Signature Blue Download Square Button (Screenshot #3)
            BlueDownloadSquareButton(
                isDone = item.isDownloaded,
                onClick = onDownload,
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .padding(10.dp)
            )

            // Center Play Button
            Box(
                modifier = Modifier
                    .align(Alignment.Center)
                    .size(if (compact) 40.dp else 50.dp)
                    .clip(CircleShape)
                    .background(Color.Black.copy(alpha = 0.55f))
                    .border(1.5.dp, Color.White.copy(alpha = 0.75f), CircleShape),
                contentAlignment = Alignment.Center
            ) {
                Text("▶", color = Color.White, fontSize = if (compact) 15.sp else 18.sp)
            }

            // Bottom-Right: Creator Avatar + Platform Badge (exact Screenshot #3 overlay)
            Row(
                modifier = Modifier
                    .align(Alignment.BottomEnd)
                    .padding(10.dp),
                horizontalArrangement = Arrangement.spacedBy(5.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Box(
                    modifier = Modifier
                        .size(24.dp)
                        .clip(CircleShape)
                        .background(Color(item.avatarColorHex))
                        .border(1.dp, Color.White, CircleShape),
                    contentAlignment = Alignment.Center
                ) {
                    Text(item.avatarInitials, color = Color.White, fontSize = 9.sp, fontWeight = FontWeight.Bold)
                }
                PlatformGlyphBadge(platform = item.platform, size = 24.dp)
            }

            if (item.status == RecordingStatus.DOWNLOADING) {
                LinearProgressIndicator(
                    progress = { item.downloadProgress },
                    color = SRColors.ElectricBlue,
                    trackColor = Color.Black.copy(alpha = 0.6f),
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(4.dp)
                        .align(Alignment.BottomCenter)
                )
            }
        }

        // Metadata & Quick Actions Footer
        Column(modifier = Modifier.padding(12.dp)) {
            Text(
                text = item.title,
                color = Color.White,
                fontSize = if (compact) 13.sp else 15.sp,
                fontWeight = FontWeight.Bold,
                maxLines = if (compact) 1 else 2,
                overflow = TextOverflow.Ellipsis
            )
            Spacer(Modifier.height(4.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "${item.streamerName} • ${item.recordedAtLabel} • ${item.sizeLabel}",
                    color = SRColors.TextSecondary,
                    fontSize = 11.sp,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.weight(1f)
                )

                if (!compact) {
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                        if (item.status == RecordingStatus.LIVE_RECORDING) {
                            Box(
                                modifier = Modifier
                                    .clip(RoundedCornerShape(8.dp))
                                    .background(SRColors.HotPink.copy(alpha = 0.2f))
                                    .clickable(onClick = onStopLive)
                                    .padding(horizontal = 9.dp, vertical = 5.dp)
                            ) {
                                Text("■ Stop", color = SRColors.HotPinkGlow, fontSize = 11.sp, fontWeight = FontWeight.Bold)
                            }
                        }

                        // Quick "Clip ✂️" trigger pill
                        Row(
                            modifier = Modifier
                                .clip(RoundedCornerShape(8.dp))
                                .background(SRColors.ElectricBlue)
                                .clickable(onClick = onPlayAndClip)
                                .padding(horizontal = 10.dp, vertical = 5.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text("Clip", color = Color.White, fontSize = 11.sp, fontWeight = FontWeight.ExtraBold)
                            Spacer(Modifier.width(4.dp))
                            ScissorsVectorIcon(size = 12.dp)
                        }

                        Text(
                            text = "🗑",
                            fontSize = 13.sp,
                            modifier = Modifier
                                .padding(start = 2.dp)
                                .clickable(onClick = onDelete)
                        )
                    }
                }
            }
        }
    }
}
