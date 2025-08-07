# 📱 Plain Text Wealth - iOS Financial Tracker

## Project Philosophy: Native-First Architecture
This app is built using **100% native iOS technologies and patterns** - no external dependencies, no custom frameworks, just pure SwiftUI, SwiftData, and native iOS design patterns. The goal is maximum reliability, performance, and consistency with iOS ecosystem standards.

## Technology Stack - Pure Native iOS
- **Platform**: iOS 17.0+ (using Xcode 16 Beta)
- **UI Framework**: SwiftUI (native Apple framework)
- **Data Persistence**: SwiftData (native Apple framework) 
- **Charts**: Swift Charts (native Apple framework)
- **Development Environment**: Xcode 16 Beta
- **Language**: Swift
- **Architecture**: Native iOS app lifecycle and patterns

## Core Design Principles

### 1. Native iOS Patterns Only
- **Navigation**: Standard SwiftUI NavigationStack with native toolbar
- **Lists**: Native SwiftUI List with standard section headers
- **Data Flow**: SwiftUI @Query and @Model reactivity
- **Styling**: Native iOS system fonts, colors, and materials
- **User Interface**: Follows Apple Human Interface Guidelines

### 2. Update-Only Data Architecture
- **No caching layers**: Direct real-time calculations from raw data
- **No external dependencies**: Pure SwiftData relationships
- **Simple data flow**: User updates → SwiftData storage → SwiftUI reactivity
- **Native performance**: Leverages SwiftUI's built-in optimization

### 3. Offline-First with Local Storage
- **Pure SwiftData**: No cloud dependencies or syncing complexity
- **Local privacy**: All financial data stays on device
- **Native backup**: Leverages iOS backup and iCloud document sync

## Data Models (SwiftData - Native Apple Framework)

### `Account` 
```swift
@Model
class Account {
    var name: String
    var createdAt: Date
    var isActive: Bool
    var closedAt: Date?
    
    @Relationship(deleteRule: .cascade) 
    var updates: [AccountUpdate] = []
}
```

### `AccountUpdate`
```swift
@Model 
class AccountUpdate {
    var value: Decimal        // Native precision for financial data
    var date: Date           // Native date handling
    var account: Account?    // Native SwiftData relationship
}
```

### Model Registration (Native SwiftData Pattern)
```swift
.modelContainer(for: [Account.self, AccountUpdate.self])
```

## Real-Time Calculation System - Native Performance

### Current Value Calculation (Native SwiftData Query)
```swift
private func currentValue(for account: Account) -> Decimal {
    // Native Swift sorting with proper chronological order
    account.updates
        .sorted { $0.date < $1.date }
        .last?.value ?? 0
}
```

### Portfolio Total (Native Swift Reduce)
```swift
private var totalPortfolioValue: Decimal {
    activeAccounts.reduce(0) { total, account in
        total + currentValue(for: account)
    }
}
```

### Chart Data Generation (Native Swift Collections)
**Account Charts:**
```swift
private var chartDataPoints: [ChartDataPoint] {
    account.updates
        .sorted { $0.date < $1.date }
        .map { ChartDataPoint(date: $0.date, value: $0.value) }
}
```

**Portfolio Charts:**
```swift
private var chartDataPoints: [ChartDataPoint] {
    let allUpdates = accounts.flatMap { $0.updates }
        .sorted { $0.date < $1.date }
    
    var currentAccountValues: [String: Decimal] = [:]
    return allUpdates.map { update in
        currentAccountValues[update.account?.name ?? ""] = update.value
        let total = currentAccountValues.values.reduce(0, +)
        return ChartDataPoint(date: update.date, value: total)
    }
}
```

## Native iOS UI Implementation

### Navigation Bar (Native iOS Pattern)
```swift
.toolbarBackground(.regularMaterial, for: .navigationBar)  // Native material
.toolbar {
    ToolbarItem(placement: .principal) {                    // Native centered placement
        Text("Plain Text Wealth")
            .font(.headline)                                // Native system font
            .fontWeight(.semibold)                         // Native font weight
    }
    
    ToolbarItem(placement: .navigationBarTrailing) {       // Native trailing placement
        Button(action: { showingAddAccount = true }) {
            Image(systemName: "plus")                      // Native SF Symbol
        }
    }
}
```

