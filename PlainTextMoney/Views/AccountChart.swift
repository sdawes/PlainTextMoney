//
//  AccountChart.swift
//  PlainTextMoney
//
//  Created by Stephen Dawes on 31/07/2025.
//

import SwiftUI
import Charts

struct ChartDataPoint {
    let date: Date
    let value: Decimal
    
    // Helper to convert Decimal to Double for Charts
    var doubleValue: Double {
        NSDecimalNumber(decimal: value).doubleValue
    }
}

struct AccountChart: View {
    let account: Account
    let height: CGFloat
    let interpolationMethod: InterpolationMethod
    
    init(account: Account, height: CGFloat = 200, interpolationMethod: InterpolationMethod = .monotone) {
        self.account = account
        self.height = height
        self.interpolationMethod = interpolationMethod
    }
    
    // PERFORMANCE: Direct chart data from updates only (no snapshots)
    private var chartDataPoints: [ChartDataPoint] {
        let updates = account.updates.sorted { $0.date < $1.date }
        let dataPoints = updates.map { update in
            ChartDataPoint(date: update.date, value: update.value)
        }
        
        
        return dataPoints
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
            Text("No data available")
                .foregroundColor(.secondary)
                .frame(height: height)
        } else {
            Chart(chartDataPoints, id: \.date) { dataPoint in
                // Light gradient area underneath the line
                AreaMark(
                    x: .value("Date", dataPoint.date),
                    yStart: .value("Base", 0),
                    yEnd: .value("Value", dataPoint.doubleValue)
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
                    y: .value("Value", dataPoint.doubleValue)
                )
                .foregroundStyle(.green)
                .lineStyle(StrokeStyle(lineWidth: 1.5))
                .interpolationMethod(.linear)
                
                // Small points to show actual update locations
                PointMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Value", dataPoint.doubleValue)
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