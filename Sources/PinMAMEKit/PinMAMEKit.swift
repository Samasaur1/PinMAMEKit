import Foundation
import Synchronization
import libpinmame

public protocol PinMAMEDelegate: AnyObject {
    func stateDidUpdate(to newState: EmulationState)
    func displayDidBecomeAvailable(displayIndex: Int32, displayCount: Int32, displayLayout: Void)
    func displayDidUpdate(displayIndex: Int32, displayData: Data, displayLayout: Void)
    /*
      osd_start_audio_stream() is called at the start of the emulation to initialize
      the output stream, then osd_update_audio_stream() is called every frame to
      feed new data. osd_stop_audio_stream() is called when the emulation is stopped.

      The sample rate is fixed at Machine->sample_rate. Samples are 16-bit, signed.
      When the stream is stereo, left and right samples are alternated in the
      stream.

      osd_start_audio_stream() and osd_update_audio_stream() must return the number
      of samples (or couples of samples, when using stereo) required for next frame.
      This will be around Machine->sample_rate / Machine->drv->frames_per_second,
      the code may adjust it by SMALL AMOUNTS to keep timing accurate and to
      maintain audio and video in sync when using vsync. Note that sound emulation,
      especially when DACs are involved, greatly depends on the number of samples
      per frame to be roughly constant, so the returned value must always stay close
      to the reference value of Machine->sample_rate / Machine->drv->frames_per_second.
      Of course that value is not necessarily an integer so at least a +/- 1
      adjustment is necessary to avoid drifting over time.
    */
    func audioDidBecomeAvailable(audioInfo: Void) -> Int
    func audioDidUpdate(buffer: Data, samples: Int32) -> Int
    func mechDidBecomeAvailable(mechNumber: Int32, mechInfo: Void)
    func mechDidUpdate(mechNumber: Int32, mechInfo: Void)
    func solenoidDidUpdate(state: Void)
    func consoleDataDidUpdate(data: Data, size: Int32)
    func isKeyPressed(keycode: Void) -> Bool
    func log(logLevel: Int, message: String)
    func soundCommandDidFire(board: Int32, command: Int32)
}

