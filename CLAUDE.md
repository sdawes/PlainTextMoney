# 📱 Savings & Portfolio Tracker App

## Project Overview
This is an iOS app built with SwiftUI and SwiftData for tracking multiple savings and investment accounts. The app is designed to be offline-first, storing all data locally for privacy and performance while providing fast, smooth charts of account and portfolio growth.

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
- Clean design with pre-aggregated data for performance

## Data Models (SwiftData)

### `Account`
Represents each savings or investment account.
- `name`: String - User-given name (e.g. "ISA Savings")
- `createdAt`: Date - When the account was created
- `isActive`: Bool - True if account is open; false if closed
- `closedAt`: Date? - Date the account was closed, if any
- `updates`: [AccountUpdate] - All raw updates made by user
- `snapshots`: [AccountSnapshot] - Daily snapshots for charts

### `AccountUpdate`
Each time the user changes an account's value.
- `value`: Decimal - New account value (£)
- `date`: Date - Exact date & time when update was made
- `account`: Account - Link to parent account

### `AccountSnapshot`
Daily snapshot of an account's value for chart performance.
- `date`: Date - Snapshot date (normalized to start-of-day for consistent daily keys)
- `value`: Decimal - Latest known account value for that calendar day
- `account`: Account - Link to parent account

**AccountSnapshot Logic:**
- **One snapshot per account per calendar day** (date normalized to start-of-day)
- **Same-day updates**: If user updates account multiple times in one day, replace that day's snapshot with the latest update value
- **Days with no updates**: Create snapshot using the most recent update value from any previous day (carry forward)
- **Purpose**: Enables fast chart rendering and historical account value lookup without scanning all AccountUpdates

### `PortfolioSnapshot`
Daily snapshot of total value of all active accounts.
- `date`: Date - Snapshot date (normalized to start-of-day for consistent daily keys)
- `totalValue`: Decimal - Sum of all active accounts' snapshot values for that calendar day

**PortfolioSnapshot Logic:**
- **One snapshot per calendar day** for total portfolio value
- **Calculation**: Sum of all active accounts' AccountSnapshot values for that specific day
- **Trigger**: Recalculated whenever any AccountSnapshot is created/updated for that day
- **Historical gaps**: When creating snapshots for past days, carry forward each account's most recent value and sum for portfolio total
- **Purpose**: Enables fast portfolio chart rendering and current total display without real-time aggregation across all accounts

## Data Update Flow
**When user adds new account value update:**
1. **Create AccountUpdate**: Store raw update with exact timestamp and value
2. **Update AccountSnapshot**: Create or replace today's snapshot for that account with the new value
3. **Update PortfolioSnapshot**: Recalculate today's portfolio total using all active accounts' snapshot values for today
4. **Historical backfill** (if needed): Fill any missing daily snapshots between last snapshot and today by carrying forward previous values

**Snapshot Update Rules:**
- AccountSnapshot uses latest update value for that calendar day (regardless of time)
- PortfolioSnapshot sums all active accounts' snapshot values for that day
- Both snapshots use start-of-day dates as keys for consistent daily aggregation
- Missing days are backfilled by carrying forward the most recent known values

## AccountSnapshot Implementation

### Complete Daily Coverage System
The AccountSnapshot system ensures **perfect daily coverage** with zero gaps:

**Key Features:**
- **4,392+ snapshots** for 6 accounts over 2 years (732 snapshots per account)
- **Automatic gap filling**: Every day from account creation to today has exactly one snapshot
- **Carry-forward logic**: Days without updates use the most recent account value
- **Performance optimized**: Charts query snapshots instead of scanning all updates

### SnapshotService Implementation
**Core Functions:**
- `updateAccountSnapshot()`: Creates/updates daily snapshots when users add updates
- `fillMissingSnapshots()`: Fills all gaps from account creation to specified date
- `ensureCompleteSnapshotCoverage()`: Guarantees complete daily coverage for an account
- `getValueForDate()`: Determines correct value for any given date using carry-forward logic

**Gap Filling Logic:**
```
For each day from account creation to today:
  - If user update exists for that day → use latest update value
  - If no update exists → carry forward most recent value from previous day
  - Result: Continuous daily snapshots with no gaps
```

