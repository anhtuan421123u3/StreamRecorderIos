package io.streamrecorder.app.data

import io.streamrecorder.app.model.AppSettings
import io.streamrecorder.app.model.ClipItem
import io.streamrecorder.app.model.DetectedWebStream
import io.streamrecorder.app.model.LayoutViewMode
import io.streamrecorder.app.model.RecordingItem
import io.streamrecorder.app.model.RecordingStatus
import io.streamrecorder.app.model.StreamPlatform
import io.streamrecorder.app.model.StreamerProfile
import io.streamrecorder.app.platform.MediaActionCallback
import io.streamrecorder.app.platform.PlatformServices
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import kotlin.math.max
import kotlin.random.Random

class StreamRepository {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private val json = Json {
        ignoreUnknownKeys = true
        encodeDefaults = true
    }

    private val _streamers = MutableStateFlow(loadStreamers())
    val streamers: StateFlow<List<StreamerProfile>> = _streamers.asStateFlow()

    private val _recordings = MutableStateFlow(loadRecordings())
    val recordings: StateFlow<List<RecordingItem>> = _recordings.asStateFlow()

    private val _clips = MutableStateFlow(loadClips())
    val clips: StateFlow<List<ClipItem>> = _clips.asStateFlow()

    private val _settings = MutableStateFlow(loadSettings())
    val settings: StateFlow<AppSettings> = _settings.asStateFlow()

    private val _recordingsViewMode = MutableStateFlow(LayoutViewMode.LIST)
    val recordingsViewMode: StateFlow<LayoutViewMode> = _recordingsViewMode.asStateFlow()

    private val _clipsViewMode = MutableStateFlow(LayoutViewMode.LIST)
    val clipsViewMode: StateFlow<LayoutViewMode> = _clipsViewMode.asStateFlow()

    private val _toastMessage = MutableStateFlow<String?>(null)
    val toastMessage: StateFlow<String?> = _toastMessage.asStateFlow()

    private val _detectedStreams = MutableStateFlow<List<DetectedWebStream>>(emptyList())
    val detectedStreams: StateFlow<List<DetectedWebStream>> = _detectedStreams.asStateFlow()

    init {
        startLiveRecordingTicker()
    }

    private fun startLiveRecordingTicker() {
        scope.launch {
            while (true) {
                delay(1000L)
                _recordings.update { list ->
                    list.map { item ->
                        if (item.status == RecordingStatus.LIVE_RECORDING) {
                            val nextSec = item.durationSeconds + 1
                            val mb = max(12, (nextSec * 0.45).toInt())
                            item.copy(
                                durationSeconds = nextSec,
                                sizeLabel = "$mb MB"
                            )
                        } else {
                            item
                        }
                    }
                }
            }
        }
    }

    fun showToast(message: String) {
        _toastMessage.value = message
        scope.launch {
            delay(3200L)
            if (_toastMessage.value == message) {
                _toastMessage.value = null
            }
        }
    }

    fun toggleMonitorStreamer(streamerId: String) {
        var target: StreamerProfile? = null
        _streamers.update { current ->
            current.map { s ->
                if (s.id == streamerId) {
                    val nextMonitored = !s.isMonitored
                    val nextRecording = nextMonitored && (s.isLiveNow || _settings.value.autoRecordWhenLive)
                    val updated = s.copy(
                        isMonitored = nextMonitored,
                        isActivelyRecording = nextRecording
                    )
                    target = updated
                    updated
                } else {
                    s
                }
            }
        }
        persistStreamers()

        target?.let { st ->
            if (st.isMonitored) {
                val existingLive = _recordings.value.any {
                    it.streamerId == st.id && it.status == RecordingStatus.LIVE_RECORDING
                }
                if (!existingLive && st.isActivelyRecording) {
                    val newRec = RecordingItem(
                        id = "rec_${Random.nextInt(100000, 999999)}",
                        streamerId = st.id,
                        streamerName = st.displayName,
                        streamerHandle = st.handle,
                        platform = st.platform,
                        avatarColorHex = st.avatarColorHex,
                        avatarInitials = st.avatarInitials,
                        title = st.streamTitle,
                        streamUrl = st.streamUrl,
                        durationSeconds = 15,
                        sizeLabel = "12 MB",
                        recordedAtLabel = "LIVE • Auto-Recording",
                        status = RecordingStatus.LIVE_RECORDING,
                        thumbnailAccentHex = st.avatarColorHex
                    )
                    _recordings.update { listOf(newRec) + it }
                    persistRecordings()
                }
                showToast("Auto-recording enabled for ${st.displayName}")
            } else {
                _recordings.update { list ->
                    list.map { r ->
                        if (r.streamerId == st.id && r.status == RecordingStatus.LIVE_RECORDING) {
                            r.copy(status = RecordingStatus.READY, recordedAtLabel = "Just now")
                        } else {
                            r
                        }
                    }
                }
                persistRecordings()
                showToast("Stopped monitoring ${st.displayName}")
            }
        }
    }

