import Foundation
import Testing
@testable import PinMAMEKit

extension PinMAMEKitTests {
    @Suite
    struct GameTests {
        let pm: PinMAME

        init() throws {
            pm = try #require(PinMAME(sampleRate: 44100, vpmPath: NSTemporaryDirectory()))
        }

        @Test func `can identify st:tng`() async throws {
            let game = try await #require(pm.getGame("sttng_l7"))
            #expect(game.description == "Star Trek: The Next Generation (LX-7, Sound L-1)")
            #expect(!game.found)
        }
    }
}
