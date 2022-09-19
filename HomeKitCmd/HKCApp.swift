import SwiftUI

@main
struct HKCApp: App {
    let homeKitRunner: HKCRunner

    init() {
        HKCAppKitBridge.loadAppKitIntegrationFramework()
        homeKitRunner = HKCRunner(command: .list, completion: { result, exitCode in
            print(result)
            exit(exitCode)
        })
    }

    var body: some Scene {
        WindowGroup {
            Text("Loading...")
        }
    }
}
