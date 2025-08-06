//
//  ContentView.swift
//  PlainTextMoney
//
//  Created by Stephen Dawes on 29/07/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var isLoading = true
    
    var body: some View {
        if isLoading {
            LoadingViewWrapper(onLoadingComplete: { 
                isLoading = false 
            })
        } else {
            DashboardView()
        }
    }
}

struct LoadingViewWrapper: View {
    let onLoadingComplete: () -> Void
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        LoadingView(
            onLoadingComplete: onLoadingComplete,
            modelContainer: modelContext.container
        )
    }
}