    fun addCustomStreamOrChannel(
        nameInput: String,
        urlOrHandleInput: String,
        selectedPlatform: StreamPlatform?
    ): RecordingItem? {
        val trimmedUrl = urlOrHandleInput.trim()
        if (trimmedUrl.isBlank()) return null

        val platform = selectedPlatform ?: StreamPlatform.detectFromInput(trimmedUrl)
        val isDirectMedia = trimmedUrl.contains(".m3u8", ignoreCase = true) ||
            trimmedUrl.contains(".mp4", ignoreCase = true)

        val cleanName = nameInput.trim().ifBlank {
            trimmedUrl
                .substringAfterLast("/")
                .substringBefore("?")
                .substringBefore(".m3u8")
                .substringBefore(".mp4")
                .removePrefix("@")
                .ifBlank { "${platform.displayName} Stream" }
        }
        val initials = cleanName.take(2).uppercase()
        val playableUrl = if (trimmedUrl.startsWith("http://") || trimmedUrl.startsWith("https://")) {
            if (isDirectMedia) trimmedUrl else SeedData.SAMPLE_HLS_1
        } else {
            SeedData.SAMPLE_MP4_1
        }

        val streamerId = "st_${Random.nextInt(10000, 99999)}"
        val newStreamer = StreamerProfile(
            id = streamerId,
            displayName = cleanName,
            handle = if (trimmedUrl.startsWith("http")) "@${cleanName.lowercase().replace(" ", "")}" else trimmedUrl,
            platform = platform,
            avatarColorHex = platform.brandColorHex,
            avatarInitials = initials,
            recordingsCountBadge = "1",
            isMonitored = true,
            isLiveNow = true,
            isActivelyRecording = true,
            streamUrl = playableUrl,
            streamTitle = if (isDirectMedia) "Direct HLS/MP4 Live Capture ($cleanName)" else "$cleanName Live Broadcast",
            viewerCount = "LIVE"
        )

        _streamers.update { listOf(newStreamer) + it }
        persistStreamers()

        val newRecording = RecordingItem(
            id = "rec_${Random.nextInt(100000, 999999)}",
            streamerId = streamerId,
            streamerName = newStreamer.displayName,
            streamerHandle = newStreamer.handle,
            platform = platform,
            avatarColorHex = platform.brandColorHex,
            avatarInitials = initials,
            title = newStreamer.streamTitle,
            streamUrl = playableUrl,
            durationSeconds = 5,
            sizeLabel = "14 MB",
            recordedAtLabel = "LIVE • Capturing",
            status = RecordingStatus.LIVE_RECORDING,
            thumbnailAccentHex = platform.brandColorHex
        )

        _recordings.update { listOf(newRecording) + it }
        persistRecordings()

        if (isDirectMedia) {
            downloadRecordingToDevice(newRecording.id)
        } else {
            showToast("Monitoring & recording ${newStreamer.displayName}!")
        }
        return newRecording
    }

    fun stopLiveRecording(recordingId: String) {
        _recordings.update { list ->
            list.map { item ->
                if (item.id == recordingId && item.status == RecordingStatus.LIVE_RECORDING) {
                    item.copy(status = RecordingStatus.READY, recordedAtLabel = "Saved • Just now")
                } else {
                    item
                }
            }
        }
        persistRecordings()
        showToast("Recording finalized & archived in HD")
    }

