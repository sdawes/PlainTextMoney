//
//  PortfolioChart.swift
//  PlainTextMoney
//
//  Created by Stephen Dawes on 31/07/2025.
//

import SwiftUI
import Charts

struct PortfolioChart: View {
    let accounts: [Account]
    let height: CGFloat
    let interpolationMethod: InterpolationMethod
    
    init(accounts: [Account], height: CGFloat = 200, interpolationMethod: InterpolationMethod = .monotone) {
        // Filter for active accounts only
        self.accounts = accounts.filter { $0.isActive }
        self.height = height
        self.interpolationMethod = interpolationMethod
        
        #if DEBUG
        print("🏗️ PortfolioChart init: \(accounts.count) total accounts → \(self.accounts.count) active accounts")
        for account in self.accounts {
            print("   Active: \(account.name) (\(account.updates.count) updates)")
        }
        #endif
    }
    
    // PERFORMANCE: Incremental portfolio calculation from updates only
    private var chartDataPoints: [ChartDataPoint] {
        // Get all updates from all active accounts, sorted chronologically
        let allUpdates = accounts.flatMap { $0.updates }
            .sorted { $0.date < $1.date }
        
        guard !allUpdates.isEmpty else { 
            #if DEBUG
            print("📊 PortfolioChart: No updates found across \(accounts.count) accounts")
            #endif
            return [] 
        }
        
        var portfolioPoints: [ChartDataPoint] = []
        var currentAccountValues: [String: Decimal] = [:] // Track running account values
        
        // For each update, recalculate portfolio total incrementally
        for update in allUpdates {
            // Update this account's current value
            currentAccountValues[update.account?.name ?? ""] = update.value
            
            // Calculate portfolio total from current values
            let portfolioTotal = currentAccountValues.values.reduce(0, +)
            portfolioPoints.append(ChartDataPoint(date: update.date, value: portfolioTotal))
        }
        
        #if DEBUG
        print("📊 PortfolioChart: \(portfolioPoints.count) data points from \(allUpdates.count) total updates across \(accounts.count) accounts")
        if let firstPoint = portfolioPoints.first, let lastPoint = portfolioPoints.last {
            print("   Portfolio range: £\(firstPoint.value) to £\(lastPoint.value)")
            print("   Date range: \(firstPoint.date.formatted(date: .abbreviated, time: .omitted)) to \(lastPoint.date.formatted(date: .abbreviated, time: .omitted))")
        }
        #endif
        
        return portfolioPoints
    }
    
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
    
    private func formatLargeNumber(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "%.1fM", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "%.0fk", value / 1_000)
        } else {
            return String(format: "%.0f", value)
        }
    }
    
    var body: some View {
        if chartDataPoints.isEmpty {
            Text("No portfolio data available")
                .foregroundColor(.secondary)
                .frame(height: height)
        } else {
            Chart(chartDataPoints, id: \.date) { dataPoint in
                // CHANGE: Pure line chart connecting actual update points
                LineMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Total Value", dataPoint.doubleValue)
                )
                .foregroundStyle(.blue)
                .lineStyle(StrokeStyle(lineWidth: 2.5))
                .interpolationMethod(.linear) // Linear interpolation for true line chart
                
                // Add small points to show when portfolio changed
                PointMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Total Value", dataPoint.doubleValue)
                )
                .foregroundStyle(.blue)
                .symbolSize(20)
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(.gray.opacity(0.2))
                    AxisValueLabel()
                        .foregroundStyle(.secondary)
                        .font(.caption2)
                }
            }
            .chartXScale(domain: chartDateRange)
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(.gray.opacity(0.2))
                    AxisValueLabel {
                        if let doubleValue = value.as(Double.self) {
                            Text("£\(formatLargeNumber(doubleValue))")
                                .foregroundStyle(.secondary)
                                .font(.caption2)
                        }
                    }
                }
            }
            .frame(height: height)
        }
    }
}