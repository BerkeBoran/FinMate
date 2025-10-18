//
//  PersistenceController.swift
//  FinMate
//
//  Created by Berke Boran on 18.10.2025.
//

import Foundation
import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init() {
        container=NSPersistentContainer(name: "FinMateModel")
        container.loadPersistentStores { _, error in if let error = error as NSError?
            { fatalError("Hata \(error)")}
        }
    }
}
