import SwiftUI
import SwiftData

let appVersion = "0.55"

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
    @State private var selectedMake: String? = nil
    @State private var selectedModel: String? = nil
    @State private var selectedTrim: String? = nil
    @State private var selectedMinYear: Int? = nil
    @State private var selectedMaxYear: Int? = nil

    @State private var searchText = ""
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false

    let quickFilters = ["SUV", "Sedan", "Coupe", "Pickup Truck"]

    var filteredCars: [Car] {
        cars.filter { car in
            let matchesBody   = selectedBodyType == nil || car.bodyType == selectedBodyType
            let matchesFuel   = selectedFuelType == nil || car.fuelType == selectedFuelType
            let matchesMake   = selectedMake == nil     || car.make == selectedMake
            let matchesModel  = selectedModel == nil    || car.model == selectedModel
            let matchesTrim   = selectedTrim == nil     || car.trim == selectedTrim

            let matchesMinPrice    = (car.price ?? 0) >= (selectedMinPrice ?? 0)
            let matchesMaxPrice    = selectedMaxPrice == nil || (car.price ?? 0) <= selectedMaxPrice!
            let matchesMinMileage  = car.mileage >= (selectedMinMileage ?? 0)
            let matchesMaxMileage  = selectedMaxMileage == nil || car.mileage <= selectedMaxMileage!
            let matchesMinYear     = car.year >= (selectedMinYear ?? 0)
            let matchesMaxYear     = selectedMaxYear == nil || car.year <= selectedMaxYear!

            let matchesSearch = searchText.isEmpty ||
                car.make.localizedCaseInsensitiveContains(searchText) ||
                car.model.localizedCaseInsensitiveContains(searchText) ||
                car.vin?.localizedCaseInsensitiveContains(searchText) ?? false ||
                String(car.year).contains(searchText) ||
                (car.stockNumber?.localizedCaseInsensitiveContains(searchText) ?? false)

            return matchesBody && matchesFuel && matchesMake && matchesModel && matchesTrim &&
                   matchesMinPrice && matchesMaxPrice && matchesMinMileage && matchesMaxMileage &&
                   matchesMinYear && matchesMaxYear && matchesSearch
        }
    }

    // when true X for filters appear
    var hasActiveFilters: Bool {
        selectedBodyType != nil || selectedFuelType != nil ||
        selectedMake != nil || selectedModel != nil || selectedTrim != nil ||
        selectedMinPrice != nil || selectedMaxPrice != nil ||
        selectedMinMileage != nil || selectedMaxMileage != nil ||
        selectedMinYear != nil || selectedMaxYear != nil
    }

    func clearAllFilters() {
        selectedBodyType = nil;  selectedFuelType = nil
        selectedMake = nil;      selectedModel = nil;     selectedTrim = nil
        selectedMinPrice = nil;  selectedMaxPrice = nil
        selectedMinMileage = nil; selectedMaxMileage = nil
        selectedMinYear = nil;   selectedMaxYear = nil
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

                Button { showInfo.toggle() } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 15))
                        .padding(9)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(Color(.systemGray4), lineWidth: 0.5))
                }

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
        .sheet(isPresented: $showFilters) {
            FilterSheet(
                cars: cars,
                make: $selectedMake,
                model: $selectedModel,
                trim: $selectedTrim,
                minYear: $selectedMinYear,
                maxYear: $selectedMaxYear,
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
                Button {
                    showFilters.toggle()
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 15))
                        .padding(9)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(Color(.systemGray4), lineWidth: 0.5))
                }

                if hasActiveFilters {
                    Button {
                        withAnimation(.spring(duration: 0.25)) { clearAllFilters() }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .semibold))
                            .padding(9)
                            .background(Color.green.opacity(0.15))
                            .foregroundStyle(.green)
                            .clipShape(Circle())
                            .overlay(Circle().strokeBorder(Color.green.opacity(0.4), lineWidth: 0.5))
                    }
                    .transition(.scale.combined(with: .opacity))
                }

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
            .animation(.spring(duration: 0.25), value: hasActiveFilters)
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
                    "No vehicles found",
                    systemImage: "car.fill",
                    description: Text("Try adjusting your filters or search")
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
                if sync.progressValue > 0 {
                    ProgressView(value: sync.progressValue)
                        .progressViewStyle(.linear)
                        .tint(.green)
                        .padding(.horizontal, 40)
                        .animation(.easeInOut, value: sync.progressValue)
                    Text("\(Int(sync.progressValue * 100))%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.green)
                        .scaleEffect(1.2)
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
        case .failed:  return .red
        default:       return .green
        }
    }

    var statusText: String {
        switch sync.state {
        case .syncing: return "Syncing"
        case .failed:  return "Error"
        default:       return "Online"
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            HStack {
                HStack(spacing: 8) {
                    ZStack {
                        Circle().fill(statusColor.opacity(0.3)).frame(width: 14, height: 14)
                        Circle().fill(statusColor).frame(width: 8, height: 8)
                    }
                    Text(statusText)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(Color(.systemGray4), lineWidth: 0.5))

                HStack(spacing: 8) {
                    ZStack {
                        Circle().fill(Color(.systemBlue).opacity(0.3)).frame(width: 14, height: 14)
                        Circle().fill(Color(.systemBlue)).frame(width: 8, height: 8)
                    }
                    Button { onShowUpdates() } label: {
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

            VStack(spacing: 6) {
                Text("Created by Fritz Fils-Aime")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                Text("Version \(appVersion)")
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

    struct UpdateEntry {
        let version: String
        let title: String
        let body: String
        let category: Category

        enum Category {
            case feature, fix, ui, performance, general

            var label: String {
                switch self {
                case .feature:     return "Feature"
                case .general:     return "General"
                case .fix:         return "Fix"
                case .ui:          return "UI"
                case .performance: return "Performance"
                }
            }

            var color: Color {
                switch self {
                case .feature:     return .blue
                case .general:     return .purple
                case .fix:         return .red
                case .ui:          return Color(.systemGray)
                case .performance: return .green
                }
            }
        }
    }

    let updates: [UpdateEntry] = [
        UpdateEntry(version: appVersion, title: "Filter Overhaul", body: "Rebuilt filter sheet with cascading Make → Model → Trim selectors and year range, matching CarFax/CarGurus-style filtering. All filters apply together on confirm.", category: .feature),
        UpdateEntry(version: appVersion, title: "Loading Screen Fix", body: "Loading screen now shows an animated spinner on startup instead of a flat empty progress bar.", category: .fix),
        UpdateEntry(version: "0.48", title: "Filter Update", body: "Added more filter options. More filters are in development.", category: .feature),
        UpdateEntry(version: "0.42", title: "Feature", body: "Fully implemented the filter sheet. Now you can filter by price, mileage, and vehicle body type. More filter(s) are in progress", category: .feature),
        UpdateEntry(version: "0.41", title: "General", body: "Implemented a update log. Redesigned the info structure, added the option to click an update button. Added Filter option, creating the filter function soon.", category: .general),
        UpdateEntry(version: "0.41", title: "UI", body: "When enabling dark mode, the app will now be able to retain that mode.", category: .ui),
    ]

    var groupedUpdates: [String: [UpdateEntry]] {
        Dictionary(grouping: updates, by: { $0.version })
    }

    var sortedVersions: [String] {
        groupedUpdates.keys.sorted { a, b in
            (Double(a) ?? 0) > (Double(b) ?? 0)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("What's New")
                    .font(.system(size: 20, weight: .semibold))
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 16)

                ForEach(sortedVersions, id: \.self) { version in
                    Text("Version \(version)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)

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
            ZStack {
                Circle().fill(entry.category.color.opacity(0.2)).frame(width: 14, height: 14)
                Circle().fill(entry.category.color).frame(width: 8, height: 8)
            }
            .padding(.top, 14)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
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
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color(.systemGray4), lineWidth: 0.5))
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }
}

// MARK: - Filter Section Helper
struct FilterSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            content()
        }
    }
}

// MARK: - Selector Row (Make / Model / Trim )
struct SelectorRow: View {
    let options: [String]
    let selected: String?
    let isEnabled: Bool
    let disabledHint: String
    let onSelect: (String?) -> Void

    var displayText: String {
        if !isEnabled { return disabledHint }
        return selected ?? "Any"
    }

    var body: some View {
        Menu {
            Button("Any") { onSelect(nil) }
            if !options.isEmpty { Divider() }
            ForEach(options, id: \.self) { option in
                Button(option) { onSelect(option) }
            }
        } label: {
            HStack {
                Text(displayText)
                    .foregroundStyle(selected != nil && isEnabled ? .primary : .secondary)
                    .font(.subheadline)
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color(.systemGray4), lineWidth: 0.5))
        }
        .disabled(!isEnabled)
        .opacity(!isEnabled ? 0.4 : 1.0)
    }
}

// MARK: - Filter Field Modifier
extension View {
    func filterFieldStyle() -> some View {
        self
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color(.systemGray4), lineWidth: 0.5))
    }
}

