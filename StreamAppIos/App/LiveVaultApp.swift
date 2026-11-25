import SwiftUI
import SwiftData
import LiveVaultDatabase
import LiveVaultAppCore

@main
@MainActor
struct LiveVaultApp: App {
    private let databaseService = DatabaseService.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(databaseService.modelContainer)
        }
    }
}
