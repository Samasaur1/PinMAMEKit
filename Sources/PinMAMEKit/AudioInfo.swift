import Foundation
import libpinmame

extension PinMAME {
    public struct AudioInfo {
        public let format: AudioFormat
        public let channels: Int
        public let sampleRate: Double
        public let framesPerSecond: Double
        public let samplesPerFrame: Int
        public let bufferSize: Int
    }
}

extension PinMAME.AudioInfo {
    init?(libpinmame: PinmameAudioInfo) {
        guard let format = PinMAME.AudioFormat(libpinmame: libpinmame.format) else { return nil }
        self.init(
            format: format,
            channels: Int(libpinmame.channels),
            sampleRate: libpinmame.sampleRate,
            framesPerSecond: libpinmame.framesPerSecond,
            samplesPerFrame: Int(libpinmame.samplesPerFrame),
            bufferSize: Int(libpinmame.bufferSize)
        )
    }
}
