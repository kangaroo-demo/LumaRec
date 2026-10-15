import Foundation
import AVFoundation

/// Deterministic synthetic media checks. Never opens a camera or microphone.
public enum MediaQualification {
    private static func require(_ value: Bool, _ message: String) throws {
        if !value { throw NativeExporter.failure(message) }
    }

    @discardableResult
    public static func run(in directory: URL) async throws -> [String] {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var evidence: [String] = []
        let silent = directory.appendingPathComponent("synthetic-silent.mov")
        try await makeVideo(at: silent)
        let input = directory.appendingPathComponent("synthetic-two-tones.mov")
        try await addAudio(to: silent, output: input, directory: directory)
        evidence.append("PASS: Apple-only synthetic 640×360 video + independent 440/880 Hz PCM tracks")
        for quality in ExportQuality.allCases {
            let output = directory.appendingPathComponent("landscape-\(quality.rawValue).mp4")
            try await NativeExporter.export(input: input, output: output, configuration: ExportConfiguration(quality: quality))
            try await verify(output, portrait: false, audio: true, mixed: false)
            evidence.append("PASS: H.264/AAC landscape 1920×1080 30fps, quality \(quality), decoded picture + audible 440 Hz")
        }
        let portrait = directory.appendingPathComponent("portrait-mixed.mp4")
        try await NativeExporter.export(input: input, output: portrait, configuration: ExportConfiguration(portrait: true, mixAudio: true))
        try await verify(portrait, portrait: true, audio: true, mixed: true)
        evidence.append("PASS: portrait 1080×1920 clockwise rotation; mixed AAC contains both 440/880 Hz")
        let silentOutput = directory.appendingPathComponent("silent.mp4")
        try await NativeExporter.export(input: silent, output: silentOutput, configuration: ExportConfiguration())
        try await verify(silentOutput, portrait: false, audio: false, mixed: false)
        evidence.append("PASS: silent MP4 is playable, no audio track required")
        let fourByThree = directory.appendingPathComponent("synthetic-4x3.mov")
        let cropped = directory.appendingPathComponent("4x3-filled.mp4")
        try await makeVideo(at: fourByThree, width: 640, height: 480)
        try await NativeExporter.export(input: fourByThree, output: cropped, configuration: ExportConfiguration())
        try await verify(cropped, portrait: false, audio: false, mixed: false)
        evidence.append("PASS: actual 4:3 source exports with all four frame corners filled, no added black borders")
        let missingAudio = directory.appendingPathComponent("missing-audio.mp4")
        var missingAudioRejected = false
        do {
            try await NativeExporter.export(input: silent, output: missingAudio, configuration: ExportConfiguration(requireAudio: true))
        } catch { missingAudioRejected = true }
        try require(missingAudioRejected && !FileManager.default.fileExists(atPath: missingAudio.path), "Mic mode accepted missing audio")
        evidence.append("PASS: Mic mode rejects a missing audio track; Silent mode remains supported")
        let original = try Data(contentsOf: silentOutput)
        do {
            try await NativeExporter.export(input: input, output: silentOutput, configuration: ExportConfiguration())
            throw NativeExporter.failure("Collision was not rejected")
        } catch {
            try require(try Data(contentsOf: silentOutput) == original, "Existing output changed")
        }
        evidence.append("PASS: output collision preserves existing MP4")
        let invalid = directory.appendingPathComponent("invalid.mov")
        try Data("not a movie".utf8).write(to: invalid)
        let rejected = directory.appendingPathComponent("rejected.mp4")
        var failed = false
        do { try await NativeExporter.export(input: invalid, output: rejected, configuration: ExportConfiguration()) }
        catch { failed = true }
        try require(failed && !FileManager.default.fileExists(atPath: rejected.path), "Invalid media left a final output")
        try require(FileManager.default.fileExists(atPath: input.path), "Source was removed")
        evidence.append("PASS: corrupt source rejected; no final partial MP4; original kept")
        let transform = NativeExporter.fillTransform(size: CGSize(width: 640, height: 480),
            preferred: CGAffineTransform(translationX: 17, y: -25), portrait: false,
            target: CGSize(width: 1920, height: 1080))
        let bounds = CGRect(x: 0, y: 0, width: 640, height: 480).applying(transform)
        try require(abs(bounds.minY + 180) < 0.1 && abs(bounds.width - 1920) < 0.1 && abs(bounds.height - 1440) < 0.1, "4:3 center crop failed")
        evidence.append("PASS: nonzero source origin and 4:3 center crop without black borders")
        try evidence.joined(separator: "\n").appending("\nSYNTHETIC ONLY: no camera capture, pause/resume, or physical device acceptance claimed.\n")
            .write(to: directory.appendingPathComponent("verification.txt"), atomically: true, encoding: .utf8)
        return evidence
    }

