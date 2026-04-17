import AppKit
import Foundation

public struct PermisoHostApp: Sendable {
    public let displayName: String
    public let bundleURL: URL
    public let icon: NSImage

    public init(displayName: String, bundleURL: URL, icon: NSImage) {
        self.displayName = displayName
        self.bundleURL = bundleURL
        self.icon = icon
    }

    public static func current(bundle: Bundle = .main) -> PermisoHostApp {
        let displayName = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? bundle.object(forInfoDictionaryKey: kCFBundleNameKey as String) as? String
            ?? bundle.bundleURL.deletingPathExtension().lastPathComponent
        let icon = NSWorkspace.shared.icon(forFile: bundle.bundleURL.path)
        icon.size = NSSize(width: 48, height: 48)
        return PermisoHostApp(displayName: displayName, bundleURL: bundle.bundleURL, icon: icon)
    }
}
