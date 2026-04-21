import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject var sync: SyncService
    @State private var showUpdates: Bool = false
    @Query(sort: \Car.year, order: .reverse) var cars: [Car]
    
    @State private var showInfo = false
    @State private var showFilters: Bool = false
    
    @State private var selectedBodyType: String? = nil
    @State private var selectedMinPrice: Int? = nil
    @State private var selectedMaxPrice: Int? = nil
    @State private var selectedMinMileage: Int? = nil
    @State private var selectedMaxMileage: Int? = nil
    @State private var selectedFuelType: String? = nil
    
    
    @State private var searchText = ""
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    
    let quickFilters = ["SUV", "Sedan", "Coupe", "Pickup Truck"]
    
    var filteredCars: [Car] {
        cars.filter { car in
            let matchesBody = selectedBodyType == nil || car.bodyType == selectedBodyType
            let matchesFuel = selectedFuelType == nil || car.fuelType == selectedFuelType
            
            let minPrice = selectedMinPrice ?? 0
            let maxPrice = selectedMaxPrice ?? 1000000
            let minMileage = selectedMinMileage ?? 0
            let maxMileage = selectedMaxMileage ?? 100000000
            
            let matchesMinPrice = (car.price ?? 0) >= minPrice
            let matchesMaxPrice = (car.price ?? 0) <= maxPrice
            let matchesMinMileage = (car.mileage) >= minMileage
            let matchesMaxMileage = (car.mileage) <= maxMileage
            
            let matchesSearch = searchText.isEmpty ||
            car.make.localizedCaseInsensitiveContains(searchText) ||
            car.model.localizedCaseInsensitiveContains(searchText) ||
            car.vin?.localizedCaseInsensitiveContains(searchText) ?? false ||
            String(car.year).contains(searchText) ||
            (car.stockNumber?.localizedCaseInsensitiveContains(searchText) ?? false)
            
            let filters = [
                matchesBody,
                matchesFuel,
                matchesSearch,
                matchesMinPrice,
                matchesMaxPrice,
                matchesMinMileage,
                matchesMaxMileage
            ]
            
            return filters.allSatisfy{$0}
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HeaderView
                CarCountView
                CarListOrLoadingView
            }
            .navigationBarHidden(true)
            .searchable(text: $searchText, prompt: "Search make, model, year...")
            .overlay(alignment: .bottom) {
                SyncStatusView
                    .padding(.bottom, 0.5)
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .task {
            await sync.sync(context: context)
        }
    }
}

// MARK: - Header
extension ContentView {
    var HeaderView: some View {
        VStack(spacing: 10) {
            TitleRowView
            FilterChipsView
        }
        .padding(.top, 12)
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color(.systemGray5)).frame(height: 0.5)
        }
    }
}

// MARK: - Title Row
extension ContentView {
    var TitleRowView: some View {
        HStack {
            // Title pill
            HStack(spacing: 8) {
                Image(systemName: "car.2.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                Text("747 Motors")
                    .font(.system(size: 16, weight: .semibold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(Color(.systemGray4), lineWidth: 0.5))
            
            Spacer()
            
            HStack(spacing: 8) {
                // Dark mode toggle
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) { isDarkMode.toggle() }
                } label: {
                    Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill")
                        .font(.system(size: 15))
                        .padding(9)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(Color(.systemGray4), lineWidth: 0.5))
                }
                
                // Info button
                Button {
                    showInfo.toggle()
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 15))
                        .padding(9)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(Color(.systemGray4), lineWidth: 0.5))
                }
                
                // Refresh button
                Button {
                    Task { await sync.sync(context: context) }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 15))
                        .padding(9)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(Color(.systemGray4), lineWidth: 0.5))
                }
                .disabled(sync.state == .syncing)
            }
        }
        .padding(.horizontal, 16)
        .sheet(isPresented: $showInfo) {
            InfoSheet(sync: sync, onShowUpdates: {
                showInfo = false
                showUpdates = true
            })
        }
        .sheet(isPresented: $showUpdates) {
            UpdatesSheet()
        }
        .sheet(isPresented: $showFilters){
            FilterSheet(
                cars: filteredCars,
                minPrice: $selectedMinPrice,
                maxPrice: $selectedMaxPrice,
                minMileage: $selectedMinMileage,
                maxMileage: $selectedMaxMileage,
                fuelType: $selectedFuelType,
                bodyType: $selectedBodyType
            )
        }
    }
}
// MARK: - Filter Chips Row
extension ContentView {
    var FilterChipsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                
                //Filter Button
                Button {
                    showFilters.toggle()
                } label :{
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 15))
                        .padding(9)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(Color(.systemGray4), lineWidth: 0.5))
                }
                
                //Quick Filter
                FilterChip(label: "All", isSelected: selectedBodyType == nil) {
                    selectedBodyType = nil
                }
                ForEach(quickFilters, id: \.self) { type in
                    FilterChip(label: type, isSelected: selectedBodyType == type) {
                        selectedBodyType = selectedBodyType == type ? nil : type
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 10)
    }
}

