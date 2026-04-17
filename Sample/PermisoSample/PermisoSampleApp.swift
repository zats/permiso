import SwiftUI

@main
struct PermisoSampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 620, minHeight: 320)
        }
        .defaultSize(width: 760, height: 420)
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
    }
}
