import Foundation
import LumaRecCore

struct CheckFailure: Error, CustomStringConvertible {
    let description: String
}

func require(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    if !condition() { throw CheckFailure(description: message) }
}

var passed = 0
var failed = 0
func check(_ name: String, _ body: () throws -> Void) {
    do {
        try body()
        passed += 1
        print("PASS: \(name)")
    } catch {
        failed += 1
        fputs("FAIL: \(name): \(error)\n", stderr)
    }
}

check("packaged English and Chinese translations") {
    try require(L10n.string("Start recording", language: .english) == "Start recording", "English translation failed")
    try require(L10n.string("Start recording", language: .simplifiedChinese) == "开始录制", "Chinese translation failed")
    try require(L10n.string("Language", language: .simplifiedChinese) == "语言", "Chinese menu translation failed")
}

check("translated paths and counts") {
    let format = L10n.string("File: %@\nFolder: %@", language: .simplifiedChinese)
    try require(String(format: format, "camera.mp4", "/tmp/videos") == "文件：camera.mp4\n目录：/tmp/videos", "Path formatting failed")
    let countFormat = L10n.string("Exporting MP4 · Audio tracks: %d", language: .simplifiedChinese)
    try require(String(format: countFormat, 2) == "正在生成 MP4 · 音轨：2", "Count formatting failed")
}

check("invalid explicit FFmpeg paths do not fall back silently") {
    for path in ["/path/that/does/not/exist", "/tmp", "relative/ffmpeg"] {
        try require(FFmpegLocator.find(environment: ["LUMAREC_FFMPEG": path]) == nil, "Accepted invalid path: \(path)")
    }
}

let directory = FileManager.default.temporaryDirectory.appendingPathComponent("LumaRecChecks-\(UUID().uuidString)")
try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
defer { try? FileManager.default.removeItem(at: directory) }

func run(_ executable: URL, _ arguments: [String]) throws -> (status: Int32, text: String) {
    let logURL = directory.appendingPathComponent("process-\(UUID().uuidString).log")
    FileManager.default.createFile(atPath: logURL.path, contents: nil)
    let handle = try FileHandle(forWritingTo: logURL)
    defer { try? handle.close() }
    let process = Process()
    process.executableURL = executable
    process.arguments = arguments
    process.standardOutput = handle
    process.standardError = handle
    try process.run()
    process.waitUntilExit()
    try handle.synchronize()
    return (process.terminationStatus, try String(contentsOf: logURL, encoding: .utf8))
}

if let ffmpeg = FFmpegLocator.find() {
    let ffprobe = ffmpeg.deletingLastPathComponent().appendingPathComponent("ffprobe")
    if FileManager.default.isExecutableFile(atPath: ffprobe.path) {
        let input = directory.appendingPathComponent("synthetic input.mov")
        check("create synthetic camera and two audio tracks") {
            let result = try run(ffmpeg, ["-hide_banner", "-loglevel", "error", "-nostdin",
                "-f", "lavfi", "-i", "testsrc2=size=640x360:rate=30:duration=0.4",
                "-f", "lavfi", "-i", "sine=frequency=440:duration=0.4",
                "-f", "lavfi", "-i", "sine=frequency=880:duration=0.4",
                "-map", "0:v", "-map", "1:a", "-map", "2:a",
                "-c:v", "libx264", "-preset", "ultrafast", "-c:a", "pcm_s16le", input.path])
            try require(ExportValidation.succeeded(output: input, exitCode: result.status, errorLog: result.text), result.text)
        }

        func verifyExport(_ configuration: ExportConfiguration, width: Int, height: Int) throws {
            let output = directory.appendingPathComponent("export \(UUID().uuidString).mp4")
            let result = try run(ffmpeg, configuration.arguments(input: input, output: output))
            try require(ExportValidation.succeeded(output: output, exitCode: result.status, errorLog: result.text), result.text)
            let probe = try run(ffprobe, ["-v", "error", "-show_streams", "-of", "json", output.path])
            try require(probe.status == 0, probe.text)
            guard let json = try JSONSerialization.jsonObject(with: Data(probe.text.utf8)) as? [String: Any],
                  let streams = json["streams"] as? [[String: Any]],
                  let video = streams.first(where: { $0["codec_type"] as? String == "video" }) else {
                throw CheckFailure(description: "Missing video stream")
            }
            let audio = streams.filter { $0["codec_type"] as? String == "audio" }
            try require(video["codec_name"] as? String == "h264", "Expected H.264 video")
            try require(video["width"] as? Int == width && video["height"] as? Int == height, "Unexpected dimensions")
            try require(video["r_frame_rate"] as? String == "30/1", "Expected 30 fps")
            try require(audio.count == 1 && audio.first?["codec_name"] as? String == "aac", "Expected one AAC track")
            let decode = try run(ffmpeg, ["-v", "error", "-nostdin", "-i", output.path, "-f", "null", "-"])
            try require(decode.status == 0, decode.text)
        }

        check("landscape H.264/AAC encoding and decoding") {
            try verifyExport(ExportConfiguration(), width: 1920, height: 1080)
        }
        check("portrait rotation and mixed audio export") {
            try verifyExport(ExportConfiguration(portrait: true, mixAudio: true, audioTrackCount: 2), width: 1080, height: 1920)
        }
        check("all quality presets encode and decode") {
            for quality in [ExportQuality.standard, .compact, .high] {
                try verifyExport(ExportConfiguration(quality: quality), width: 1920, height: 1080)
            }
        }
        check("filename collisions preserve existing recordings and source MOV") {
            let output = directory.appendingPathComponent("existing recording.mp4")
            let original = Data("an existing recording".utf8)
            try original.write(to: output)
            let result = try run(ffmpeg, ExportConfiguration().arguments(input: input, output: output))
            try require(!ExportValidation.succeeded(output: output, exitCode: result.status, errorLog: result.text), "Expected export to reject an existing file")
            let remaining = try Data(contentsOf: output)
            try require(remaining == original, "Existing file was modified")
            try require(FileManager.default.fileExists(atPath: input.path), "Source MOV was removed")
        }
    } else {
        print("SKIP: encoding checks require FFprobe beside FFmpeg")
        if ProcessInfo.processInfo.arguments.contains("--require-ffmpeg") { failed += 1 }
    }
} else {
    print("SKIP: encoding checks require FFmpeg and FFprobe")
    if ProcessInfo.processInfo.arguments.contains("--require-ffmpeg") { failed += 1 }
}

print("\(passed) checks passed, \(failed) failed")
exit(failed == 0 ? 0 : 1)
