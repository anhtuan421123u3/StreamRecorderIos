package io.streamrecorder.app.platform

import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.viewinterop.UIKitViewController
import io.streamrecorder.app.model.DetectedWebStream
import platform.Foundation.NSUserDefaults
import platform.UIKit.UIViewController

interface IosPlaybackListener {
    fun onTimeUpdate(currentSec: Double, durationSec: Double)
}

interface IosSnifferListener {
    fun onStreamDetected(url: String, typeLabel: String, pageTitle: String)
    fun onUrlChanged(currentUrl: String)
}

interface IosTaskListener {
    fun onProgress(progress: Float)
    fun onFinished(success: Boolean, pathOrMessage: String)
}

interface IosNativeDelegate {
    fun createPlayerViewController(
        urlOrPath: String,
        autoPlay: Boolean,
        listener: IosPlaybackListener
    ): UIViewController

    fun updatePlayerState(
        controller: UIViewController,
        urlOrPath: String,
        isPlaying: Boolean,
        seekSeconds: Double
    )

    fun releasePlayer(controller: UIViewController)

    fun createWebSnifferViewController(
        initialUrl: String,
        listener: IosSnifferListener
    ): UIViewController

    fun loadUrlInSniffer(controller: UIViewController, url: String)

    fun downloadStream(
        recordingId: String,
        streamUrl: String,
        suggestedFileName: String,
        listener: IosTaskListener
    )

    fun trimClipToMp4(
        sourceUrlOrPath: String,
        startSec: Double,
        endSec: Double,
        outputClipName: String,
        listener: IosTaskListener
    )

    fun saveVideoToPhotoLibrary(
        filePathOrUrl: String,
        listener: IosTaskListener
    )

    fun shareItem(filePathOrUrl: String, title: String)
    fun getStorageSummary(): String
    fun clearDownloadsDirectory(): Boolean
}

object IosBridgeRegistry {
    var delegate: IosNativeDelegate? = null
}

@Composable
actual fun NativeVideoPlayer(
    urlOrPath: String,
    isPlaying: Boolean,
    seekRequestSec: Double?,
    onProgress: (currentSec: Double, durationSec: Double) -> Unit,
    modifier: Modifier
) {
    val playbackListener = remember(urlOrPath) {
        object : IosPlaybackListener {
            override fun onTimeUpdate(currentSec: Double, durationSec: Double) {
                onProgress(currentSec, durationSec)
            }
        }
    }

    UIKitViewController(
        factory = {
            IosBridgeRegistry.delegate?.createPlayerViewController(
                urlOrPath = urlOrPath,
                autoPlay = isPlaying,
                listener = playbackListener
            ) ?: UIViewController()
        },
        modifier = modifier,
        update = { vc ->
            IosBridgeRegistry.delegate?.updatePlayerState(
                controller = vc,
                urlOrPath = urlOrPath,
                isPlaying = isPlaying,
                seekSeconds = seekRequestSec ?: -1.0
            )
        },
        onRelease = { vc ->
            IosBridgeRegistry.delegate?.releasePlayer(vc)
        }
    )
}

@Composable
actual fun NativeWebStreamSniffer(
    initialUrl: String,
    reloadTrigger: Int,
    onStreamDetected: (DetectedWebStream) -> Unit,
    onUrlChanged: (String) -> Unit,
    modifier: Modifier
) {
    val snifferListener = remember {
        object : IosSnifferListener {
            override fun onStreamDetected(url: String, typeLabel: String, pageTitle: String) {
                onStreamDetected(DetectedWebStream(url = url, typeLabel = typeLabel, pageTitle = pageTitle))
            }

            override fun onUrlChanged(currentUrl: String) {
                onUrlChanged(currentUrl)
            }
        }
    }

    UIKitViewController(
        factory = {
            IosBridgeRegistry.delegate?.createWebSnifferViewController(
                initialUrl = initialUrl,
                listener = snifferListener
            ) ?: UIViewController()
        },
        modifier = modifier,
        update = { vc ->
            if (reloadTrigger > 0) {
                IosBridgeRegistry.delegate?.loadUrlInSniffer(vc, initialUrl)
            }
        }
    )
}

actual object PlatformServices {
    private val defaults: NSUserDefaults
        get() = NSUserDefaults.standardUserDefaults

    actual fun loadPersistedString(key: String): String? = defaults.stringForKey(key)

    actual fun savePersistedString(key: String, value: String) {
        defaults.setObject(value, forKey = key)
    }

    actual fun downloadStreamToLocal(
        recordingId: String,
        streamUrl: String,
        suggestedFileName: String,
        callback: MediaActionCallback
    ) {
        val d = IosBridgeRegistry.delegate
        if (d == null) {
            callback.onCompleted(false, "Native iOS media engine unavailable")
            return
        }
        d.downloadStream(
            recordingId = recordingId,
            streamUrl = streamUrl,
            suggestedFileName = suggestedFileName,
            listener = object : IosTaskListener {
                override fun onProgress(progress: Float) = callback.onProgress(progress)
                override fun onFinished(success: Boolean, pathOrMessage: String) =
                    callback.onCompleted(success, pathOrMessage)
            }
        )
    }

    actual fun trimVideoClip(
        sourceUrlOrPath: String,
        startSec: Double,
        endSec: Double,
        outputClipName: String,
        callback: MediaActionCallback
    ) {
        val d = IosBridgeRegistry.delegate
        if (d == null) {
            callback.onCompleted(false, "Native clip exporter unavailable")
            return
        }
        d.trimClipToMp4(
            sourceUrlOrPath = sourceUrlOrPath,
            startSec = startSec,
            endSec = endSec,
            outputClipName = outputClipName,
            listener = object : IosTaskListener {
                override fun onProgress(progress: Float) = callback.onProgress(progress)
                override fun onFinished(success: Boolean, pathOrMessage: String) =
                    callback.onCompleted(success, pathOrMessage)
            }
        )
    }

    actual fun saveVideoToPhotos(
        filePathOrUrl: String,
        callback: MediaActionCallback
    ) {
        val d = IosBridgeRegistry.delegate
        if (d == null) {
            callback.onCompleted(false, "Photos bridge unavailable")
            return
        }
        d.saveVideoToPhotoLibrary(
            filePathOrUrl = filePathOrUrl,
            listener = object : IosTaskListener {
                override fun onProgress(progress: Float) = callback.onProgress(progress)
                override fun onFinished(success: Boolean, pathOrMessage: String) =
                    callback.onCompleted(success, pathOrMessage)
            }
        )
    }

    actual fun shareMediaItem(filePathOrUrl: String, title: String) {
        IosBridgeRegistry.delegate?.shareItem(filePathOrUrl, title)
    }

    actual fun getLocalStorageSummary(): String =
        IosBridgeRegistry.delegate?.getStorageSummary() ?: "Documents/Recordings & Clips ready"

    actual fun clearLocalDownloads(): Boolean =
        IosBridgeRegistry.delegate?.clearDownloadsDirectory() ?: true
}
