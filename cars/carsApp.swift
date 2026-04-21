import SwiftUI
import SwiftData

@main
struct carsApp: App {
    @StateObject private var syncService = SyncService.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(syncService)
        }
        .modelContainer(for: Car.self)
    }
}
