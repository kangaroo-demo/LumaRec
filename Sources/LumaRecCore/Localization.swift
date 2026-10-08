import Foundation

public enum AppLanguage: String, CaseIterable {
    case english = "en"
    case simplifiedChinese = "zh-Hans"

    public var title: String {
        switch self {
        case .english: return "English"
        case .simplifiedChinese: return "简体中文"
        }
    }
}

public enum L10n {
    private static let resources: Bundle = {
        if let url = Bundle.main.resourceURL?.appendingPathComponent("LumaRec_LumaRecCore.bundle"),
           let bundle = Bundle(url: url) {
            return bundle
        }
        return Bundle.module
    }()

    public static let preferenceKey = "appLanguage"
    public static var language: AppLanguage = {
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "--language"),
           arguments.indices.contains(index + 1),
           let language = AppLanguage(rawValue: arguments[index + 1]) {
            return language
        }
        return AppLanguage(rawValue: UserDefaults.standard.string(forKey: preferenceKey) ?? "") ?? .english
    }()

    public static func string(_ key: String, language: AppLanguage? = nil) -> String {
        // SwiftPM normalizes localization directory names to lowercase.
        guard let path = resources.path(forResource: (language ?? self.language).rawValue.lowercased(), ofType: "lproj"),
              let bundle = Bundle(path: path) else { return key }
        return bundle.localizedString(forKey: key, value: key, table: nil)
    }
}

public func L(_ key: String) -> String { L10n.string(key) }

public func LF(_ key: String, _ arguments: CVarArg...) -> String {
    String(format: L(key), locale: Locale(identifier: L10n.language.rawValue), arguments: arguments)
}
