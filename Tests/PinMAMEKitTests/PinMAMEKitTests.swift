import Foundation
import Testing
@testable import PinMAMEKit

// Currently there is no way to make one suite serialized and mutually exclusive with the other suites
// so we nest everything within PinMAMEKitTests and mark that serialized
@Suite(.serialized)
struct PinMAMEKitTests {
    @Test
    func `get PinmameSetConfig log line`() async throws {
        let pm = try #require(PinMAME(audioFormat: .float, sampleRate: 44100, vpmPath: NSTemporaryDirectory()))
        let del = StubDelegate()
        pm.delegate = del
        await pm.configure(audioFormat: .float, sampleRate: 44100, vpmPath: NSTemporaryDirectory())
        #expect(del.setConfigLogLinesSeen == 1, "Delegate method was not called")
    }

    class StubDelegate: PinMAMEDelegate {
        var setConfigLogLinesSeen = 0

        func stateDidUpdate(to newState: EmulationState) {}
        func displayDidBecomeAvailable(index: Int, count: Int, layout: PinMAME.DisplayLayout) {}
        func displayDidUpdate(index: Int, frame: PinMAME.DisplayFrame) {}
        func audioDidBecomeAvailable(info: PinMAME.AudioInfo) -> Int { info.samplesPerFrame }
        func audioDidUpdate(samples: Int, data: UnsafeRawPointer) -> Int { samples }
        func mechDidBecomeAvailable(number: Int, info: PinMAME.MechInfo) {}
        func mechDidUpdate(number: Int, info: PinMAME.MechInfo) {}
        func solenoidDidUpdate(number: Int, state: Int) {}
        func consoleDataDidUpdate(data: UnsafeRawPointer, size: Int) {}
        func isKeyPressed(keycode: UInt32) -> Bool { false }
        func log(logLevel: PinMAME.LogLevel, message: String) {
            if message.contains("PinmameSetConfig()") {
                setConfigLogLinesSeen += 1
            }
        }
        func soundCommandDidFire(board: Int, command: Int) {}
    }

    @Test
    func `dont crash on multiple log line calls`() async throws {
        let pm = try #require(PinMAME(audioFormat: .float, sampleRate: 44100, vpmPath: NSTemporaryDirectory()))
        let del = StubDelegate()
        pm.delegate = del
        await pm.configure(audioFormat: .float, sampleRate: 44100, vpmPath: NSTemporaryDirectory())
        await pm.configure(audioFormat: .float, sampleRate: 44100, vpmPath: NSTemporaryDirectory())
        await pm.configure(audioFormat: .float, sampleRate: 44100, vpmPath: NSTemporaryDirectory())
        await pm.configure(audioFormat: .float, sampleRate: 44100, vpmPath: NSTemporaryDirectory())
        await pm.configure(audioFormat: .float, sampleRate: 44100, vpmPath: NSTemporaryDirectory())
        #expect(del.setConfigLogLinesSeen == 5, "Delegate method called wrong number of times")
    }
}
