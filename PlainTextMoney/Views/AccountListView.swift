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
        NavigationStack {
            List {
                ForEach(accounts, id: \.name) { account in
                    NavigationLink(destination: AccountDetailView(account: account)) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(account.name)
                                    .font(.headline)
                                Spacer()
                                Text("£\(currentValue(for: account).formatted())")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            HStack {
                                Text("Created: \(account.createdAt.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete(perform: deleteAccounts)
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
    
    private func deleteAccounts(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(accounts[index])
            }
        }
    }
}

