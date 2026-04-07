//
//  IPLocateApp.swift
//  IPLocate
//
//  Created by Caitsy on 07/04/2026.
//

import SwiftUI
import CoreData

@main
struct IPLocateApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
