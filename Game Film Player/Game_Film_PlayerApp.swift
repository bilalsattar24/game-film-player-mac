import SwiftUI

@main
struct Game_Film_PlayerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(
                    minWidth: 640,
                    idealWidth: 960,
                    maxWidth: .infinity,
                    minHeight: 420,
                    idealHeight: 640,
                    maxHeight: .infinity
                )
        }
        .defaultSize(width: 960, height: 640)
    }
}
