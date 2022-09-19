import SwiftUI
import UIKit

@main
struct HKCApp: App {
    let homeKitRunner: HKCRunner?

    init() {
        let command = HKCCommand.parseCommand(Array(CommandLine.arguments.dropFirst()))

        if case .info = command {
            homeKitRunner = nil
        } else {
            HKCAppKitBridge.loadAppKitIntegrationFramework()
            homeKitRunner = HKCRunner(command: command) { result, exitCode in
                print(result)
                exit(exitCode)
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            HKCInfoWindow()
        }
    }
}
