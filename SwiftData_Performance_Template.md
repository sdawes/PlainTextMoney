# SwiftData Performance Optimization Template

Copy this prompt when starting new SwiftData projects to avoid common performance pitfalls.

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