import Foundation
import Testing
@testable import PinMAMEKit

// Currently there is no way to make one suite serialized and mutually exclusive with the other suites
// so we nest everything within PinMAMEKitTests and mark that serialized
@Suite(.serialized)
struct PinMAMEKitTests {
    @Test
    func `get PinmameSetConfig log line`() async throws {
        let pm = try #require(PinMAME(sampleRate: 44100, vpmPath: NSTemporaryDirectory()))
        let del = StubDelegate()
        pm.delegate = del
        await pm.configure(sampleRate: 44100, vpmPath: NSTemporaryDirectory())
        #expect(del.setConfigLogLinesSeen == 1, "Delegate method was not called")
    }

    class StubDelegate: PinMAMEDelegate {
        var setConfigLogLinesSeen = 0

        func stateDidUpdate(to newState: EmulationState) {}
        func displayBecameAvailable(displayIndex: Int32, displayCount: Int32, displayLayout: Void) {}
        func displayDidUpdate(displayIndex: Int32, displayData: Data, displayLayout: Void) {}
        func audioDidBecomeAvailable(audioInfo: Void) {}
        func audioDidUpdate(buffer: Data, samples: Int32) {}
        func mechDidBecomeAvailable(mechNumber: Int32, mechInfo: Void) {}
        func mechDidUpdate(mechNumber: Int32, mechInfo: Void) {}
        func solenoidDidUpdate(state: Void) {}
        func consoleDataDidUpdate(data: Data, size: Int32) {}
        // func isKeyPressed(keycode: Void) -> Bool
        func log(logLevel: Int, message: String) {
            if message.contains("PinmameSetConfig()") {
                setConfigLogLinesSeen += 1
            }
        }
        func soundCommandDidFire(board: Int32, command: Int32) {}
    }

    @Test
    func `dont crash on multiple log line calls`() async throws {
        let pm = try #require(PinMAME(sampleRate: 44100, vpmPath: NSTemporaryDirectory()))
        let del = StubDelegate()
        pm.delegate = del
        await pm.configure(sampleRate: 44100, vpmPath: NSTemporaryDirectory())
        await pm.configure(sampleRate: 44100, vpmPath: NSTemporaryDirectory())
        await pm.configure(sampleRate: 44100, vpmPath: NSTemporaryDirectory())
        await pm.configure(sampleRate: 44100, vpmPath: NSTemporaryDirectory())
        await pm.configure(sampleRate: 44100, vpmPath: NSTemporaryDirectory())
        #expect(del.setConfigLogLinesSeen == 5, "Delegate method called wrong number of times")
    }
}
