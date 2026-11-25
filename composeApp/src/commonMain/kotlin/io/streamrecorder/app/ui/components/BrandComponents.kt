package io.streamrecorder.app.ui.components

import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import io.streamrecorder.app.model.LayoutViewMode
import io.streamrecorder.app.model.StreamPlatform
import io.streamrecorder.app.theme.SRColors

/**
 * Exact StreamRecorder Icon: Two rounded periwinkle blue L-brackets framing a hot-pink recording dot.
 */
@Composable
fun StreamRecorderLogoMark(
    size: Dp = 28.dp,
    modifier: Modifier = Modifier
) {
    Canvas(modifier = modifier.size(size)) {
        val w = this.size.width
        val h = this.size.height
        val stroke = w * 0.17f

        // Top-Right Blue Bracket
        val topRight = Path().apply {
            moveTo(w * 0.30f, h * 0.14f)
            lineTo(w * 0.86f, h * 0.14f)
            lineTo(w * 0.86f, h * 0.68f)
        }
        drawPath(
            path = topRight,
            color = SRColors.ElectricBlue,
            style = Stroke(width = stroke, cap = StrokeCap.Round, join = StrokeJoin.Round)
        )

        // Bottom-Left Blue Bracket
        val bottomLeft = Path().apply {
            moveTo(w * 0.14f, h * 0.32f)
            lineTo(w * 0.14f, h * 0.86f)
            lineTo(w * 0.70f, h * 0.86f)
        }
        drawPath(
            path = bottomLeft,
            color = SRColors.ElectricBlue,
            style = Stroke(width = stroke, cap = StrokeCap.Round, join = StrokeJoin.Round)
        )

        // Center Hot Pink Recording Dot
        drawCircle(
            color = SRColors.HotPink,
            radius = w * 0.165f,
            center = Offset(w * 0.5f, h * 0.5f)
        )
    }
}

@Composable
fun StreamRecorderWordmark(modifier: Modifier = Modifier) {
    Row(
        modifier = modifier,
        verticalAlignment = Alignment.CenterVertically
    ) {
        StreamRecorderLogoMark(size = 28.dp)
        Spacer(Modifier.width(9.dp))
        Text(
            text = "streamrecorder",
            color = Color.White,
            fontSize = 21.sp,
            fontWeight = FontWeight.ExtraBold,
            letterSpacing = (-0.4).sp
        )
    }
}

@Composable
fun PlatformGlyphBadge(
    platform: StreamPlatform,
    size: Dp = 24.dp,
    elevated3D: Boolean = false
) {
    val bgColor = if (elevated3D) Color(0xFF0A0915) else Color(0xFF1A1831)
    Box(
        modifier = Modifier
            .size(size)
            .then(
                if (elevated3D) {
                    Modifier
                        .border(1.2.dp, SRColors.ElectricBlue.copy(alpha = 0.65f), RoundedCornerShape(size * 0.32f))
                } else {
                    Modifier
                }
            )
            .clip(RoundedCornerShape(size * 0.30f))
            .background(bgColor),
        contentAlignment = Alignment.Center
    ) {
        when (platform) {
            StreamPlatform.TWITCH -> {
                Canvas(Modifier.size(size * 0.56f)) {
                    val w = this.size.width
                    val h = this.size.height
                    val p = Path().apply {
                        moveTo(w * 0.15f, h * 0.1f)
                        lineTo(w * 0.9f, h * 0.1f)
                        lineTo(w * 0.9f, h * 0.65f)
                        lineTo(w * 0.65f, h * 0.85f)
                        lineTo(w * 0.42f, h * 0.85f)
                        lineTo(w * 0.25f, h * 1.0f)
                        lineTo(w * 0.25f, h * 0.85f)
                        lineTo(w * 0.1f, h * 0.85f)
                        close()
                    }
                    drawPath(p, color = Color(0xFFB482FF), style = Stroke(width = w * 0.13f, join = StrokeJoin.Round))
                    drawLine(Color.White, Offset(w * 0.44f, h * 0.32f), Offset(w * 0.44f, h * 0.56f), strokeWidth = w * 0.12f, cap = StrokeCap.Round)
                    drawLine(Color.White, Offset(w * 0.68f, h * 0.32f), Offset(w * 0.68f, h * 0.56f), strokeWidth = w * 0.12f, cap = StrokeCap.Round)
                }
            }
            StreamPlatform.KICK -> {
                Text("K", color = Color(0xFF53FC18), fontWeight = FontWeight.Black, fontSize = (size.value * 0.52f).sp)
            }
            StreamPlatform.TIKTOK -> {
                Text("♪", color = Color(0xFF25F4EE), fontWeight = FontWeight.Black, fontSize = (size.value * 0.54f).sp)
            }
            StreamPlatform.YOUTUBE -> {
                Canvas(Modifier.size(size * 0.60f)) {
                    val w = this.size.width
                    val h = this.size.height
                    drawRoundRect(
                        color = Color(0xFFFF1E42),
                        topLeft = Offset(0f, h * 0.16f),
                        size = Size(w, h * 0.68f),
                        cornerRadius = CornerRadius(w * 0.24f, w * 0.24f)
                    )
                    val tri = Path().apply {
                        moveTo(w * 0.40f, h * 0.33f)
                        lineTo(w * 0.68f, h * 0.50f)
                        lineTo(w * 0.40f, h * 0.67f)
                        close()
                    }
                    drawPath(tri, Color.White)
                }
            }
            StreamPlatform.SOOP -> {
                Text("S", color = Color(0xFF3FA2FF), fontWeight = FontWeight.Black, fontSize = (size.value * 0.50f).sp)
            }
            StreamPlatform.BILIBILI -> {
                Text("tv", color = Color(0xFF00A1D6), fontWeight = FontWeight.ExtraBold, fontSize = (size.value * 0.44f).sp)
            }
            StreamPlatform.CHZZK -> {
                Text("⚡", color = Color(0xFF00FFA3), fontWeight = FontWeight.Bold, fontSize = (size.value * 0.48f).sp)
            }
            StreamPlatform.CUSTOM -> {
                Text("HLS", color = SRColors.ElectricBlueLight, fontWeight = FontWeight.ExtraBold, fontSize = (size.value * 0.34f).sp)
            }
        }
    }
}

