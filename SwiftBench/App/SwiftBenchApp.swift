//
//  SwiftBenchApp.swift
//  SwiftBench
//
//  Created by Arya Mirsepasi on 21.12.25.
//

import AIProxy
import SwiftData
import SwiftUI

@main
struct SwiftBenchApp: App {
    @State private var appState = AppState()

    private let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            BenchmarkRun.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        AIProxy.configure(
            logLevel: .info,
            printRequestBodies: false,
            printResponseBodies: false,
            resolveDNSOverTLS: true,
            useStableID: false
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
        .modelContainer(sharedModelContainer)
    }
}
