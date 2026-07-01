import AppKit
import Foundation

public enum PermisoPanel: String, CaseIterable, Sendable {
    case accessibility = "Privacy_Accessibility"
    case screenRecording = "Privacy_ScreenCapture"
    case appManagement = "Privacy_AppBundles"

    public var title: String {
        switch self {
        case .accessibility:
            "Accessibility"
        case .screenRecording:
            "Screen Recording"
        case .appManagement:
            "App Management"
        }
    }

    public var settingsURL: URL {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?\(rawValue)") else {
            preconditionFailure("Invalid System Settings URL for \(rawValue)")
        }
        return url
    }
}
