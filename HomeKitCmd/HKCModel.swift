import Foundation
import HomeKit

struct Home: Encodable {
    var name: String
    var isPrimary: Bool
    var id: UUID
    var accessories: [Accessory]

    init(_ home: HMHome, filterUnsupported: Bool) {
        name = home.name
        isPrimary = home.isPrimary
        id = home.uniqueIdentifier
        accessories = home.accessories.map {
            Accessory($0, filterUnsupported: filterUnsupported)
        }
    }
}

struct Accessory: Encodable {
    var name: String
    var id: UUID
    var description: String
    var isReachable: Bool
    var isBridged: Bool
    var isBlocked: Bool
    var isIdentifiable: Bool
    var category: Category
    var room: Room?
    var services: [Service]

    init(_ accessory: HMAccessory, filterUnsupported: Bool) {
        name = accessory.name
        id = accessory.uniqueIdentifier
        description = "\(accessory.manufacturer ?? "") \(accessory.model ?? "")".trimmingCharacters(in: .whitespaces)
        isReachable = accessory.isReachable
        isBridged = accessory.isBridged
        isBlocked = accessory.isBlocked
        isIdentifiable = accessory.supportsIdentify
        category = Category(accessory.category)
        room = accessory.room.map(Room.init)
        services = accessory.services.compactMap {
            Service($0, filterUnsupported: filterUnsupported)
        }
    }
}

struct Category: Encodable {
    var type: String
    var description: String

    init(_ category: HMAccessoryCategory) {
        type = category.categoryType
        description = category.localizedDescription
    }
}

struct Room: Encodable {
    var name: String
    var id: UUID

    init(_ room: HMRoom) {
        name = room.name
        id = room.uniqueIdentifier
    }
}

struct Service: Encodable {
    var name: String
    var type: String
    var description: String
    var id: UUID
    var isInteractive: Bool
    var isPrimary: Bool
    var characteristics: [Characteristic]

    init?(_ service: HMService, filterUnsupported: Bool) {
        name = service.name
        type = service.serviceType
        description = service.localizedDescription
        id = service.uniqueIdentifier
        isInteractive = service.isUserInteractive
        isPrimary = service.isPrimaryService
        characteristics = service.characteristics.compactMap {
            Characteristic($0, filterUnsupported: filterUnsupported)
        }

        if characteristics.isEmpty {
            return nil
        }
    }
}

struct Characteristic: Encodable {
    var type: String
    var description: String
    var id: UUID
    var isWritable: Bool
    var isReadable: Bool
    var value: Value

    init?(_ characteristic: HMCharacteristic, filterUnsupported: Bool) {
        description = characteristic.localizedDescription
        id = characteristic.uniqueIdentifier

        isWritable = characteristic.properties.contains(HMCharacteristicPropertyWritable)
        isReadable = characteristic.properties.contains(HMCharacteristicPropertyReadable)

        // Parse the type and value into known formats
        // TODO: Parse more from HMCharacteristicDefines
        switch characteristic.characteristicType {
        case HMCharacteristicTypeOutletInUse:
            type = "HMCharacteristicTypeOutletInUse"
            value = parse(characteristic.value) { .bool(bool: $0) }
        case HMCharacteristicTypePowerState:
            type = "HMCharacteristicTypePowerState"
            value = parse(characteristic.value) { .bool(bool: $0) }
        case HMCharacteristicTypeBrightness:
            type = "HMCharacteristicTypeBrightness"
            value = parse(characteristic.value) { .percent(percent: $0) }
        default:
            if filterUnsupported {
                return nil
            }

            type = "_unknown"
            value = .unknown(message: "Unknown characteristic type")
        }
    }
}

enum Value: Codable {
    case bool(bool: Bool)
    case percent(percent: Int)

    case unknown(message: String)
    case error(message: String)
}

func parse<T>(_ v: Any?, valid: (T) -> Value) -> Value {
    guard let v = v else {
        return .unknown(message: "Value not loaded")
    }

    guard let v = v as? T else {
        return .error(message: "Incorrect type found")
    }

    return valid(v)
}
