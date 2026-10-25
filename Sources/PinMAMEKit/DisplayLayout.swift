import Foundation
import libpinmame

extension PinMAME {
    public struct DisplayLayout {
        public let top: Int
        public let left: Int
        public let length: Int
        public let width: Int
        public let height: Int
        public let depth: Int
    }
}

extension PinMAME.DisplayLayout {
    init(libpinmame: PinmameDisplayLayout) {
        self.init(
            top: Int(libpinmame.top),
            left: Int(libpinmame.left),
            length: Int(libpinmame.length),
            width: Int(libpinmame.width),
            height: Int(libpinmame.height),
            depth: Int(libpinmame.depth)
        )
    }
}

extension PinMAME {
    public struct DisplayFrame {
        public let layout: DisplayLayout
        public let data: UnsafeRawPointer
    }
}