### Navigation Behavior (Native iOS Conventions)
- **Transparent at top**: Following iOS 15+ conventions
- **Material background on scroll**: Native .regularMaterial provides proper contrast
- **Automatic adaptation**: Native iOS scroll-based transparency behavior

### Charts (Native Swift Charts Framework)
```swift
Chart(chartDataPoints, id: \.date) { dataPoint in
    AreaMark(
        x: .value("Date", dataPoint.date),
        yStart: .value("Base", 0),
        yEnd: .value("Value", dataPoint.doubleValue)
    )
    .foregroundStyle(
        LinearGradient(
            gradient: Gradient(colors: [.blue.opacity(0.3), .blue.opacity(0.05)]),
            startPoint: .top,
            endPoint: .bottom
        )
    )
    .interpolationMethod(.linear)                          // Native interpolation
    
    LineMark(
        x: .value("Date", dataPoint.date),
        y: .value("Value", dataPoint.doubleValue)
    )
    .foregroundStyle(.blue)                               // Native system blue
    .lineStyle(StrokeStyle(lineWidth: 1.5))              // Native stroke style
}
```

### List Implementation (Native SwiftUI)
```swift
List {
    Section("Portfolio Total") {                          // Native section headers
        // Content with native spacing and styling
    }
    
    Section("Accounts") {
        ForEach(accounts, id: \.name) { account in
            NavigationLink(destination: AccountDetailView(account: account)) {
                // Native NavigationLink behavior
                VStack(alignment: .leading, spacing: 8) {
                    // Native layout with system spacing
                }
            }
        }
        .onDelete(perform: deleteAccounts)               // Native swipe-to-delete
    }
}
```

## Data Flow - Native SwiftUI Reactivity

### User Updates Data Flow
1. **User Input**: Native SwiftUI forms and controls
2. **SwiftData Insert**: Native `.insert()` and `.save()`  
3. **SwiftUI Reactivity**: Native `@Query` triggers view updates
4. **Chart Updates**: Native Swift Charts recalculates automatically
5. **UI Refresh**: Native SwiftUI view diffing and updates

### Chart Reactivity (Native SwiftUI)
```swift
PortfolioChart(accounts: accounts)
    .id("\(accounts.count)-\(totalUpdateCount)")         // Native identity-based updates
```

## Performance Characteristics - Native Optimization

### Storage Efficiency
- **Native SwiftData**: Optimized binary storage format
- **Minimal records**: Only actual user updates (~200-300 records vs 4,000+ cached)
- **Native relationships**: Efficient cascade deletes and queries

### Calculation Performance  
- **Native Collections**: Swift's optimized sorting and reducing
- **O(n log n)** complexity for account values (n = ~5-50 updates per account)
- **O(m)** complexity for portfolio totals (m = ~8 accounts)
- **Native memory management**: ARC handles all memory automatically

### UI Performance
- **Native SwiftUI**: Automatic view diffing and minimal redraws
- **Native Charts**: Hardware-accelerated rendering
- **Native materials**: GPU-optimized background blur effects

## User Interface - Pure iOS Native

### Typography
- **System fonts only**: `.headline`, `.subheadline`, `.caption`
- **Native font weights**: `.semibold`, `.medium`, `.regular`
- **No custom fonts**: Maintains iOS accessibility and consistency

### Colors
- **System colors**: `.blue`, `.green`, `.red`, `.secondary`
- **Native adaptivity**: Automatic dark/light mode support
- **Accessibility**: Full native high contrast and color blindness support

### Layout
- **Native spacing**: System-defined padding and margins
- **Native sizing**: Automatic font scaling for accessibility
- **Native behaviors**: Standard iOS gestures and interactions

### Dashboard Features
- **Portfolio Total**: Large title showing current total value with auto-scaling text
- **Account Count**: Simple "N accounts" display below portfolio total  
- **Account List**: Individual accounts show percentage and absolute value changes
- **Chart Integration**: Native Swift Charts showing portfolio growth over time
- **Consistent Typography**: App locked to `.large` text size to prevent layout issues

