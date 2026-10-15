import Foundation

public enum ExportQuality: Int, Codable, CaseIterable {
    case standard, compact, high

    public var bitRate: Int {
        switch self {
        case .standard: return 8_000_000
        case .compact: return 4_000_000
        case .high: return 16_000_000
        }
    }
}

public struct ExportConfiguration: Codable {
    public var portrait: Bool
    public var mixAudio: Bool
    public var requireAudio: Bool
    public var quality: ExportQuality

    public init(portrait: Bool = false, mixAudio: Bool = false, quality: ExportQuality = .standard, requireAudio: Bool = false) {
        self.portrait = portrait
        self.mixAudio = mixAudio
        self.quality = quality
        self.requireAudio = requireAudio
    }
}
