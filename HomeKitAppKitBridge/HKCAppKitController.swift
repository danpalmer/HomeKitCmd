import AppKit

extension NSWindow {
    @objc func hkc_makeKeyAndOrderFront(_ sender: Any) {}
}

@objc class HKCAppKitController: NSObject {
    override init() {
        super.init()

//        NSApplication.shared.setActivationPolicy(.accessory)

        let m1 = class_getInstanceMethod(NSClassFromString("NSWindow"), NSSelectorFromString("makeKeyAndOrderFront:"))
        let m2 = class_getInstanceMethod(NSClassFromString("NSWindow"), NSSelectorFromString("hkc_makeKeyAndOrderFront:"))

        if let m1 = m1, let m2 = m2 {
            method_exchangeImplementations(m1, m2)
        }
    }
}
