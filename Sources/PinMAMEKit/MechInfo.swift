import Foundation
import libpinmame

extension PinMAME {
    public struct MechInfo {
        public let type: Int
        public let length: Int
        public let steps: Int
        public let pos: Int
        public let speed: Int
    }
}

extension PinMAME.MechInfo {
    init(libpinmame: PinmameMechInfo) {
        self.init(
            type: Int(libpinmame.type),
            length: Int(libpinmame.length),
            steps: Int(libpinmame.steps),
            pos: Int(libpinmame.pos),
            speed: Int(libpinmame.speed)
        )
    }
}
