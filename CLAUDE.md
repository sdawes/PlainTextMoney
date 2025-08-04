# 📱 Savings & Portfolio Tracker App

## Project Overview
This is an iOS app built with SwiftUI and SwiftData for tracking multiple savings and investment accounts. The app is designed to be offline-first, storing all data locally for privacy and performance while providing fast, smooth charts of account and portfolio growth using real-time calculations.

## Technology Stack
- **Platform**: iOS 26 (using Xcode 16 Beta - Apple's new year-based versioning system)
- **UI Framework**: SwiftUI
- **Data Persistence**: SwiftData
- **Development Environment**: Xcode 16 Beta
- **Language**: Swift
- **Deployment Target**: iOS 17.0 minimum (supports iOS 26 when released)

## Key Features
- Track multiple user-created accounts (savings, ISAs, pensions, etc.)
- Fast, smooth charts showing account and portfolio growth
- Offline-first with local data storage
- Account creation, value updates, and history tracking
- Account closing (preserves history but removes from current totals)
- Real-time calculations for optimal performance

## 🚀 Update-Only Architecture (CORE SYSTEM)

### **The Simple Logic**
This app uses an **update-only architecture** - no complex caching, no pre-calculated snapshots, just simple real-time calculations from raw user data.

**How it works:**
1. **Store raw updates**: When users change account values, store the exact update with timestamp
2. **Calculate current values**: Find the chronologically latest update for each account
3. **Generate charts in real-time**: Walk through all updates chronologically to build chart data points
4. **Portfolio totals**: Simple arithmetic - sum all active account current values

**Why it's faster:**
- **Minimal storage**: ~200-300 update records instead of 4,000+ cached snapshots
- **No maintenance overhead**: No complex sync logic, gap filling, or cache invalidation
- **Real-time accuracy**: Always shows correct data, never stale
- **Simple debugging**: Easy to understand data flow and troubleshoot

## Data Models (SwiftData)

### `Account`
Represents each savings or investment account.
- `name`: String - User-given name (e.g. "ISA Savings")
- `createdAt`: Date - When the account was created
- `isActive`: Bool - True if account is open; false if closed
- `closedAt`: Date? - Date the account was closed, if any
- `updates`: [AccountUpdate] - All raw updates made by user (cascade delete)

### `AccountUpdate`
Each time the user changes an account's value.
- `value`: Decimal - New account value (£)
- `date`: Date - Exact date & time when update was made
- `account`: Account - Link to parent account

**Model Registration:**
```swift
.modelContainer(for: [Account.self, AccountUpdate.self])
```

## Real-Time Calculation System

### Current Value Calculation
**Critical Implementation** - Must use chronological sorting:
```swift
private func currentValue(for account: Account) -> Decimal {
    // Get the chronologically latest update (not just the last in array)
    account.updates
        .sorted { $0.date < $1.date }
        .last?.value ?? 0
}
```

**⚠️ NEVER USE**: `account.updates.last?.value` - SwiftData doesn't guarantee chronological order!

### Portfolio Total Calculation
**Simple real-time summation:**
```swift
private var totalPortfolioValue: Decimal {
    return activeAccounts.reduce(0) { total, account in
        total + currentValue(for: account)
    }
}
```

### Chart Data Generation

#### Account Charts
**Real-time calculation from updates:**
```swift
private var chartDataPoints: [ChartDataPoint] {
    let sortedUpdates = account.updates.sorted { $0.date < $1.date }
    return sortedUpdates.map { update in
        ChartDataPoint(date: update.date, value: update.value)
    }
}
```

#### Portfolio Charts
**Incremental calculation from all updates:**
```swift
private var chartDataPoints: [ChartDataPoint] {
    // Get all updates from all active accounts, sorted chronologically
    let allUpdates = accounts.flatMap { $0.updates }
        .sorted { $0.date < $1.date }
    
    var portfolioPoints: [ChartDataPoint] = []
    var currentAccountValues: [String: Decimal] = [:] // Track running values
    
    // For each update, recalculate portfolio total incrementally
    for update in allUpdates {
        currentAccountValues[update.account?.name ?? ""] = update.value
        let portfolioTotal = currentAccountValues.values.reduce(0, +)
        portfolioPoints.append(ChartDataPoint(date: update.date, value: portfolioTotal))
    }
    
    return portfolioPoints
}
```

## Chart Implementation & Visual Styling

### Chart Visual Configuration
- **Chart Type**: Line charts with `.linear` interpolation
- **Account Charts**: Blue line (1.5px width) with light blue gradient area fill
- **Portfolio Charts**: Blue line (2.5px width) with points to show portfolio changes
- **Date Range**: Always extends to today to show data freshness
- **Axis Labels**: 4 automatic date marks, formatted currency values

### Chart Reactivity System
**Enhanced reactivity for immediate updates:**
```swift
PortfolioChart(accounts: accounts)
    .frame(height: 200)
    .id("\(accounts.count)-\(totalUpdateCount)") // Force refresh when accounts or updates change
```

**Why this works:**
- `accounts.count` changes when accounts are deleted/added
- `totalUpdateCount` changes when any account is updated
- SwiftUI recreates the chart when the ID changes

### Chart Date Range Logic
**Always show full context:**
```swift
private var chartDateRange: ClosedRange<Date> {
    guard let firstDate = chartDataPoints.first?.date,
          let lastDate = chartDataPoints.last?.date else {
        let today = Date()
        return today...today
    }
    
    // Ensure the range always extends to today to show full context
    let today = Calendar.current.startOfDay(for: Date())
    let endDate = max(lastDate, today)
    
    return firstDate...endDate
}
```

## Data Flow & Performance

### Data Update Flow
**When user adds new account value update:**
1. **Create AccountUpdate**: Store raw update with exact timestamp and value
2. **UI Updates Automatically**: SwiftUI reactivity triggers chart recalculation
3. **Real-time Charts**: Charts calculate data points from all updates on-demand

### Performance Characteristics
**Storage Efficiency:**
- **Old system**: 4,000+ snapshot records for 6 accounts over 2 years
- **New system**: ~200-300 update records (only when users make changes)
- **Reduction**: 95% less data storage required

**Calculation Performance:**
- **Account current value**: O(n log n) where n = updates per account (~5-50 updates)
- **Portfolio total**: O(m) where m = number of accounts (~8 accounts)
- **Chart generation**: O(n log n) where n = total updates (~200-300 updates)
- **All operations complete in milliseconds**

**Memory Usage:**
- No cached data to manage
- Minimal memory footprint
- No risk of memory leaks from cached snapshots

## UI Requirements & Implementation

### Account Detail Views
- **Current Value**: Calculated from chronologically latest update
- **Update History**: Sorted by date (newest first) for user display
- **Charts**: Generated from account's updates in real-time

### Portfolio Dashboard
- **Total Value**: Real-time summation of all active account current values
- **Account List**: Shows current value for each account
- **Portfolio Chart**: Calculated from all updates across all accounts

### Update Display Format
- **Full timestamps**: "27 Jul 2025, 14:30" format for all updates
- **Chart time**: Shows dates only, not times for cleaner visualization
- **Currency formatting**: £1,234.56 with safe number formatting for large values

## Development Best Practices

### SwiftData Usage
- Use `@Model` for SwiftData entities
- Use `Decimal` for money values (not Double) for precision
- Store dates in UTC, format locally in UI
- Use `@Relationship(deleteRule: .cascade)` for data integrity
- Always sort updates by date when calculating values

### Chart Implementation
- Use `.linear` interpolation for financial data
- Limit chart data points if performance becomes an issue (unlikely with ~300 points)
- Cache expensive computations in chart initializers if needed
- Use proper date ranges that extend to today

### Code Organization
- Keep calculation logic in computed properties
- Use descriptive variable names for financial calculations
- Add debug logging for troubleshooting value calculations
- Follow MVVM patterns with SwiftUI

## Account Management

### Account Lifecycle
- **Creation**: Users create accounts with name only, add initial value as first update
- **Updates**: Add timestamped value updates at any time
- **History**: Full update history preserved with exact timestamps
- **Current Value**: Always calculated from chronologically latest update
- **Closing**: Set `isActive = false` and `closedAt` date (preserves history)
- **Deletion**: Complete removal including all updates (cascade delete)

### Data Integrity
- SwiftData relationships with cascade delete ensure no orphaned updates
- Account closing preserves all historical data
- Update deletion recalculates current values automatically

## Testing Strategy

### Test Data Sets
**Organized test data for different scenarios:**

- **Set 1 (Real Financial Data)**: 7 accounts with actual historical financial values
  - 42 total updates across 7 accounts over 6 dates (01/05/2025 to 01/08/2025)
  - All updates timestamped at 08:00 for consistency
  - Real account names and values for authentic testing scenarios

- **Set 2 (Large Historic Data)**: 6 synthetic accounts with 2 years of data
  - Tests performance with larger datasets (~200+ updates)
  - Simulates long-term usage patterns

- **Set 3 (Simple Patterns)**: 2 accounts with predictable increments for math verification
  - Account 1: £100 on 1st of each month for 6 months (total £600)
  - Account 2: £100 on 15th of each month for 6 months (total £600)
  - Perfect for testing calculation accuracy and chart generation

### Testing Approach
- **Unit tests**: Data models and calculation logic
- **UI tests**: Critical user flows (account creation, updates, charts)
- **Performance tests**: Chart rendering with various dataset sizes
- **Manual testing**: Use test data sets to verify calculations

## Build & Development

### Build Requirements
- Open `PlainTextMoney.xcodeproj` in Xcode
- No external dependencies or setup required
- Build and run with Cmd+R

### SDK Compatibility
- **Deployment Target**: iOS 17.0 minimum
- **Development**: Xcode 16 Beta with iOS 26 support
- **Testing**: Use iOS 18.4 or 18.5 simulators for stability

## 🚨 CRITICAL TECHNICAL DECISIONS & LESSONS LEARNED

### Current Value Calculation (MANDATORY)
**🔧 PROBLEM SOLVED**: Incorrect current values due to array order assumptions

**✅ MANDATORY IMPLEMENTATION**:
```swift
// ✅ CORRECT: Always sort by date first
private func currentValue(for account: Account) -> Decimal {
    account.updates
        .sorted { $0.date < $1.date }
        .last?.value ?? 0
}

// ❌ NEVER USE: Assumes array order
private func currentValue(for account: Account) -> Decimal {
    account.updates.last?.value ?? 0  // WRONG!
}
```

**WHY CRITICAL**: SwiftData relationships don't guarantee chronological order. Updates could be stored in creation order, not date order.

### Chart Reactivity (MANDATORY)
**🔧 PROBLEM SOLVED**: Charts not updating when accounts deleted

**✅ MANDATORY IMPLEMENTATION**:
```swift
PortfolioChart(accounts: accounts)
    .id("\(accounts.count)-\(totalUpdateCount)")
```

**WHY CRITICAL**: SwiftUI needs explicit identity changes to recreate charts when underlying data changes dramatically.

### SwiftData Threading Rules (MANDATORY)
- **RULE**: SwiftData ModelContext is NOT thread-safe and must stay on original queue
- **NEVER DO**: `Task.detached { modelContext.fetch() }` → CRASHES with "Unbinding from main queue"
- **ALWAYS DO**: Use `@MainActor` for async SwiftData operations
- **WHY**: Prevents "Could not cast to PersistentModel" crashes and thread safety violations

### Build System Stability
**🚨 COMMON ISSUE**: Build failures with iOS 26.0 Beta SDK
- **Symptoms**: "Undefined symbols", "Could not find swift_DarwinFoundation" errors
- **Solution**: Use iOS 18.4 or 18.5 simulators for stable builds
- **Quick fix**: `xcodebuild clean` + switch to stable simulator OS

### Performance Architecture Pattern
**📊 OPTIMAL DATA FLOW**:
1. **Raw Updates**: Store user input with exact timestamps (minimal data)
2. **Current Values**: Calculate from latest update per account (O(n log n) per account)
3. **Portfolio Totals**: Sum current values (O(m) where m = account count)
4. **Chart Data**: Generate from all updates chronologically (O(n log n) total)

**💡 KEY INSIGHT**: With ~300 updates total, all calculations complete in milliseconds. No caching needed!

## Architecture Evolution & Context

### Why Update-Only Architecture?
**Previous approach**: Complex snapshot caching system
- 4,000+ daily snapshots pre-calculated and stored
- 870+ lines of maintenance logic
- Cache invalidation and sync complexity
- Stale data risks

**Current approach**: Real-time calculations
- 200-300 raw update records
- Simple, predictable calculations
- Always accurate, never stale
- 95% less storage, much simpler code

### Performance Comparison
| Metric | Old (Snapshots) | New (Updates) | Improvement |
|--------|----------------|---------------|-------------|
| Data Records | 4,000+ | ~300 | 93% reduction |
| Code Lines | 1,400+ | ~500 | 64% reduction |
| Calculation Time | Instant (cached) | <10ms (real-time) | Negligible difference |
| Storage Size | Large | Minimal | 95% reduction |
| Complexity | High | Low | Much simpler |
| Accuracy Risk | Stale data possible | Always accurate | Zero risk |

### Migration Benefits Achieved
- ✅ **Simplified architecture**: Easy to understand and maintain
- ✅ **Better performance**: Less data, faster operations
- ✅ **Improved reliability**: No cache invalidation bugs
- ✅ **Easier debugging**: Clear data flow, predictable calculations
- ✅ **Future-proof**: Scales naturally with user data growth

## Debug & Performance Monitoring

### Debug Logging
**Comprehensive logging for troubleshooting:**
```swift
#if DEBUG
print("💰 Portfolio total: £\(total) from \(activeAccounts.count) active accounts")
for account in activeAccounts {
    print("   \(account.name): £\(currentValue(for: account)) (\(account.updates.count) updates)")
}
#endif
```

### Safe Number Formatting
**Prevents crashes with large numbers:**
```swift
private func formatLargeNumber(_ value: Double) -> String {
    if value >= 1_000_000 {
        return String(format: "%.1fM", value / 1_000_000)
    } else if value >= 1_000 {
        return String(format: "%.0fk", value / 1_000)
    } else {
        return String(format: "%.0f", value)
    }
}
```

### Performance Monitoring
- All calculations complete in milliseconds
- Memory usage stays minimal
- No memory leaks from cached data
- UI remains responsive during large dataset operations

## Data Persistence Strategy

### Local Storage
- All data stored locally using SwiftData
- Raw update history maintained for full audit trail
- No external dependencies or cloud storage required
- Future-ready for potential iCloud sync or export features

### Data Integrity
- Cascade delete rules ensure no orphaned data
- Account closing preserves all historical updates
- Update deletion automatically recalculates dependent values
- Real-time calculations eliminate data inconsistency risks