@Composable
fun StreamerAvatarWithBadge(
    initials: String,
    colorHex: Long,
    countBadge: String? = null,
    isLive: Boolean = false,
    size: Dp = 44.dp
) {
    Box(modifier = Modifier.size(size + 6.dp), contentAlignment = Alignment.Center) {
        Box(
            modifier = Modifier
                .size(size)
                .clip(CircleShape)
                .background(Color(colorHex).copy(alpha = 0.26f))
                .border(
                    width = if (isLive) 2.dp else 1.dp,
                    color = if (isLive) SRColors.HotPink else Color(colorHex).copy(alpha = 0.7f),
                    shape = CircleShape
                ),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = initials,
                color = Color.White,
                fontWeight = FontWeight.ExtraBold,
                fontSize = (size.value * 0.35f).sp
            )
        }

        if (!countBadge.isNullOrBlank()) {
            Box(
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .offset(x = 2.dp, y = (-2).dp)
                    .clip(CircleShape)
                    .background(SRColors.ElectricBlue)
                    .padding(horizontal = 5.dp, vertical = 1.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = countBadge,
                    color = Color.White,
                    fontSize = 9.sp,
                    fontWeight = FontWeight.ExtraBold
                )
            }
        }
    }
}

/**
 * List (☰) / Grid (⊞) toggle buttons matching Screenshot #3 ("Your clips" top right).
 */
@Composable
fun ListGridModeSwitcher(
    mode: LayoutViewMode,
    onModeChange: (LayoutViewMode) -> Unit
) {
    Row(
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // List Icon (☰)
        Box(
            modifier = Modifier
                .size(34.dp)
                .clip(RoundedCornerShape(8.dp))
                .background(if (mode == LayoutViewMode.LIST) SRColors.ElectricBlue.copy(alpha = 0.18f) else Color.Transparent)
                .clickable { onModeChange(LayoutViewMode.LIST) },
            contentAlignment = Alignment.Center
        ) {
            val tint = if (mode == LayoutViewMode.LIST) SRColors.ElectricBlue else SRColors.TextSecondary
            Canvas(Modifier.size(18.dp)) {
                val w = size.width
                val h = size.height
                drawLine(tint, Offset(0f, h * 0.2f), Offset(w, h * 0.2f), strokeWidth = 2.4f, cap = StrokeCap.Round)
                drawLine(tint, Offset(0f, h * 0.5f), Offset(w, h * 0.5f), strokeWidth = 2.4f, cap = StrokeCap.Round)
                drawLine(tint, Offset(0f, h * 0.8f), Offset(w, h * 0.8f), strokeWidth = 2.4f, cap = StrokeCap.Round)
            }
        }

        // Grid Icon (⊞)
        Box(
            modifier = Modifier
                .size(34.dp)
                .clip(RoundedCornerShape(8.dp))
                .background(if (mode == LayoutViewMode.GRID) SRColors.ElectricBlue.copy(alpha = 0.18f) else Color.Transparent)
                .clickable { onModeChange(LayoutViewMode.GRID) },
            contentAlignment = Alignment.Center
        ) {
            val tint = if (mode == LayoutViewMode.GRID) SRColors.ElectricBlue else SRColors.TextSecondary
            Canvas(Modifier.size(17.dp)) {
                val cell = size.width * 0.38f
                val gap = size.width * 0.62f
                val stroke = Stroke(width = 2.2f)
                drawRoundRect(tint, Offset(0f, 0f), Size(cell, cell), CornerRadius(3f, 3f), style = stroke)
                drawRoundRect(tint, Offset(gap, 0f), Size(cell, cell), CornerRadius(3f, 3f), style = stroke)
                drawRoundRect(tint, Offset(0f, gap), Size(cell, cell), CornerRadius(3f, 3f), style = stroke)
                drawRoundRect(tint, Offset(gap, gap), Size(cell, cell), CornerRadius(3f, 3f), style = stroke)
            }
        }
    }
}

