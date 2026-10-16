import Foundation
import Testing
@testable import PinMAMEKit

// Currently there is no way to make one suite serialized and mutually exclusive with the other suites
// so we nest everything within PinMAMEKitTests and mark that serialized
@Suite(.serialized)
struct PinMAMEKitTests {
}
