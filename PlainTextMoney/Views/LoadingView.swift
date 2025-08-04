//
//  LoadingView.swift
//  PlainTextMoney
//
//  Created by Claude on 03/08/2025.
//

import SwiftUI
import SwiftData

struct LoadingView: View {
    @State private var loadingProgress: Double = 0.0
    @State private var loadingText = "Initializing..."
    @State private var isLoading = true
    @State private var rotationAngle: Double = 0
    
    // Callback when loading is complete
    let onLoadingComplete: () -> Void
    let modelContainer: ModelContainer
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [.blue.opacity(0.1), .blue.opacity(0.05)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // App Icon/Logo Area
                VStack(spacing: 20) {
                    // App Icon (using SF Symbol as placeholder)
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                        .rotationEffect(.degrees(rotationAngle))
                        .onAppear {
                            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                                rotationAngle = 360
                            }
                        }
                    
                    // App Name
                    VStack(spacing: 8) {
                        Text("PlainTextMoney")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Track • Save • Grow")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Loading Section
                VStack(spacing: 16) {
                    // Progress Bar
                    ProgressView(value: loadingProgress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .frame(width: 200)
                    
                    // Loading Text
                    Text(loadingText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .animation(.easeInOut(duration: 0.3), value: loadingText)
                }
                
                Spacer()
                
                // Version/Copyright
                Text("© 2025 PlainTextMoney")
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.7))
                    .padding(.bottom, 20)
            }
            .padding()
        }
        .onAppear {
            startPreloading()
        }
    }
    
    // MARK: - Preloading Logic
    
    private func startPreloading() {
        Task {
            await performPreloadingTasks()
        }
    }
    
    @MainActor
    private func performPreloadingTasks() async {
        let tasks = [
            ("Warming up database...", warmUpDatabase),
            ("Loading models...", initializeModels),
            ("Preparing UI...", warmUpUI),
            ("Finalizing...", finalizeSetup)
        ]
        
        let progressIncrement = 1.0 / Double(tasks.count)
        
        for (text, task) in tasks {
            loadingText = text
            
            // Perform the task
            await task()
            
            // Update progress
            loadingProgress += progressIncrement
            
            // Small delay for smooth UX (remove in production if desired)
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        }
        
        // Complete loading
        loadingText = "Ready!"
        loadingProgress = 1.0
        
        // Small delay before transition
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Notify completion
        onLoadingComplete()
    }
    
    // MARK: - Preloading Tasks
    
    private func warmUpDatabase() async {
        // Warm up SwiftData by performing a simple fetch
        let descriptor = FetchDescriptor<Account>()
        _ = try? modelContainer.mainContext.fetch(descriptor)
    }
    
    private func initializeModels() async {
        // Initialize model relationships and verify schema
        let accountDescriptor = FetchDescriptor<Account>()
        let snapshotDescriptor = FetchDescriptor<AccountSnapshot>()
        let portfolioDescriptor = FetchDescriptor<PortfolioSnapshot>()
        
        _ = try? modelContainer.mainContext.fetch(accountDescriptor)
        _ = try? modelContainer.mainContext.fetch(snapshotDescriptor)
        _ = try? modelContainer.mainContext.fetch(portfolioDescriptor)
    }
    
    private func warmUpUI() async {
        // Pre-warm SwiftUI components by creating and destroying dummy views
        // This helps with first-interaction responsiveness
        await MainActor.run {
            let _ = Text("Warming up...")
            let _ = Button("Test") { }
            let _ = TextField("Test", text: .constant(""))
        }
    }
    
    private func finalizeSetup() async {
        // Any final setup tasks
        // Could include user preferences, notifications setup, etc.
        await Task.yield() // Ensure other tasks can run
    }
}