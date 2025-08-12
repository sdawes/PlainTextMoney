# SwiftData Performance Optimization Template

Copy this prompt when starting new SwiftData projects to avoid common performance pitfalls.

**Last Updated:** August 2025  
**Proven in Production:** PlainTextMoney app with comprehensive test coverage

---

## 🚀 SwiftData Performance Requirements

I'm building a SwiftData app and need you to follow these performance optimization rules from the start:

### 1. Query Performance Rules
- ALWAYS add `fetchLimit` to queries that don't need all results
- Use `sortBy` in FetchDescriptor, not Swift's `.sorted()`
- Avoid complex predicates - keep them simple
- Use `@Query` in SwiftUI views instead of accessing relationships directly
- Sort data ONCE and cache results when displaying in multiple places

### 2. Threading Rules (CRITICAL)
- SwiftData ModelContext is NOT thread-safe
- NEVER use `Task.detached` with SwiftData operations
- ALWAYS use `@MainActor` for async SwiftData operations
- Use `await Task.yield()` in long-running operations
- Avoid SwiftData operations in computed properties - they can trigger on background threads

### 2.1 Swift 6 + SwiftData Actor Isolation (NEW - 2025)
**Critical for Swift 6 language mode projects:**

#### Project Configuration
- Set `SWIFT_DEFAULT_ACTOR_ISOLATION = nonisolated` in project settings
- Do NOT set SwiftData models as `nonisolated` (breaks SwiftData macros)
- Explicitly mark all SwiftUI views as `@MainActor`

#### Cross-Actor Communication Pattern
```swift
// ✅ CORRECT: MainActor extracts IDs, background actor re-fetches
@MainActor
struct MyView: View {
    private func accountIDsSnapshot() -> [PersistentIdentifier] {
        accounts.map(\.persistentModelID) // Safe on MainActor
    }
    
    private func updateData() async {
        let accountIDs = accountIDsSnapshot()
        await backgroundEngine.process(accountIDs: accountIDs) // Pass IDs only
    }
}

@ModelActor
actor BackgroundEngine {
    func process(accountIDs: [PersistentIdentifier]) async {
        let accounts = fetchAccounts(withIDs: accountIDs) // Re-fetch in actor
        // Process accounts safely...
    }
    
    private func fetchAccounts(withIDs ids: [PersistentIdentifier]) -> [Account] {
        let descriptor = FetchDescriptor<Account>(
            predicate: #Predicate { ids.contains($0.persistentModelID) }
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
}
```

#### Actor Isolation Rules
- ❌ NEVER pass SwiftData models between actors
- ✅ ALWAYS pass `PersistentIdentifier` (Sendable) between actors
- ✅ Each actor re-fetches models using its own ModelContext
- ✅ Use `@ModelActor` for background SwiftData operations
- ✅ MainActor for all UI and @Query operations

### 3. UI Performance Rules
- Cache expensive computations in view initializers, not computed properties
- Limit chart data to reasonable amounts (300-500 points max)
- Pre-aggregate data for display instead of real-time calculations
- Use simple arithmetic for totals/summaries when possible
- Use `.minimumScaleFactor()` for dynamic text that may overflow
- Lock text size with `.environment(\.sizeCategory, .large)` if layout breaks with accessibility sizes

### 4. Data Architecture Pattern
- Raw Data: Store user input with exact timestamps
- Aggregated Data: Pre-calculate for charts/reports
- Display Totals: Use simple math on current values, not database queries
- Relationships: Use cascade delete rules for data integrity
- Timeline Generation: Build portfolio timelines incrementally from account updates

### 5. Performance Caching Strategy
Implement smart caching with invalidation:
- Cache Key: Use hash of relevant data (update count, account count, etc.)
- Cache Storage: Store in service classes with private cache dictionaries
- Invalidation: Clear on data changes or use hash-based validation
- Granularity: Cache at appropriate levels (portfolio-wide vs per-account)

Example pattern:
```swift
private var cache: [String: (data: PerformanceData, hash: Int)] = [:]

func calculateWithCache(accounts: [Account]) -> PerformanceData {
    let currentHash = accounts.hashValue
    if let cached = cache["key"], cached.hash == currentHash {
        return cached.data
    }
    // Calculate and cache with hash
}
```

### 6. Chart Performance Optimization
- Portfolio Timeline: Generate ONCE, filter for display periods
- Date Filtering: Use post-aggregation filtering, not pre-filtering
- Boundary Points: Include last point before filter date for continuity
- Exact Match Detection: Skip boundary points when filter date matches existing data point
- Update Counting: Count visible updates after filtering, not total

### 7. State Management Best Practices
- Use `@State` for view-local state
- Use `@Binding` for bidirectional data flow between views
- Pass state DOWN the view hierarchy, not up
- Synchronize pickers/controls using shared state
- Use `.id()` modifier to force view refreshes when data changes