/**
 * Blue square download badge (`↓`) in top-right of video cards (matches Screenshot #3).
 */
@Composable
fun BlueDownloadSquareButton(
    isDone: Boolean = false,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .size(32.dp)
            .clip(RoundedCornerShape(8.dp))
            .background(if (isDone) SRColors.EmeraldLive else SRColors.ElectricBlue)
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center
    ) {
        if (isDone) {
            Text("✓", color = Color.White, fontSize = 14.sp, fontWeight = FontWeight.Black)
        } else {
            Canvas(Modifier.size(15.dp)) {
                val w = size.width
                val h = size.height
                drawLine(Color.White, Offset(w * 0.5f, h * 0.1f), Offset(w * 0.5f, h * 0.72f), strokeWidth = 2.4f, cap = StrokeCap.Round)
                drawLine(Color.White, Offset(w * 0.25f, h * 0.50f), Offset(w * 0.5f, h * 0.75f), strokeWidth = 2.4f, cap = StrokeCap.Round)
                drawLine(Color.White, Offset(w * 0.75f, h * 0.50f), Offset(w * 0.5f, h * 0.75f), strokeWidth = 2.4f, cap = StrokeCap.Round)
                drawLine(Color.White, Offset(w * 0.18f, h * 0.92f), Offset(w * 0.82f, h * 0.92f), strokeWidth = 2.4f, cap = StrokeCap.Round)
            }
        }
    }
}

@Composable
fun PulsingRecBadge(label: String = "RECORDING") {
    val transition = rememberInfiniteTransition()
    val alpha by transition.animateFloat(
        initialValue = 0.35f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(tween(750), RepeatMode.Reverse)
    )
    Row(
        modifier = Modifier
            .clip(RoundedCornerShape(50))
            .background(SRColors.HotPink.copy(alpha = 0.22f))
            .border(1.dp, SRColors.HotPink.copy(alpha = 0.65f), RoundedCornerShape(50))
            .padding(horizontal = 9.dp, vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .size(7.dp)
                .clip(CircleShape)
                .background(SRColors.HotPink.copy(alpha = alpha))
        )
        Spacer(Modifier.width(5.dp))
        Text(
            text = label,
            color = Color.White,
            fontSize = 10.sp,
            fontWeight = FontWeight.ExtraBold,
            letterSpacing = 0.4.sp
        )
    }
}

@Composable
fun ScissorsVectorIcon(size: Dp = 16.dp, color: Color = Color.White) {
    Canvas(Modifier.size(size)) {
        val w = this.size.width
        val h = this.size.height
        val stroke = Stroke(width = 2.2f, cap = StrokeCap.Round)
        drawCircle(color, radius = w * 0.16f, center = Offset(w * 0.24f, h * 0.28f), style = stroke)
        drawCircle(color, radius = w * 0.16f, center = Offset(w * 0.24f, h * 0.72f), style = stroke)
        drawLine(color, Offset(w * 0.36f, h * 0.36f), Offset(w * 0.88f, h * 0.78f), strokeWidth = 2.3f, cap = StrokeCap.Round)
        drawLine(color, Offset(w * 0.36f, h * 0.64f), Offset(w * 0.88f, h * 0.22f), strokeWidth = 2.3f, cap = StrokeCap.Round)
    }
}
