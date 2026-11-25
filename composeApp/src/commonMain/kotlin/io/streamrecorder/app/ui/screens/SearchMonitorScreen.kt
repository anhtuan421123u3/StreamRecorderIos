package io.streamrecorder.app.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
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
import io.streamrecorder.app.model.RecordingItem
import io.streamrecorder.app.model.StreamPlatform
import io.streamrecorder.app.model.StreamerProfile
import io.streamrecorder.app.theme.SRColors
import io.streamrecorder.app.ui.components.PlatformGlyphBadge
import io.streamrecorder.app.ui.components.StreamRecorderWordmark
import io.streamrecorder.app.ui.components.StreamerAvatarWithBadge

@Composable
fun SearchMonitorScreen(
    streamers: List<StreamerProfile>,
    showHeroBanner: Boolean,
    onDismissHeroBanner: () -> Unit,
    onToggleMonitor: (String) -> Unit,
    onAddCustomStream: (name: String, url: String, platform: StreamPlatform?) -> RecordingItem?,
    onOpenWebSniffer: () -> Unit,
    onOpenRecordingForStreamer: (String) -> Unit
) {
    var searchQuery by remember { mutableStateOf("") }
    var selectedPlatform by remember { mutableStateOf<StreamPlatform?>(null) }
    var showAddUrlDialog by remember { mutableStateOf(false) }

    val filteredStreamers = remember(streamers, searchQuery, selectedPlatform) {
        streamers.filter { s ->
            val matchesPlatform = selectedPlatform == null || s.platform == selectedPlatform
            val q = searchQuery.trim().lowercase()
            val matchesQuery = q.isEmpty() ||
                s.displayName.lowercase().contains(q) ||
                s.handle.lowercase().contains(q) ||
                s.platform.displayName.lowercase().contains(q)
            matchesPlatform && matchesQuery
        }
    }

    val featuredRecordingStreamer = remember(streamers) {
        streamers.firstOrNull { it.isActivelyRecording } ?: streamers.firstOrNull()
    }

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(bottom = 96.dp)
    ) {
        // Top Header Bar
        item {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 18.dp, vertical = 14.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                StreamRecorderWordmark()

                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    // Live Browser Sniffer Button
                    Box(
                        modifier = Modifier
                            .clip(RoundedCornerShape(10.dp))
                            .background(SRColors.BgCardElevated)
                            .border(1.dp, SRColors.BorderSubtle, RoundedCornerShape(10.dp))
                            .clickable(onClick = onOpenWebSniffer)
                            .padding(horizontal = 10.dp, vertical = 7.dp)
                    ) {
                        Text(
                            text = "🌐 Sniff Live",
                            color = SRColors.ElectricBlueLight,
                            fontSize = 12.sp,
                            fontWeight = FontWeight.Bold
                        )
                    }

                    // Paste Link / Add Stream Button
                    Box(
                        modifier = Modifier
                            .clip(RoundedCornerShape(10.dp))
                            .background(SRColors.ElectricBlue)
                            .clickable { showAddUrlDialog = true }
                            .padding(horizontal = 11.dp, vertical = 7.dp)
                    ) {
                        Text(
                            text = "+ Link",
                            color = Color.White,
                            fontSize = 12.sp,
                            fontWeight = FontWeight.ExtraBold
                        )
                    }
                }
            }
        }

        // App Store Screenshot #1 Hero Card ("7.6M+ Recordings — #1 Stream recorder for Twitch & more!")
        if (showHeroBanner) {
            item {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 18.dp, vertical = 4.dp)
                        .clip(RoundedCornerShape(20.dp))
                        .background(
                            Brush.linearGradient(
                                listOf(
                                    Color(0xFF1E174C),
                                    Color(0xFF120E2E)
                                )
                            )
                        )
                        .border(1.dp, SRColors.ElectricBlue.copy(alpha = 0.4f), RoundedCornerShape(20.dp))
                        .padding(18.dp)
                ) {
                    Column(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.End
                        ) {
                            Text(
                                text = "✕",
                                color = SRColors.TextMuted,
                                fontSize = 13.sp,
                                modifier = Modifier.clickable(onClick = onDismissHeroBanner)
                            )
                        }
                        Text(
                            text = "7.6M+",
                            color = Color.White,
                            fontSize = 36.sp,
                            fontWeight = FontWeight.Black,
                            letterSpacing = (-1).sp
                        )
                        Text(
                            text = "Recordings",
                            color = SRColors.TextSecondary,
                            fontSize = 14.sp,
                            fontWeight = FontWeight.SemiBold
                        )
                        Spacer(Modifier.height(8.dp))
                        Text(
                            text = "#1 Stream recorder",
                            color = Color.White,
                            fontSize = 16.sp,
                            fontWeight = FontWeight.Bold
                        )
                        Spacer(Modifier.height(6.dp))
                        Box(
                            modifier = Modifier
                                .clip(RoundedCornerShape(50))
                                .background(SRColors.HotPink)
                                .padding(horizontal = 16.dp, vertical = 5.dp)
                        ) {
                            Text(
                                text = "for Twitch, Kick, TikTok & more!",
                                color = Color.White,
                                fontSize = 12.sp,
                                fontWeight = FontWeight.ExtraBold
                            )
                        }
                    }
                }
                Spacer(Modifier.height(12.dp))
            }
        }

        // Screenshot #2 Heading + 3D Platform Icon Strip
        item {
            Column(modifier = Modifier.padding(horizontal = 18.dp)) {
                Text(
                    text = "Search for streamers",
                    color = Color.White,
                    fontSize = 22.sp,
                    fontWeight = FontWeight.ExtraBold
                )
                Text(
                    text = "from any platform!",
                    color = SRColors.ElectricBlueLight,
                    fontSize = 18.sp,
                    fontWeight = FontWeight.Bold
                )
                Spacer(Modifier.height(14.dp))
            }

            // Platform Filter Row (matching Screenshot #2 floating 3D badges)
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .horizontalScroll(rememberScrollState())
                    .padding(horizontal = 18.dp),
                horizontalArrangement = Arrangement.spacedBy(10.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                val allSelected = selectedPlatform == null
                Box(
                    modifier = Modifier
                        .height(40.dp)
                        .clip(RoundedCornerShape(12.dp))
                        .background(if (allSelected) SRColors.ElectricBlue else SRColors.BgCardElevated)
                        .border(
                            1.dp,
                            if (allSelected) SRColors.ElectricBlueLight else SRColors.BorderSubtle,
                            RoundedCornerShape(12.dp)
                        )
                        .clickable { selectedPlatform = null }
                        .padding(horizontal = 14.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Text("All", color = Color.White, fontWeight = FontWeight.Bold, fontSize = 13.sp)
                }

                StreamPlatform.entries.filter { it != StreamPlatform.CUSTOM }.forEach { platform ->
                    val isSelected = selectedPlatform == platform
                    Row(
                        modifier = Modifier
                            .height(40.dp)
                            .clip(RoundedCornerShape(12.dp))
                            .background(if (isSelected) SRColors.ElectricBlue.copy(alpha = 0.25f) else Color(0xFF0E0C1D))
                            .border(
                                width = if (isSelected) 1.5.dp else 1.dp,
                                color = if (isSelected) SRColors.ElectricBlue else SRColors.ElectricBlue.copy(alpha = 0.35f),
                                shape = RoundedCornerShape(12.dp)
                            )
                            .clickable {
                                selectedPlatform = if (isSelected) null else platform
                            }
                            .padding(horizontal = 10.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        PlatformGlyphBadge(platform = platform, size = 24.dp, elevated3D = false)
                        Spacer(Modifier.width(6.dp))
                        Text(
                            text = platform.displayName,
                            color = if (isSelected) Color.White else SRColors.TextSecondary,
                            fontSize = 12.sp,
                            fontWeight = FontWeight.SemiBold
                        )
                    }
                }
            }

            Spacer(Modifier.height(14.dp))

            // Search Input Box + Quick URL Trigger
            OutlinedTextField(
                value = searchQuery,
                onValueChange = { searchQuery = it },
                placeholder = {
                    Text(
                        "Search streamer name, @handle, or paste .m3u8 URL...",
                        color = SRColors.TextMuted,
                        fontSize = 13.sp
                    )
                },
                singleLine = true,
                shape = RoundedCornerShape(14.dp),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedContainerColor = SRColors.BgInput,
                    unfocusedContainerColor = SRColors.BgInput,
                    focusedBorderColor = SRColors.ElectricBlue,
                    unfocusedBorderColor = SRColors.BorderSubtle,
                    focusedTextColor = Color.White,
                    unfocusedTextColor = Color.White,
                    cursorColor = SRColors.HotPink
                ),
                trailingIcon = {
                    if (searchQuery.startsWith("http://") || searchQuery.startsWith("https://")) {
                        Text(
                            text = "RECORD",
                            color = SRColors.HotPink,
                            fontSize = 12.sp,
                            fontWeight = FontWeight.ExtraBold,
                            modifier = Modifier
                                .padding(end = 10.dp)
                                .clickable {
                                    onAddCustomStream("", searchQuery, selectedPlatform)
                                    searchQuery = ""
                                }
                        )
                    } else if (searchQuery.isNotEmpty()) {
                        Text(
                            text = "✕",
                            color = SRColors.TextMuted,
                            modifier = Modifier
                                .padding(end = 10.dp)
                                .clickable { searchQuery = "" }
                        )
                    }
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 18.dp)
            )
            Spacer(Modifier.height(16.dp))
        }

        // Screenshot #2 Highlighted Popped-Out Active Recording Card (Pink Border + [ ● RECORD ] Pill)
        if (featuredRecordingStreamer != null && searchQuery.isBlank()) {
            item {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 18.dp)
                        .clip(RoundedCornerShape(18.dp))
                        .background(Color(0xFF0E0B20))
                        .border(2.dp, SRColors.HotPink, RoundedCornerShape(18.dp))
                        .clickable { onOpenRecordingForStreamer(featuredRecordingStreamer.id) }
                        .padding(horizontal = 14.dp, vertical = 13.dp)
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        StreamerAvatarWithBadge(
                            initials = featuredRecordingStreamer.avatarInitials,
                            colorHex = featuredRecordingStreamer.avatarColorHex,
                            countBadge = null,
                            isLive = true,
                            size = 44.dp
                        )
                        Spacer(Modifier.width(12.dp))
                        Column(modifier = Modifier.weight(1f)) {
                            Text(
                                text = featuredRecordingStreamer.displayName,
                                color = Color.White,
                                fontSize = 17.sp,
                                fontWeight = FontWeight.ExtraBold,
                                maxLines = 1,
                                overflow = TextOverflow.Ellipsis
                            )
                            Text(
                                text = if (featuredRecordingStreamer.isActivelyRecording)
                                    "Auto-recording live • ${featuredRecordingStreamer.viewerCount} watching"
                                else
                                    "Tap to auto-record next live stream",
                                color = SRColors.TextSecondary,
                                fontSize = 11.sp,
                                maxLines = 1,
                                overflow = TextOverflow.Ellipsis
                            )
                        }
                        Spacer(Modifier.width(10.dp))

                        // Iconic Blue [ ● RECORD ] Pill from Screenshot #2
                        Row(
                            modifier = Modifier
                                .clip(RoundedCornerShape(12.dp))
                                .background(SRColors.ElectricBlue)
                                .clickable { onToggleMonitor(featuredRecordingStreamer.id) }
                                .padding(horizontal = 14.dp, vertical = 9.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Box(
                                modifier = Modifier
                                    .size(12.dp)
                                    .clip(CircleShape)
                                    .background(Color.White.copy(alpha = 0.28f)),
                                contentAlignment = Alignment.Center
                            ) {
                                Box(
                                    modifier = Modifier
                                        .size(6.dp)
                                        .clip(CircleShape)
                                        .background(Color.White)
                                )
                            }
                            Spacer(Modifier.width(7.dp))
                            Text(
                                text = if (featuredRecordingStreamer.isMonitored) "RECORD" else "MONITOR",
                                color = Color.White,
                                fontSize = 12.sp,
                                fontWeight = FontWeight.Black,
                                letterSpacing = 0.5.sp
                            )
                        }
                    }
                }
                Spacer(Modifier.height(14.dp))
            }
        }

        // Streamers Directory List (1:1 row layout from Screenshot #2)
        items(filteredStreamers, key = { it.id }) { streamer ->
            StreamerDirectoryRow(
                streamer = streamer,
                onToggleMonitor = { onToggleMonitor(streamer.id) },
                onRowClick = { onOpenRecordingForStreamer(streamer.id) }
            )
        }
    }

    if (showAddUrlDialog) {
        AddCustomStreamDialog(
            onDismiss = { showAddUrlDialog = false },
            onConfirm = { name, url, platform ->
                onAddCustomStream(name, url, platform)
                showAddUrlDialog = false
            }
        )
    }
}

