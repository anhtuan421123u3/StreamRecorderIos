package io.streamrecorder.app.platform

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import io.streamrecorder.app.model.DetectedWebStream

@Composable
actual fun NativeVideoPlayer(
    urlOrPath: String,
    isPlaying: Boolean,
    seekRequestSec: Double?,
    onProgress: (currentSec: Double, durationSec: Double) -> Unit,
    modifier: Modifier
) {
    Box(modifier = modifier.background(Color.Black), contentAlignment = Alignment.Center) {
        Text("Video Player Preview ($urlOrPath)", color = Color.White)
    }
}

@Composable
actual fun NativeWebStreamSniffer(
    initialUrl: String,
    reloadTrigger: Int,
    onStreamDetected: (DetectedWebStream) -> Unit,
    onUrlChanged: (String) -> Unit,
    modifier: Modifier
) {
    Box(modifier = modifier.background(Color(0xFF0E0C22)), contentAlignment = Alignment.Center) {
        Text("Web Stream Sniffer ($initialUrl)", color = Color.White)
    }
}

actual object PlatformServices {
    private val memoryStore = mutableMapOf<String, String>()

    actual fun loadPersistedString(key: String): String? = memoryStore[key]

    actual fun savePersistedString(key: String, value: String) {
        memoryStore[key] = value
    }

    actual fun downloadStreamToLocal(
        recordingId: String,
        streamUrl: String,
        suggestedFileName: String,
        callback: MediaActionCallback
    ) {
        callback.onProgress(1f)
        callback.onCompleted(true, streamUrl)
    }

    actual fun trimVideoClip(
        sourceUrlOrPath: String,
        startSec: Double,
        endSec: Double,
        outputClipName: String,
        callback: MediaActionCallback
    ) {
        callback.onCompleted(true, sourceUrlOrPath)
    }

    actual fun saveVideoToPhotos(
        filePathOrUrl: String,
        callback: MediaActionCallback
    ) {
        callback.onCompleted(true, "Saved")
    }

    actual fun shareMediaItem(filePathOrUrl: String, title: String) = Unit

    actual fun getLocalStorageSummary(): String = "Desktop Verification Mode"

    actual fun clearLocalDownloads(): Boolean = true
}
