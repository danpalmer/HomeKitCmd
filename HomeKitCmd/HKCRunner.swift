import Foundation
import HomeKit

class HKCRunner: NSObject {
    private let homeKit = HMHomeManager()
    private let command: HKCParsedCommand
    private let completion: (String, Int32) -> Never

    init(command: HKCParsedCommand, completion: @escaping (String, Int32) -> Never) {
        self.command = command
        self.completion = completion
        super.init()
        homeKit.delegate = self
    }

    private func run(_ homes: [HMHome]) {
        switch (self.command) {
        case let .list(all: all):
            list(homes, all: all)
            return
        case let .writeValue(
            home: home,
            accessory: accessory,
            service: service,
            characteristic: characteristic,
            value: value
        ):
            writeValue(
                homes,
                home: home,
                accessory: accessory,
                service: service,
                characteristic: characteristic,
                value: value
            )
            return
        case let .readValue(
            home: home,
            accessory: accessory,
            service: service,
            characteristic: characteristic
        ):
            readValue(
                homes,
                home: home,
                accessory: accessory,
                service: service,
                characteristic: characteristic
            )
        case .info:
            return
        }
    }

    private func list(_ homes: [HMHome], all: Bool) {
        let homes: [Home] = homes.map { Home($0, filterUnsupported: !all) }
        let result = renderJSON(homes)
        completion(result, 0)
    }

    private func writeValue(
        _ homes: [HMHome],
        home: UUID,
        accessory: UUID,
        service: UUID,
        characteristic: UUID,
        value: String
    ) {
        let characteristic = findAccessoryCharacteristic(
            homes,
            home: home,
            accessory: accessory,
            service: service,
            characteristic: characteristic
        )

        let value = characteristicValue(
            value,
            characteristicType: characteristic.characteristicType
        )

        characteristic.writeValue(value) { error in
            guard error == nil else {
                self.completion(self.renderJSONError("Failed to write accessory value", error), 1)
            }
        }
    }

    private func readValue(
        _ homes: [HMHome],
        home: UUID,
        accessory: UUID,
        service: UUID,
        characteristic: UUID
    ) {
        let characteristic = findAccessoryCharacteristic(
            homes,
            home: home,
            accessory: accessory,
            service: service,
            characteristic: characteristic
        )
        characteristic.readValue { error in
            guard error == nil else {
                self.completion(self.renderJSONError("Failed to read accessory value", error), 1)
            }

            let value = Characteristic(characteristic, filterUnsupported: false)?.value
            self.completion(self.renderJSON(value), 0)
        }
    }

    private func findAccessoryCharacteristic(_ homes: [HMHome], home: UUID, accessory: UUID, service: UUID, characteristic: UUID) -> HMCharacteristic {
        guard let home = homes.first(where: { $0.uniqueIdentifier == home }) else {
            completion(renderJSONError("Unknown home"), 1)
        }

        guard
            let accessory = home.accessories.first(where: { $0.uniqueIdentifier == accessory }),
            !accessory.isBlocked
        else {
            completion(renderJSONError("Unknown accessory"), 1)
        }

        guard
            let service = accessory.services.first(where: { $0.uniqueIdentifier == service }),
            service.isUserInteractive
        else {
            completion(renderJSONError("Unknown service"), 1)
        }

        guard let characteristic = service.characteristics.first(where: { $0.uniqueIdentifier == characteristic }) else {
            completion(renderJSONError("Unknown characteristic"), 1)
        }

        return characteristic
    }

    private func renderJSON(_ value: Encodable) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        guard let result = try? String(data: encoder.encode(value), encoding: .utf8) else {
            completion("Failed to serialise output", 1)
        }

        return result
    }

    private func renderJSONError(_ message: String, _ error: Error? = nil) -> String {
        return renderJSON(["message": message, "error": error?.localizedDescription ?? "unknown"])
    }

    private func characteristicValue(_ value: String, characteristicType: String) -> Any {
        let decoder = JSONDecoder()
        let data = Data(value.utf8)

        do {
            switch characteristicType {
            case HMCharacteristicTypeOutletInUse:
                return try decoder.decode(Bool.self, from: data)
            case HMCharacteristicTypePowerState:
                return try decoder.decode(Bool.self, from: data)
            case HMCharacteristicTypeBrightness:
                return try decoder.decode(Int.self, from: data)
            default:
                completion(renderJSONError("Unsupported characteristic type"), 1)
            }
        } catch {
            completion(renderJSONError("Failed to decode JSON value", error), 1)
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
