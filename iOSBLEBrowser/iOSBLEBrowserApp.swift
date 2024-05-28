//
//  iOSBLEBrowserApp.swift
//  iOSBLEBrowser
//
//  Created by Nick Lambourne on 10/20/22.
//

import SwiftUI

struct ParticleBLEExampleGlobals {
    static let particleBLEScannerInstance = ParticleBLEScanner()
}

@main
struct iOSBLEBrowserApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