### Integration Points
**Account Creation:** `AddAccountView` calls `SnapshotService.updateAccountSnapshot()` for initial value
**Account Updates:** `AccountDetailView` calls `SnapshotService.updateAccountSnapshot()` for new values
**Test Data:** `TestDataGenerator` uses `ensureCompleteSnapshotCoverage()` for historical backfill

### Verification & Debugging
**Debug Tools (Development Only):**
- `printSnapshotDebugInfo()`: Analyzes individual account coverage
- `verifyAllAccountSnapshots()`: Comprehensive verification across all accounts
- "Debug Snapshots" button: Real-time verification in app
- Console logging: Shows gap filling progress during data generation

**Expected Results:**
- Each account: 730+ snapshots (one per day from creation)
- Total system: 4,000+ snapshots across all accounts
- Zero gaps: Continuous daily coverage verified
- Performance: Instant chart queries using pre-aggregated data

## Architecture & Performance
- **Pre-aggregation**: Daily snapshots provide fast chart data without scanning full history
- **Current Values**: Always available from latest `AccountUpdate` and `PortfolioSnapshot`
- **Data Relationships**: Use `@Relationship(deleteRule: .cascade)` for clean data management
- **Architecture**: Follow MVVM or clean architecture patterns
- **Service Layer**: Keep snapshot update logic separate from views

## UI Requirements
- **Account Screens**: Show current value and growth chart from snapshots
- **Portfolio Screen**: Show total value and portfolio growth chart
- **Updates Display**: Full date & time format (e.g. "27 Jul 2025, 14:30")
- **Charts**: Fast, smooth performance using pre-aggregated snapshot data

## Development Best Practices
- Use `@Model` for SwiftData entities
- Use `Decimal` for money values (not Double) for precision
- Store dates in UTC, format locally in UI
- Implement cascade delete rules to maintain data integrity
- Keep data update logic in service classes, not views
- Design for offline-first operation

## Account Management
- **Creation**: Users can create accounts with just a name
- **Updates**: Add value updates with timestamps at any time
- **History**: Full update history preserved with exact timestamps
- **Closing**: Set `isActive = false` and `closedAt` date (preserves history)
- **Deletion**: Complete removal including all updates and snapshots

## Data Persistence Strategy
- All data stored locally using SwiftData
- Raw update history maintained for full audit trail
- Daily snapshots cached for chart performance
- No external dependencies or cloud storage required
- Future-ready for potential iCloud sync or export features

## Testing Approach
- Unit tests for data models and business logic
- UI tests for critical user flows
- Performance tests for chart rendering with large datasets
- Test account creation, updates, and closing scenarios

## Build & Run
- Open `PlainTextMoney.xcodeproj` in Xcode
- Select target device or simulator
- Build and run with Cmd+R
- No external dependencies or setup required

## 🚨 CRITICAL TECHNICAL DECISIONS & PERFORMANCE LESSONS
**⚠️ NEVER UNDO THESE - LEARNED THE HARD WAY ⚠️**

### SwiftData Threading Rules (MANDATORY)
- **RULE**: SwiftData ModelContext is NOT thread-safe and must stay on original queue
- **NEVER DO**: `Task.detached { modelContext.fetch() }` → CRASHES with "Unbinding from main queue"
- **ALWAYS DO**: Use `@MainActor` for async SwiftData operations
- **WHY**: Prevents "Could not cast to PersistentModel" crashes and thread safety violations
- **IMPLEMENTATION**: All SnapshotService async methods use `@MainActor`

### Portfolio Performance Architecture
- **PROBLEM SOLVED**: Portfolio snapshots prevent expensive real-time calculations
- **CRITICAL FIX**: Portfolio total uses smart snapshot detection - only TODAY's snapshots, fallback to real-time
- **NEVER REVERT TO**: Always using snapshots (causes stale data during recalculation)
- **PERFORMANCE GAIN**: Instant portfolio total updates + background historical accuracy

