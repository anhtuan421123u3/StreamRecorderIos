package io.streamrecorder.app.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import io.streamrecorder.app.model.AppSettings
import io.streamrecorder.app.platform.PlatformServices
import io.streamrecorder.app.theme.SRColors
import io.streamrecorder.app.ui.components.StreamRecorderWordmark

@Composable
fun SettingsScreen(
    settings: AppSettings,
    monitoredCount: Int,
    recordingsCount: Int,
    clipsCount: Int,
    onUpdateSettings: ((AppSettings) -> AppSettings) -> Unit,
    onClearCache: () -> Unit
) {
    val storageSummary = remember(recordingsCount, clipsCount) {
        PlatformServices.getLocalStorageSummary()
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 18.dp, vertical = 14.dp)
            .padding(bottom = 86.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        StreamRecorderWordmark()

        // Stats Summary Card
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(16.dp))
                .background(SRColors.BgCardElevated)
                .border(1.dp, SRColors.ElectricBlue.copy(alpha = 0.45f), RoundedCornerShape(16.dp))
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceEvenly
        ) {
            StatColumn(value = "$monitoredCount", label = "Monitored")
            StatColumn(value = "$recordingsCount", label = "Recordings")
            StatColumn(value = "$clipsCount", label = "Saved Clips")
        }

        // Auto Recording Preferences
        SettingsGroupCard(title = "Automatic Stream Capture") {
            SettingToggleRow(
                title = "Auto-Record Lives",
                subtitle = "Automatically capture broadcasts when monitored creators go live",
                checked = settings.autoRecordWhenLive,
                onCheckedChange = { v -> onUpdateSettings { it.copy(autoRecordWhenLive = v) } }
            )
            SettingToggleRow(
                title = "Offline Cloud Recording",
                subtitle = "Continue scheduled recording sessions even when phone is offline",
                checked = settings.offlineCloudBackup,
                onCheckedChange = { v -> onUpdateSettings { it.copy(offlineCloudBackup = v) } }
            )
            SettingToggleRow(
                title = "Live Start Notifications",
                subtitle = "Alert when monitored Twitch, Kick, TikTok or YouTube channels go live",
                checked = settings.pushNotificationsEnabled,
                onCheckedChange = { v -> onUpdateSettings { it.copy(pushNotificationsEnabled = v) } }
            )
            SettingToggleRow(
                title = "Wi-Fi Only Offline Downloads",
                subtitle = "Restrict heavy MP4 downloads to Wi-Fi connections",
                checked = settings.wifiOnlyDownload,
                onCheckedChange = { v -> onUpdateSettings { it.copy(wifiOnlyDownload = v) } }
            )
        }

        // Video Quality Selector
        SettingsGroupCard(title = "Recording Quality") {
            val qualities = listOf("1080p60 HD (Source)", "1080p HD", "720p60 Balanced")
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .horizontalScroll(rememberScrollState()),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                qualities.forEach { q ->
                    val selected = settings.preferredQuality == q
                    Box(
                        modifier = Modifier
                            .clip(RoundedCornerShape(10.dp))
                            .background(if (selected) SRColors.ElectricBlue else SRColors.BgDeepCosmos)
                            .border(
                                1.dp,
                                if (selected) SRColors.ElectricBlueLight else SRColors.BorderSubtle,
                                RoundedCornerShape(10.dp)
                            )
                            .clickable { onUpdateSettings { it.copy(preferredQuality = q) } }
                            .padding(horizontal = 10.dp, vertical = 8.dp)
                    ) {
                        Text(
                            text = q,
                            color = if (selected) Color.White else SRColors.TextSecondary,
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }
            }
        }

        // Storage & Finder / iTunes File Sharing
        SettingsGroupCard(title = "iPhone Storage & File Export") {
            Text(
                text = storageSummary,
                color = Color.White,
                fontSize = 13.sp,
                fontWeight = FontWeight.SemiBold
            )
            Spacer(Modifier.height(4.dp))
            Text(
                text = "iTunes / macOS Finder File Sharing is enabled. Connect your iPhone to access exported MP4 recordings and clips directly under StreamRecorder.",
                color = SRColors.TextSecondary,
                fontSize = 12.sp
            )
            Spacer(Modifier.height(10.dp))
            Box(
                modifier = Modifier
                    .clip(RoundedCornerShape(10.dp))
                    .background(SRColors.HotPink.copy(alpha = 0.18f))
                    .border(1.dp, SRColors.HotPink.copy(alpha = 0.5f), RoundedCornerShape(10.dp))
                    .clickable(onClick = onClearCache)
                    .padding(horizontal = 14.dp, vertical = 9.dp)
            ) {
                Text(
                    text = "Clear Local Video Cache",
                    color = SRColors.HotPinkGlow,
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Bold
                )
            }
        }

        // App Store Legal Disclaimer
        SettingsGroupCard(title = "Disclaimer & Compliance") {
            Text(
                text = "StreamRecorder is an independent tool and is not affiliated with or endorsed by Twitch, Kick, TikTok, YouTube, SOOP, BiliBili, or any social media platform.\n\nPlease ensure you have permission before recording or sharing any video content. Use responsibly and in accordance with local laws and platform policies.\n\n© StreamRecorder.io — Built with Kotlin Multiplatform & Native iOS AVFoundation.",
                color = SRColors.TextSecondary,
                fontSize = 11.sp,
                lineHeight = 16.sp
            )
        }
    }
}

@Composable
private fun StatColumn(value: String, label: String) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(value, color = Color.White, fontSize = 22.sp, fontWeight = FontWeight.Black)
        Text(label, color = SRColors.TextSecondary, fontSize = 11.sp)
    }
}

@Composable
private fun SettingsGroupCard(
    title: String,
    content: @Composable () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(SRColors.BgCard)
            .border(1.dp, SRColors.BorderSubtle, RoundedCornerShape(16.dp))
            .padding(16.dp)
    ) {
        Text(
            text = title,
            color = SRColors.ElectricBlueLight,
            fontSize = 13.sp,
            fontWeight = FontWeight.ExtraBold
        )
        Spacer(Modifier.height(10.dp))
        content()
    }
}

@Composable
private fun SettingToggleRow(
    title: String,
    subtitle: String,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 6.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(modifier = Modifier.weight(1f).padding(end = 10.dp)) {
            Text(title, color = Color.White, fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
            Text(subtitle, color = SRColors.TextSecondary, fontSize = 11.sp)
        }
        Switch(
            checked = checked,
            onCheckedChange = onCheckedChange,
            colors = SwitchDefaults.colors(
                checkedThumbColor = Color.White,
                checkedTrackColor = SRColors.ElectricBlue,
                uncheckedThumbColor = SRColors.TextSecondary,
                uncheckedTrackColor = SRColors.BgDeepCosmos
            )
        )
    }
}
