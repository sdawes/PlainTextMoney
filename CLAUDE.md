# 📱 Savings & Portfolio Tracker App

## Project Overview
This is an iOS app built with SwiftUI and SwiftData for tracking multiple savings and investment accounts. The app is designed to be offline-first, storing all data locally for privacy and performance while providing fast, smooth charts of account and portfolio growth.

## Technology Stack
- **Platform**: iOS
- **UI Framework**: SwiftUI
- **Data Persistence**: SwiftData
- **Development Environment**: Xcode
- **Language**: Swift

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
- `date`: Date - Snapshot date
- `value`: Decimal - End-of-day account value
- `account`: Account - Link to parent account

### `PortfolioSnapshot`
Daily snapshot of total value of all active accounts.
- `date`: Date - Snapshot date
- `totalValue`: Decimal - Total portfolio value on that day

## Data Update Flow
1. User adds new update → Create new `AccountUpdate`
2. Update or insert today's `AccountSnapshot` for that account
3. Recalculate portfolio total across all active accounts
4. Update or insert today's `PortfolioSnapshot`

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