import SwiftUI
import SwiftData
import LiveVaultDatabase

@main
public struct LiveVaultApp: App {
    private let databaseService = DatabaseService.shared
    
    public init() {}
    
    public var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(databaseService.modelContainer)
        }
    }
}
