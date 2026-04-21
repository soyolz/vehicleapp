import Foundation
import SwiftData
import Combine

@MainActor
class SyncService: ObservableObject {
    static let shared = SyncService()
    private init() {}

    enum SyncState: Equatable {
        case idle
        case syncing
        case done(new: Int, removed: Int)
        case failed(String)
    }

    @Published private(set) var state: SyncState = .idle
    @Published private(set) var progress: String = ""
    @Published private(set) var progressValue: Double = 0.0
    @Published private(set) var currentCar: String = ""
    @Published private(set) var foundCount: Int = 0
    @Published private(set) var totalCount: Int = 0

    func sync(context: ModelContext) async {
        guard state != .syncing else { return }
        state = .syncing
        progress = "Connecting to 747 Motors..."
        progressValue = 0.0
        currentCar = ""
        foundCount = 0
        totalCount = 0

        do {
            // 1. Fetch live car IDs
            progress = "Scanning inventory..."
            let liveItems = try await ScraperService.shared.fetchInventoryIDs()
            let liveIDs = Set(liveItems.map { $0.id })
            totalCount = liveItems.count
            progress = "Found \(totalCount) vehicles on site"

            // 2. Fetch local cars
            let localCars = try context.fetch(FetchDescriptor<Car>())
            let localIDs = Set(localCars.map { $0.id })

            // 3. Diff
            let newIDs = liveIDs.subtracting(localIDs)
            let removedIDs = localIDs.subtracting(liveIDs)

            // 4. Remove sold cars
            for car in localCars where removedIDs.contains(car.id) {
                context.delete(car)
            }

            // 5. Fetch new cars
            print("🔍 Live cars found: \(liveIDs.count)")
            print("🔍 Local cars found: \(localIDs.count)")
            print("🔍 New cars to fetch: \(newIDs.count)")
            print("🔍 Cars to remove: \(removedIDs.count)")

            if newIDs.isEmpty {
                progress = "Inventory is up to date"
                progressValue = 1.0
            } else {
                var added = 0
                for item in liveItems where newIDs.contains(item.id) {
                    added += 1
                    foundCount = added
                    progressValue = Double(added) / Double(newIDs.count)

                    let car = try await ScraperService.shared.fetchCarDetail(
                        id: item.id,
                        path: item.path
                    )
                    // Show the car name as it's found
                    currentCar = "\(car.year) \(car.make) \(car.model) \(car.trim)"
                    progress = "Adding \(added) of \(newIDs.count) new vehicles..."
                    context.insert(car)
                }
            }

            try context.save()
            state = .done(new: newIDs.count, removed: removedIDs.count)

        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
