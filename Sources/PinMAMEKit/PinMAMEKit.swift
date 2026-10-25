import Foundation
import Synchronization
import libpinmame

public protocol PinMAMEDelegate: AnyObject {
    func stateDidUpdate(to newState: PinMAME.EmulationState)
    func displayDidBecomeAvailable(index: Int, count: Int, layout: PinMAME.DisplayLayout)
    func displayDidUpdate(index: Int, frame: PinMAME.DisplayFrame)
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
    func audioDidBecomeAvailable(info: PinMAME.AudioInfo) -> Int
    func audioDidUpdate(samples: Int, data: UnsafeRawPointer) -> Int
    func mechDidBecomeAvailable(number: Int, info: PinMAME.MechInfo)
    func mechDidUpdate(number: Int, info: PinMAME.MechInfo)
    func solenoidDidUpdate(number: Int, state: Int)
    func consoleDataDidUpdate(data: UnsafeRawPointer, size: Int)
    func isKeyPressed(keycode: UInt32) -> Bool
    func log(logLevel: PinMAME.LogLevel, message: String)
    func soundCommandDidFire(board: Int, command: Int)
}

public class PinMAME {
    private static let instanceLock = Mutex<Bool>(false)

    // this is probably bad. does this even need to be an actor?
    public nonisolated(unsafe) weak var delegate: (any PinMAMEDelegate)?

    // Currently needed so that the type isn't automatically inherently initialized,
    // which would mean that `deinit` runs even on failed initializers
    private var __initialzed: Bool

    public init?(audioFormat: AudioFormat, sampleRate: Int32, vpmPath: String) {
        let res: Void? = Self.instanceLock.withLock { (instanceCurrentlyExists: inout Bool) -> Void? in
            guard !instanceCurrentlyExists else { return nil }
            instanceCurrentlyExists = true
        }
        guard res != nil else { return nil }
        __initialzed = true
        self._configure(audioFormat: audioFormat, sampleRate: sampleRate, vpmPath: vpmPath)
        PinmameSetUserData(Unmanaged.passUnretained(self).toOpaque())
    }

    deinit {
        Self.instanceLock.withLock { instanceCurrentlyExists in
            assert(instanceCurrentlyExists, "PinMAME.deinit should only be called when there is an existing instance, which the lock should agree with")
            instanceCurrentlyExists = false
            PinmameSetUserData(nil)
        }
    }

    public func configure(audioFormat: AudioFormat, sampleRate: Int32, vpmPath: String) {
        return self._configure(audioFormat: audioFormat, sampleRate: sampleRate, vpmPath: vpmPath)
    }

    private nonisolated func _configure(audioFormat: AudioFormat, sampleRate: Int32, vpmPath: String) {
        let config = PinmameConfig(
            audioFormat: audioFormat.libpinmame,
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
                let index = Int(index)
                let count = Int(displayCount)
                guard let ptr = displayLayout else { return }
                let layout = DisplayLayout(libpinmame: ptr.pointee)

                let pinmame = Unmanaged<PinMAME>.fromOpaque(userData).takeUnretainedValue()

                pinmame.delegate?.displayDidBecomeAvailable(index: index, count: count, layout: layout)
            },
            cb_OnDisplayUpdated: { index, displayData, displayLayout, userData in
                guard let userData else { return }
                let index = Int(index)
                guard let layoutPtr = displayLayout, let dataPtr = displayData else { return }
                let layout = DisplayLayout(libpinmame: layoutPtr.pointee)

                let pinmame = Unmanaged<PinMAME>.fromOpaque(userData).takeUnretainedValue()

                pinmame.delegate?.displayDidUpdate(index: index, frame: DisplayFrame(layout: layout, data: dataPtr))
            },
            cb_OnAudioAvailable: { audioInfo, userData in
                guard let ptr = audioInfo else { return -1 } // maybe assert or precondition?
                guard let userData else { return ptr.pointee.samplesPerFrame }
                guard let info = AudioInfo(libpinmame: ptr.pointee) else { return ptr.pointee.samplesPerFrame }

                let pinmame = Unmanaged<PinMAME>.fromOpaque(userData).takeUnretainedValue()
                guard let delegate = pinmame.delegate else { return ptr.pointee.samplesPerFrame }

                return Int32(delegate.audioDidBecomeAvailable(info: info))
            },
            cb_OnAudioUpdated: { buffer, samples, userData in
                guard let userData else { return samples }
                guard let buffer else { return samples }

                let pinmame = Unmanaged<PinMAME>.fromOpaque(userData).takeUnretainedValue()
                guard let delegate = pinmame.delegate else { return samples }

                return Int32(delegate.audioDidUpdate(samples: Int(samples), data: buffer))
            },
            cb_OnMechAvailable: { mechNumber, mechInfo, userData in
                guard let userData else { return }
                guard let ptr = mechInfo else { return }
                let info = MechInfo(libpinmame: ptr.pointee)

                let pinmame = Unmanaged<PinMAME>.fromOpaque(userData).takeUnretainedValue()

                pinmame.delegate?.mechDidBecomeAvailable(number: Int(mechNumber), info: info)
            },
            cb_OnMechUpdated: { mechNumber, mechInfo, userData in
                guard let userData else { return }
                guard let ptr = mechInfo else { return }
                let info = MechInfo(libpinmame: ptr.pointee)

                let pinmame = Unmanaged<PinMAME>.fromOpaque(userData).takeUnretainedValue()

                pinmame.delegate?.mechDidUpdate(number: Int(mechNumber), info: info)
            },
            cb_OnSolenoidUpdated: { solenoidState, userData in
                guard let userData else { return }
                guard let ptr = solenoidState else { return }
                let state = ptr.pointee

                let pinmame = Unmanaged<PinMAME>.fromOpaque(userData).takeUnretainedValue()

                pinmame.delegate?.solenoidDidUpdate(number: Int(state.solNo), state: Int(state.state))
            },
            cb_OnConsoleDataUpdated: { data, size, userData in
                guard let userData else { return }
                guard let data else { return }

                let pinmame = Unmanaged<PinMAME>.fromOpaque(userData).takeUnretainedValue()

                pinmame.delegate?.consoleDataDidUpdate(data: data, size: Int(size))
            },
            fn_IsKeyPressed: { keycode, userData in
                guard let userData else { return 0 }

                let pinmame = Unmanaged<PinMAME>.fromOpaque(userData).takeUnretainedValue()

                return (pinmame.delegate?.isKeyPressed(keycode: keycode.rawValue) ?? false) ? 1 : 0
            },
            cb_OnLogMessage: { logLevel, format, args, userData in
                guard let userData else { return }
                guard let logLevel = LogLevel(from: logLevel), let format, let args else { return }

                let pinmame = Unmanaged<PinMAME>.fromOpaque(userData).takeUnretainedValue()

                let formattedMessage = NSString(format: String(cString: format), arguments: args) as String
                pinmame.delegate?.log(logLevel: logLevel, message: formattedMessage)
            },
            cb_OnSoundCommand: { boardNumber, command, userData in
                guard let userData else { return }

                let pinmame = Unmanaged<PinMAME>.fromOpaque(userData).takeUnretainedValue()

                pinmame.delegate?.soundCommandDidFire(board: Int(boardNumber), command: Int(command))
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
