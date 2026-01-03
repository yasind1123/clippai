import AppKit

enum AppNameResolver {
    private static var cache: [String: String] = [:]

    static func displayName(sourceName: String?, bundleId: String?) -> String? {
        if let sourceName, !sourceName.isEmpty {
            return sourceName
        }
        guard let bundleId, !bundleId.isEmpty else { return nil }
        if let cached = cache[bundleId] {
            return cached
        }
        if let runningName = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bundleId })?.localizedName,
           !runningName.isEmpty {
            cache[bundleId] = runningName
            return runningName
        }
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId),
              let bundle = Bundle(url: url) else {
            return nil
        }
        let name = (bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
            ?? (bundle.object(forInfoDictionaryKey: "CFBundleName") as? String)
        if let name, !name.isEmpty {
            cache[bundleId] = name
        }
        return name
    }
}