### Async Portfolio Recalculation Strategy
- **CHUNKED PROCESSING**: Process 50 days at a time with `await Task.yield()` between chunks
- **WHY**: Prevents UI blocking on large historical recalculations (732+ snapshots)
- **NEVER DO**: Single large transaction - freezes UI for seconds
- **IMPLEMENTATION**: Save after each chunk, yield to UI, progress logging

### Chart Smoothing Configuration
- **INTERPOLATION**: Use `.monotone` for financial data (preserves trends without false peaks)
- **ACCOUNT CHARTS**: Black line, 1.5px width, `.monotone`  
- **PORTFOLIO CHARTS**: Blue line, 2.0px width, `.monotone`
- **WHY**: Eliminates jagged lines from minimal account updates while maintaining data integrity

### SwiftData Model Registration
- **ALL MODELS MUST BE REGISTERED**: `[Account.self, AccountUpdate.self, AccountSnapshot.self, PortfolioSnapshot.self]`
- **FAILURE MODE**: Silent failures in fetch/insert operations if models not registered
- **LOCATION**: PlainTextMoneyApp.swift `.modelContainer(for: ...)`

### Data Flow Performance Rules  
- **ACCOUNT OPERATIONS**: Account changes → Account snapshots → Portfolio snapshots (all updates)
- **DELETE OPERATIONS**: Use async portfolio recalculation to prevent UI blocking
- **PORTFOLIO TOTAL**: Smart caching with real-time fallback for immediate responsiveness
- **CHART DATA**: Pre-aggregated snapshots only (never raw updates for charts)

### Chart Reactivity Fix (CRITICAL - DO NOT UNDO)
**🚨 PROBLEM SOLVED**: Charts not updating after deleting historical values
**🔧 ROOT CAUSE**: SwiftData relationship caching + incomplete snapshot deletion

**MANDATORY IMPLEMENTATION**:
1. **Use @Query for Chart Data (NOT relationships)**:
   - `@Query private var allSnapshots: [AccountSnapshot]` in views
   - Filter with computed property: `allSnapshots.filter { $0.account == account }`
   - **NEVER access snapshots via**: `account.snapshots` for chart data
   - **WHY**: @Query is reactive to database changes, relationships cache and don't auto-update UI

2. **Complete Snapshot Deletion Logic**:
   - **When deleting updates**: Always recalculate from deletion date to TODAY+1 (not just to next update)
   - **When zero updates remain**: Delete ALL snapshots for that account
   - **Proper relationship management**: Remove from relationship AND model context
   - **WHY**: Prevents stale snapshots from showing outdated chart data

3. **SwiftData Update Deletion Pattern**:
   ```swift
   // Remove from relationship first
   if let index = account.updates.firstIndex(of: update) {
       account.updates.remove(at: index)
   }
   // Then delete from context
   modelContext.delete(update)
   ```

**SYMPTOMS OF REGRESSION**: 
- Chart shows old values after deleting historical updates
- Update count shows 0 but chart still displays line
- Snapshot count doesn't match expected empty state

**TESTING VERIFICATION**:
- Load Test Set 3, delete all "Minimal Updates" values
- Chart should show "No data available" when empty
- Debug logs should show: `accountSnapshots.count: 0`, `Chart will show: 'No data available'`

### Snapshot Recalculation Logic Fix (CRITICAL - DO NOT UNDO)
**🚨 PROBLEM SOLVED**: Chart spikes after deleting middle updates
**🔧 ROOT CAUSE**: Incorrect carry-forward logic in snapshot recalculation

**MANDATORY IMPLEMENTATION**:
```swift
// CRITICAL: Dynamic carry-forward value that updates as we encounter remaining updates
var currentCarryForwardValue = previousValue

while currentDate < endDate {
    if let latestUpdateForDay = updatesForDate.first {
        valueToUse = latestUpdateForDay.value
        currentCarryForwardValue = latestUpdateForDay.value  // CRITICAL: Update carry-forward
    } else if let carryForward = currentCarryForwardValue {
        valueToUse = carryForward  // CRITICAL: Use current carry-forward, not original
    }
}
```