    fun downloadRecordingToDevice(recordingId: String) {
        val rec = _recordings.value.find { it.id == recordingId } ?: return
        _recordings.update { list ->
            list.map {
                if (it.id == recordingId) it.copy(status = RecordingStatus.DOWNLOADING, downloadProgress = 0.05f) else it
            }
        }
        showToast("Downloading HD video to device...")

        val safeFileName = "${rec.streamerName.replace(" ", "_")}_${rec.id}"
        PlatformServices.downloadStreamToLocal(
            recordingId = rec.id,
            streamUrl = rec.streamUrl,
            suggestedFileName = safeFileName,
            callback = object : MediaActionCallback {
                override fun onProgress(progress: Float) {
                    scope.launch {
                        _recordings.update { list ->
                            list.map {
                                if (it.id == recordingId) it.copy(downloadProgress = progress.coerceIn(0f, 1f)) else it
                            }
                        }
                    }
                }

                override fun onCompleted(success: Boolean, resultPathOrMessage: String) {
                    scope.launch {
                        if (success) {
                            _recordings.update { list ->
                                list.map {
                                    if (it.id == recordingId) {
                                        it.copy(
                                            status = RecordingStatus.READY,
                                            localFilePath = resultPathOrMessage,
                                            downloadProgress = 1f,
                                            recordedAtLabel = "Downloaded • Offline HD"
                                        )
                                    } else {
                                        it
                                    }
                                }
                            }
                            persistRecordings()
                            showToast("Saved offline to iPhone Recordings!")
                        } else {
                            _recordings.update { list ->
                                list.map {
                                    if (it.id == recordingId) it.copy(status = RecordingStatus.READY, downloadProgress = 0f) else it
                                }
                            }
                            showToast("Download note: $resultPathOrMessage")
                        }
                    }
                }
            }
        )
    }

    fun deleteRecording(recordingId: String) {
        _recordings.update { list -> list.filterNot { it.id == recordingId } }
        persistRecordings()
        showToast("Recording removed")
    }

    fun createClipFromRecording(
        recording: RecordingItem,
        clipTitle: String,
        startSec: Double,
        endSec: Double,
        onFinished: (Boolean, ClipItem?) -> Unit
    ) {
        val safeStart = max(0.0, startSec)
        val safeEnd = max(safeStart + 1.0, endSec)
        val clipId = "clip_${Random.nextInt(100000, 999999)}"
        val finalTitle = clipTitle.trim().ifBlank { "${recording.streamerName} Clip" }

        PlatformServices.trimVideoClip(
            sourceUrlOrPath = recording.effectivePlayablePath,
            startSec = safeStart,
            endSec = safeEnd,
            outputClipName = clipId,
            callback = object : MediaActionCallback {
                override fun onProgress(progress: Float) = Unit

                override fun onCompleted(success: Boolean, resultPathOrMessage: String) {
                    scope.launch {
                        val exportedPath = if (success && resultPathOrMessage.isNotBlank()) {
                            resultPathOrMessage
                        } else {
                            recording.effectivePlayablePath
                        }
                        val newClip = ClipItem(
                            id = clipId,
                            sourceRecordingId = recording.id,
                            streamerName = recording.streamerName,
                            streamerHandle = recording.streamerHandle,
                            platform = recording.platform,
                            avatarColorHex = recording.avatarColorHex,
                            avatarInitials = recording.avatarInitials,
                            title = finalTitle,
                            videoUrlOrPath = exportedPath,
                            startSec = safeStart,
                            endSec = safeEnd,
                            durationSeconds = (safeEnd - safeStart).toInt().coerceAtLeast(1),
                            createdAtLabel = "Just now",
                            thumbnailAccentHex = recording.thumbnailAccentHex
                        )
                        _clips.update { listOf(newClip) + it }
                        persistClips()
                        showToast(
                            if (success) "Clip exported to MP4 & saved to Your clips!"
                            else "Clip bookmarked in Your clips ($resultPathOrMessage)"
                        )
                        onFinished(true, newClip)
                    }
                }
            }
        )
    }

    fun renameClip(clipId: String, newTitle: String) {
        val trimmed = newTitle.trim()
        if (trimmed.isBlank()) return
        _clips.update { list ->
            list.map { if (it.id == clipId) it.copy(title = trimmed) else it }
        }
        persistClips()
        showToast("Clip title updated")
    }

