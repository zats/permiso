import AppKit
import Foundation

final class OverlayWindowController: NSWindowController {
    private let windowSize = NSSize(width: 530, height: 109)
    private let launchAnimationDuration: TimeInterval = 0.72
    private let launchAnimationResponse: Double = 0.72
    private let launchAnimationDampingFraction: Double = 1.0
    private let initialAlpha: CGFloat = 0.9
    private var launchTimer: Timer?
    private var launchStartTime: CFTimeInterval = 0
    private var launchFromFrame = NSRect.zero
    private var launchToFrame = NSRect.zero

    init(hostApp: PermisoHostApp, panel: PermisoPanel, onBack: @escaping () -> Void) {
        let window = PassiveOverlayPanel(
            contentRect: NSRect(origin: .zero, size: windowSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        super.init(window: window)
        configureWindow(window)
        window.contentView = OverlayContentView(hostApp: hostApp, panel: panel, onBack: onBack)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func close() {
        stopLaunchAnimation()
        window?.orderOut(nil)
        super.close()
    }

    func present(from sourceFrameInScreen: CGRect?, settingsFrame: CGRect, visibleFrame: CGRect) {
        stopLaunchAnimation()
        guard let window else { return }
        let targetOrigin = anchoredOrigin(for: settingsFrame, visibleFrame: visibleFrame)
        let targetFrame = NSRect(origin: targetOrigin, size: windowSize)

        guard let sourceFrameInScreen, !sourceFrameInScreen.isEmpty else {
            window.alphaValue = 1
            window.setFrame(targetFrame, display: false)
            window.orderFrontRegardless()
            return
        }

        launchFromFrame = sourceFrameInScreen
        launchToFrame = targetFrame
        launchStartTime = CACurrentMediaTime()

        window.alphaValue = initialAlpha
        window.setFrame(sourceFrameInScreen, display: false)
        window.orderFrontRegardless()
        stepLaunchAnimation()

        let timer = Timer(timeInterval: 1.0 / 120.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.stepLaunchAnimation()
            }
        }
        launchTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    func updatePosition(with settingsFrame: CGRect, visibleFrame: CGRect) {
        guard let window else { return }
        let origin = anchoredOrigin(for: settingsFrame, visibleFrame: visibleFrame)
        launchToFrame.origin = origin
        window.setFrameOrigin(origin)
        window.orderFrontRegardless()
    }

    func hide() {
        stopLaunchAnimation()
        window?.orderOut(nil)
    }

    private func configureWindow(_ window: NSWindow) {
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .statusBar
        window.hasShadow = true
        window.hidesOnDeactivate = false
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        window.animationBehavior = .none
    }

    private func stepLaunchAnimation() {
        guard let window else {
            stopLaunchAnimation()
            return
        }

        let elapsed = max(0, CACurrentMediaTime() - launchStartTime)
        if elapsed >= launchAnimationDuration {
            stopLaunchAnimation()
            window.alphaValue = 1
            window.setFrame(launchToFrame, display: true)
            return
        }

        let progress = springProgress(at: elapsed)
        window.alphaValue = initialAlpha + ((1 - initialAlpha) * progress)
        window.setFrame(curvedFrame(from: launchFromFrame, to: launchToFrame, progress: progress), display: true)
    }

    private func stopLaunchAnimation() {
        launchTimer?.invalidate()
        launchTimer = nil
    }

    // Hopper shows the transition builder fed with 0.72 and 1.0; model it as a critically damped spring.
    private func springProgress(at elapsed: TimeInterval) -> CGFloat {
        let omega = (2 * Double.pi) / launchAnimationResponse
        let t = max(0, elapsed)
        let progress: Double

        if abs(launchAnimationDampingFraction - 1) < 0.0001 {
            progress = 1 - exp(-omega * t) * (1 + (omega * t))
        } else {
            progress = min(1, t / launchAnimationDuration)
        }

        return min(max(progress, 0), 1)
    }

    private func curvedFrame(from: NSRect, to: NSRect, progress: CGFloat) -> NSRect {
        let size = NSSize(
            width: from.size.width + ((to.size.width - from.size.width) * progress),
            height: from.size.height + ((to.size.height - from.size.height) * progress)
        )

        let startCenter = CGPoint(x: from.midX, y: from.midY)
        let endCenter = CGPoint(x: to.midX, y: to.midY)
        let midPoint = CGPoint(
            x: (startCenter.x + endCenter.x) * 0.5,
            y: max(startCenter.y, endCenter.y)
        )

        let distance = hypot(endCenter.x - startCenter.x, endCenter.y - startCenter.y)
        let lift = min(140, max(44, distance * 0.18))
        let controlPoint = CGPoint(x: midPoint.x, y: midPoint.y + lift)
        let inverse = 1 - progress
        let center = CGPoint(
            x: (inverse * inverse * startCenter.x) + (2 * inverse * progress * controlPoint.x) + (progress * progress * endCenter.x),
            y: (inverse * inverse * startCenter.y) + (2 * inverse * progress * controlPoint.y) + (progress * progress * endCenter.y)
        )

        return NSRect(
            x: center.x - (size.width * 0.5),
            y: center.y - (size.height * 0.5),
            width: size.width,
            height: size.height
        )
    }

    private func anchoredOrigin(for settingsFrame: CGRect, visibleFrame: CGRect) -> NSPoint {
        let sidebarWidth: CGFloat = 170
        let contentMinX = settingsFrame.minX + sidebarWidth
        let contentWidth = max(settingsFrame.width - sidebarWidth, windowSize.width)
        let preferredX = contentMinX + ((contentWidth - windowSize.width) / 2) - 8
        let preferredY = settingsFrame.minY + 14
        let minX = visibleFrame.minX + 8
        let maxX = visibleFrame.maxX - windowSize.width - 8
        let minY = visibleFrame.minY + 8
        let maxY = visibleFrame.maxY - windowSize.height - 8

        return NSPoint(
            x: min(max(preferredX, minX), maxX),
            y: min(max(preferredY, minY), maxY)
        )
    }
}

private final class PassiveOverlayPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

private final class OverlayContentView: NSView {
    private let onBack: () -> Void

    init(hostApp: PermisoHostApp, panel: PermisoPanel, onBack: @escaping () -> Void) {
        self.onBack = onBack
        super.init(frame: NSRect(x: 0, y: 0, width: 530, height: 109))
        translatesAutoresizingMaskIntoConstraints = false
        setup(hostApp: hostApp, panel: panel)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup(hostApp: PermisoHostApp, panel: PermisoPanel) {
        let materialView = NSVisualEffectView()
        materialView.translatesAutoresizingMaskIntoConstraints = false
        materialView.material = .popover
        materialView.blendingMode = .behindWindow
        materialView.state = .active
        materialView.wantsLayer = true
        materialView.layer?.cornerRadius = 18
        materialView.layer?.masksToBounds = true
        materialView.layer?.borderWidth = 1
        materialView.layer?.borderColor = NSColor.separatorColor.withAlphaComponent(0.35).cgColor
        addSubview(materialView)

        let tintView = NSView()
        tintView.translatesAutoresizingMaskIntoConstraints = false
        tintView.wantsLayer = true
        tintView.layer?.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.78).cgColor
        materialView.addSubview(tintView)

        let backChrome = NSView()
        backChrome.translatesAutoresizingMaskIntoConstraints = false
        backChrome.wantsLayer = true
        backChrome.layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.95).cgColor
        backChrome.layer?.cornerRadius = 16
        materialView.addSubview(backChrome)

        let backButton = NSButton()
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.isBordered = false
        backButton.image = NSImage(systemSymbolName: "chevron.left", accessibilityDescription: "Back")
        backButton.contentTintColor = NSColor.labelColor.withAlphaComponent(0.72)
        backButton.target = self
        backButton.action = #selector(backPressed)
        if let cell = backButton.cell as? NSButtonCell {
            cell.imagePosition = .imageOnly
        }
        backChrome.addSubview(backButton)

        let arrowView = NSImageView()
        arrowView.translatesAutoresizingMaskIntoConstraints = false
        arrowView.image = NSImage(systemSymbolName: "arrow.up", accessibilityDescription: nil)
        arrowView.symbolConfiguration = .init(pointSize: 28, weight: .bold)
        arrowView.contentTintColor = NSColor(calibratedRed: 0.15, green: 0.54, blue: 0.98, alpha: 1)
        materialView.addSubview(arrowView)

        let titleLabel = NSTextField(labelWithAttributedString: title(hostApp: hostApp, panel: panel))
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.maximumNumberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail
        materialView.addSubview(titleLabel)

        let dragSource = AppDragSourceView(hostApp: hostApp)
        materialView.addSubview(dragSource)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 530),
            heightAnchor.constraint(equalToConstant: 109),

            materialView.leadingAnchor.constraint(equalTo: leadingAnchor),
            materialView.trailingAnchor.constraint(equalTo: trailingAnchor),
            materialView.topAnchor.constraint(equalTo: topAnchor),
            materialView.bottomAnchor.constraint(equalTo: bottomAnchor),

            tintView.leadingAnchor.constraint(equalTo: materialView.leadingAnchor),
            tintView.trailingAnchor.constraint(equalTo: materialView.trailingAnchor),
            tintView.topAnchor.constraint(equalTo: materialView.topAnchor),
            tintView.bottomAnchor.constraint(equalTo: materialView.bottomAnchor),

            backChrome.leadingAnchor.constraint(equalTo: materialView.leadingAnchor, constant: 18),
            backChrome.topAnchor.constraint(equalTo: materialView.topAnchor, constant: 52),
            backChrome.widthAnchor.constraint(equalToConstant: 32),
            backChrome.heightAnchor.constraint(equalToConstant: 32),

            backButton.centerXAnchor.constraint(equalTo: backChrome.centerXAnchor),
            backButton.centerYAnchor.constraint(equalTo: backChrome.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 14),
            backButton.heightAnchor.constraint(equalToConstant: 14),

            arrowView.leadingAnchor.constraint(equalTo: materialView.leadingAnchor, constant: 35),
            arrowView.topAnchor.constraint(equalTo: materialView.topAnchor, constant: 10),
            arrowView.widthAnchor.constraint(equalToConstant: 28),
            arrowView.heightAnchor.constraint(equalToConstant: 28),

            titleLabel.leadingAnchor.constraint(equalTo: arrowView.trailingAnchor, constant: 10),
            titleLabel.centerYAnchor.constraint(equalTo: arrowView.centerYAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: materialView.trailingAnchor, constant: -22),

            dragSource.leadingAnchor.constraint(equalTo: materialView.leadingAnchor, constant: 64),
            dragSource.trailingAnchor.constraint(equalTo: materialView.trailingAnchor, constant: -21),
            dragSource.topAnchor.constraint(equalTo: materialView.topAnchor, constant: 47),
            dragSource.heightAnchor.constraint(equalToConstant: 43)
        ])
    }

    private func title(hostApp: PermisoHostApp, panel: PermisoPanel) -> NSAttributedString {
        NSAttributedString(
            string: "Drag \(hostApp.displayName) to the list above to allow \(panel.title)",
            attributes: [
                .font: NSFont.systemFont(ofSize: 14, weight: .medium),
                .foregroundColor: NSColor.labelColor.withAlphaComponent(0.82)
            ]
        )
    }

    @objc
    private func backPressed() {
        onBack()
    }
}
