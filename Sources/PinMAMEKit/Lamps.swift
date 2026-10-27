import Foundation
import libpinmame

extension PinMAME {
    public func getLamp(_ number: Int) -> Bool {
        PinmameGetLamp(Int32(number)) != 0
    }
}