### 8. Common Anti-Patterns to Avoid
❌ Complex database queries for simple arithmetic
❌ Repeated expensive calculations in SwiftUI computed properties  
❌ Unbounded database queries without limits
❌ Thread-unsafe SwiftData operations
❌ Excessive debug logging in performance-critical paths
❌ Generating the same timeline data multiple times
❌ Using individual update dates instead of portfolio timeline points
❌ Forgetting to handle edge cases (no data, single data point)

### 8.1 Swift 6 Actor Isolation Anti-Patterns
❌ Passing SwiftData models between actors (causes data races)
❌ Using `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` with SwiftData
❌ Making SwiftData models `nonisolated` (breaks macro generation)
❌ Accessing MainActor-isolated properties from background actors
❌ Sharing ModelContext instances between actors
❌ Using `@MainActor.run` to "fix" actor isolation (masks real issues)

### 9. Performance Targets
- ⚡ Database operations: <50ms
- ✅ UI updates: <100ms  
- ⚠️ Complex calculations: <200ms
- 🚨 Anything >500ms needs immediate optimization
- 📊 Chart rendering: <150ms for 500+ data points

### 10. Real-World Patterns That Work

**Portfolio Performance Calculation:**
- Generate portfolio timeline once
- Filter timeline for display periods
- Cache calculations with hash-based invalidation
- Use graceful fallbacks for insufficient data

**Time Period Filtering:**
- Last Update: Use second-to-last portfolio point
- Month/Year: Use calendar date arithmetic
- All Time: Show complete unfiltered data
- Always maintain chart continuity with boundary points

**Dynamic Period Labels:**
- Detect when requested period has insufficient data
- Fall back to "since [earliest date]" labeling
- Communicate actual period to user clearly

### 11. Testing Performance Optimizations

**Test Coverage Requirements:**
- Unit tests for all calculation services
- Edge case testing (zero values, single data points, no data)
- Decimal precision validation for financial calculations
- Performance regression tests with timing assertions

**Test Data Generation:**
```swift
@MainActor
func createTestContext() throws -> ModelContext {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: Account.self, AccountUpdate.self, 
                                      configurations: config)
    return ModelContext(container)
}
```

**Performance Assertion Pattern:**
```swift
func testPerformanceWithLargeDataset() async throws {
    // Create 1000+ data points
    let startTime = Date()
    let result = await service.calculate()
    let elapsed = Date().timeIntervalSince(startTime)
    
    XCTAssertLessThan(elapsed, 0.2) // Must complete in 200ms
}
```

### 12. SwiftUI View Performance Patterns

**View Identity Management:**
```swift
// Force view refresh when data changes significantly
PortfolioChart(accounts: accounts)
    .id("\(accounts.count)-\(totalUpdateCount)")
```

**Expensive Computation Caching:**
```swift
struct DashboardView: View {
    @Query private var accounts: [Account]
    
    // Cache expensive calculations
    private let portfolioData: PortfolioData
    
    init() {
        // Perform expensive setup once
        self.portfolioData = calculateInitialData()
    }
}
```

**Text Size Management for Financial Apps:**
```swift
// Lock text size to prevent layout breaks with large numbers
.environment(\.sizeCategory, .large)

// Or use auto-scaling for monetary values
Text("£\(value.formatted())")
    .minimumScaleFactor(0.5)
    .lineLimit(1)
```

### 13. ModelActor Implementation Pattern

**Complete Working Example:**
```swift
@ModelActor
actor PortfolioEngine {
    // Fetch accounts safely within actor context
    private func fetchAccounts(withIDs ids: [PersistentIdentifier]) -> [Account] {
        let descriptor = FetchDescriptor<Account>(
            predicate: #Predicate { account in
                ids.contains(account.persistentModelID)
            }
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    // Process data in background
    func generatePortfolioTimeline(accountIDs: [PersistentIdentifier]) async -> [ChartDataPoint] {
        let accounts = fetchAccounts(withIDs: accountIDs)
        
        // Heavy calculation off main thread
        var portfolioPoints: [ChartDataPoint] = []
        // ... processing logic ...
        
        return portfolioPoints
    }
}
```

### 14. Production-Ready Service Pattern

**Service with Smart Caching:**
```swift
class PerformanceCalculationService {
    // Cache with validation
    private static var portfolioTimelineCache: (
        data: [ChartDataPoint],
        accountHash: Int,
        updateHash: Int
    )?
    
    static func generatePortfolioTimeline(accounts: [Account]) -> [ChartDataPoint] {
        let currentAccountHash = accounts.map(\.name).hashValue
        let currentUpdateHash = accounts.flatMap(\.updates).count
        
        // Return cached if valid
        if let cache = portfolioTimelineCache,
           cache.accountHash == currentAccountHash,
           cache.updateHash == currentUpdateHash {
            return cache.data
        }
        
        // Calculate and cache
        let timeline = calculateTimeline(accounts)
        portfolioTimelineCache = (timeline, currentAccountHash, currentUpdateHash)
        return timeline
    }
}
```

