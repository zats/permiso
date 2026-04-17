import AppKit
import Foundation

final class AppDragSourceView: NSView, NSPasteboardItemDataProvider, NSDraggingSource {
    private let hostApp: PermisoHostApp
    private let rowView = NSView()
    private let iconChrome = NSView()
    private let label = NSTextField(labelWithString: "")

    init(hostApp: PermisoHostApp) {
        self.hostApp = hostApp
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setup()
        updateAppearance()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func mouseDown(with event: NSEvent) {
        let pasteboardItem = NSPasteboardItem()
        pasteboardItem.setDataProvider(self, forTypes: [.fileURL])

        let draggingItem = NSDraggingItem(pasteboardWriter: pasteboardItem)
        draggingItem.setDraggingFrame(draggingFrame(), contents: draggingImage())

        let session = beginDraggingSession(with: [draggingItem], event: event, source: self)
        session.animatesToStartingPositionsOnCancelOrFail = true
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateAppearance()
    }

    func pasteboard(_ pasteboard: NSPasteboard?, item: NSPasteboardItem, provideDataForType type: NSPasteboard.PasteboardType) {
        guard type == .fileURL else { return }
        item.setData(hostApp.bundleURL.dataRepresentation, forType: .fileURL)
    }

    func draggingSession(_ session: NSDraggingSession, willBeginAt screenPoint: NSPoint) {
        rowView.isHidden = true
    }

    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        .copy
    }

    func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        rowView.isHidden = false
    }

    private func setup() {
        wantsLayer = true

        rowView.wantsLayer = true
        rowView.layer?.cornerRadius = 7
        rowView.layer?.borderWidth = 1
        rowView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rowView)

        iconChrome.wantsLayer = true
        iconChrome.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.9).cgColor
        iconChrome.layer?.cornerRadius = 6
        iconChrome.translatesAutoresizingMaskIntoConstraints = false
        rowView.addSubview(iconChrome)

        let iconView = NSImageView(image: hostApp.icon)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconChrome.addSubview(iconView)

        label.stringValue = hostApp.displayName
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = NSColor.labelColor.withAlphaComponent(0.82)
        label.translatesAutoresizingMaskIntoConstraints = false
        rowView.addSubview(label)

        NSLayoutConstraint.activate([
            rowView.leadingAnchor.constraint(equalTo: leadingAnchor),
            rowView.trailingAnchor.constraint(equalTo: trailingAnchor),
            rowView.topAnchor.constraint(equalTo: topAnchor),
            rowView.bottomAnchor.constraint(equalTo: bottomAnchor),
            rowView.heightAnchor.constraint(equalToConstant: 43),

            iconChrome.leadingAnchor.constraint(equalTo: rowView.leadingAnchor, constant: 10),
            iconChrome.centerYAnchor.constraint(equalTo: rowView.centerYAnchor),
            iconChrome.widthAnchor.constraint(equalToConstant: 26),
            iconChrome.heightAnchor.constraint(equalToConstant: 26),

            iconView.centerXAnchor.constraint(equalTo: iconChrome.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconChrome.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 22),
            iconView.heightAnchor.constraint(equalToConstant: 22),

            label.leadingAnchor.constraint(equalTo: iconChrome.trailingAnchor, constant: 11),
            label.trailingAnchor.constraint(lessThanOrEqualTo: rowView.trailingAnchor, constant: -12),
            label.centerYAnchor.constraint(equalTo: rowView.centerYAnchor)
        ])
    }

    private func updateAppearance() {
        let isDark = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        if isDark {
            rowView.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.06).cgColor
            rowView.layer?.borderColor = NSColor.white.withAlphaComponent(0.08).cgColor
        } else {
            rowView.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.65).cgColor
            rowView.layer?.borderColor = NSColor(
                red: 0.87451,
                green: 0.866667,
                blue: 0.862745,
                alpha: 1
            ).cgColor
        }
    }

    private func draggingFrame() -> NSRect {
        convert(rowView.bounds, from: rowView)
    }

    private func draggingImage() -> NSImage {
        let image = NSImage(size: rowView.bounds.size)
        image.lockFocus()
        rowView.displayIgnoringOpacity(rowView.bounds, in: NSGraphicsContext.current!)
        image.unlockFocus()
        return image
    }
}
