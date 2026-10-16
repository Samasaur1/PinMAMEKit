import Foundation
import Testing
@testable import PinMAMEKit

@Test func example() async throws {
    // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    // Swift Testing Documentation
    // https://developer.apple.com/documentation/testing
}

@Test func `can identify st:tng`() async throws {
    await PinMAME.shared.configure(sampleRate: 44100, vpmPath: NSTemporaryDirectory())
    let game = try await #require(PinMAME.shared.getGame("sttng_l7"))
    #expect(game.description == "Star Trek: The Next Generation (LX-7, Sound L-1)")
    #expect(!game.found)
}