### Fixed Text Sizing
```swift
.environment(\.sizeCategory, .large)  // Prevents user text scaling issues
```

### Auto-Scaling Portfolio Value
```swift
Text("£\(totalPortfolioValue.formatted())")
    .font(.largeTitle)
    .minimumScaleFactor(0.5)  // Auto-scales for large values
    .lineLimit(1)             // Prevents wrapping
```

## Account Management - Native Patterns

### Account Lifecycle
- **Creation**: Standard SwiftUI form with native validation
- **Updates**: Native date picker and numeric input
- **History**: Native List with chronological sorting
- **Deletion**: Native swipe-to-delete with confirmation alerts

### Data Integrity (Native SwiftData)
- **Cascade relationships**: Native `@Relationship(deleteRule: .cascade)`
- **Data validation**: Native Swift property requirements
- **Error handling**: Native SwiftData error types and handling

## Test Data - Realistic Financial Scenarios

### Set 1: Real Financial Data
- **7 accounts**: Realistic UK financial account names
- **6 time periods**: May 2025 to August 2025
- **Staggered timestamps**: Realistic user input patterns
  - Initial updates: 9:00 AM with 2-minute intervals
  - Subsequent updates: Random times between 8 AM - 8 PM
- **42 total updates**: Authentic financial tracking scenario

### Set 2: Performance Testing
- **6 accounts**: 2-year historical data
- **200+ updates**: Tests calculation performance
- **Synthetic growth**: Various realistic growth patterns

### Set 3: Pattern Verification
- **2 accounts**: Simple predictable patterns
- **Monthly updates**: £100 increments for math verification

## Build & Development - Native iOS

### Xcode Project Structure
```
PlainTextMoney/
├── Models/              # SwiftData models
├── Views/               # SwiftUI views  
├── Services/            # Native Swift services
└── TestDataGenerator    # Debug-only native test data
```

### Build Configuration
- **Target**: iOS 17.0 minimum (maximum compatibility)
- **Dependencies**: None (100% native)
- **Frameworks**: SwiftUI, SwiftData, Swift Charts (all native Apple)

### Development Workflow
1. **Native debugging**: Xcode native debugger and console
2. **Native testing**: XCTest framework
3. **Native performance**: Xcode Instruments
4. **Native deployment**: App Store Connect

## Critical Technical Decisions - Native iOS Best Practices

### 1. SwiftData Threading (Native Pattern)
```swift
@MainActor  // Native main thread enforcement
private func updateAccount() async {
    // All SwiftData operations on main actor - native threading pattern
}
```

### 2. Financial Precision (Native Types)
```swift
var value: Decimal  // Native precise decimal type, not Double
```

### 3. Date Handling (Native Foundation)
```swift
Calendar.current.startOfDay(for: date)  // Native date normalization
```

### 4. Memory Management (Native ARC)
- **No retain cycles**: Native weak references in closures
- **No manual memory**: Native ARC handles all allocation/deallocation
- **Native lifecycle**: SwiftUI manages view lifecycle automatically

## Future Considerations - Staying Native

### Potential Native Enhancements
1. **iCloud sync**: Native CloudKit integration (if needed)
2. **Shortcuts**: Native Siri Shortcuts support
3. **Widgets**: Native WidgetKit implementation
4. **Watch app**: Native WatchKit companion
5. **macOS**: Native Mac Catalyst deployment

### Maintaining Native Purity
- **No external dependencies**: Avoid third-party libraries
- **No custom UI**: Use native iOS controls and behaviors
- **No performance hacks**: Trust native framework optimization
- **No architectural complexity**: Follow native SwiftUI patterns

## Summary

This app represents a **pure native iOS implementation** using only Apple's frameworks and design patterns. Every aspect - from data storage to user interface - follows native iOS conventions, ensuring maximum reliability, performance, and user familiarity while maintaining the simplicity of a direct update-only architecture.

The result is a fast, reliable financial tracking app that feels completely native to iOS users and leverages the full power of Apple's development ecosystem.