package io.streamrecorder.app.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color

object SRColors {
    // Authentic StreamRecorder.io Cosmic Dark Palette (from App Store ID 6754601768)
    val BgDeepCosmos = Color(0xFF070612)
    val BgNebulaTop = Color(0xFF141036)
    val BgCard = Color(0xFF121024)
    val BgCardElevated = Color(0xFF1A1733)
    val BgInput = Color(0xFF17142D)
    val BorderSubtle = Color(0xFF28244A)
    val BorderActiveBlue = Color(0xFF5B6CFF)

    // Brand Accents
    val ElectricBlue = Color(0xFF5B6CFF)      // Primary "RECORD" & "Clip" button blue/periwinkle
    val ElectricBlueLight = Color(0xFF7B8BFF)
    val RoyalSavePurple = Color(0xFF6839FF)   // "Save ▷" badge purple
    val HotPink = Color(0xFFFF2E88)           // Center record dot & highlight border
    val HotPinkGlow = Color(0xFFFF5CA4)
    val EmeraldLive = Color(0xFF18E299)
    val AmberWarn = Color(0xFFFFB020)

    // Typography Colors
    val TextPrimary = Color(0xFFF9FAFF)
    val TextSecondary = Color(0xFFA3A0C2)
    val TextMuted = Color(0xFF69658B)
}

private val SRDarkColorScheme = darkColorScheme(
    primary = SRColors.ElectricBlue,
    onPrimary = Color.White,
    secondary = SRColors.HotPink,
    onSecondary = Color.White,
    background = SRColors.BgDeepCosmos,
    onBackground = SRColors.TextPrimary,
    surface = SRColors.BgCard,
    onSurface = SRColors.TextPrimary,
    surfaceVariant = SRColors.BgCardElevated,
    onSurfaceVariant = SRColors.TextSecondary,
    outline = SRColors.BorderSubtle
)

@Composable
fun StreamRecorderTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = SRDarkColorScheme,
        content = content
    )
}

/**
 * Draws the signature deep purple-indigo cosmos gradient + subtle starfield dots
 * seen in the official StreamRecorder App Store screens.
 */
fun Modifier.cosmicStarfieldBackground(): Modifier = this.drawBehind {
    drawRect(
        brush = Brush.verticalGradient(
            colors = listOf(
                SRColors.BgNebulaTop,
                Color(0xFF0B091D),
                SRColors.BgDeepCosmos
            )
        )
    )

    // Subtle radial nebula glow in upper center
    drawCircle(
        brush = Brush.radialGradient(
            colors = listOf(
                SRColors.ElectricBlue.copy(alpha = 0.14f),
                Color.Transparent
            ),
            center = Offset(size.width * 0.5f, size.height * 0.14f),
            radius = size.width * 0.7f
        ),
        center = Offset(size.width * 0.5f, size.height * 0.14f),
        radius = size.width * 0.7f
    )

    // Deterministic subtle star points
    val starSeeds = listOf(
        0.12f to 0.06f, 0.84f to 0.08f, 0.31f to 0.14f, 0.68f to 0.19f,
        0.08f to 0.27f, 0.91f to 0.31f, 0.45f to 0.24f, 0.22f to 0.42f,
        0.77f to 0.48f, 0.15f to 0.65f, 0.88f to 0.72f, 0.56f to 0.83f
    )
    starSeeds.forEachIndexed { index, (rx, ry) ->
        val alpha = if (index % 3 == 0) 0.35f else 0.18f
        val radius = if (index % 4 == 0) 2.2f else 1.4f
        drawCircle(
            color = Color.White.copy(alpha = alpha),
            radius = radius,
            center = Offset(size.width * rx, size.height * ry)
        )
    }
}

fun formatDurationClock(totalSeconds: Int): String {
    val safe = totalSeconds.coerceAtLeast(0)
    val h = safe / 3600
    val m = (safe % 3600) / 60
    val s = safe % 60
    return if (h > 0) {
        "${h.toString().padStart(2, '0')}:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}"
    } else {
        "${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}"
    }
}
