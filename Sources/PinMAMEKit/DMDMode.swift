import Foundation
import libpinmame

extension PinMAME {
    public enum DMDMode: Int {
        case brightness = 0
        case raw = 1
    }
}

extension PinMAME.DMDMode {
    init?(libpinmame: PINMAME_DMD_MODE) {
        self.init(rawValue: Int(libpinmame.rawValue))
    }

    var libpinmame: PINMAME_DMD_MODE {
        PINMAME_DMD_MODE(rawValue: UInt32(rawValue))
    }
}

extension PinMAME {
    public var dmdMode: DMDMode {
        get {
            .init(libpinmame: PinmameGetDmdMode())!
        }
        set {
            PinmameSetDmdMode(newValue.libpinmame)
        }
    }
}
