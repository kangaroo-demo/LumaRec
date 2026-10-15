import Foundation
import AVFoundation

/// Decode actual hardware output for local acceptance. Does not create synthetic media.
public enum RecordingInspection {
    public static func inspect(_ url: URL, expectedDuration: Double) async throws -> String {
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration).seconds
        let video = try await asset.loadTracks(withMediaType: .video)
        let audio = try await asset.loadTracks(withMediaType: .audio)
        guard let videoTrack = video.first, let audioTrack = audio.first else {
            throw NativeExporter.failure("Hardware output needs both a video track and an audio track")
        }
        guard abs(duration - expectedDuration) < 0.6 else {
            throw NativeExporter.failure("Pause was not removed from the actual output timeline: \(duration)s")
        }
        func decode(_ track: AVAssetTrack, settings: [String: Any]) throws -> (count: Int, gap: Double, end: Double, rms: Double) {
            let reader = try AVAssetReader(asset: asset)
            let output = AVAssetReaderTrackOutput(track: track, outputSettings: settings)
            reader.add(output)
            guard reader.startReading() else { throw reader.error ?? NativeExporter.failure("Cannot decode hardware output") }
            var count = 0, previous = -1.0, previousEnd = 0.0, maxGap = 0.0, end = 0.0, energy = 0.0
            var audioSamples = 0
            while let sample = output.copyNextSampleBuffer() {
                let pts = CMSampleBufferGetPresentationTimeStamp(sample).seconds
                let span = CMSampleBufferGetDuration(sample).seconds
                if previous >= 0 {
                    guard pts >= previous else { throw NativeExporter.failure("Non-monotonic hardware timestamps") }
                    maxGap = max(maxGap, pts - previousEnd)
                }
                previous = pts; previousEnd = pts + (span.isFinite ? span : 0)
                end = max(end, previousEnd); count += 1
                if track.mediaType == .audio, let block = CMSampleBufferGetDataBuffer(sample) {
                    let length = CMBlockBufferGetDataLength(block) / 4
                    var values = [Float](repeating: 0, count: length)
                    let status = values.withUnsafeMutableBytes { raw in
                        CMBlockBufferCopyDataBytes(block, atOffset: 0, dataLength: length * 4, destination: raw.baseAddress!)
                    }
                    guard status == noErr else { throw NativeExporter.failure("Cannot read hardware PCM") }
                    for value in values { energy += Double(value) * Double(value) }
                    audioSamples += values.count
                }
            }
            guard reader.status == .completed else { throw reader.error ?? NativeExporter.failure("Hardware decode incomplete") }
            return (count, maxGap, end, audioSamples > 0 ? sqrt(energy / Double(audioSamples)) : 0)
        }
        let videoRange = try await videoTrack.load(.timeRange)
        let audioRange = try await audioTrack.load(.timeRange)
        let picture = try decode(videoTrack, settings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA])
        let sound = try decode(audioTrack, settings: [AVFormatIDKey: kAudioFormatLinearPCM, AVSampleRateKey: 48_000,
            AVNumberOfChannelsKey: 1, AVLinearPCMBitDepthKey: 32, AVLinearPCMIsFloatKey: true,
            AVLinearPCMIsNonInterleaved: false])
        guard picture.count > 60, picture.gap < 0.15, sound.gap < 0.15, abs(picture.end - sound.end) < 0.15 else {
            throw NativeExporter.failure("Hardware timestamp check: frames=\(picture.count), videoGap=\(picture.gap), audioGap=\(sound.gap), videoEnd=\(picture.end), audioEnd=\(sound.end), duration=\(duration), rms=\(sound.rms)")
        }
        guard sound.rms > 0.00001 else { throw NativeExporter.failure("Hardware audio is silent; repeat with audible microphone input") }
        return "PASS: actual camera/microphone MP4 decoded\nDuration: \(duration)s; expected active duration: \(expectedDuration)s\nVideo/audio track starts: \(videoRange.start.seconds)s / \(audioRange.start.seconds)s\nVideo frames: \(picture.count); maximum timestamp gap: \(picture.gap)s\nAudio buffers: \(sound.count); maximum timestamp gap: \(sound.gap)s\nAudio/video end difference: \(abs(picture.end - sound.end))s\nMicrophone decoded RMS: \(sound.rms)\nPause interval was excluded from output duration. Human playback/lip-sync review is still separate.\n"
    }
}