    fun deleteClip(clipId: String) {
        _clips.update { list -> list.filterNot { it.id == clipId } }
        persistClips()
        showToast("Clip deleted")
    }

    fun saveClipToPhotosLibrary(clip: ClipItem) {
        showToast("Saving clip to iPhone Photos...")
        PlatformServices.saveVideoToPhotos(
            filePathOrUrl = clip.videoUrlOrPath,
            callback = object : MediaActionCallback {
                override fun onProgress(progress: Float) = Unit
                override fun onCompleted(success: Boolean, resultPathOrMessage: String) {
                    scope.launch {
                        if (success) {
                            _clips.update { list ->
                                list.map { if (it.id == clip.id) it.copy(savedToPhotos = true) else it }
                            }
                            persistClips()
                            showToast("Saved clip directly to Photos Library!")
                        } else {
                            showToast(resultPathOrMessage)
                        }
                    }
                }
            }
        )
    }

    fun shareClip(clip: ClipItem) {
        PlatformServices.shareMediaItem(clip.videoUrlOrPath, clip.title)
    }

    fun onWebStreamSniffed(stream: DetectedWebStream) {
        _detectedStreams.update { existing ->
            if (existing.any { it.url == stream.url }) existing else listOf(stream) + existing
        }
    }

    fun clearSniffedStreams() {
        _detectedStreams.value = emptyList()
    }

    fun setRecordingsViewMode(mode: LayoutViewMode) {
        _recordingsViewMode.value = mode
    }

    fun setClipsViewMode(mode: LayoutViewMode) {
        _clipsViewMode.value = mode
    }

    fun updateSettings(transform: (AppSettings) -> AppSettings) {
        _settings.update(transform)
        persistSettings()
    }

    fun clearOfflineStorage() {
        PlatformServices.clearLocalDownloads()
        _recordings.update { list ->
            list.map { it.copy(localFilePath = null, downloadProgress = 0f) }
        }
        persistRecordings()
        showToast("Cleared local video cache")
    }

    private fun loadStreamers(): List<StreamerProfile> {
        val raw = PlatformServices.loadPersistedString(KEY_STREAMERS) ?: return SeedData.defaultStreamers
        return runCatching { json.decodeFromString<List<StreamerProfile>>(raw) }
            .getOrDefault(SeedData.defaultStreamers)
    }

    private fun persistStreamers() {
        runCatching {
            PlatformServices.savePersistedString(KEY_STREAMERS, json.encodeToString(_streamers.value))
        }
    }

    private fun loadRecordings(): List<RecordingItem> {
        val raw = PlatformServices.loadPersistedString(KEY_RECORDINGS) ?: return SeedData.defaultRecordings
        return runCatching { json.decodeFromString<List<RecordingItem>>(raw) }
            .getOrDefault(SeedData.defaultRecordings)
    }

    private fun persistRecordings() {
        runCatching {
            PlatformServices.savePersistedString(KEY_RECORDINGS, json.encodeToString(_recordings.value))
        }
    }

    private fun loadClips(): List<ClipItem> {
        val raw = PlatformServices.loadPersistedString(KEY_CLIPS) ?: return SeedData.defaultClips
        return runCatching { json.decodeFromString<List<ClipItem>>(raw) }
            .getOrDefault(SeedData.defaultClips)
    }

    private fun persistClips() {
        runCatching {
            PlatformServices.savePersistedString(KEY_CLIPS, json.encodeToString(_clips.value))
        }
    }

    private fun loadSettings(): AppSettings {
        val raw = PlatformServices.loadPersistedString(KEY_SETTINGS) ?: return AppSettings()
        return runCatching { json.decodeFromString<AppSettings>(raw) }
            .getOrDefault(AppSettings())
    }

    private fun persistSettings() {
        runCatching {
            PlatformServices.savePersistedString(KEY_SETTINGS, json.encodeToString(_settings.value))
        }
    }

    companion object {
        private const val KEY_STREAMERS = "sr_streamers_v1"
        private const val KEY_RECORDINGS = "sr_recordings_v1"
        private const val KEY_CLIPS = "sr_clips_v1"
        private const val KEY_SETTINGS = "sr_settings_v1"
    }
}
