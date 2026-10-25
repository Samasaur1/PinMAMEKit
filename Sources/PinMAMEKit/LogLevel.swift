import Foundation
import libpinmame

extension PinMAME {
    public enum LogLevel: Int {
        case debug = 0
        case info = 1
        case error = 2
    }
}

extension PinMAME.LogLevel {
    init?(from pinmame_log_level: PINMAME_LOG_LEVEL) {
        self.init(rawValue: Int(pinmame_log_level.rawValue))
    }
}
