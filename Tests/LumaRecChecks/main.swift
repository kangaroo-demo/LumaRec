import Foundation
import LumaRecCore

Task {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent("LumaRecChecks-\(UUID().uuidString)")
    do {
        guard L10n.string("Start recording", language: .simplifiedChinese) == "开始录制",
              L10n.string("Silent", language: .simplifiedChinese) == "无声",
              L10n.string("Recover recordings…", language: .simplifiedChinese) == "恢复录制…" else {
            throw NSError(domain: "Checks", code: 1, userInfo: [NSLocalizedDescriptionKey: "Packaged Chinese resources missing"])
        }
        print("PASS: packaged English/Chinese localization")
        for line in try await MediaQualification.run(in: directory) { print(line) }
        let unwritable = directory.appendingPathComponent("not-a-folder")
        try Data([1]).write(to: unwritable)
        var rejected = false
        do { try RecordingStore.validateDestination(unwritable) } catch { rejected = true }
        guard rejected else { fatalError("Invalid destination accepted") }
        rejected = false
        do { try RecordingStore.validateDestination(directory, minimumFreeBytes: Int64.max) } catch { rejected = true }
        guard rejected else { fatalError("Insufficient space was not rejected") }
        print("PASS: invalid destination and insufficient space rejected before capture")
        let record = try PendingRecording(output: directory.appendingPathComponent("recovered.mp4"), configuration: ExportConfiguration(portrait: true))
        defer { try? record.remove() }
        try FileManager.default.copyItem(at: directory.appendingPathComponent("synthetic-two-tones.mov"), to: record.source)
        guard let restored = RecordingStore.pending().first(where: { $0.id == record.id }), restored.configuration.portrait else {
            fatalError("Persistent recovery metadata missing")
        }
        try await NativeExporter.export(input: restored.source, output: restored.output, configuration: restored.configuration)
        guard FileManager.default.fileExists(atPath: restored.source.path) else { fatalError("Exporter deleted original") }
        print("PASS: persisted recording rediscovery and native recovery export")
        try FileManager.default.removeItem(at: directory)
        print("ALL CHECKS PASSED. Synthetic media only; hardware acceptance is separate.")
        exit(0)
    } catch {
        fputs("FAIL: \(error as NSError)\nEvidence kept at: \(directory.path)\n", stderr)
        exit(1)
    }
}
dispatchMain()
