import Foundation

public enum ExportQuality: Int {
    case standard, compact, high

    public var crf: String {
        switch self {
        case .standard: return "23"
        case .compact: return "28"
        case .high: return "18"
        }
    }
}

public struct ExportConfiguration {
    public var portrait: Bool
    public var mixAudio: Bool
    public var audioTrackCount: Int
    public var quality: ExportQuality

    public init(portrait: Bool = false, mixAudio: Bool = false, audioTrackCount: Int = 1, quality: ExportQuality = .standard) {
        self.portrait = portrait
        self.mixAudio = mixAudio
        self.audioTrackCount = audioTrackCount
        self.quality = quality
    }

    public var videoFilter: String {
        let width = portrait ? 1080 : 1920
        let height = portrait ? 1920 : 1080
        let rotation = portrait ? "transpose=1," : ""
        return "\(rotation)scale=\(width):\(height):force_original_aspect_ratio=decrease,pad=\(width):\(height):(ow-iw)/2:(oh-ih)/2"
    }

    public func arguments(input: URL, output: URL) -> [String] {
        // Refuse to overwrite another recording, even when a filename collides.
        var args = ["-n", "-nostdin", "-hide_banner", "-loglevel", "error", "-i", input.path]
        if mixAudio && audioTrackCount > 1 {
            let inputs = (0..<audioTrackCount).map { "[0:a:\($0)]" }.joined()
            args += ["-filter_complex", "\(inputs)amix=inputs=\(audioTrackCount):duration=longest:dropout_transition=2[a]",
                     "-map", "0:v:0", "-map", "[a]"]
        } else {
            args += ["-map", "0:v:0", "-map", "0:a:0?"]
        }
        args += ["-vf", videoFilter, "-r", "30", "-c:v", "libx264", "-preset", "veryfast",
                 "-crf", quality.crf, "-pix_fmt", "yuv420p", "-c:a", "aac", "-b:a", "192k",
                 "-movflags", "+faststart", output.path]
        return args
    }
}

public enum FFmpegLocator {
    public static func find(environment: [String: String] = ProcessInfo.processInfo.environment) -> URL? {
        if let override = environment["LUMAREC_FFMPEG"], !override.isEmpty {
            return executable(at: override)
        }
        let directories = ["/opt/homebrew/bin", "/usr/local/bin"] + (environment["PATH"] ?? "").components(separatedBy: ":")
        return directories.filter { !$0.isEmpty }.lazy.compactMap { executable(at: $0 + "/ffmpeg") }.first
    }

    private static func executable(at path: String) -> URL? {
        var isDirectory: ObjCBool = false
        guard path.hasPrefix("/"),
              FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory), !isDirectory.boolValue,
              FileManager.default.isExecutableFile(atPath: path) else { return nil }
        return URL(fileURLWithPath: path)
    }
}

public enum ExportValidation {
    public static func succeeded(output: URL, exitCode: Int32, errorLog: String) -> Bool {
        // Some FFmpeg builds exit with zero when refusing to overwrite a file.
        guard exitCode == 0, errorLog.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let attributes = try? FileManager.default.attributesOfItem(atPath: output.path),
              let size = attributes[.size] as? NSNumber else { return false }
        return size.int64Value > 0
    }
}
