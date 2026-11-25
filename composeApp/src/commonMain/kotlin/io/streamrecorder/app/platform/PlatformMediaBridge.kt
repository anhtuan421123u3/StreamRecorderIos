package io.streamrecorder.app.platform

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import io.streamrecorder.app.model.DetectedWebStream

interface MediaActionCallback {
    fun onProgress(progress: Float)
    fun onCompleted(success: Boolean, resultPathOrMessage: String)
}

@Composable
expect fun NativeVideoPlayer(
    urlOrPath: String,
    isPlaying: Boolean,
    seekRequestSec: Double?,
    onProgress: (currentSec: Double, durationSec: Double) -> Unit,
    modifier: Modifier = Modifier
)

@Composable
expect fun NativeWebStreamSniffer(
    initialUrl: String,
    reloadTrigger: Int,
    onStreamDetected: (DetectedWebStream) -> Unit,
    onUrlChanged: (String) -> Unit,
    modifier: Modifier = Modifier
)

expect object PlatformServices {
    fun loadPersistedString(key: String): String?
    fun savePersistedString(key: String, value: String)
    fun downloadStreamToLocal(
        recordingId: String,
        streamUrl: String,
        suggestedFileName: String,
        callback: MediaActionCallback
    )
    fun trimVideoClip(
        sourceUrlOrPath: String,
        startSec: Double,
        endSec: Double,
        outputClipName: String,
        callback: MediaActionCallback
    )
    fun saveVideoToPhotos(
        filePathOrUrl: String,
        callback: MediaActionCallback
    )
    fun shareMediaItem(filePathOrUrl: String, title: String)
    fun getLocalStorageSummary(): String
    fun clearLocalDownloads(): Boolean
}
