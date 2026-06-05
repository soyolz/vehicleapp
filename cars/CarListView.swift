import SwiftUI
import Kingfisher

struct CarRowView: View {
    let car: Car
    
    var body: some View {
        HStack(spacing: 12) {
            KFImage(URL(string: car.photoURLs.first ?? ""))
                .placeholder {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .overlay(
                            Image(systemName: "car")
                                .foregroundStyle(Color(.systemGray3))
                        )
                }
                .resizable()
                .scaledToFill()
                .frame(width: 115, height: 78)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text("\(String(car.year)) \(car.make)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if let stock = car.stockNumber {
                        Text("#\(stock)")
                            .font(.caption2)
                            .foregroundStyle(Color(.systemGray2))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
                
                Text("\(car.model) \(car.trim)")
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)
                
                HStack(spacing: 10) {
                    HStack(spacing: 4) {
                        Image(systemName: "gauge.medium")
                            .font(.caption2)
                        Text("\(car.mileage.formatted()) mi")
                            .font(.caption)
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "car.rear.and.tire.marks")
                            .font(.caption2)
                        Text(car.drivetrain)
                            .font(.caption)
                    }
                }
                .foregroundStyle(.secondary)
                
                HStack(spacing: 6) {
                    if let price = car.price {
                        Text("$\(price.formatted())")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.green)
                    } else {
                        Text("Call for Price")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if let finance = car.finance {
                        Text("$\(finance.formatted())/mo")
                            .font(.caption2)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(.systemGreen))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    } else {
                        Text("")
                    }
                }
                
            }
        }
        .padding(.vertical, 6)
    }
}
