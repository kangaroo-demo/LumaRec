import Foundation
import AVFoundation

/// Apple-only, offline H.264/AAC export. Source files are never changed or deleted here.
public enum NativeExporter {
    public static func export(input: URL, output: URL, configuration: ExportConfiguration) async throws {
        let asset = AVURLAsset(url: input)
        let duration = try await asset.load(.duration)
        let videos = try await asset.loadTracks(withMediaType: .video)
        let audios = try await asset.loadTracks(withMediaType: .audio)
        guard let video = videos.first, duration.isNumeric, duration.seconds > 0 else {
            throw failure("The source recording has no playable video.")
        }
        if FileManager.default.fileExists(atPath: output.path) {
            throw failure("A file already exists at the output path. Choose another filename.")
        }
        if configuration.requireAudio && audios.isEmpty {
            throw failure("The microphone did not produce an audio track. The original video has been kept.")
        }
        let sourceSize = try await video.load(.naturalSize)
        let sourceTransform = try await video.load(.preferredTransform)
        let size = CGSize(width: configuration.portrait ? 1080 : 1920,
                          height: configuration.portrait ? 1920 : 1080)
        let composition = AVMutableVideoComposition()
        composition.renderSize = size
        composition.frameDuration = CMTime(value: 1, timescale: 30)
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: duration)
        instruction.backgroundColor = CGColor(gray: 0, alpha: 1)
        let layer = AVMutableVideoCompositionLayerInstruction(assetTrack: video)
        layer.setTransform(fillTransform(size: sourceSize, preferred: sourceTransform,
                                          portrait: configuration.portrait, target: size), at: .zero)
        instruction.layerInstructions = [layer]
        composition.instructions = [instruction]

        // Encode privately in the destination volume, then move without overwriting.
        // A failure cannot replace a previous recording or expose a half-written final MP4.
        let staging = output.deletingLastPathComponent().appendingPathComponent(".LumaRec-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: staging, withIntermediateDirectories: false,
                                               attributes: [.posixPermissions: 0o700])
        defer { try? FileManager.default.removeItem(at: staging) }
        let partial = staging.appendingPathComponent("export.mp4")
        let reader = try AVAssetReader(asset: asset)
        let writer = try AVAssetWriter(outputURL: partial, fileType: .mp4)
        writer.shouldOptimizeForNetworkUse = true
        let videoOutput = AVAssetReaderVideoCompositionOutput(videoTracks: [video], videoSettings: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ])
        videoOutput.videoComposition = composition
        videoOutput.alwaysCopiesSampleData = false
        let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: Int(size.width), AVVideoHeightKey: Int(size.height),
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: configuration.quality.bitRate,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
                AVVideoExpectedSourceFrameRateKey: 30,
                AVVideoMaxKeyFrameIntervalKey: 60
            ]
        ])
        videoInput.expectsMediaDataInRealTime = false
        guard reader.canAdd(videoOutput), writer.canAdd(videoInput) else {
            throw failure("The native video encoder is unavailable.")
        }
        reader.add(videoOutput)
        writer.add(videoInput)
        var streams: [(AVAssetReaderOutput, AVAssetWriterInput)] = [(videoOutput, videoInput)]
        let selectedAudio = configuration.mixAudio ? audios : Array(audios.prefix(1))
        if !selectedAudio.isEmpty {
            let audioOutput = AVAssetReaderAudioMixOutput(audioTracks: selectedAudio, audioSettings: [
                AVFormatIDKey: kAudioFormatLinearPCM, AVSampleRateKey: 48_000,
                AVNumberOfChannelsKey: 2, AVLinearPCMBitDepthKey: 32,
                AVLinearPCMIsFloatKey: true, AVLinearPCMIsNonInterleaved: false
            ])
            if selectedAudio.count > 1 {
                let mix = AVMutableAudioMix()
                mix.inputParameters = selectedAudio.map { track in
                    let parameters = AVMutableAudioMixInputParameters(track: track)
                    parameters.setVolume(1 / Float(selectedAudio.count), at: .zero)
                    return parameters
                }
                audioOutput.audioMix = mix
            }
            let audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: [
                AVFormatIDKey: kAudioFormatMPEG4AAC, AVSampleRateKey: 48_000,
                AVNumberOfChannelsKey: 2, AVEncoderBitRateKey: 192_000
            ])
            audioInput.expectsMediaDataInRealTime = false
            guard reader.canAdd(audioOutput), writer.canAdd(audioInput) else {
                throw failure("The native audio encoder is unavailable.")
            }
            reader.add(audioOutput)
            writer.add(audioInput)
            streams.append((audioOutput, audioInput))
        }
        try await encode(reader: reader, writer: writer, streams: streams)
        let result = AVURLAsset(url: partial)
        let resultDuration = try await result.load(.duration)
        let resultVideo = try await result.loadTracks(withMediaType: .video)
        let resultAudio = try await result.loadTracks(withMediaType: .audio)
        guard resultDuration.seconds > 0, !resultVideo.isEmpty,
              selectedAudio.isEmpty || !resultAudio.isEmpty else {
            throw failure("The exported MP4 is incomplete. The original recording has been kept.")
        }
        try FileManager.default.moveItem(at: partial, to: output)
    }

    public static func fillTransform(size: CGSize, preferred: CGAffineTransform,
                                       portrait: Bool, target: CGSize) -> CGAffineTransform {
        var transform = preferred
        if portrait { transform = transform.concatenating(CGAffineTransform(rotationAngle: .pi / 2)) }
        let bounds = CGRect(origin: .zero, size: size).applying(transform)
        transform = transform.concatenating(CGAffineTransform(translationX: -bounds.minX, y: -bounds.minY))
        let scale = max(target.width / bounds.width, target.height / bounds.height)
        transform = transform.concatenating(CGAffineTransform(scaleX: scale, y: scale))
        return transform.concatenating(CGAffineTransform(translationX: (target.width - bounds.width * scale) / 2,
                                                       y: (target.height - bounds.height * scale) / 2))
    }

    private static func encode(reader: AVAssetReader, writer: AVAssetWriter,
                               streams: [(AVAssetReaderOutput, AVAssetWriterInput)]) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let job = EncodingJob(reader: reader, writer: writer, streams: streams, continuation: continuation)
            job.start()
        }
    }

    static func failure(_ text: String) -> NSError {
        NSError(domain: "LumaRec", code: 1, userInfo: [NSLocalizedDescriptionKey: L(text)])
    }
}

