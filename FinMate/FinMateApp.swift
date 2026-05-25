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
        // Delegate'i bağlar + izin ister (ön plandayken banner gözükmesi için şart)
        NotificationManager.shared.bootstrap()
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