public actor PinMAME {
    private static let instanceLock = Mutex<Bool>(false)

    // this is probably bad. does this even need to be an actor?
    public nonisolated(unsafe) weak var delegate: (any PinMAMEDelegate)?

    // Currently needed so that the type isn't automatically inherently initialized,
    // which would mean that `deinit` runs even on failed initializers
    private var __initialzed: Bool

    public init?(sampleRate: Int32, vpmPath: String) {
        let res: Void? = Self.instanceLock.withLock { (instanceCurrentlyExists: inout Bool) -> Void? in
            guard !instanceCurrentlyExists else { return nil }
            instanceCurrentlyExists = true
        }
        guard res != nil else { return nil }
        __initialzed = true
        self._configure(sampleRate: sampleRate, vpmPath: vpmPath)
        PinmameSetUserData(Unmanaged.passUnretained(self).toOpaque())
    }

    deinit {
        Self.instanceLock.withLock { instanceCurrentlyExists in
            assert(instanceCurrentlyExists, "PinMAME.deinit should only be called when there is an existing instance, which the lock should agree with")
            instanceCurrentlyExists = false
            PinmameSetUserData(nil)
        }
    }

    public func configure(sampleRate: Int32, vpmPath: String) {
        return self._configure(sampleRate: sampleRate, vpmPath: vpmPath)
    }

    private nonisolated func _configure(sampleRate: Int32, vpmPath: String) {
        let config = PinmameConfig(
            audioFormat: PINMAME_AUDIO_FORMAT_INT16,
            sampleRate: sampleRate,
            vpmPath: vpmPath.toTuple(),
            cb_OnStateUpdated: { state, userData in
                guard let userData else { return }
                guard let state = EmulationState(rawValue: state) else { return }

                let pinmame = Unmanaged<PinMAME>.fromOpaque(userData).takeUnretainedValue()

                pinmame.delegate?.stateDidUpdate(to: state)
            },
            cb_OnDisplayAvailable: { index, displayCount, displayLayout, userData in
                guard let userData else { return }

                let pinmame = Unmanaged<PinMAME>.fromOpaque(userData).takeUnretainedValue()

                pinmame.delegate?.displayDidBecomeAvailable(displayIndex: index, displayCount: displayCount, displayLayout: displayLayout)
            },
            cb_OnDisplayUpdated: { index, displayData, displayLayout, userData in
                guard let userData else { return }

                let pinmame = Unmanaged<PinMAME>.fromOpaque(userData).takeUnretainedValue()

                pinmame.delegate?.displayDidUpdate(displayIndex: index, displayData: displayData, displayLayout: displayLayout)
            },
            cb_OnAudioAvailable: { audioInfo, userData in
                guard let userData else { return 0 }

                let pinmame = Unmanaged<PinMAME>.fromOpaque(userData).takeUnretainedValue()

                return pinmame.delegate?.audioDidBecomeAvailable(audioInfo: audioInfo) ?? 0
            },
            cb_OnAudioUpdated: { buffer, samples, userData in
                guard let userData else { return samples }

                let pinmame = Unmanaged<PinMAME>.fromOpaque(userData).takeUnretainedValue()

                return pinmame.delegate?.audioDidUpdate(buffer: buffer, samples: samples) ?? samples
            },
            cb_OnMechAvailable: { mechNumber, mechInfo, userData in
                guard let userData else { return }

                let pinmame = Unmanaged<PinMAME>.fromOpaque(userData).takeUnretainedValue()

                pinmame.delegate?.mechDidBecomeAvailable(mechNumber: mechNumber, mechInfo: mechInfo)
            },
            cb_OnMechUpdated: { mechNumber, mechInfo, userData in
                guard let userData else { return }

                let pinmame = Unmanaged<PinMAME>.fromOpaque(userData).takeUnretainedValue()

                pinmame.delegate?.mechDidUpdate(mechNumber: mechNumber, mechInfo: mechInfo)
            },
            cb_OnSolenoidUpdated: { solenoidState, userData in
                guard let userData else { return }

                let pinmame = Unmanaged<PinMAME>.fromOpaque(userData).takeUnretainedValue()

                pinmame.delegate?.solenoidDidUpdate(state: solenoidState)
            },
            cb_OnConsoleDataUpdated: { data, size, userData in
                guard let userData else { return }

                let pinmame = Unmanaged<PinMAME>.fromOpaque(userData).takeUnretainedValue()

                pinmame.delegate?.consoleDataDidUpdate(data: data, size: size)
            },
            fn_IsKeyPressed: { keycode, userData in
                guard let userData else { return 0 }

                let pinmame = Unmanaged<PinMAME>.fromOpaque(userData).takeUnretainedValue()

                return pinmame.delegate?.isKeyPressed(keycode: keycode) ?? false
            },
            cb_OnLogMessage: { logLevel, format, args, userData in
                guard let userData else { return }
                guard let format, let args else { return }

                let pinmame = Unmanaged<PinMAME>.fromOpaque(userData).takeUnretainedValue()

                let formattedMessage = NSString(format: String(cString: format), arguments: args)
                pinmame.delegate?.log(logLevel: 0, message: formattedMessage as String)
            },
            cb_OnSoundCommand: { boardNumber, command, userData in
                guard let userData else { return }

                let pinmame = Unmanaged<PinMAME>.fromOpaque(userData).takeUnretainedValue()

                pinmame.delegate?.soundCommandDidFire(board: boardNumber, command: command)
            }
        )

        withUnsafePointer(to: config) { ptr in
            PinmameSetConfig(ptr)
        }
    }
}

private func zeros<each T: ExpressibleByIntegerLiteral>() -> (repeat each T) {
    return (repeat 0 as each T)
}

extension String {
    func toTuple<each T: ExpressibleByIntegerLiteral>() -> (repeat each T) {
        var tup: (repeat each T) = zeros()
        withUnsafeMutableBytes(of: &tup) { out in
            self.utf8CString.withUnsafeBytes { str in
                out.copyMemory(from: str)
            }
        }
        return tup
    }
}
