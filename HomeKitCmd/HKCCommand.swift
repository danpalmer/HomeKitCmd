import Foundation
import ArgumentParser

struct HKCCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "HomeKitCmd.app/Contents/MacOS/HomeKitCmd",
        abstract: "A utility for controlling HomeKit.",
        subcommands: [List.self, WriteValue.self, ReadValue.self]
    )

    @Flag var help: Bool = false

    static func parseCommand(_ args: [String]) -> HKCParsedCommand {
        do {
            let command = try parseAsRoot(args)
            switch command {
            case let command as HKCCommand.List:
                return .list(all: command.includeUnsupported)
            case let command as HKCCommand.WriteValue:
                return .writeValue(
                    home: command.home,
                    accessory: command.accessory,
                    service: command.service,
                    characteristic: command.characteristic,
                    value: command.value
                )
            case let command as HKCCommand.ReadValue:
                return .readValue(
                    home: command.home,
                    accessory: command.accessory,
                    service: command.service,
                    characteristic: command.characteristic
                )
            case var command as HKCCommand:
                if command.help {
                    try command.run()
                    exit()
                }
                return .info
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
        @Flag var includeUnsupported: Bool = false
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
        @Option var home: UUID
        @Option var accessory: UUID
        @Option var service: UUID
        @Option var characteristic: UUID
    }
}

enum HKCParsedCommand {
    case list(all: Bool)
    case writeValue(home: UUID, accessory: UUID, service: UUID, characteristic: UUID, value: String)
    case readValue(home: UUID, accessory: UUID, service: UUID, characteristic: UUID)
    case info
}

extension UUID: ExpressibleByArgument {
    public init?(argument: String) {
        self.init(uuidString: argument)
    }
}
