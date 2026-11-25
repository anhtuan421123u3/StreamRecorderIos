package io.streamrecorder.app.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import io.streamrecorder.app.model.DetectedWebStream
import io.streamrecorder.app.platform.NativeWebStreamSniffer
import io.streamrecorder.app.theme.SRColors

@Composable
fun WebSnifferModal(
    detectedStreams: List<DetectedWebStream>,
    onStreamDetected: (DetectedWebStream) -> Unit,
    onRecordStream: (DetectedWebStream) -> Unit,
    onClose: () -> Unit
) {
    var addressInput by remember { mutableStateOf("https://www.twitch.tv") }
    var activeUrl by remember { mutableStateOf("https://www.twitch.tv") }
    var reloadCount by remember { mutableStateOf(0) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(SRColors.BgDeepCosmos)
    ) {
        // Top Browser Toolbar
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 14.dp, vertical = 10.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Box(
                modifier = Modifier
                    .clip(RoundedCornerShape(10.dp))
                    .background(SRColors.BgCardElevated)
                    .clickable(onClick = onClose)
                    .padding(horizontal = 12.dp, vertical = 9.dp)
            ) {
                Text("✕ Close", color = Color.White, fontSize = 12.sp, fontWeight = FontWeight.Bold)
            }

            OutlinedTextField(
                value = addressInput,
                onValueChange = { addressInput = it },
                singleLine = true,
                placeholder = { Text("Enter live stream page URL...", color = SRColors.TextMuted, fontSize = 12.sp) },
                shape = RoundedCornerShape(12.dp),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedContainerColor = SRColors.BgInput,
                    unfocusedContainerColor = SRColors.BgInput,
                    focusedTextColor = Color.White,
                    unfocusedTextColor = Color.White,
                    focusedBorderColor = SRColors.ElectricBlue,
                    unfocusedBorderColor = SRColors.BorderSubtle
                ),
                modifier = Modifier.weight(1f)
            )

            Box(
                modifier = Modifier
                    .clip(RoundedCornerShape(10.dp))
                    .background(SRColors.ElectricBlue)
                    .clickable {
                        val normalized = if (addressInput.startsWith("http://") || addressInput.startsWith("https://")) {
                            addressInput.trim()
                        } else {
                            "https://${addressInput.trim()}"
                        }
                        addressInput = normalized
                        activeUrl = normalized
                        reloadCount += 1
                    }
                    .padding(horizontal = 14.dp, vertical = 10.dp)
            ) {
                Text("Go", color = Color.White, fontSize = 13.sp, fontWeight = FontWeight.ExtraBold)
            }
        }

        // Detected HLS / MP4 Live Streams Drawer
        if (detectedStreams.isNotEmpty()) {
            LazyColumn(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(132.dp)
                    .background(Color(0xFF130F2A))
                    .padding(horizontal = 14.dp, vertical = 8.dp),
                verticalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                items(detectedStreams, key = { it.url }) { stream ->
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(10.dp))
                            .background(SRColors.BgCardElevated)
                            .border(1.dp, SRColors.HotPink.copy(alpha = 0.65f), RoundedCornerShape(10.dp))
                            .padding(horizontal = 10.dp, vertical = 8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column(modifier = Modifier.weight(1f)) {
                            Text(
                                text = "● ${stream.typeLabel} — ${stream.pageTitle}",
                                color = Color.White,
                                fontSize = 12.sp,
                                fontWeight = FontWeight.Bold,
                                maxLines = 1,
                                overflow = TextOverflow.Ellipsis
                            )
                            Text(
                                text = stream.url,
                                color = SRColors.TextSecondary,
                                fontSize = 10.sp,
                                maxLines = 1,
                                overflow = TextOverflow.Ellipsis
                            )
                        }
                        Spacer(Modifier.width(8.dp))
                        Box(
                            modifier = Modifier
                                .clip(RoundedCornerShape(8.dp))
                                .background(SRColors.ElectricBlue)
                                .clickable { onRecordStream(stream) }
                                .padding(horizontal = 11.dp, vertical = 6.dp)
                        ) {
                            Text("RECORD", color = Color.White, fontSize = 11.sp, fontWeight = FontWeight.Black)
                        }
                    }
                }
            }
        } else {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(Color(0xFF120E28))
                    .padding(horizontal = 14.dp, vertical = 7.dp)
            ) {
                Text(
                    text = "Sniffer active: Open any live stream page — .m3u8 & .mp4 streams appear here automatically.",
                    color = SRColors.ElectricBlueLight,
                    fontSize = 11.sp
                )
            }
        }

        NativeWebStreamSniffer(
            initialUrl = activeUrl,
            reloadTrigger = reloadCount,
            onStreamDetected = onStreamDetected,
            onUrlChanged = { addressInput = it },
            modifier = Modifier
                .fillMaxWidth()
                .weight(1f)
        )
    }
}
