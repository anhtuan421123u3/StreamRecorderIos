package io.streamrecorder.app

import androidx.compose.ui.window.ComposeUIViewController
import io.streamrecorder.app.platform.IosBridgeRegistry
import io.streamrecorder.app.platform.IosNativeDelegate
import platform.UIKit.UIViewController

fun MainViewController(delegate: IosNativeDelegate? = null): UIViewController {
    if (delegate != null) {
        IosBridgeRegistry.delegate = delegate
    }
    return ComposeUIViewController {
        StreamRecorderApp()
    }
}