**WHY CRITICAL**: Without dynamic carry-forward, deleting middle updates causes:
- Charts to show spikes (jumps to future values then back down)
- Incorrect step-wise progression in account and portfolio charts
- Visual confusion about account value history

**TESTING VERIFICATION**:
- Load Set 3 → Delete middle update → Chart should show smooth steps, no spikes
- Portfolio chart should reflect accurate aggregated values without artifacts

### Chart Date Range Fix (CRITICAL - DO NOT UNDO)  
**🚨 PROBLEM SOLVED**: X-axis not showing current date when last update was months ago
**🔧 ROOT CAUSE**: Chart date range ending at last data point instead of today

**MANDATORY IMPLEMENTATION**:
```swift
private var chartDateRange: ClosedRange<Date> {
    // CRITICAL: Always extend to today to show full context
    let today = Calendar.current.startOfDay(for: Date())
    let endDate = max(lastDate, today)
    return firstDate...endDate
}

// CRITICAL: Apply to BOTH AccountChart and PortfolioChart
.chartXAxis {
    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
        // Increased from 3 to 4 to show more date labels including today
    }
}
.chartXScale(domain: chartDateRange)  // CRITICAL: Force full date range
```

**WHY CRITICAL**: Shows user that account hasn't been updated recently via flat line extending to today. Missing current date creates confusion about data freshness.

**TESTING VERIFICATION**:
- When today is August but last update was May → X-axis should show "Aug"
- Chart should show flat line from last update to today (not truncated)
- Both account and portfolio charts should have consistent date ranges

### Test Data System Organization
**SIMPLIFIED UI**: Compact horizontal layout with 4 buttons: "Set 1", "Set 2", "Set 3", "Clear"

**Data Sets**:
- **Set 1 (Personal)**: 7 real accounts with actual finance values over 5 dates
- **Set 2 (Historic)**: 6 synthetic accounts with 2 years of data (4000+ snapshots)  
- **Set 3 (Patterns)**: 2 simple accounts with predictable increments for math verification
  - Account 1: £500 increments on 1st & 15th of each month
  - Account 2: £100 increments at 15, 35, 50, 70 days after creation

**WHY ORGANIZED**: Each set tests different scenarios - realistic data, performance with large datasets, and simple predictable patterns for debugging math logic.

### iOS 26 Development Notes
- **DEPLOYMENT TARGET**: iOS 17.0 minimum (NOT 26.0 - that was invalid and caused build failures)
- **XCODE VERSION**: Xcode 16 Beta with year-based versioning system
- **SWIFT CHARTS**: iOS 16.0+ required for chart interpolation features

### Build & Simulator Issues (COMMON RECURRING PROBLEMS)
**🚨 SYMPTOM**: Build failures with "Undefined symbols" or "Could not find or use auto-linked library" errors
**🔧 ROOT CAUSE**: iOS 26.0 Beta SDK instability and missing SwiftData symbols in beta toolchain

**SOLUTIONS (in order of preference):**
1. **Use iOS 18.4/18.5 simulators** - Most stable option:
   ```bash
   xcodebuild -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4'
   ```

2. **Clean build when switching SDK versions**:
   ```bash
   xcodebuild clean -project PlainTextMoney.xcodeproj -scheme PlainTextMoney
   ```

3. **SDK-specific issues to watch for**:
   - `swift_DarwinFoundation1/2/3` library not found → SDK instability
   - `SwiftUICore.framework` linking errors → Use older simulator OS
   - SwiftData symbol errors → Clean build + use stable iOS version

**NEVER WASTE TIME ON**: Trying to fix iOS 26.0 beta linker issues - use stable simulators instead

**QUICK FIX SEQUENCE**:
1. `xcodebuild clean`
2. Switch to iOS 18.4 or 18.5 simulator  
3. Build with stable SDK version
4. Test functionality on stable platform

**WHY THIS KEEPS HAPPENING**: Xcode 16 Beta defaults to iOS 26.0 which has incomplete SwiftData libraries and framework linking issues. Always verify simulator OS version before building.

## Performance Monitoring
- Debug logs show async recalculation progress
- Portfolio verification tools available in debug builds
- Monitor for "Unbinding from main queue" errors (indicates threading violations)