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
import io.streamrecorder.app.model.ClipItem
import io.streamrecorder.app.model.LayoutViewMode
import io.streamrecorder.app.theme.SRColors
import io.streamrecorder.app.theme.formatDurationClock
import io.streamrecorder.app.ui.components.BlueDownloadSquareButton
import io.streamrecorder.app.ui.components.ListGridModeSwitcher
import io.streamrecorder.app.ui.components.PlatformGlyphBadge

/**
 * 1:1 recreation of App Store Screenshot #3 bottom phone ("Your clips / Create clips from your recordings.")
 */
@Composable
fun YourClipsScreen(
    clips: List<ClipItem>,
    viewMode: LayoutViewMode,
    onViewModeChange: (LayoutViewMode) -> Unit,
    onPlayClip: (ClipItem) -> Unit,
    onSaveClipToPhotos: (ClipItem) -> Unit,
    onShareClip: (ClipItem) -> Unit,
    onRenameClip: (clipId: String, newTitle: String) -> Unit,
    onDeleteClip: (String) -> Unit
) {
    var editingClip by remember { mutableStateOf<ClipItem?>(null) }

    Column(modifier = Modifier.fillMaxSize()) {
        // Exact Header from Screenshot #3
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 18.dp, vertical = 14.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column {
                Text(
                    text = "Your clips",
                    color = Color.White,
                    fontSize = 28.sp,
                    fontWeight = FontWeight.ExtraBold
                )
                Spacer(Modifier.height(2.dp))
                Text(
                    text = "Create clips from your recordings.",
                    color = SRColors.TextSecondary,
                    fontSize = 13.sp
                )
            }
            ListGridModeSwitcher(mode = viewMode, onModeChange = onViewModeChange)
        }

        if (clips.isEmpty()) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(32.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "No clips yet. Open any recording and tap 'Clip ✂️' to cut your favorite moments!",
                    color = SRColors.TextSecondary,
                    fontSize = 14.sp
                )
            }
        } else if (viewMode == LayoutViewMode.LIST) {
            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(start = 18.dp, end = 18.dp, top = 6.dp, bottom = 92.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                items(clips, key = { it.id }) { clip ->
                    YourClipCard(
                        clip = clip,
                        compact = false,
                        onPlay = { onPlayClip(clip) },
                        onSaveToPhotos = { onSaveClipToPhotos(clip) },
                        onShare = { onShareClip(clip) },
                        onEditTitle = { editingClip = clip },
                        onDelete = { onDeleteClip(clip.id) }
                    )
                }
            }
        } else {
            LazyVerticalGrid(
                columns = GridCells.Fixed(2),
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(start = 18.dp, end = 18.dp, top = 6.dp, bottom = 92.dp),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                items(clips, key = { it.id }) { clip ->
                    YourClipCard(
                        clip = clip,
                        compact = true,
                        onPlay = { onPlayClip(clip) },
                        onSaveToPhotos = { onSaveClipToPhotos(clip) },
                        onShare = { onShareClip(clip) },
                        onEditTitle = { editingClip = clip },
                        onDelete = { onDeleteClip(clip.id) }
                    )
                }
            }
        }
    }

    editingClip?.let { target ->
        var draft by remember(target.id) { mutableStateOf(target.title) }
        AlertDialog(
            onDismissRequest = { editingClip = null },
            containerColor = SRColors.BgCardElevated,
            title = { Text("Rename Clip", color = Color.White, fontWeight = FontWeight.Bold) },
            text = {
                OutlinedTextField(
                    value = draft,
                    onValueChange = { draft = it },
                    singleLine = true,
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedTextColor = Color.White,
                        unfocusedTextColor = Color.White,
                        focusedBorderColor = SRColors.ElectricBlue,
                        unfocusedBorderColor = SRColors.BorderSubtle
                    ),
                    modifier = Modifier.fillMaxWidth()
                )
            },
            confirmButton = {
                Button(
                    onClick = {
                        onRenameClip(target.id, draft)
                        editingClip = null
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = SRColors.ElectricBlue)
                ) {
                    Text("Save", color = Color.White)
                }
            },
            dismissButton = {
                TextButton(onClick = { editingClip = null }) {
                    Text("Cancel", color = SRColors.TextSecondary)
                }
            }
        )
    }
}

