import Foundation

enum HKCCommand {
    case list
    case toggleLight(home: String, accessory: String, service: String, characteristic: String)
}
