import Foundation
import libpinmame

extension PinMAME {
    public enum EmulationState: Int32 {
        case stopped = 0
        case starting = 2
        case running = 1
        case stopping = 3
    }

    public func run(game: String) {
        PinmameRun(game)
    }

    public func pause(_ paused: Bool) {
        PinmamePause(paused ? 1 : 0)
    }

    public func reset() {
        PinmameReset()
    }

    public func stop() {
        PinmameStop()
    }

    public func isRunning() -> Bool {
        PinmameIsRunning() != 0
    }

    public func isPaused() -> Bool {
        PinmameIsPaused() != 0
    }
}
