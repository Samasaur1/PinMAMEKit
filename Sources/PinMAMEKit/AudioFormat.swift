import Foundation
import libpinmame

extension PinMAME {
    public enum AudioFormat: Int {
        case int16 = 0
        case float = 1
    }
}

extension PinMAME.AudioFormat {
    init?(libpinmame: PINMAME_AUDIO_FORMAT) {
        self.init(rawValue: Int(libpinmame.rawValue))
    }

    var libpinmame: PINMAME_AUDIO_FORMAT {
        PINMAME_AUDIO_FORMAT(rawValue: UInt32(self.rawValue))
    }
}
