import AppKit
import CoreGraphics
import Foundation

struct SettingsWindowSnapshot: Equatable {
    let pid: pid_t
    let frame: CGRect
    let visibleFrame: CGRect
}

enum SettingsWindowLocator {
    static let bundleIdentifier = "com.apple.systempreferences"

    static var isSystemSettingsFrontmost: Bool {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier == bundleIdentifier
    }

    static func frontmostWindow() -> SettingsWindowSnapshot? {
        guard isSystemSettingsFrontmost else {
            return nil
        }

        guard let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier)
            .max(by: { ($0.activationPolicy == .prohibited ? 0 : 1) < ($1.activationPolicy == .prohibited ? 0 : 1) }) else {
            return nil
        }

        guard let windowInfo = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], .zero) as? [[String: Any]] else {
            return nil
        }

        let windows = windowInfo.compactMap { info -> SettingsWindowSnapshot? in
            guard let ownerPID = info[kCGWindowOwnerPID as String] as? pid_t, ownerPID == app.processIdentifier else {
                return nil
            }
            guard let layer = info[kCGWindowLayer as String] as? Int, layer == 0 else {
                return nil
            }
            guard let bounds = info[kCGWindowBounds as String] as? [String: CGFloat] else {
                return nil
            }

            let cgFrame = CGRect(
                x: bounds["X"] ?? 0,
                y: bounds["Y"] ?? 0,
                width: bounds["Width"] ?? 0,
                height: bounds["Height"] ?? 0
            )
            let converted = appKitGeometry(from: cgFrame)
            let frame = converted.frame
            guard frame.width > 320, frame.height > 240 else {
                return nil
            }
            return SettingsWindowSnapshot(
                pid: ownerPID,
                frame: frame,
                visibleFrame: converted.visibleFrame
            )
        }

        return windows.max(by: { $0.frame.width * $0.frame.height < $1.frame.width * $1.frame.height })
    }

    private static func appKitGeometry(from cgFrame: CGRect) -> (frame: CGRect, visibleFrame: CGRect) {
        let screens = NSScreen.screens.compactMap { screen -> (frame: CGRect, visibleFrame: CGRect, cgBounds: CGRect)? in
            guard
                let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
            else {
                return nil
            }
            let displayID = CGDirectDisplayID(number.uint32Value)
            return (
                frame: screen.frame,
                visibleFrame: screen.visibleFrame,
                cgBounds: CGDisplayBounds(displayID)
            )
        }

        let matchedScreen = screens
            .filter { $0.cgBounds.intersects(cgFrame) }
            .max { lhs, rhs in
                lhs.cgBounds.intersection(cgFrame).width * lhs.cgBounds.intersection(cgFrame).height
                    < rhs.cgBounds.intersection(cgFrame).width * rhs.cgBounds.intersection(cgFrame).height
            }

        guard let matchedScreen else {
            let mainVisibleFrame = NSScreen.main?.visibleFrame ?? CGRect(origin: .zero, size: cgFrame.size)
            return (
                frame: cgFrame,
                visibleFrame: mainVisibleFrame
            )
        }

        let localX = cgFrame.minX - matchedScreen.cgBounds.minX
        let localY = cgFrame.minY - matchedScreen.cgBounds.minY
        let frame = CGRect(
            x: matchedScreen.frame.minX + localX,
            y: matchedScreen.frame.maxY - localY - cgFrame.height,
            width: cgFrame.width,
            height: cgFrame.height
        )

        return (frame: frame, visibleFrame: matchedScreen.visibleFrame)
    }
}