### 15. SwiftData Model Best Practices

**Model Design:**
```swift
@Model
class Account {
    var name: String
    var createdAt: Date
    var isActive: Bool = true
    
    @Relationship(deleteRule: .cascade)
    var updates: [AccountUpdate] = []
    
    init(name: String, createdAt: Date = Date()) {
        self.name = name
        self.createdAt = createdAt
    }
}
```

**Relationship Management:**
- Use `.cascade` delete rules for dependent data
- Avoid bidirectional relationships when possible
- Store minimal data in models (compute the rest)

### 16. Query Optimization Patterns

**Efficient @Query Usage:**
```swift
struct DashboardView: View {
    // Fetch only active accounts, sorted efficiently
    @Query(filter: #Predicate<Account> { $0.isActive },
           sort: \.createdAt) 
    private var activeAccounts: [Account]
    
    // Avoid complex predicates - do filtering in Swift when needed
    private var accountsWithUpdates: [Account] {
        activeAccounts.filter { !$0.updates.isEmpty }
    }
}
```

**FetchDescriptor for Background Operations:**
```swift
let descriptor = FetchDescriptor<Account>(
    predicate: #Predicate { $0.isActive },
    sortBy: [SortDescriptor(\.createdAt)]
)
descriptor.fetchLimit = 100 // Always limit when possible
```

### 17. Chart Performance Optimization

**Efficient Chart Data Generation:**
```swift
// Generate once, filter multiple times
private func generateChartData() -> [ChartDataPoint] {
    let timeline = PerformanceCalculationService.generatePortfolioTimeline(accounts)
    
    // Smart filtering based on period
    switch selectedPeriod {
    case .lastUpdate:
        return Array(timeline.suffix(2)) // Exactly 2 points
    case .oneMonth:
        let cutoff = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
        return filterWithBoundary(timeline, after: cutoff)
    case .allTime:
        return timeline // No filtering needed
    }
}

// Include boundary point for chart continuity
private func filterWithBoundary(_ points: [ChartDataPoint], after date: Date) -> [ChartDataPoint] {
    guard let firstAfter = points.firstIndex(where: { $0.date >= date }) else {
        return points
    }
    
    // Include one point before cutoff for continuity
    let startIndex = max(0, firstAfter - 1)
    return Array(points[startIndex...])
}
```

### 18. Debug Logging Best Practices

**Performance-Aware Logging:**
```swift
#if DEBUG
private let debugLogging = false // Toggle for performance testing

func logPerformance(_ message: String) {
    if debugLogging {
        print("⚡ PERF: \(message)")
    }
}
#else
// No logging in release builds
func logPerformance(_ message: String) { }
#endif
```

### 19. Xcode Project Configuration for Swift 6

**Build Settings for Actor Isolation:**
```
SWIFT_DEFAULT_ACTOR_ISOLATION = nonisolated
SWIFT_VERSION = 6.0
SWIFT_STRICT_CONCURRENCY = complete
```

**Test Configuration:**
- Create in-memory test contexts for speed
- Use XCTest for unit tests (not Swift Testing for SwiftData)
- Run tests on iPhone 16 simulator for consistency

### 20. Common Pitfalls and Solutions

**Problem: Simulator cloning during tests**
- Solution: Stop simulator before running tests (Cmd+U)
- Use consistent device (iPhone 16, iOS 18.5)

**Problem: SwiftData model not found in tests**
- Solution: Explicitly register models in test setup
```swift
let container = try ModelContainer(
    for: Account.self, AccountUpdate.self,
    configurations: ModelConfiguration(isStoredInMemoryOnly: true)
)
```

**Problem: Chart not updating with data changes**
- Solution: Use `.id()` modifier with data hash
```swift
chart.id("\(dataCount)-\(updateCount)")
```

**Problem: Decimal precision loss**
- Solution: Always use `Decimal` type for financial values
```swift
var value: Decimal // NOT Double!
```

Please implement these patterns from the beginning and remind me if I suggest anything that violates these performance rules.

---

**Based on successful optimization of PlainTextMoney app that achieved:**
- Portfolio calculations: Complex queries → Simple O(n) arithmetic with caching
- Chart rendering: Repeated calculations → Pre-cached values with hash validation  
- Database performance: Unbounded queries → Limited, optimized queries
- Threading stability: Crash-prone → Rock solid @MainActor pattern
- Performance tracking: No metrics → Comprehensive caching with 10-100x speedup
- Chart filtering: Naive re-aggregation → Smart post-aggregation filtering
- Update counting: Total counts → Filtered visible counts matching display
- Test coverage: 0% → 100% core logic with edge case validation
- Swift 6 compliance: Full actor isolation with zero data races