// MARK: - Filter Sheet
struct FilterSheet: View {

    let cars: [Car]

    // Bindings back to ContentView
    @Binding var make: String?
    @Binding var model: String?
    @Binding var trim: String?
    @Binding var minYear: Int?
    @Binding var maxYear: Int?
    @Binding var minPrice: Int?
    @Binding var maxPrice: Int?
    @Binding var minMileage: Int?
    @Binding var maxMileage: Int?
    @Binding var fuelType: String?
    @Binding var bodyType: String?

    // only written to bindings on Apply
    @State private var localMake: String? = nil
    @State private var localModel: String? = nil
    @State private var localTrim: String? = nil
    @State private var localFuelType: String? = nil
    @State private var localBodyType: String? = nil
    @State private var minPriceValue: String = ""
    @State private var maxPriceValue: String = ""
    @State private var minMileageValue: String = ""
    @State private var maxMileageValue: String = ""
    @State private var minYearValue: String = ""
    @State private var maxYearValue: String = ""

    @Environment(\.dismiss) var dismiss

    let fuelTypes = ["Gasoline", "Hybrid", "Electric", "Diesel"]
    let bodyTypes = ["SUV", "Sedan", "Coupe", "Pickup Truck"]

    // MARK: Dynamic option lists (make -> model -> trim)

