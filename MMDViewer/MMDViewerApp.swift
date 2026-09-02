//
//  MMDViewerApp.swift
//  MMDViewer
//
//  A deliberately small host for the shared Mathpix Markdown workbench.
//

import SwiftUI
import MMDWorkbench

@main
struct MMDViewerApp: App {
    var body: some Scene {
        WindowGroup("MMD Viewer") {
            NavigationStack {
                MathpixReaderView()
            }
        }
        .defaultSize(width: 1080, height: 760)
    }
}
