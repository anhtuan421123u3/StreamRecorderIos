package io.streamrecorder.app.ui.screens

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Slider
import androidx.compose.material3.SliderDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import io.streamrecorder.app.model.RecordingItem
import io.streamrecorder.app.platform.NativeVideoPlayer
import io.streamrecorder.app.theme.SRColors
import io.streamrecorder.app.theme.cosmicStarfieldBackground
import io.streamrecorder.app.theme.formatDurationClock
import io.streamrecorder.app.ui.components.PlatformGlyphBadge
import io.streamrecorder.app.ui.components.ScissorsVectorIcon
import kotlin.math.max
import kotlin.math.min

@Composable
fun PlayerClipScreen(
    recording: RecordingItem,
    onClose: () -> Unit,
    onExportClip: (title: String, startSec: Double, endSec: Double, onDone: () -> Unit) -> Unit,
    onDownloadFullVideo: () -> Unit
) {
    var isPlaying by remember { mutableStateOf(true) }
    var currentSec by remember { mutableStateOf(0.0) }
    var totalDurationSec by remember { mutableStateOf(recording.durationSeconds.toDouble().coerceAtLeast(15.0)) }
    var seekRequestSec by remember { mutableStateOf<Double?>(null) }

    var clipModeExpanded by remember { mutableStateOf(true) }
    var clipStartSec by remember { mutableStateOf(0.0) }
    var clipEndSec by remember { mutableStateOf(min(15.0, recording.durationSeconds.toDouble().coerceAtLeast(10.0))) }
    var clipTitle by remember { mutableStateOf("${recording.streamerName} Highlight") }
    var isExporting by remember { mutableStateOf(false) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .cosmicStarfieldBackground()
            .verticalScroll(rememberScrollState())
            .padding(bottom = 32.dp)
    ) {
        // Top Navigation Bar
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 14.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(
                modifier = Modifier
                    .clip(RoundedCornerShape(10.dp))
                    .background(SRColors.BgCardElevated)
                    .clickable(onClick = onClose)
                    .padding(horizontal = 12.dp, vertical = 7.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text("← Back", color = Color.White, fontSize = 13.sp, fontWeight = FontWeight.Bold)
            }

            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text(
                    text = "Create clips",
                    color = Color.White,
                    fontSize = 16.sp,
                    fontWeight = FontWeight.ExtraBold
                )
                Text(
                    text = "from your recordings",
                    color = SRColors.ElectricBlueLight,
                    fontSize = 12.sp,
                    fontWeight = FontWeight.SemiBold
                )
            }

            Box(
                modifier = Modifier
                    .clip(RoundedCornerShape(10.dp))
                    .background(SRColors.ElectricBlue.copy(alpha = 0.2f))
                    .border(1.dp, SRColors.ElectricBlue, RoundedCornerShape(10.dp))
                    .clickable(onClick = onDownloadFullVideo)
                    .padding(horizontal = 10.dp, vertical = 7.dp)
            ) {
                Text("↓ Save Full", color = Color.White, fontSize = 12.sp, fontWeight = FontWeight.Bold)
            }
        }

        // Native iOS AVPlayer Container + Screenshot #3 Clip ✂️ Pill Overlay
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp)
                .clip(RoundedCornerShape(18.dp))
                .background(Color.Black)
                .border(1.5.dp, SRColors.BorderSubtle, RoundedCornerShape(18.dp))
        ) {
            Column {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .aspectRatio(16f / 9f)
                ) {
                    NativeVideoPlayer(
                        urlOrPath = recording.effectivePlayablePath,
                        isPlaying = isPlaying,
                        seekRequestSec = seekRequestSec,
                        onProgress = { cur, dur ->
                            currentSec = cur
                            if (dur > 1.0) {
                                totalDurationSec = dur
                                if (clipEndSec > dur) {
                                    clipEndSec = dur
                                }
                            }
                        },
                        modifier = Modifier.fillMaxSize()
                    )

                    // Floating Screenshot #3 "Clip ✂️" Pill Badge
                    Row(
                        modifier = Modifier
                            .align(Alignment.CenterEnd)
                            .padding(end = 12.dp)
                            .clip(RoundedCornerShape(50))
                            .background(SRColors.ElectricBlue)
                            .border(1.5.dp, Color.White.copy(alpha = 0.4f), RoundedCornerShape(50))
                            .clickable {
                                clipModeExpanded = true
                                clipStartSec = max(0.0, currentSec - 2.0)
                                clipEndSec = min(totalDurationSec, clipStartSec + 12.0)
                            }
                            .padding(horizontal = 16.dp, vertical = 9.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = "Clip",
                            color = Color.White,
                            fontSize = 15.sp,
                            fontWeight = FontWeight.ExtraBold
                        )
                        Spacer(Modifier.width(7.dp))
                        ScissorsVectorIcon(size = 17.dp, color = Color.White)
                    }
                }

                // Custom Bottom Player Control Bar (Screenshot #3 exact timeline + trim bar)
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(Color(0xFF0B0A16))
                        .padding(horizontal = 14.dp, vertical = 10.dp)
                ) {
                    // Visual Timeline with Highlighted Blue Clip Segment |====|
                    ClipRangeTimelineBar(
                        currentSec = currentSec,
                        startSec = clipStartSec,
                        endSec = clipEndSec,
                        durationSec = totalDurationSec,
                        onSeek = { target ->
                            currentSec = target
                            seekRequestSec = target
                        }
                    )

                    Spacer(Modifier.height(8.dp))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Row(
                            horizontalArrangement = Arrangement.spacedBy(16.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = if (isPlaying) "⏸" else "▶",
                                color = Color.White,
                                fontSize = 18.sp,
                                modifier = Modifier.clickable { isPlaying = !isPlaying }
                            )
                            Text(
                                text = "⏮ 10s",
                                color = SRColors.TextSecondary,
                                fontSize = 12.sp,
                                fontWeight = FontWeight.Bold,
                                modifier = Modifier.clickable {
                                    val t = max(0.0, currentSec - 10.0)
                                    currentSec = t
                                    seekRequestSec = t
                                }
                            )
                            Text(
                                text = "10s ⏭",
                                color = SRColors.TextSecondary,
                                fontSize = 12.sp,
                                fontWeight = FontWeight.Bold,
                                modifier = Modifier.clickable {
                                    val t = min(totalDurationSec, currentSec + 10.0)
                                    currentSec = t
                                    seekRequestSec = t
                                }
                            )
                        }

                        Text(
                            text = "${formatDurationClock(currentSec.toInt())} / ${formatDurationClock(totalDurationSec.toInt())}",
                            color = Color.White,
                            fontSize = 12.sp,
                            fontWeight = FontWeight.SemiBold
                        )
                    }
                }
            }
        }

        Spacer(Modifier.height(16.dp))

        // Stream Metadata Card
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp)
                .clip(RoundedCornerShape(14.dp))
                .background(SRColors.BgCard)
                .border(1.dp, SRColors.BorderSubtle, RoundedCornerShape(14.dp))
                .padding(14.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            PlatformGlyphBadge(platform = recording.platform, size = 32.dp)
            Spacer(Modifier.width(12.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = recording.title,
                    color = Color.White,
                    fontSize = 15.sp,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = "${recording.streamerName} (${recording.streamerHandle}) • ${recording.resolutionLabel}",
                    color = SRColors.TextSecondary,
                    fontSize = 12.sp
                )
            }
        }

        Spacer(Modifier.height(16.dp))

        // Clip Trimmer Studio Card ("Clip ✂️" -> "Save ▷" via AVAssetExportSession)
        if (clipModeExpanded) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp)
                    .clip(RoundedCornerShape(18.dp))
                    .background(SRColors.BgCardElevated)
                    .border(1.5.dp, SRColors.ElectricBlue.copy(alpha = 0.65f), RoundedCornerShape(18.dp))
                    .padding(16.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        ScissorsVectorIcon(size = 18.dp, color = SRColors.ElectricBlueLight)
                        Spacer(Modifier.width(8.dp))
                        Text(
                            text = "Clip Trimmer (MP4 Export)",
                            color = Color.White,
                            fontSize = 16.sp,
                            fontWeight = FontWeight.ExtraBold
                        )
                    }

                    Text(
                        text = "${formatDurationClock(clipStartSec.toInt())} → ${formatDurationClock(clipEndSec.toInt())} (${max(1, (clipEndSec - clipStartSec).toInt())}s)",
                        color = SRColors.HotPinkGlow,
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold
                    )
                }

                Spacer(Modifier.height(12.dp))

                Text(
                    text = "Start Time: ${formatDurationClock(clipStartSec.toInt())}",
                    color = SRColors.TextSecondary,
                    fontSize = 12.sp
                )
                Slider(
                    value = clipStartSec.toFloat(),
                    onValueChange = { v ->
                        clipStartSec = v.toDouble().coerceAtMost(max(0.0, clipEndSec - 1.0))
                        seekRequestSec = clipStartSec
                    },
                    valueRange = 0f..totalDurationSec.toFloat().coerceAtLeast(2f),
                    colors = SliderDefaults.colors(
                        thumbColor = SRColors.ElectricBlue,
                        activeTrackColor = SRColors.ElectricBlue
                    )
                )

                Text(
                    text = "End Time: ${formatDurationClock(clipEndSec.toInt())}",
                    color = SRColors.TextSecondary,
                    fontSize = 12.sp
                )
                Slider(
                    value = clipEndSec.toFloat(),
                    onValueChange = { v ->
                        clipEndSec = v.toDouble().coerceAtLeast(min(totalDurationSec, clipStartSec + 1.0))
                    },
                    valueRange = 0f..totalDurationSec.toFloat().coerceAtLeast(2f),
                    colors = SliderDefaults.colors(
                        thumbColor = SRColors.HotPink,
                        activeTrackColor = SRColors.HotPink
                    )
                )

                Spacer(Modifier.height(8.dp))

                OutlinedTextField(
                    value = clipTitle,
                    onValueChange = { clipTitle = it },
                    label = { Text("Clip Title") },
                    singleLine = true,
                    shape = RoundedCornerShape(12.dp),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedTextColor = Color.White,
                        unfocusedTextColor = Color.White,
                        focusedBorderColor = SRColors.ElectricBlue,
                        unfocusedBorderColor = SRColors.BorderSubtle
                    ),
                    modifier = Modifier.fillMaxWidth()
                )

                Spacer(Modifier.height(14.dp))

                // Iconic Screenshot #3 "Save ▷" Purple-Blue Pill Button
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(50.dp)
                        .clip(RoundedCornerShape(14.dp))
                        .background(SRColors.RoyalSavePurple)
                        .clickable(enabled = !isExporting) {
                            isExporting = true
                            onExportClip(clipTitle, clipStartSec, clipEndSec) {
                                isExporting = false
                            }
                        },
                    contentAlignment = Alignment.Center
                ) {
                    if (isExporting) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            CircularProgressIndicator(
                                color = Color.White,
                                strokeWidth = 2.5.dp,
                                modifier = Modifier.size(20.dp)
                            )
                            Spacer(Modifier.width(10.dp))
                            Text(
                                text = "Exporting MP4 Clip...",
                                color = Color.White,
                                fontWeight = FontWeight.Bold,
                                fontSize = 15.sp
                            )
                        }
                    } else {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text(
                                text = "Save Clip to Your Clips",
                                color = Color.White,
                                fontSize = 16.sp,
                                fontWeight = FontWeight.ExtraBold
                            )
                            Spacer(Modifier.width(8.dp))
                            Box(
                                modifier = Modifier
                                    .size(22.dp)
                                    .border(1.5.dp, Color.White, RoundedCornerShape(5.dp)),
                                contentAlignment = Alignment.Center
                            ) {
                                Text("▷", color = Color.White, fontSize = 11.sp, fontWeight = FontWeight.Bold)
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun ClipRangeTimelineBar(
    currentSec: Double,
    startSec: Double,
    endSec: Double,
    durationSec: Double,
    onSeek: (Double) -> Unit
) {
    val safeDur = durationSec.coerceAtLeast(1.0)
    Canvas(
        modifier = Modifier
            .fillMaxWidth()
            .height(22.dp)
            .pointerInput(safeDur) {
                detectTapGestures { offset ->
                    val ratio = (offset.x / size.width).coerceIn(0f, 1f)
                    onSeek(ratio * safeDur)
                }
            }
    ) {
        val w = size.width
        val h = size.height
        val trackTop = h * 0.38f
        val trackHeight = h * 0.24f

        // Base dark track
        drawRoundRect(
            color = Color(0xFF282542),
            topLeft = Offset(0f, trackTop),
            size = Size(w, trackHeight),
            cornerRadius = CornerRadius(6f, 6f)
        )

        // Selected Clip Blue Segment (|====| from Screenshot #3)
        val startX = ((startSec / safeDur).toFloat().coerceIn(0f, 1f)) * w
        val endX = ((endSec / safeDur).toFloat().coerceIn(0f, 1f)) * w
        drawRect(
            color = SRColors.ElectricBlue,
            topLeft = Offset(startX, trackTop),
            size = Size(max(4f, endX - startX), trackHeight)
        )

        // Vertical Trim Handles
        drawLine(SRColors.ElectricBlueLight, Offset(startX, h * 0.12f), Offset(startX, h * 0.88f), strokeWidth = 3.5f)
        drawLine(SRColors.ElectricBlueLight, Offset(endX, h * 0.12f), Offset(endX, h * 0.88f), strokeWidth = 3.5f)

        // Playhead dot
        val playX = ((currentSec / safeDur).toFloat().coerceIn(0f, 1f)) * w
        drawCircle(
            color = Color.White,
            radius = 6f,
            center = Offset(playX, h * 0.5f)
        )
    }
}