@Composable
private fun YourClipCard(
    clip: ClipItem,
    compact: Boolean,
    onPlay: () -> Unit,
    onSaveToPhotos: () -> Unit,
    onShare: () -> Unit,
    onEditTitle: () -> Unit,
    onDelete: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(SRColors.BgCard)
            .border(1.dp, SRColors.BorderSubtle, RoundedCornerShape(16.dp))
            .clickable(onClick = onPlay)
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .aspectRatio(16f / 9f)
                .background(
                    Brush.linearGradient(
                        listOf(
                            Color(clip.thumbnailAccentHex).copy(alpha = 0.45f),
                            Color(0xFF191538),
                            Color(0xFF090814)
                        )
                    )
                )
        ) {
            // Duration badge
            Box(
                modifier = Modifier
                    .align(Alignment.TopStart)
                    .padding(10.dp)
                    .clip(RoundedCornerShape(6.dp))
                    .background(Color.Black.copy(alpha = 0.65f))
                    .padding(horizontal = 7.dp, vertical = 3.dp)
            ) {
                Text(
                    text = "CLIP • ${formatDurationClock(clip.durationSeconds)}",
                    color = Color.White,
                    fontSize = 10.sp,
                    fontWeight = FontWeight.Bold
                )
            }

            // Top-Right Blue Download/Save-to-Photos Square Button (Screenshot #3)
            BlueDownloadSquareButton(
                isDone = clip.savedToPhotos,
                onClick = onSaveToPhotos,
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .padding(10.dp)
            )

            // Center Play Icon
            Box(
                modifier = Modifier
                    .align(Alignment.Center)
                    .size(if (compact) 38.dp else 46.dp)
                    .clip(CircleShape)
                    .background(Color.Black.copy(alpha = 0.55f))
                    .border(1.5.dp, Color.White.copy(alpha = 0.8f), CircleShape),
                contentAlignment = Alignment.Center
            ) {
                Text("▶", color = Color.White, fontSize = if (compact) 14.sp else 17.sp)
            }

            // Bottom-Right Avatar + Platform Icon (Screenshot #3)
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
                        .background(Color(clip.avatarColorHex))
                        .border(1.dp, Color.White, CircleShape),
                    contentAlignment = Alignment.Center
                ) {
                    Text(clip.avatarInitials, color = Color.White, fontSize = 9.sp, fontWeight = FontWeight.Bold)
                }
                PlatformGlyphBadge(platform = clip.platform, size = 24.dp)
            }
        }

        // Footer with Pencil Edit Icon + Timestamp (11:40AM) + Share/Delete
        Column(modifier = Modifier.padding(12.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = clip.title,
                    color = Color.White,
                    fontSize = if (compact) 13.sp else 15.sp,
                    fontWeight = FontWeight.Bold,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.weight(1f)
                )
                Spacer(Modifier.width(6.dp))
                Text(
                    text = "✎",
                    color = SRColors.TextSecondary,
                    fontSize = 14.sp,
                    modifier = Modifier.clickable(onClick = onEditTitle)
                )
            }

            Spacer(Modifier.height(4.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = clip.createdAtLabel,
                    color = SRColors.TextMuted,
                    fontSize = 11.sp
                )

                if (!compact) {
                    Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        Text(
                            text = "Share ↗",
                            color = SRColors.ElectricBlueLight,
                            fontSize = 12.sp,
                            fontWeight = FontWeight.SemiBold,
                            modifier = Modifier.clickable(onClick = onShare)
                        )
                        Text(
                            text = "Delete",
                            color = SRColors.HotPink.copy(alpha = 0.85f),
                            fontSize = 12.sp,
                            fontWeight = FontWeight.SemiBold,
                            modifier = Modifier.clickable(onClick = onDelete)
                        )
                    }
                }
            }
        }
    }
}
