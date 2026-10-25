import Foundation
import libpinmame

extension PinMAME {
    public func getSwitch(_ number: Int) -> Bool {
        PinmameGetSwitch(Int32(number)) != 0
    }

    public func setSwitch(_ number: Int, closed: Bool) {
        PinmameSetSwitch(Int32(number), closed ? 1 : 0)
    }

    public func setSwitches(_ dict: [Int: Bool]) {
        var arr = [PinmameSwitchState]()
        for (number, closed) in dict {
            var obj = PinmameSwitchState()
            obj.swNo = Int32(number)
            obj.state = closed ? 1 : 0
            arr.append(obj)
        }
        PinmameSetSwitches(&arr, Int32(arr.count))
    }
}