private final class EncodingJob {
    let reader: AVAssetReader
    let writer: AVAssetWriter
    let streams: [(AVAssetReaderOutput, AVAssetWriterInput)]
    let queue = DispatchQueue(label: "com.kangaroo-demo.LumaRec.export")
    var remaining: Int
    var finished = false
    let continuation: CheckedContinuation<Void, Error>

    init(reader: AVAssetReader, writer: AVAssetWriter, streams: [(AVAssetReaderOutput, AVAssetWriterInput)],
         continuation: CheckedContinuation<Void, Error>) {
        self.reader = reader; self.writer = writer; self.streams = streams
        self.remaining = streams.count; self.continuation = continuation
    }

    func start() {
        guard writer.startWriting() else { fail(writer.error); return }
        guard reader.startReading() else { fail(reader.error); return }
        writer.startSession(atSourceTime: .zero)
        for (output, input) in streams {
            var ended = false
            input.requestMediaDataWhenReady(on: queue) { [self] in
                guard !finished, !ended else { return }
                while input.isReadyForMoreMediaData {
                    if let sample = output.copyNextSampleBuffer() {
                        guard input.append(sample) else { fail(writer.error); return }
                    } else {
                        ended = true
                        input.markAsFinished()
                        if reader.status == .failed || reader.status == .cancelled { fail(reader.error); return }
                        remaining -= 1
                        if remaining == 0 {
                            finished = true
                            writer.finishWriting { [self] in
                                if writer.status == .completed { continuation.resume() }
                                else { continuation.resume(throwing: writer.error ?? NativeExporter.failure("Native MP4 encoding failed.")) }
                            }
                        }
                        return
                    }
                }
            }
        }
    }

    func fail(_ error: Error?) {
        guard !finished else { return }
        finished = true
        reader.cancelReading()
        writer.cancelWriting()
        continuation.resume(throwing: error ?? NativeExporter.failure("Native MP4 encoding failed."))
    }
}
