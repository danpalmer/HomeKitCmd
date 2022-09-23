import SwiftUI
import UIKit

struct HKCInfoWindow: View {
    init() {
        setupCatalystScene()
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text("Commands for HomeKit")
                .font(.largeTitle)
            Text("Control HomeKit devices from the command line.")
                .font(.headline)
                .padding(.bottom)
            Text("""
                Run this application from the command line for more details. You can use it like any other \ncommand line application, it won't show up in the dock.

                ```
                $ /Applications/HomeKitCmd.app/Contents/MacOS/HomeKitCmd --help
                ```

                Alias the command for easier use:\n
                ```
                $ alias hkc=/Applications/HomeKitCmd.app/Contents/MacOS/HomeKitCmd
                ```
                ```
                $ hkc --help
                ```
                """)
                .font(.body)
                .padding(.bottom)
            Text("""
                **Why is this an app?**
                HomeKit is only available as an iOS API. This means that access to HomeKit on a Mac can only
                be achieved with a Catalyst app emulating an iPad. HomeKitCmd uses a few Mac-specific
                tricks to hide its window and stay out of the dock when run from the command line.
                """)
                .font(.body)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.all)
        .frame(width: .greatestFiniteMagnitude)
    }

    func setupCatalystScene() {
        #if targetEnvironment(macCatalyst)
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }

        guard scenes.count > 0 else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { setupCatalystScene() }
            return
        }

        scenes.forEach { scene in
            scene.sizeRestrictions?.maximumSize = CGSize(width: 600, height: 400)
            scene.sizeRestrictions?.minimumSize = CGSize(width: 600, height: 400)
            scene.titlebar?.titleVisibility = .hidden
            setupCatalystWindows(scene)
        }
        #endif
    }

    func setupCatalystWindows(_ scene: UIWindowScene) {
        #if targetEnvironment(macCatalyst)
        guard scene.windows.count > 0 else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { setupCatalystWindows(scene) }
            return
        }

        scene.windows.forEach { window in
            window.backgroundColor = .tertiarySystemFill
        }
        #endif
    }
}

#if DEBUG
    struct HKCInfoWindow_Previews: PreviewProvider {
        static var previews: some View {
            HKCInfoWindow()
        }
    }
#endif
