import SwiftUI
import Kingfisher

struct CarDetailView: View {
    let car: Car
    
    @State private var selectedPhoto = 0 //default variable for photos
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                
                // MARK: Photo Gallery
                // A swipeable TabView — one photo per tab.
                
                TabView(selection: $selectedPhoto) {
                    ForEach(Array(car.photoURLs.enumerated()), id: \.offset) { index, urlStr in
                        KFImage(URL(string: urlStr))
                            .placeholder{
                                Rectangle()
                                    .fill(Color(.systemGray5))
                                    .overlay(
                                        Image(systemName: "car")
                                            .foregroundStyle(Color(.systemGray3))
                                        )
                            }
                            .resizable()
                            .scaledToFill()
                    }
                }
                .tabViewStyle(.page)
                .frame(height: 280)
                
                // MARK: Photo Counter
                
                Text("\(selectedPhoto + 1) / \(car.photoURLs.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                
                VStack(alignment: .leading, spacing: 20) {
                    
                    // MARK: Title + Price Section
                    
                    VStack(alignment: .leading, spacing: 6) {
                        // e.g. "2020 BMW X3"
                        Text("\(String(car.year)) \(car.make) \(car.model)")
                        //.font(.title2)
                            .fontWeight(.bold)
                        
                        // e.g. "xDrive30i" — shown in smaller gray text below title
                        Text(car.trim)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        // Price — green if available, secondary if not
                        HStack (alignment: .top, spacing: 5){
                            if let price = car.price {
                                Text("$\(price.formatted())")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.green)  // ← Change price color here
                            } else {
                                Text("Call for Price")
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                            }
                            
                            if let finance = car.finance {
                                Text("$\(finance.formatted())/mo")
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // MARK: Specs Grid
                    // A 2-column grid of StatCell tiles.
                    // Each StatCell shows a label and a value in a rounded box.
                    // Optional specs (engine, transmission, etc.) only appear if they have a value.
                    // To add a new spec: add `StatCell(label: "Label", value: car.newField)`
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatCell(label: "Mileage", value: "\(car.mileage.formatted()) mi")
                        StatCell(label: "Drivetrain", value: car.drivetrain)
                        StatCell(label: "Fuel", value: car.fuelType)
                        StatCell(label: "Body", value: car.bodyType)
                        
                        // Optional specs — only shown if the website provided the value
                        if let engine = car.engine {
                            StatCell(label: "Engine", value: engine)
                        }
                        if let trans = car.transmission {
                            StatCell(label: "Transmission", value: trans)
                        }
                        if let mpg = car.mpg {
                            StatCell(label: "MPG", value: mpg)
                        }
                        if let color = car.exteriorColor {
                            StatCell(label: "Exterior", value: color)
                        }
                        if let interior = car.interiorColor {
                            StatCell(label: "Interior", value: interior)
                        }
                    }
                    
                    Divider()
                    
                    // MARK: VIN + Stock Number
                    // InfoRow shows a label on the left, value on the right.
                    // Only shown if the car has these values.
                    if let vin = car.vin {
                        InfoRow(label: "VIN", value: vin)
                    }
                    if let stock = car.stockNumber {
                        InfoRow(label: "Stock #", value: stock)
                    }
                    
                    // MARK: Call Button
                    
                    HStack{
                        Link(destination: URL(string: "tel:9545563967")!) {
                            Label("Call 747 Motors", systemImage: "phone.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)   // ← Change button color here
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding()  // Adds padding around the entire content section below the photos
            }
        }
        // Navigation bar title — shows "2020 BMW X3" at the top when scrolled
        .navigationTitle("\(String(car.year)) \(car.make) \(car.model)")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Stat Cell
struct StatCell: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.gray.opacity(0.08))  // ← Change opacity for darker/lighter background
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }
}