    private static func makeVideo(at url: URL, width: Int = 640, height: Int = 360) async throws {
        let writer = try AVAssetWriter(outputURL: url, fileType: .mov)
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: width, AVVideoHeightKey: height
        ])
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: width, kCVPixelBufferHeightKey as String: height
        ])
        writer.add(input)
        try require(writer.startWriting(), "Cannot start synthetic writer")
        writer.startSession(atSourceTime: .zero)
        for frame in 0..<30 {
            while !input.isReadyForMoreMediaData {
                try require(writer.status == .writing, "Synthetic video writer failed")
                try await Task.sleep(nanoseconds: 1_000_000)
            }
            var buffer: CVPixelBuffer?
            CVPixelBufferPoolCreatePixelBuffer(nil, adaptor.pixelBufferPool!, &buffer)
            guard let buffer else { throw NativeExporter.failure("No fixture pixel buffer") }
            CVPixelBufferLockBaseAddress(buffer, [])
            let base = CVPixelBufferGetBaseAddress(buffer)!.assumingMemoryBound(to: UInt8.self)
            let stride = CVPixelBufferGetBytesPerRow(buffer)
            for y in 0..<height {
                for x in 0..<width {
                    let offset = y * stride + x * 4
                    base[offset] = UInt8((x + frame * 4) % 80)
                    base[offset + 1] = y >= height / 2 ? 210 : 20
                    base[offset + 2] = y < height / 2 ? 210 : 20
                    base[offset + 3] = 255
                }
            }
            CVPixelBufferUnlockBaseAddress(buffer, [])
            try require(adaptor.append(buffer, withPresentationTime: CMTime(value: Int64(frame), timescale: 30)), "Fixture append failed")
        }
        writer.endSession(atSourceTime: CMTime(value: 1, timescale: 1))
        input.markAsFinished()
        await writer.finishWriting()
        try require(writer.status == .completed, writer.error?.localizedDescription ?? "Fixture encoding failed")
    }

    private static func addAudio(to video: URL, output: URL, directory: URL) async throws {
        let composition = AVMutableComposition()
        let source = AVURLAsset(url: video)
        let videoTrack = try await source.loadTracks(withMediaType: .video)[0]
        let range = CMTimeRange(start: .zero, duration: CMTime(value: 1, timescale: 1))
        try composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)!
            .insertTimeRange(range, of: videoTrack, at: .zero)
        for frequency in [440.0, 880.0] {
            let wave = directory.appendingPathComponent("tone-\(Int(frequency)).wav")
            let format = AVAudioFormat(standardFormatWithSampleRate: 48_000, channels: 1)!
            var file: AVAudioFile? = try AVAudioFile(forWriting: wave, settings: format.settings)
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 48_000)!
            buffer.frameLength = 48_000
            for i in 0..<48_000 { buffer.floatChannelData![0][i] = Float(0.3 * sin(2 * .pi * frequency * Double(i) / 48_000)) }
            try file!.write(from: buffer)
            file = nil // Finalize WAV header before AVURLAsset reads it.
            let waveAsset = AVURLAsset(url: wave)
            let audio = try await waveAsset.loadTracks(withMediaType: .audio)[0]
            try composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!
                .insertTimeRange(range, of: audio, at: .zero)
        }
        let export = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetPassthrough)!
        export.outputURL = output; export.outputFileType = .mov
        await export.export()
        try require(export.status == .completed, export.error?.localizedDescription ?? "Fixture composition failed")
    }

    private static func verify(_ url: URL, portrait: Bool, audio: Bool, mixed: Bool) async throws {
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration)
        try require(abs(duration.seconds - 1) < 0.12, "Output duration is wrong")
        let video = try await asset.loadTracks(withMediaType: .video)[0]
        let size = try await video.load(.naturalSize)
        try require(size == CGSize(width: portrait ? 1080 : 1920, height: portrait ? 1920 : 1080), "Output dimensions are wrong")
        let fps = try await video.load(.nominalFrameRate)
        try require(abs(fps - 30) < 0.1, "Output frame rate is wrong")
        let formats = try await video.load(.formatDescriptions)
        try require(CMFormatDescriptionGetMediaSubType(formats[0]) == kCMVideoCodecType_H264, "Expected H.264")
        let reader = try AVAssetReader(asset: asset)
        let pixels = AVAssetReaderTrackOutput(track: video, outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA])
        reader.add(pixels)
        try require(reader.startReading(), "Cannot decode MP4 video")
        var frameCount = 0
        while let sample = pixels.copyNextSampleBuffer() {
            if frameCount == 0, let buffer = CMSampleBufferGetImageBuffer(sample) {
                CVPixelBufferLockBaseAddress(buffer, .readOnly)
                defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }
                let base = CVPixelBufferGetBaseAddress(buffer)!.assumingMemoryBound(to: UInt8.self)
                let stride = CVPixelBufferGetBytesPerRow(buffer)
                let x = Int(size.width) / 4, y = Int(size.height) / 4
                let at = y * stride + x * 4
                for (cx, cy) in [(2, 2), (Int(size.width) - 3, 2), (2, Int(size.height) - 3), (Int(size.width) - 3, Int(size.height) - 3)] {
                    let corner = cy * stride + cx * 4
                    try require(max(base[corner + 1], base[corner + 2]) > 100, "Added black border detected in decoded frame")
                }
                // Red upper half rotates to the right half; top-left becomes green in portrait.
                try require(portrait ? base[at + 1] > base[at + 2] : base[at + 2] > base[at + 1], "Picture/clockwise rotation verification failed")
            }
            frameCount += 1
        }
        try require(reader.status == .completed && frameCount >= 29, "Video does not fully decode")
        let audios = try await asset.loadTracks(withMediaType: .audio)
        try require(audios.count == (audio ? 1 : 0), "Wrong output audio count")
        guard audio else { return }
        let audioFormats = try await audios[0].load(.formatDescriptions)
        try require(CMFormatDescriptionGetMediaSubType(audioFormats[0]) == kAudioFormatMPEG4AAC, "Expected AAC")
        let audioReader = try AVAssetReader(asset: asset)
        let samples = AVAssetReaderTrackOutput(track: audios[0], outputSettings: [
            AVFormatIDKey: kAudioFormatLinearPCM, AVSampleRateKey: 48_000, AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 32, AVLinearPCMIsFloatKey: true, AVLinearPCMIsNonInterleaved: false
        ])
        audioReader.add(samples)
        try require(audioReader.startReading(), "Cannot decode AAC")
        var signal: [Float] = []
        while let sample = samples.copyNextSampleBuffer() {
            guard let block = CMSampleBufferGetDataBuffer(sample) else { continue }
            let count = CMBlockBufferGetDataLength(block) / 4
            var values = [Float](repeating: 0, count: count)
            let status = values.withUnsafeMutableBytes { raw in
                CMBlockBufferCopyDataBytes(block, atOffset: 0, dataLength: count * 4, destination: raw.baseAddress!)
            }
            try require(status == noErr, "PCM read failed")
            signal += values
        }
        try require(audioReader.status == .completed && signal.count > 42_000, "AAC does not fully decode")
        func power(_ hz: Double) -> Double {
            var a = 0.0, b = 0.0
            for (i, sample) in signal.enumerated() {
                let phase = 2 * Double.pi * hz * Double(i) / 48_000
                a += Double(sample) * cos(phase); b += Double(sample) * sin(phase)
            }
            return hypot(a, b) / Double(signal.count)
        }
        try require(power(440) > 0.02, "Expected audible 440 Hz source")
        if mixed { try require(power(880) > 0.02, "Second source absent from mix") }
        else { try require(power(880) < 0.01, "Single-input mode unexpectedly mixed a second track") }
        let videoRange = try await video.load(.timeRange)
        let audioRange = try await audios[0].load(.timeRange)
        try require(abs(videoRange.start.seconds - audioRange.start.seconds) < 0.06 &&
                    abs(videoRange.duration.seconds - audioRange.duration.seconds) < 0.12, "Synthetic audio/video timestamps diverged")
    }
}
