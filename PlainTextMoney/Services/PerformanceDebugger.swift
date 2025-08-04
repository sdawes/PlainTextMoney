//
//  PerformanceDebugger.swift
//  PlainTextMoney
//
//  Created by Claude on 03/08/2025.
//

import Foundation
import SwiftUI

#if DEBUG
class PerformanceDebugger {
    private static var timers: [String: CFAbsoluteTime] = [:]
    
    // MARK: - Timing Operations
    
    static func startTimer(_ operation: String) {
        let timestamp = CFAbsoluteTimeGetCurrent()
        timers[operation] = timestamp
        print("🚀 START: \(operation) at \(formatTime(timestamp))")
    }
    
    static func endTimer(_ operation: String) {
        let endTime = CFAbsoluteTimeGetCurrent()
        
        guard let startTime = timers[operation] else {
            print("❌ ERROR: No start time found for operation '\(operation)'")
            return
        }
        
        let duration = endTime - startTime
        let durationMs = duration * 1000
        
        let emoji = getPerformanceEmoji(durationMs)
        print("\(emoji) END: \(operation) - Duration: \(String(format: "%.2f", durationMs))ms")
        
        // Remove completed timer
        timers.removeValue(forKey: operation)
        
        // Flag slow operations
        if durationMs > 100 {
            print("⚠️ SLOW OPERATION: '\(operation)' took \(String(format: "%.2f", durationMs))ms")
        }
        
        if durationMs > 500 {
            print("🐌 VERY SLOW: '\(operation)' took \(String(format: "%.2f", durationMs))ms - This needs optimization!")
        }
    }
    
    // MARK: - Memory Monitoring
    
    static func logMemoryUsage(_ context: String) {
        var memoryInfo = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &memoryInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let memoryUsageMB = Double(memoryInfo.resident_size) / 1024.0 / 1024.0
            print("💾 MEMORY: \(context) - \(String(format: "%.1f", memoryUsageMB)) MB")
            
            if memoryUsageMB > 200 {
                print("⚠️ HIGH MEMORY: \(String(format: "%.1f", memoryUsageMB)) MB in \(context)")
            }
        }
    }
    
    // MARK: - UI Operation Tracking
    
    static func logUIOperation(_ operation: String, details: String = "") {
        let timestamp = formatTime(CFAbsoluteTimeGetCurrent())
        let fullDetails = details.isEmpty ? "" : " - \(details)"
        print("🎯 UI: \(operation)\(fullDetails) at \(timestamp)")
    }
    
    // MARK: - SwiftData Operation Tracking
    
    static func logDataOperation(_ operation: String, recordCount: Int? = nil) {
        let timestamp = formatTime(CFAbsoluteTimeGetCurrent())
        let countInfo = recordCount.map { " (\($0) records)" } ?? ""
        print("💾 DATA: \(operation)\(countInfo) at \(timestamp)")
    }
    
    // MARK: - View Lifecycle Tracking
    
    static func logViewLifecycle(_ viewName: String, event: ViewLifecycleEvent) {
        let timestamp = formatTime(CFAbsoluteTimeGetCurrent())
        print("📱 VIEW: \(viewName) - \(event.rawValue) at \(timestamp)")
    }
    
    // MARK: - Navigation Tracking
    
    static func logNavigation(from: String, to: String, action: NavigationAction) {
        let timestamp = formatTime(CFAbsoluteTimeGetCurrent())
        print("🧭 NAV: \(action.rawValue) from \(from) to \(to) at \(timestamp)")
    }
    
    // MARK: - Helper Methods
    
    private static func formatTime(_ time: CFAbsoluteTime) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: Date(timeIntervalSinceReferenceDate: time))
    }
    
    private static func getPerformanceEmoji(_ durationMs: Double) -> String {
        switch durationMs {
        case 0..<50: return "⚡"      // Very fast
        case 50..<100: return "✅"    // Good
        case 100..<200: return "⚠️"   // Slow
        case 200..<500: return "🐌"   // Very slow
        default: return "💀"          // Extremely slow
        }
    }
}

// MARK: - Enums

enum ViewLifecycleEvent: String {
    case appeared = "APPEARED"
    case disappeared = "DISAPPEARED"
    case loading = "LOADING"
    case loaded = "LOADED"
}

enum NavigationAction: String {
    case push = "PUSH"
    case pop = "POP"
    case present = "PRESENT"
    case dismiss = "DISMISS"
}

#else
// Release build - no-op implementations
class PerformanceDebugger {
    static func startTimer(_ operation: String) {}
    static func endTimer(_ operation: String) {}
    static func logMemoryUsage(_ context: String) {}
    static func logUIOperation(_ operation: String, details: String = "") {}
    static func logDataOperation(_ operation: String, recordCount: Int? = nil) {}
    static func logViewLifecycle(_ viewName: String, event: ViewLifecycleEvent) {}
    static func logNavigation(from: String, to: String, action: NavigationAction) {}
}

enum ViewLifecycleEvent: String {
    case appeared = "APPEARED"
    case disappeared = "DISAPPEARED"
    case loading = "LOADING"
    case loaded = "LOADED"
}

enum NavigationAction: String {
    case push = "PUSH"
    case pop = "POP"
    case present = "PRESENT"
    case dismiss = "DISMISS"
}
#endif