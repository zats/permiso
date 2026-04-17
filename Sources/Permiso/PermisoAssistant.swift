import AppKit
import Foundation

@MainActor
public final class PermisoAssistant {
    public static let shared = PermisoAssistant()

    private var overlayController: OverlayWindowController?
    private var trackingTimer: Timer?
    private var activePanel: PermisoPanel?
    private var pendingSourceFrameInScreen: CGRect?
    private var didPresentCurrentOverlay = false

    public init() {}

    public func present(
        panel: PermisoPanel,
        hostApp: PermisoHostApp = .current(),
        sourceFrameInScreen: CGRect? = nil
    ) {
        activePanel = panel
        pendingSourceFrameInScreen = sourceFrameInScreen
        didPresentCurrentOverlay = false
        overlayController = OverlayWindowController(hostApp: hostApp, panel: panel) { [weak self] in
            self?.dismiss()
        }
        NSWorkspace.shared.open(panel.settingsURL)
        startTracking()
    }

    public func dismiss() {
        trackingTimer?.invalidate()
        trackingTimer = nil
        overlayController?.close()
        overlayController = nil
        activePanel = nil
        pendingSourceFrameInScreen = nil
        didPresentCurrentOverlay = false
    }

    private func startTracking() {
        trackingTimer?.invalidate()
        trackingTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshPosition()
            }
        }
        refreshPosition()
    }

    private func refreshPosition() {
        guard let snapshot = SettingsWindowLocator.frontmostWindow() else {
            overlayController?.hide()
            return
        }
        if didPresentCurrentOverlay {
            overlayController?.updatePosition(with: snapshot.frame, visibleFrame: snapshot.visibleFrame)
            return
        }

        overlayController?.present(
            from: pendingSourceFrameInScreen,
            settingsFrame: snapshot.frame,
            visibleFrame: snapshot.visibleFrame
        )
        didPresentCurrentOverlay = true
    }
}
