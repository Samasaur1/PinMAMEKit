import Foundation
import libpinmame

public struct Game: Equatable, Sendable, Identifiable, Hashable {
    public let name: String
    public let cloneOf: String?
    public let description: String
    public let year: String
    public let manufacturer: String
    public let flags: UInt32
    public let found: Bool

    public var id: String {
        name
    }

    init(_ raw: PinmameGame) {
        self.name = String(cString: raw.name)
        self.cloneOf = raw.clone_of.map { String(cString: $0) }
        self.description = String(cString: raw.description)
        self.year = String(cString: raw.year)
        self.manufacturer = String(cString: raw.manufacturer)
        self.flags = raw.flags
        self.found = raw.found != 0
    }
}

extension PinMAME {
    public func getGame(_ game: String) -> Game? {
        var result: Game? = nil
        let status = withUnsafeMutablePointer(to: &result) { resultPtr in
            game.withCString { str in
                PinmameGetGame(str, { game, out in
                    guard let game else { return }
                    out?.assumingMemoryBound(to: Game?.self).pointee = Game(game.pointee)
                }, resultPtr)
            }
        }
        switch status {
        case PINMAME_STATUS_OK:
            return result
        case PINMAME_STATUS_GAME_NOT_FOUND:
            return nil
        case PINMAME_STATUS_CONFIG_NOT_SET:
            fatalError()
            // throw
        default:
            fatalError()
        }
    }

    public func getGames() -> [Game] {
        var results: [Game] = []
        let status = withUnsafeMutablePointer(to: &results) { resultsPtr in
            PinmameGetGames({ gamePtr, userPtr in
                guard let gamePtr else { return }
                userPtr?.assumingMemoryBound(to: [Game].self).pointee.append(Game(gamePtr.pointee))
            }, resultsPtr)
        }
        switch status {
        case PINMAME_STATUS_OK:
                return results
        case PINMAME_STATUS_CONFIG_NOT_SET:
            fatalError()
            // throw
        default:
            fatalError()
        }
    }
}
