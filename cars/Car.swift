import Foundation
import SwiftData

// @Model tells SwiftData this class is a database table.
@Model
class Car {

    // MARK: - Identity
    
    @Attribute(.unique) var id: Int // No car can be the same

    // MARK: - Basic Info
    
    var year: Int
    var make: String
    var model: String
    var trim: String

    // MARK: - Price
    
    var price: Int? //optional becuase some cars dont have a price
    var finance: Int?

    // MARK: - Specs
    
    var mileage: Int
    var drivetrain: String
    var fuelType: String
    var bodyType: String

    // MARK: - Optional Specs

    var engine: String?
    var transmission: String?
    var exteriorColor: String?
    var interiorColor: String?
    var vin: String?
    var stockNumber: String?
    var mpg: String?

    // MARK: - Photos

    var photoCount: Int
    var photoHash: String //code used to build the photo URLs

    // MARK: - Sync Tracking

    var dateAdded: Date

    // MARK: - Computed: Photo URLs
    // builds a list of photo URLs from id, photoCount, photoHash.
    
    var photoURLs: [String] {
        (1...max(1, photoCount)).map { num in
            let padded = String(format: "%02d", num)  // e.g. 1 → "01", 12 → "12"
            return "https://www.747motors.com/801/photo/\(id)/\(padded)_\(photoHash).jpg"
        }
    }

    // MARK: - Computed: Detail URL
    // link to the car's page on website
    
    var detailURL: String {
        "https://www.747motors.com/detail/\(id)-\(year)-\(make)-\(model)"
            .replacingOccurrences(of: " ", with: "-")
    }

    // MARK: - Initializer
    // Called by ScraperService when creating a new Car from scraped data.

    init(
        id: Int, year: Int, make: String, model: String, trim: String,
        price: Int? = nil, finance: Int? = nil, mileage: Int, drivetrain: String, fuelType: String,
        bodyType: String, engine: String? = nil, transmission: String? = nil,
        exteriorColor: String? = nil, interiorColor: String? = nil,
        vin: String, stockNumber: String? = nil, mpg: String? = nil,
        photoCount: Int, photoHash: String
    ) {
        self.id = id
        self.year = year
        self.make = make
        self.model = model
        self.trim = trim
        self.price = price
        self.finance = finance
        self.mileage = mileage
        self.drivetrain = drivetrain
        self.fuelType = fuelType
        self.bodyType = bodyType
        self.engine = engine
        self.transmission = transmission
        self.exteriorColor = exteriorColor
        self.interiorColor = interiorColor
        self.vin = vin
        self.stockNumber = stockNumber
        self.mpg = mpg
        self.photoCount = photoCount
        self.photoHash = photoHash
        self.dateAdded = Date()
    }
}
