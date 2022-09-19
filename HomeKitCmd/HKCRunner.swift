import Foundation
import HomeKit

class HKCRunner: NSObject {
    private let homeKit = HMHomeManager()
    private let command: HKCCommand
    private let completion: (String, Int32) -> Never

    init(command: HKCCommand, completion: @escaping (String, Int32) -> Never) {
        self.command = command
        self.completion = completion
        super.init()
        homeKit.delegate = self
    }

    private func run(_ homes: [HMHome]) {
        switch (self.command) {
        case .list:
            list(homes)
        case let .toggleLight(home: home, accessory: accessory, service: service, characteristic: characteristic):
            toggleLight(homes, home: home, accessory: accessory, service: service, characteristic: characteristic)
        }
    }

    private func list(_ homes: [HMHome]) {
        let homes: [Home] = homes.map { Home($0) }

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        guard let result = try? String(data: encoder.encode(homes), encoding: .utf8) else {
            completion("Failed to serialise output", 1)
        }

        completion(result, 0)
    }

    private func toggleLight(_ homes: [HMHome], home: String, accessory: String, service: String, characteristic: String) {
        guard let home = homes.first(where: { $0.uniqueIdentifier.uuidString == home }) else {
            completion("Unknown home", 1)
        }

        guard
            let accessory = home.accessories.first(where: { $0.uniqueIdentifier.uuidString == accessory }),
            !accessory.isBlocked
        else {
            completion("Unknown accessory", 1)
        }

        guard
            let service = accessory.services.first(where: { $0.uniqueIdentifier.uuidString == service }),
            service.isUserInteractive
        else {
            completion("Unknown service", 1)
        }

        guard let characteristic = service.characteristics.first(where: { $0.uniqueIdentifier.uuidString == characteristic }) else {
            completion("Unknown characteristic", 1)
        }

        characteristic.readValue { error in
            guard error == nil else {
                self.completion("Failed to read accessory state", 1)
            }

            
        }
    }
}

extension HKCRunner: HMHomeManagerDelegate {
    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        run(manager.homes)
    }

    func homeManager(_ manager: HMHomeManager, didUpdate status: HMHomeManagerAuthorizationStatus) {
        switch status {
        case .restricted:
            completion("No permission granted to access HomeKit resources. Please check System Settings to grant access.", 77)
        case .authorized, .determined:
            return
        default:
            return
        }
    }
}
