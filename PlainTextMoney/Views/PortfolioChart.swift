//
//  PortfolioChart.swift
//  PlainTextMoney
//
//  Created by Stephen Dawes on 31/07/2025.
//

import SwiftUI
import Charts
import Foundation

/// Context for smart X-axis labeling based on time period
struct TimePeriodContext {
    let period: PerformanceCalculationService.TimePeriod
    let actualPeriodLabel: String
    let dataPoints: [ChartDataPoint]
    
    var shouldShowXAxis: Bool {
        switch period {
        case .lastUpdate, .allTime:
            return true  // Show contextual labels
        case .oneMonth, .threeMonths, .oneYear:
            return false // Hide labels - period is obvious from selector
        }
    }
    
    var xAxisLabel: String? {
        guard shouldShowXAxis else { return nil }
        
        switch period {
        case .lastUpdate:
            // Show the date of the last update
            if let lastDate = dataPoints.last?.date {
                return lastDate.formatted(.dateTime.day().month(.abbreviated).year())
            }
            return nil
        case .allTime:
            // Show date range
            guard let firstDate = dataPoints.first?.date,
                  let lastDate = dataPoints.last?.date else { return nil }
            
            let startFormatted = firstDate.formatted(.dateTime.month(.abbreviated).year())
            let endFormatted = lastDate.formatted(.dateTime.month(.abbreviated).year())
            
            if startFormatted == endFormatted {
                return startFormatted
            } else {
                return "\(startFormatted) - \(endFormatted)"
            }
        case .oneMonth, .threeMonths, .oneYear:
            return nil
        }
    }
}

struct PortfolioChart: View {
    let accounts: [Account]
    let startDate: Date?
    let height: CGFloat
    let interpolationMethod: InterpolationMethod
    let preCalculatedData: [ChartDataPoint]?
    let timePeriodContext: TimePeriodContext?
    
    init(accounts: [Account], startDate: Date? = nil, height: CGFloat = 200, interpolationMethod: InterpolationMethod = .monotone) {
        // Filter for active accounts only
        self.accounts = accounts.filter { $0.isActive }
        self.startDate = startDate
        self.height = height
        self.interpolationMethod = interpolationMethod
        self.preCalculatedData = nil
        self.timePeriodContext = nil
    }
    
    init(data: [ChartDataPoint], height: CGFloat = 200, interpolationMethod: InterpolationMethod = .monotone, timePeriodContext: TimePeriodContext? = nil) {
        // Use pre-calculated data
        self.accounts = []
        self.startDate = nil
        self.height = height
        self.interpolationMethod = interpolationMethod
        self.preCalculatedData = data
        self.timePeriodContext = timePeriodContext
    }
    
    // PERFORMANCE: Incremental portfolio calculation from updates only
    private var chartDataPoints: [ChartDataPoint] {
        // Use pre-calculated data if available
        if let preCalculatedData = preCalculatedData {
            return preCalculatedData
        }
        
        // Get all updates from all active accounts, sorted chronologically
        let allUpdates = accounts.flatMap { $0.updates }
            .sorted { $0.date < $1.date }
        
        guard !allUpdates.isEmpty else { 
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
        
        // Apply date filtering to the aggregated timeline if startDate is provided
        if let startDate = startDate {
            return filterPortfolioTimeline(portfolioPoints, from: startDate)
        }
        
        return portfolioPoints
    }
    
    // PERFORMANCE: Intelligent timeline filtering with boundary handling
    private func filterPortfolioTimeline(_ portfolioPoints: [ChartDataPoint], from startDate: Date) -> [ChartDataPoint] {
        var filteredPoints: [ChartDataPoint] = []
        
        // Check if startDate exactly matches a portfolio point (no boundary needed)
        let hasExactMatch = portfolioPoints.contains { $0.date == startDate }
        
        if !hasExactMatch {
            // Find the last point before the startDate to maintain chart continuity
            var boundaryPoint: ChartDataPoint? = nil
            for point in portfolioPoints {
                if point.date < startDate {
                    boundaryPoint = point
                } else {
                    break
                }
            }
            
            // Add the boundary point if it exists (for chart continuity)
            if let boundaryPoint = boundaryPoint {
                filteredPoints.append(boundaryPoint)
            }
        }
        
        // Add all points from startDate onwards
        filteredPoints.append(contentsOf: portfolioPoints.filter { $0.date >= startDate })
        
        return filteredPoints
    }
    
    // CHART FIX: Ensure identical values still render properly as a line
    private var processedChartDataPoints: [ChartDataPoint] {
        let points = chartDataPoints
        
        // If we have exactly 2 points with identical values, add a tiny offset to make the line visible
        if points.count == 2 && points[0].value == points[1].value {
            print("🎯 CHART FIX: Detected identical values (\(points[0].value)), adding tiny visual offset")
            
            // Create new points with a minimal difference to make line render
            let offsetValue = points[0].value * 0.0001  // 0.01% offset - invisible to user but charts can render
            var processedPoints = points
            processedPoints[0] = ChartDataPoint(
                date: points[0].date, 
                value: points[0].value - offsetValue
            )
            return processedPoints
        }
        
        return points
    }
    
    private var chartDateRange: ClosedRange<Date> {
        guard let firstDate = processedChartDataPoints.first?.date,
              let lastDate = processedChartDataPoints.last?.date else {
            let today = Date()
            return today...today
        }
        
        // Use actual data range, not extended to today
        return firstDate...lastDate
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
            VStack(spacing: 4) {
            Chart(processedChartDataPoints, id: \.date) { dataPoint in
                // Light gradient area underneath the line
                AreaMark(
                    x: .value("Date", dataPoint.date),
                    yStart: .value("Base", 0),
                    yEnd: .value("Total Value", dataPoint.doubleValue)
                )
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [.blue.opacity(0.3), .blue.opacity(0.05)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.linear)
                
                // Thinner line on top of the gradient
                LineMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Total Value", dataPoint.doubleValue)
                )
                .foregroundStyle(.blue)
                .lineStyle(StrokeStyle(lineWidth: 1.5))
                .interpolationMethod(.linear)
                
                // Small points to show when portfolio changed
                PointMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Total Value", dataPoint.doubleValue)
                )
                .foregroundStyle(.blue)
                .symbolSize(8)
            }
            .chartXAxis {
                if let context = timePeriodContext, context.shouldShowXAxis, context.xAxisLabel != nil {
                    // Show smart contextual labeling with custom overlay
                    AxisMarks(values: .automatic(desiredCount: 2)) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(.gray.opacity(0.2))
                        // Hide default labels
                    }
                } else {
                    // Hide X-axis labels for month/year periods or when no context
                    AxisMarks(values: .automatic(desiredCount: 2)) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(.gray.opacity(0.2))
                        // No labels
                    }
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
                
                // Custom contextual label below chart for smart periods
                if let context = timePeriodContext, 
                   context.shouldShowXAxis, 
                   let label = context.xAxisLabel {
                    HStack {
                        Text(label)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                }
            }
        }
    }
}