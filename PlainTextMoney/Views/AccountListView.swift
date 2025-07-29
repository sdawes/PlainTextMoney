//
//  AccountListView.swift
//  PlainTextMoney
//
//  Created by Stephen Dawes on 29/07/2025.
//

import SwiftUI
import SwiftData

struct AccountListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var accounts: [Account]
    @State private var showingAddAccount = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(accounts, id: \.name) { account in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(account.name)
                            .font(.headline)
                        HStack {
                            Text("£\(currentValue(for: account).formatted())")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            Text("Created: \(account.createdAt.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Accounts")
            .toolbar {
                Button(action: { showingAddAccount = true }) {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showingAddAccount) {
                AddAccountView()
            }
        }
    }
    
    private func currentValue(for account: Account) -> Decimal {
        account.updates.last?.value ?? 0
    }
}