    var availableMakes: [String] {
        Array(Set(cars.map { $0.make })).sorted()
    }

    var availableModels: [String] {
        let source = localMake == nil ? cars : cars.filter { $0.make == localMake }
        return Array(Set(source.map { $0.model })).sorted()
    }

    var availableTrims: [String] {
        var source = cars
        if let m  = localMake  { source = source.filter { $0.make  == m  } }
        if let mo = localModel { source = source.filter { $0.model == mo } }
        return Array(Set(source.map { $0.trim }).filter { !$0.isEmpty }).sorted()
    }

    var maxCarPrice: Int {
        cars.max(by: { ($0.price ?? 0) < ($1.price ?? 0) })?.price ?? 200000
    }

    var activeFilterCount: Int {
        var n = 0
        if localMake      != nil          { n += 1 }
        if localModel     != nil          { n += 1 }
        if localTrim      != nil          { n += 1 }
        if !minYearValue.isEmpty || !maxYearValue.isEmpty { n += 1 }
        if localBodyType  != nil          { n += 1 }
        if localFuelType  != nil          { n += 1 }
        if !minPriceValue.isEmpty         { n += 1 }
        if !maxPriceValue.isEmpty         { n += 1 }
        if !minMileageValue.isEmpty       { n += 1 }
        if !maxMileageValue.isEmpty       { n += 1 }
        return n
    }

