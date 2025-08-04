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

### 2. Threading Rules (CRITICAL)
- SwiftData ModelContext is NOT thread-safe
- NEVER use `Task.detached` with SwiftData operations
- ALWAYS use `@MainActor` for async SwiftData operations
- Use `await Task.yield()` in long-running operations

### 3. UI Performance Rules
- Cache expensive computations in view initializers, not computed properties
- Limit chart data to reasonable amounts (300-500 points max)
- Pre-aggregate data for display instead of real-time calculations
- Use simple arithmetic for totals/summaries when possible

### 4. Data Architecture Pattern
- Raw Data: Store user input with exact timestamps
- Aggregated Data: Pre-calculate for charts/reports
- Display Totals: Use simple math on current values, not database queries
- Relationships: Use cascade delete rules for data integrity

### 5. Performance Monitoring
Create a PerformanceDebugger that tracks:
- Operation timing (flag anything >100ms)
- Memory usage alerts
- SwiftData operation logging
- UI lifecycle tracking

### 6. Common Anti-Patterns to Avoid
❌ Complex database queries for simple arithmetic
❌ Repeated expensive calculations in SwiftUI computed properties  
❌ Unbounded database queries without limits
❌ Thread-unsafe SwiftData operations
❌ Excessive debug logging in performance-critical paths

### 7. Performance Targets
- ⚡ Database operations: <50ms
- ✅ UI updates: <100ms  
- ⚠️ Complex calculations: <200ms
- 🚨 Anything >500ms needs immediate optimization

Please implement these patterns from the beginning and remind me if I suggest anything that violates these performance rules.

---

**Based on successful optimization of PlainTextMoney app that achieved:**
- Portfolio calculations: Complex queries → Simple O(n) arithmetic
- Chart rendering: Repeated calculations → Pre-cached values
- Database performance: Unbounded queries → Limited, optimized queries
- Threading stability: Crash-prone → Rock solid @MainActor pattern