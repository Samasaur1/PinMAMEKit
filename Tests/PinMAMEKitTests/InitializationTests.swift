import Foundation
import Testing
@testable import PinMAMEKit

extension PinMAMEKitTests {
    @Suite(.serialized)
    struct `PinMAME initialization tests` {
        @Test func `can create PinMAME object`() async throws {
            let pm = PinMAME(audioFormat: .float, sampleRate: 44100, vpmPath: NSTemporaryDirectory())
            #expect(pm != nil)
        }

        @Test func `can create second PinMAME object after first is deinitialized`() async throws {
            let first = try #require(PinMAME(audioFormat: .float, sampleRate: 44100, vpmPath: NSTemporaryDirectory()))
            consume first // Drop/deinit the first PinMAME object
            let second = PinMAME(audioFormat: .float, sampleRate: 44100, vpmPath: NSTemporaryDirectory())
            #expect(second != nil)
        }

        @Test func `cannot create second PinMAME object while first is still alive`() async throws {
            let first = try #require(PinMAME(audioFormat: .float, sampleRate: 44100, vpmPath: NSTemporaryDirectory()))
            let second = PinMAME(audioFormat: .float, sampleRate: 44100, vpmPath: NSTemporaryDirectory())
            #expect(second == nil)
            consume first
        }
    }
}