@Composable
private fun StreamerDirectoryRow(
    streamer: StreamerProfile,
    onToggleMonitor: () -> Unit,
    onRowClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 18.dp, vertical = 5.dp)
            .clip(RoundedCornerShape(14.dp))
            .background(SRColors.BgCard.copy(alpha = 0.88f))
            .border(
                width = 1.dp,
                color = if (streamer.isActivelyRecording) SRColors.ElectricBlue.copy(alpha = 0.55f) else SRColors.BorderSubtle,
                shape = RoundedCornerShape(14.dp)
            )
            .clickable(onClick = onRowClick)
            .padding(horizontal = 12.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        PlatformGlyphBadge(platform = streamer.platform, size = 26.dp)
        Spacer(Modifier.width(10.dp))

        StreamerAvatarWithBadge(
            initials = streamer.avatarInitials,
            colorHex = streamer.avatarColorHex,
            countBadge = streamer.recordingsCountBadge,
            isLive = streamer.isLiveNow,
            size = 40.dp
        )
        Spacer(Modifier.width(11.dp))

        Column(modifier = Modifier.weight(1f)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = streamer.displayName,
                    color = Color.White,
                    fontSize = 15.sp,
                    fontWeight = FontWeight.Bold,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                if (streamer.isLiveNow) {
                    Spacer(Modifier.width(6.dp))
                    Box(
                        modifier = Modifier
                            .size(7.dp)
                            .clip(CircleShape)
                            .background(SRColors.HotPink)
                    )
                }
            }
            Text(
                text = streamer.handle,
                color = SRColors.TextSecondary,
                fontSize = 12.sp,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
        }

        Spacer(Modifier.width(8.dp))

        // "Monitor" dark button vs active "● RECORD" pill
        if (streamer.isMonitored) {
            Row(
                modifier = Modifier
                    .clip(RoundedCornerShape(10.dp))
                    .background(SRColors.ElectricBlue)
                    .clickable(onClick = onToggleMonitor)
                    .padding(horizontal = 12.dp, vertical = 7.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Box(
                    modifier = Modifier
                        .size(6.dp)
                        .clip(CircleShape)
                        .background(if (streamer.isActivelyRecording) SRColors.HotPink else Color.White)
                )
                Spacer(Modifier.width(5.dp))
                Text(
                    text = if (streamer.isActivelyRecording) "RECORDING" else "MONITORED",
                    color = Color.White,
                    fontSize = 11.sp,
                    fontWeight = FontWeight.ExtraBold
                )
            }
        } else {
            Box(
                modifier = Modifier
                    .clip(RoundedCornerShape(10.dp))
                    .background(Color(0xFF131938))
                    .border(1.dp, SRColors.ElectricBlue.copy(alpha = 0.45f), RoundedCornerShape(10.dp))
                    .clickable(onClick = onToggleMonitor)
                    .padding(horizontal = 14.dp, vertical = 7.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "Monitor",
                    color = SRColors.ElectricBlueLight,
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Bold
                )
            }
        }
    }
}

