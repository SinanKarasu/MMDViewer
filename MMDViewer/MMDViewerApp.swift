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
    private var exampleURLs: [URL] {
        (Bundle.main.urls(forResourcesWithExtension: "mmd", subdirectory: "Examples") ?? [])
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
    }

    var body: some Scene {
        WindowGroup("MMD Viewer") {
            NavigationStack {
                MathpixReaderView(exampleURLs: exampleURLs)
            }
        }
        .defaultSize(width: 1080, height: 760)
    }
}
