import Foundation
import SwiftSoup

class ScraperService {
    static let shared = ScraperService()
    private init() {}

    let baseURL = "https://www.747motors.com"

    func fetchInventoryIDs() async throws -> [(id: Int, path: String)] {
        var allResults: [(id: Int, path: String)] = []
        var seen = Set<Int>()
        var offset = 0
        let pageSize = 10

        while true {
            let urlString = "\(baseURL)/cars/?type=Used&offset=0&view=tile&x=\(offset)&y=\(pageSize)&sort=photo_mod+desc,photo_count+desc,sort+desc,id"
            guard let url = URL(string: urlString) else { break }

            let (data, _) = try await URLSession.shared.data(from: url)
            let html = String(data: data, encoding: .utf8) ?? ""
            let doc = try SwiftSoup.parse(html)

            let links = try doc.select("a[href*='/detail/']")
            var foundOnPage = 0

            for link in links {
                let href = try link.attr("href")
                guard let detailRange = href.range(of: "/detail/") else { continue }
                let afterDetail = String(href[detailRange.upperBound...])
                let parts = afterDetail.split(separator: "-")
                if let first = parts.first, let id = Int(first) {
                    if !seen.contains(id) {
                        seen.insert(id)
                        let path = "/detail/" + afterDetail
                        allResults.append((id: id, path: path))
                        foundOnPage += 1
                    }
                }
            }

            print("📄 x=\(offset): found \(foundOnPage) new cars (total: \(allResults.count))")

            if foundOnPage == 0 { break }
            offset += pageSize
            if offset > 500 { break }
        }

        print("✅ Final car count: \(allResults.count)")
        return allResults
    }
    
    // MARK: - Fetch full details for one car
    func fetchCarDetail(id: Int, path: String) async throws -> Car {
        let url = URL(string: "\(baseURL)\(path)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let html = String(data: data, encoding: .utf8) ?? ""
        let doc = try SwiftSoup.parse(html)

        let title = try doc.select("h1").first()?.text() ?? ""
        let titleParts = title.split(separator: " ", maxSplits: 3)
        let year = titleParts.count > 0 ? Int(titleParts[0]) ?? 0 : 0
        let make = titleParts.count > 1 ? String(titleParts[1]) : ""
        let model = titleParts.count > 2 ? String(titleParts[2]) : ""
        let trim = titleParts.count > 3 ? String(titleParts[3]) : ""

        let specs = try doc.select("li")
        var specDict: [String: String] = [:]
        for spec in specs {
            let text = try spec.text()
            if text.contains(":") {
                let pair = text.split(separator: ":", maxSplits: 1)
                if pair.count == 2 {
                    let key = String(pair[0]).trimmingCharacters(in: .whitespaces)
                    let value = String(pair[1]).trimmingCharacters(in: .whitespaces)
                    specDict[key] = value
                }
            }
        }
        
        var price: Int? = nil
        if let priceEl = try doc.select("div.col-7.h4.text-light").first() {
            // Get only the direct text, not child elements (avoids grabbing the TMV inside it)
            let text = try priceEl.ownText()
                .replacingOccurrences(of: "$", with: "")
                .replacingOccurrences(of: ",", with: "")
                .trimmingCharacters(in: .whitespaces)
            if let p = Int(text), p > 1000 {
                price = p
            }
        }
        
        var finance: Int? = nil
        if let financeEl = try doc.select("div.h6.text-light b").first() {
            let text = try financeEl.text()
                .replacingOccurrences(of: "$", with: "")
                .replacingOccurrences(of: ",", with: "")
                .trimmingCharacters(in: .whitespaces)
            if let f = Int(text), f > 0 {
                finance = f
            }
        }
        
        var photoHash = ""
        var photoCount = 0

        // Some sites lazy-load images: early photos are in `src`, later ones in `data-src`.
        // We check both so we don't miss any photos or get a low count.
        var photoSources: [String] = []
        for img in try doc.select("img") {
            let src     = (try? img.attr("src"))      ?? ""
            let dataSrc = (try? img.attr("data-src")) ?? ""
            if src.contains("/photo/\(id)/")     { photoSources.append(src) }
            else if dataSrc.contains("/photo/\(id)/") { photoSources.append(dataSrc) }
        }

        //photo optimization cause it was a lil too slow
        if let firstSrc = photoSources.first {
            let filename = firstSrc.components(separatedBy: "/").last ?? ""
            let parts    = filename.components(separatedBy: "_")
            if parts.count >= 2 {
                photoHash = parts.dropFirst().joined(separator: "_")
                    .replacingOccurrences(of: ".jpg", with: "")
            }

            let maxPhotoNum = photoSources.compactMap { src -> Int? in
                let name = src.components(separatedBy: "/").last ?? ""
                return Int(name.components(separatedBy: "_").first ?? "")
            }.max()
            photoCount = maxPhotoNum ?? photoSources.count
        }

        let mileageStr = specDict["Mileage"]?
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " mi", with: "") ?? "0"

        return Car(
            id: id,
            year: year,
            make: make,
            model: model,
            trim: trim,
            price: price,
            finance: finance,
            mileage: Int(mileageStr) ?? 0,
            drivetrain: specDict["Drivetrain"] ?? "",
            fuelType: specDict["Fuel Type"] ?? "",
            bodyType: specDict["Body Type"] ?? "",
            engine: specDict["Engine"],
            transmission: specDict["Transmission"],
            exteriorColor: specDict["Exterior Color"],
            interiorColor: specDict["Interior Color"],
            vin: specDict["VIN"] ?? "",
            stockNumber: specDict["Stock"],
            mpg: specDict["MPG"],
            photoCount: photoCount,
            photoHash: photoHash
        )
    }
}
