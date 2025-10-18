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
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
