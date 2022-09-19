import Foundation
import ArgumentParser

struct HKCCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "HomeKitCmd.app/Contents/MacOS/HomeKitCmd",
        abstract: "A utility for controlling HomeKit.",
        subcommands: [List.self, WriteValue.self, ReadValue.self]
    )

    static func parseCommand(_ args: [String]) -> HKCParsedCommand {
        do {
            let command = try parseAsRoot(args)
            switch command {
            case let command as HKCCommand.List:
                return .list(all: command.all)
            case let command as HKCCommand.WriteValue:
                return .writeValue(
                    home: command.home,
                    accessory: command.accessory,
                    service: command.service,
                    characteristic: command.characteristic,
                    value: command.value
                )
            case let command as HKCCommand.ReadValue:
                return .list(all: true)
            default:
                return .info
            }
        } catch {
            exit(withError: error)
        }
    }
}

extension HKCCommand {
    struct List: ParsableCommand {
        @Flag var all: Bool = false
    }
}

extension HKCCommand {
    struct WriteValue: ParsableCommand {
        @Option var home: UUID
        @Option var accessory: UUID
        @Option var service: UUID
        @Option var characteristic: UUID
        @Option var value: String
    }
}

extension HKCCommand {
    struct ReadValue: ParsableCommand {

    }
}

enum HKCParsedCommand {
    case list(all: Bool)
    case writeValue(home: UUID, accessory: UUID, service: UUID, characteristic: UUID, value: String)
    case info
}

extension UUID: ExpressibleByArgument {
    public init?(argument: String) {
        self.init(uuidString: argument)
    }
}