// MARK: - Car Count
extension ContentView {
    var CarCountView: some View {
        HStack {
            Text("\(filteredCars.count) vehicles")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Car List / Loading / Empty
extension ContentView {
    var CarListOrLoadingView: some View {
        Group {
            if cars.isEmpty {
                LoadingView(sync: sync)
            } else if filteredCars.isEmpty {
                ContentUnavailableView(
                    "No \(selectedBodyType ?? "") vehicles found",
                    systemImage: "car.fill",
                    description: Text("Try a different filter")
                )
            } else {
                List(filteredCars) { car in
                    NavigationLink(destination: CarDetailView(car: car)) {
                        CarRowView(car: car)
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}

// MARK: - Sync Status Banner
extension ContentView {
    var SyncStatusView: some View {
        Group {
            if sync.state == .syncing {
                SyncBanner(message: sync.progress, color: .green)
            } else if case .done(let new, _) = sync.state, new > 0 {
                SyncBanner(message: "✅ \(new) new car\(new > 1 ? "s" : "") added!", color: .green)
            } else if case .failed(let msg) = sync.state {
                SyncBanner(message: "⚠️ \(msg)", color: .red)
            }
        }
        .animation(.spring(), value: sync.state == .syncing)
    }
}

// MARK: - Filter Chip Component
struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? AnyShapeStyle(Color.green) : AnyShapeStyle(.ultraThinMaterial))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
                .overlay(
                    Capsule().strokeBorder(
                        isSelected ? Color.clear : Color(.systemGray4),
                        lineWidth: 0.5
                    )
                )
        }
    }
}

// MARK: - Loading Screen
struct LoadingView: View {
    @ObservedObject var sync: SyncService
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            Image(systemName: "car.2.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
                .padding(.bottom, 16)
            Text("747 Motors")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 32)
            Text(sync.progress.isEmpty ? "Starting up..." : sync.progress)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 16)
                .animation(.easeInOut, value: sync.progress)
            VStack(spacing: 8) {
                ProgressView(value: sync.progressValue)
                    .progressViewStyle(.linear)
                    .tint(.green)
                    .padding(.horizontal, 40)
                    .animation(.easeInOut, value: sync.progressValue)
                if sync.progressValue > 0 {
                    Text("\(Int(sync.progressValue * 100))%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.bottom, 24)
            if !sync.currentCar.isEmpty {
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                        Text("Found:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(sync.currentCar)
                            .font(.caption)
                            .fontWeight(.medium)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 40)
                    .animation(.easeInOut, value: sync.currentCar)
                    if sync.totalCount > 0 {
                        Text("\(sync.foundCount) of \(sync.totalCount) vehicles processed")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 20)
            }
            Spacer()
            Spacer()
        }
    }
}

// MARK: - Sync Banner Component
struct SyncBanner: View {
    let message: String
    let color: Color
    
    var body: some View {
        Text(message)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(color)
            .clipShape(Capsule())
            .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .padding(.bottom, 8)
    }
}
// MARK: - Info Sheet
struct InfoSheet: View {
    
    @ObservedObject var sync: SyncService
    @Environment(\.dismiss) var dismiss
    var onShowUpdates: () -> Void
    
    var statusColor: Color {
        switch sync.state {
        case .syncing: return .yellow
        case .failed: return .red
        default: return .green
        }
    }
    
    var statusText: String {
        switch sync.state {
        case .syncing: return "Syncing"
        case .failed: return "Error"
        default: return "Online"
        }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            HStack{
                // Status pill
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(statusColor.opacity(0.3))
                            .frame(width: 14, height: 14)
                        Circle()
                            .fill(statusColor)
                            .frame(width: 8, height: 8)
                    }
                    Text("\(statusText)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(Color(.systemGray4), lineWidth: 0.5))
                
                //Update Pill
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color(.systemBlue).opacity(0.3))
                            .frame(width: 14, height: 14)
                        Circle()
                            .fill(Color(.systemBlue))
                            .frame(width: 8, height: 8)
                    }
                    Button(){
                        onShowUpdates()
                    } label: {
                        Text("Updates")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.primary)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(Color(.systemGray4), lineWidth: 0.5))
            }
            
            // Dev info
            VStack(spacing: 6) {
                Text("Created by Fritz Fils-Aime")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                Text("Version 0.41")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .presentationDetents([.fraction(0.25)])
        .presentationDragIndicator(.visible)
    }
}


// MARK: - Updates Sheet
struct UpdatesSheet: View {

    // MARK: - Update Entry Model
    struct UpdateEntry {
        let version: String
        let title: String
        let body: String
        let category: Category

        enum Category {
            case feature, fix, ui, performance, general

            var label: String {
                switch self {
                case .feature: return "Feature"
                case .general: return "General"
                case .fix: return "Fix"
                case .ui: return "UI"
                case .performance: return "Performance"
                }
            }

            var color: Color {
                switch self {
                case .feature: return .blue
                case .general: return .purple
                case .fix: return .red
                case .ui: return Color(.systemGray)
                case .performance: return .green
                }
            }
        }
    }

    // MARK: - update log
    //UpdateEntry(version: number, title: "String", body: "About the update", category: )
    
    let updates: [UpdateEntry] = [
        UpdateEntry(version: "0.42", title: "Feature", body: "Fully implemented the filter sheet. Now you can filter by price, mileage, and vehicle body type. More filter(s) are in progress", category: .feature),
        UpdateEntry(version: "0.41", title: "General", body: "Implemented a update log. Redesigned the info structure, added the option to click an update button. Added Filter option, creatng the filter function soon.", category: .general),
        UpdateEntry(version: "0.41", title: "UI", body: "When enabling dark mode, the app will now be able to retain that mode.", category: .ui),
        
    ]

    //Groups list by version number
    var groupedUpdates: [String: [UpdateEntry]] {
        Dictionary(grouping: updates, by: { $0.version })
    }

    //newest version first
    var sortedVersions: [String] {
        groupedUpdates.keys.sorted { a, b in
            (Double(a) ?? 0) > (Double(b) ?? 0)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // Title
                Text("What's New")
                    .font(.system(size: 20, weight: .semibold))
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 16)

                // Loop through version
                ForEach(sortedVersions, id: \.self) { version in

                    // Versions
                    Text("Version \(version)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)

                    // Loop through entries for this version
                    ForEach(groupedUpdates[version] ?? [], id: \.title) { entry in
                        UpdateRow(entry: entry)
                    }

                    Spacer().frame(height: 8)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Update Row Component
struct UpdateRow: View {
    let entry: UpdatesSheet.UpdateEntry

    var body: some View {
        HStack(alignment: .top, spacing: 12) {

            //status dot
            ZStack {
                Circle()
                    .fill(entry.category.color.opacity(0.2))
                    .frame(width: 14, height: 14)
                Circle()
                    .fill(entry.category.color)
                    .frame(width: 8, height: 8)
            }
            .padding(.top, 14)

            // The card
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    // Category badge
                    Text(entry.category.label)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(entry.category.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(entry.category.color.opacity(0.12))
                        .clipShape(Capsule())
                        .overlay(Capsule().strokeBorder(entry.category.color.opacity(0.5), lineWidth: 0.5))

                    Text(entry.title)
                        .font(.system(size: 14, weight: .semibold))
                }
                Text(entry.body)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemGray6).opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color(.systemGray4), lineWidth: 0.5))}
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
    }
}

// MARK: - Filter Sheet
struct FilterSheet: View {

    let cars: [Car]
    @Binding var minPrice: Int?
    @Binding var maxPrice: Int?
    @Binding var minMileage: Int?
    @Binding var maxMileage: Int?
    @Binding var fuelType: String?
    @Binding var bodyType: String?

    @State private var minPriceValue: String = ""
    @State private var maxPriceValue: String = ""
    @State private var minMileageValue: String = ""
    @State private var maxMileageValue: String = ""

    @Environment(\.dismiss) var dismiss

    let fuelTypes = ["Gasoline", "Hybrid", "Electric", "Diesel"]

    var maxCarPrice: Int {
        cars.max(by: { ($0.price ?? 0) < ($1.price ?? 0) })?.price ?? 200000
    }

    var activeFilterCount: Int {
        [minPrice, maxPrice, minMileage, maxMileage]
            .compactMap { $0 }.count +
        (fuelType != nil ? 1 : 0) +
        (bodyType != nil ? 1 : 0)
    }

    var body: some View {
        VStack(spacing: 0) {

            // Header
            HStack {
                Button("Reset") { clearAll() }
                    .foregroundStyle(.red)
                    .font(.system(size: 15))
                Spacer()
                Text("Filters")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Text("Reset")
                    .foregroundStyle(.clear)
                    .font(.system(size: 15))
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Price range
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Price range")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        HStack(spacing: 10) {
                            HStack(spacing: 6) {
                                Text("$")
                                    .foregroundStyle(.secondary)
                                    .font(.subheadline)
                                TextField("0", text: $minPriceValue)
                                    .keyboardType(.numberPad)
                                    .onChange(of: minPriceValue) { _, newValue in
                                        minPrice = newValue.isEmpty ? nil : Int(newValue)
                                    }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(Color(.systemGray4), lineWidth: 0.5))

                            Text("—").foregroundStyle(.secondary)

                            HStack(spacing: 6) {
                                Text("$")
                                    .foregroundStyle(.secondary)
                                    .font(.subheadline)
                                TextField(String(maxCarPrice), text: $maxPriceValue)
                                    .keyboardType(.numberPad)
                                    .onChange(of: maxPriceValue) { _, newValue in
                                        maxPrice = newValue.isEmpty ? nil : Int(newValue)
                                    }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(Color(.systemGray4), lineWidth: 0.5))
                        }
                    }

                    // Mileage range
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Mileage range")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        HStack(spacing: 10) {
                            HStack(spacing: 6) {
                                Text("mi")
                                    .foregroundStyle(.secondary)
                                    .font(.subheadline)
                                TextField("0", text: $minMileageValue)
                                    .keyboardType(.numberPad)
                                    .onChange(of: minMileageValue) { _, newValue in
                                        minMileage = newValue.isEmpty ? nil : Int(newValue)
                                    }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(Color(.systemGray4), lineWidth: 0.5))

                            Text("—").foregroundStyle(.secondary)

                            HStack(spacing: 6) {
                                Text("mi")
                                    .foregroundStyle(.secondary)
                                    .font(.subheadline)
                                TextField("Any", text: $maxMileageValue)
                                    .keyboardType(.numberPad)
                                    .onChange(of: maxMileageValue) { _, newValue in
                                        maxMileage = newValue.isEmpty ? nil : Int(newValue)
                                    }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(Color(.systemGray4), lineWidth: 0.5))
                        }
                    }

                    // Fuel type
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Fuel type")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                FilterChip(label: "Any", isSelected: fuelType == nil) {
                                    fuelType = nil
                                }
                                ForEach(fuelTypes, id: \.self) { type in
                                    FilterChip(label: type, isSelected: fuelType == type) {
                                        fuelType = fuelType == type ? nil : type
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }

            Divider()

            // Bottom buttons
            VStack(spacing: 10) {
                Button {
                    clearAll()
                    dismiss()
                } label: {
                    Text("Clear all")
                        .font(.system(size: 15))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color(.systemGray4), lineWidth: 0.5))
                }
                .foregroundStyle(.primary)

                Button {
                    applyFilters()
                    dismiss()
                } label: {
                    Text(activeFilterCount > 0 ? "Apply (\(activeFilterCount))" : "Apply")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onAppear {
            restoreFields()
        }
    }

    func applyFilters() {
        minPrice = minPriceValue.isEmpty ? nil : Int(minPriceValue)
        maxPrice = maxPriceValue.isEmpty ? nil : Int(maxPriceValue)
        minMileage = minMileageValue.isEmpty ? nil : Int(minMileageValue)
        maxMileage = maxMileageValue.isEmpty ? nil : Int(maxMileageValue)
    }

    func clearAll() {
        minPrice = nil
        maxPrice = nil
        minMileage = nil
        maxMileage = nil
        fuelType = nil
        bodyType = nil
        minPriceValue = ""
        maxPriceValue = ""
        minMileageValue = ""
        maxMileageValue = ""
    }

    func restoreFields() {
        if let v = minPrice { minPriceValue = String(v) }
        if let v = maxPrice { maxPriceValue = String(v) }
        if let v = minMileage { minMileageValue = String(v) }
        if let v = maxMileage { maxMileageValue = String(v) }
    }
}


#Preview("Filter Sheet") {
    FilterSheet(
        cars: [],
        minPrice: .constant(nil),
        maxPrice: .constant(nil),
        minMileage: .constant(nil),
        maxMileage: .constant(nil),
        fuelType: .constant(nil),
        bodyType: .constant(nil)
    )
}

#Preview {
    ContentView()
        .environmentObject(SyncService.shared)
        .modelContainer(for: Car.self, inMemory: true)
}


