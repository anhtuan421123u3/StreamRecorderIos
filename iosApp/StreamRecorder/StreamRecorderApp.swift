import SwiftUI
import UIKit
import ComposeApp

struct ComposeRootContainer: UIViewControllerRepresentable {
    private let mediaEngine = NativeMediaEngine.shared

    func makeUIViewController(context: Context) -> UIViewController {
        MainViewControllerKt.MainViewController(delegate: mediaEngine)
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

@main
struct StreamRecorderIosApp: App {
    var body: some Scene {
        WindowGroup {
            ComposeRootContainer()
                .ignoresSafeArea()
                .preferredColorScheme(.dark)
        }
    }
}
