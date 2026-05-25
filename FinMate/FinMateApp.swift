//
//  FinMateApp.swift
//  FinMate
//
//  Created by Berke Boran on 7.10.2025.
//

import SwiftUI

@main
struct FinMateApp: App {
    let persistenceController = PersistenceController.shared
    @State private var priceStore = PriceStore()
    @StateObject private var investmentStore = InvestmentStore()

    init() {
            NotificationManager.shared.requestAuthorization()
        }
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environment(priceStore)
                .environmentObject(investmentStore)
                .task {
                    priceStore.start()
                }
        }
    }
}