@Composable
private fun AddCustomStreamDialog(
    onDismiss: () -> Unit,
    onConfirm: (name: String, url: String, platform: StreamPlatform?) -> Unit
) {
    var name by remember { mutableStateOf("") }
    var url by remember { mutableStateOf("") }

    AlertDialog(
        onDismissRequest = onDismiss,
        containerColor = SRColors.BgCardElevated,
        title = {
            Text(
                "Add Stream Link or Creator",
                color = Color.White,
                fontWeight = FontWeight.ExtraBold,
                fontSize = 18.sp
            )
        },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Text(
                    "Paste a direct HLS (.m3u8) / MP4 stream URL to capture & save immediately, or enter a creator channel link.",
                    color = SRColors.TextSecondary,
                    fontSize = 12.sp
                )
                OutlinedTextField(
                    value = name,
                    onValueChange = { name = it },
                    label = { Text("Creator / Stream Title (optional)") },
                    singleLine = true,
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedTextColor = Color.White,
                        unfocusedTextColor = Color.White,
                        focusedBorderColor = SRColors.ElectricBlue,
                        unfocusedBorderColor = SRColors.BorderSubtle
                    ),
                    modifier = Modifier.fillMaxWidth()
                )
                OutlinedTextField(
                    value = url,
                    onValueChange = { url = it },
                    label = { Text("Stream URL (.m3u8 / .mp4 / channel link)") },
                    placeholder = { Text("https://.../master.m3u8", color = SRColors.TextMuted) },
                    singleLine = true,
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedTextColor = Color.White,
                        unfocusedTextColor = Color.White,
                        focusedBorderColor = SRColors.ElectricBlue,
                        unfocusedBorderColor = SRColors.BorderSubtle
                    ),
                    modifier = Modifier.fillMaxWidth()
                )
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    if (url.isNotBlank()) {
                        onConfirm(name, url, null)
                    }
                },
                colors = ButtonDefaults.buttonColors(containerColor = SRColors.ElectricBlue)
            ) {
                Text("Start Recording", color = Color.White, fontWeight = FontWeight.Bold)
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel", color = SRColors.TextSecondary)
            }
        }
    )
}
