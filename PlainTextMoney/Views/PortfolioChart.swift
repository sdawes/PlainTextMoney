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
    let startDate: Date?
    let height: CGFloat
    let interpolationMethod: InterpolationMethod
    
    init(accounts: [Account], startDate: Date? = nil, height: CGFloat = 200, interpolationMethod: InterpolationMethod = .monotone) {
        // Filter for active accounts only
        self.accounts = accounts.filter { $0.isActive }
        self.startDate = startDate
        self.height = height
        self.interpolationMethod = interpolationMethod
    }
    
    // PERFORMANCE: Incremental portfolio calculation from updates only
    private var chartDataPoints: [ChartDataPoint] {
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
        
        // Add all points from startDate onwards
        filteredPoints.append(contentsOf: portfolioPoints.filter { $0.date >= startDate })
        
        return filteredPoints
    }
    
    private var chartDateRange: ClosedRange<Date> {
        guard let firstDate = chartDataPoints.first?.date,
              let lastDate = chartDataPoints.last?.date else {
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
            Chart(chartDataPoints, id: \.date) { dataPoint in
                // Light gradient area underneath the line
                AreaMark(
                    x: .value("Date", dataPoint.date),
                    yStart: .value("Base", 0),
                    yEnd: .value("Total Value", dataPoint.doubleValue)
                )
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [.green.opacity(0.3), .green.opacity(0.05)]),
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
                .foregroundStyle(.green)
                .lineStyle(StrokeStyle(lineWidth: 1.5))
                .interpolationMethod(.linear)
                
                // Small points to show when portfolio changed
                PointMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Total Value", dataPoint.doubleValue)
                )
                .foregroundStyle(.green)
                .symbolSize(8)
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