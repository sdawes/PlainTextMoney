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