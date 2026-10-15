import Foundation

/// Persistent originals and export settings survive failed export, app restart and temp cleanup.
public struct PendingRecording: Codable {
    public let id: UUID
    public let output: URL
    public let configuration: ExportConfiguration
    public let createdAt: Date

    public var directory: URL { RecordingStore.directory.appendingPathComponent(id.uuidString, isDirectory: true) }
    public var source: URL { directory.appendingPathComponent("capture.mov") }

    public init(output: URL, configuration: ExportConfiguration) throws {
        id = UUID(); self.output = output; self.configuration = configuration; createdAt = Date()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true,
                                               attributes: [.posixPermissions: 0o700])
        do {
            try JSONEncoder().encode(self).write(to: directory.appendingPathComponent("recording.json"), options: .atomic)
        } catch {
            try? FileManager.default.removeItem(at: directory)
            throw error
        }
    }

    /// Call only after a validated export, or when the user explicitly discards this recording.
    public func remove() throws { try FileManager.default.removeItem(at: directory) }
}

public enum RecordingStore {
    public static var directory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("LumaRec/Recordings", isDirectory: true)
    }

    public static func pending() -> [PendingRecording] {
        let directories = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        return directories.compactMap { folder in
            guard let data = try? Data(contentsOf: folder.appendingPathComponent("recording.json")),
                  let record = try? JSONDecoder().decode(PendingRecording.self, from: data),
                  folder.lastPathComponent == record.id.uuidString,
                  FileManager.default.fileExists(atPath: record.source.path) else { return nil }
            return record
        }.sorted { $0.createdAt < $1.createdAt }
    }

    public static func validateDestination(_ directory: URL, minimumFreeBytes: Int64 = 512 * 1024 * 1024) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let probe = directory.appendingPathComponent(".LumaRec-write-check-\(UUID().uuidString)")
        try Data([0]).write(to: probe, options: .withoutOverwriting)
        defer { try? FileManager.default.removeItem(at: probe) }
        let attributes = try FileManager.default.attributesOfFileSystem(forPath: directory.path)
        if let bytes = attributes[.systemFreeSize] as? NSNumber, bytes.int64Value < minimumFreeBytes {
            throw NativeExporter.failure("Not enough disk space. Free at least 512 MB before recording or exporting.")
        }
    }
}
