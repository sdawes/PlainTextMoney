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
    let dataPoints: [ChartDataPoint]
    let height: CGFloat
    let interpolationMethod: InterpolationMethod
    
    init(dataPoints: [ChartDataPoint], height: CGFloat = 200, interpolationMethod: InterpolationMethod = .monotone) {
        self.dataPoints = dataPoints.sorted { $0.date < $1.date }
        self.height = height
        self.interpolationMethod = interpolationMethod
    }
    
    private var chartDateRange: ClosedRange<Date> {
        guard let firstDate = dataPoints.first?.date,
              let lastDate = dataPoints.last?.date else {
            let today = Date()
            return today...today
        }
        
        // Ensure the range always extends to today to show full context
        let today = Calendar.current.startOfDay(for: Date())
        let endDate = max(lastDate, today)
        
        return firstDate...endDate
    }
    
    
    var body: some View {
        if dataPoints.isEmpty {
            Text("No data available")
                .foregroundColor(.secondary)
                .frame(height: height)
        } else {
            Chart(dataPoints, id: \.date) { dataPoint in
                LineMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Value", dataPoint.doubleValue)
                )
                .foregroundStyle(.black)
                .lineStyle(StrokeStyle(lineWidth: 1.5))
                .interpolationMethod(interpolationMethod)
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
                            Text("£\(Int(doubleValue))")
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