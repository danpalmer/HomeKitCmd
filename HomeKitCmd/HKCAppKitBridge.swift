import Foundation

class HKCAppKitBridge: NSObject {
    static var appKitController: NSObject?

    class func loadAppKitIntegrationFramework() {
        if let frameworksPath = Bundle.main.privateFrameworksPath {
            let bundlePath = "\(frameworksPath)/HomeKitAppKitBridge.framework"
            do {
                try Bundle(path: bundlePath)?.loadAndReturnError()

                let bundle = Bundle(path: bundlePath)!

                if let appKitControllerClass = bundle.classNamed("HomeKitAppKitBridge.HKCAppKitController") as? NSObject.Type {
                    appKitController = appKitControllerClass.init()
                }
            }
            catch {
                NSLog("Error loading bridge framework: \(error)")
            }
        }
    }
}
