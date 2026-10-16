import Foundation
import Synchronization
import libpinmame

public actor PinMAME {
    private static let instanceLock = Mutex<Bool>(false)

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
    }

    deinit {
        Self.instanceLock.withLock { instanceCurrentlyExists in
            assert(instanceCurrentlyExists, "PinMAME.deinit should only be called when there is an existing instance, which the lock should agree with")
            instanceCurrentlyExists = false
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
                // print(#function, "state is now:", state)
            },
            cb_OnDisplayAvailable: { index, displayCount, displayLayout, userData in
                // print(#function, "display \(index) (of \(displayCount)) now available")
            },
            cb_OnDisplayUpdated: { index, displayData, displayLayout, userData in
                // if let displayData {
                //     guard let layout = displayLayout?.pointee else { return }
                //     if layout.type == PINMAME_DISPLAY_TYPE_VIDEO {
                //         // video, displayData is UInt8*
                //     } else if (layout.type.rawValue & PINMAME_DISPLAY_TYPE_DMD.rawValue) == PINMAME_DISPLAY_TYPE_DMD.rawValue {
                //         displayDMD(Int(index), displayData, layout)
                //     } else {
                //         //alphanumeric, displayData is UInt16*
                //     }
                // }
            },
            cb_OnAudioAvailable: { audioInfo, userData in
                // print(#function, audioInfo?.pointee)
                return audioInfo?.pointee.samplesPerFrame ?? 0
            },
            cb_OnAudioUpdated: { buffer, samples, userData in
                // print(#function, "got \(samples) samples")
                return samples
            },
            cb_OnMechAvailable: { mechNumber, mechInfo, userData in
                // print(#function, "mech \(mechNumber) now available with info \(mechInfo?.pointee)")
            },
            cb_OnMechUpdated: { mechNumber, mechInfo, userData in
                // print(#function, "mech \(mechNumber) updated with info \(mechInfo?.pointee)")
            },
            cb_OnSolenoidUpdated: { solenoidState, userData in
                // print(#function, solenoidState?.pointee)
            },
            cb_OnConsoleDataUpdated: { data, size, userData in
                // print(#function, "\(size) bytes updated")
            },
            fn_IsKeyPressed: { keycode, userData in
                // print(#function, "asking about \(keycode)")
                return 0
            },
            cb_OnLogMessage: { logLevel, format, args, userData in
                if let format, let args {
                    let formattedMessage = NSString(format: String(cString: format), arguments: args)
                    print(#function, logLevel, formattedMessage)
                } else {
                    print(#function, logLevel, format, args)
                }
            },
            cb_OnSoundCommand: { boardNumber, command, userData in
                // print(#function, "command \(command) issued to board \(boardNumber)")
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
