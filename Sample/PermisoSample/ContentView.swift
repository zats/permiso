import Permiso
import SwiftUI

struct ContentView: View {
    @State private var accessibilityButtonFrame = CGRect.zero
    @State private var screenRecordingButtonFrame = CGRect.zero

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(nsColor: .windowBackgroundColor),
                    Color(nsColor: .underPageBackgroundColor)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Permiso Sample")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)

                    Text("Test macOS permission flows")
                        .font(.system(size: 32, weight: .semibold))
                        .tracking(-0.6)

                    Text("Open System Settings and launch the drag helper from the action you want to test.")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: 480, alignment: .leading)
                }

                HStack(spacing: 16) {
                    PermissionButton(
                        title: "Accessibility",
                        subtitle: "Control your Mac",
                        systemImage: "figure.wave",
                        frameInScreen: $accessibilityButtonFrame
                    ) {
                        PermisoAssistant.shared.present(
                            panel: .accessibility,
                            sourceFrameInScreen: accessibilityButtonFrame
                        )
                    }

                    PermissionButton(
                        title: "Screen Recording",
                        subtitle: "Capture the display",
                        systemImage: "record.circle",
                        frameInScreen: $screenRecordingButtonFrame
                    ) {
                        PermisoAssistant.shared.present(
                            panel: .screenRecording,
                            sourceFrameInScreen: screenRecordingButtonFrame
                        )
                    }
                }
            }
            .padding(32)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

private struct PermissionButton: View {
    let title: String
    let subtitle: String
    let systemImage: String
    @Binding var frameInScreen: CGRect
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 18) {
                Image(systemName: systemImage)
                    .font(.system(size: 22, weight: .medium))
                    .symbolRenderingMode(.hierarchical)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))

                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 126, alignment: .leading)
            .padding(22)
            .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
        .buttonStyle(.glassProminent)
        .controlSize(.large)
        .background(ScreenFrameReader(frameInScreen: $frameInScreen))
    }
}

private struct ScreenFrameReader: NSViewRepresentable {
    @Binding var frameInScreen: CGRect

    func makeNSView(context: Context) -> ScreenFrameTrackingView {
        let view = ScreenFrameTrackingView()
        view.onFrameChange = { frame in
            frameInScreen = frame
        }
        return view
    }

    func updateNSView(_ nsView: ScreenFrameTrackingView, context: Context) {
        nsView.onFrameChange = { frame in
            frameInScreen = frame
        }
        nsView.reportFrame()
    }
}

private final class ScreenFrameTrackingView: NSView {
    var onFrameChange: ((CGRect) -> Void)?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        reportFrame()
    }

    override func layout() {
        super.layout()
        reportFrame()
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        reportFrame()
    }

    func reportFrame() {
        guard let window else { return }
        let frame = window.convertToScreen(convert(bounds, to: nil))
        DispatchQueue.main.async { [onFrameChange] in
            onFrameChange?(frame)
        }
    }
}