    var body: some View {
        VStack(spacing: 0) {
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // MARK: Make — always enabled, resets model+trim on change
                    FilterSection(title: "Make") {
                        SelectorRow(
                            options: availableMakes,
                            selected: localMake,
                            isEnabled: true,
                            disabledHint: "Any"
                        ) { picked in
                            localMake = picked; localModel = nil; localTrim = nil
                        }
                    }

                    // MARK: Model — locked until a make is chosen
                    FilterSection(title: "Model") {
                        SelectorRow(
                            options: availableModels,
                            selected: localModel,
                            isEnabled: localMake != nil,
                            disabledHint: "Select a make first"
                        ) { picked in
                            localModel = picked; localTrim = nil
                        }
                    }

                    // MARK: Trim — locked until a model is chosen
                    FilterSection(title: "Trim") {
                        SelectorRow(
                            options: availableTrims,
                            selected: localTrim,
                            isEnabled: localModel != nil,
                            disabledHint: "Select a model first"
                        ) { picked in
                            localTrim = picked
                        }
                    }

                    // MARK: Year
                    FilterSection(title: "Year") {
                        HStack(spacing: 10) {
                            TextField("Min", text: $minYearValue)
                                .keyboardType(.numberPad)
                                .filterFieldStyle()
                            Text("—").foregroundStyle(.secondary)
                            TextField("Max", text: $maxYearValue)
                                .keyboardType(.numberPad)
                                .filterFieldStyle()
                        }
                    }

                    // MARK: Body Type
                    FilterSection(title: "Body type") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                FilterChip(label: "Any", isSelected: localBodyType == nil) {
                                    localBodyType = nil
                                }
                                ForEach(bodyTypes, id: \.self) { type in
                                    FilterChip(label: type, isSelected: localBodyType == type) {
                                        localBodyType = localBodyType == type ? nil : type
                                    }
                                }
                            }
                        }
                    }

                    // MARK: Fuel Type
                    FilterSection(title: "Fuel type") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                FilterChip(label: "Any", isSelected: localFuelType == nil) {
                                    localFuelType = nil
                                }
                                ForEach(fuelTypes, id: \.self) { type in
                                    FilterChip(label: type, isSelected: localFuelType == type) {
                                        localFuelType = localFuelType == type ? nil : type
                                    }
                                }
                            }
                        }
                    }

                    // MARK: Price Range
                    FilterSection(title: "Price range") {
                        HStack(spacing: 10) {
                            HStack(spacing: 6) {
                                Text("$").foregroundStyle(.secondary).font(.subheadline)
                                TextField("Min", text: $minPriceValue).keyboardType(.numberPad)
                            }
                            .filterFieldStyle()
                            Text("—").foregroundStyle(.secondary)
                            HStack(spacing: 6) {
                                Text("$").foregroundStyle(.secondary).font(.subheadline)
                                TextField("Max", text: $maxPriceValue).keyboardType(.numberPad)
                            }
                            .filterFieldStyle()
                        }
                    }

                    // MARK: Mileage Range
                    FilterSection(title: "Mileage range") {
                        HStack(spacing: 10) {
                            HStack(spacing: 6) {
                                Text("mi").foregroundStyle(.secondary).font(.subheadline)
                                TextField("Min", text: $minMileageValue).keyboardType(.numberPad)
                            }
                            .filterFieldStyle()
                            Text("—").foregroundStyle(.secondary)
                            HStack(spacing: 6) {
                                Text("mi").foregroundStyle(.secondary).font(.subheadline)
                                TextField("Max", text: $maxMileageValue).keyboardType(.numberPad)
                            }
                            .filterFieldStyle()
                        }
                    }
                }
                .padding(20)
            }

            Divider()

            // Bottom Buttons
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
        .onAppear { restoreFields() }
    }

    func applyFilters() {
        make      = localMake
        model     = localModel
        trim      = localTrim
        fuelType  = localFuelType
        bodyType  = localBodyType
        minPrice   = minPriceValue.isEmpty   ? nil : Int(minPriceValue)
        maxPrice   = maxPriceValue.isEmpty   ? nil : Int(maxPriceValue)
        minMileage = minMileageValue.isEmpty ? nil : Int(minMileageValue)
        maxMileage = maxMileageValue.isEmpty ? nil : Int(maxMileageValue)
        minYear    = minYearValue.isEmpty    ? nil : Int(minYearValue)
        maxYear    = maxYearValue.isEmpty    ? nil : Int(maxYearValue)
    }

    func clearAll() {
        localMake = nil; localModel = nil; localTrim = nil
        localFuelType = nil; localBodyType = nil
        minPriceValue = ""; maxPriceValue = ""
        minMileageValue = ""; maxMileageValue = ""
        minYearValue = ""; maxYearValue = ""
        make = nil; model = nil; trim = nil
        fuelType = nil; bodyType = nil
        minPrice = nil; maxPrice = nil
        minMileage = nil; maxMileage = nil
        minYear = nil; maxYear = nil
    }

    func restoreFields() {
        localMake = make; localModel = model; localTrim = trim
        localFuelType = fuelType; localBodyType = bodyType
        if let v = minPrice   { minPriceValue   = String(v) }
        if let v = maxPrice   { maxPriceValue   = String(v) }
        if let v = minMileage { minMileageValue = String(v) }
        if let v = maxMileage { maxMileageValue = String(v) }
        if let v = minYear    { minYearValue    = String(v) }
        if let v = maxYear    { maxYearValue    = String(v) }
    }
}

// MARK: - Previews

#Preview("Filter Sheet") {
    FilterSheet(
        cars: [],
        make: .constant(nil),
        model: .constant(nil),
        trim: .constant(nil),
        minYear: .constant(nil),
        maxYear: .constant(nil),
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
