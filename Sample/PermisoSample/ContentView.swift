import Permiso
import SwiftUI

struct ContentView: View {
    @State private var accessibilityButtonFrame = CGRect.zero
    @State private var screenRecordingButtonFrame = CGRect.zero

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Permiso Sample")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)

                Text("Open System Settings and launch the drag helper from the control you want to test.")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: 520, alignment: .leading)
            }

            HStack(spacing: 12) {
                Button {
                    PermisoAssistant.shared.present(
                        panel: .accessibility,
                        sourceFrameInScreen: accessibilityButtonFrame
                    )
                } label: {
                    Label("Accessibility", systemImage: "figure.wave")
                }
                .buttonStyle(.glassProminent)
                .controlSize(.large)
                .background(ScreenFrameReader(frameInScreen: $accessibilityButtonFrame))

                Button {
                    PermisoAssistant.shared.present(
                        panel: .screenRecording,
                        sourceFrameInScreen: screenRecordingButtonFrame
                    )
                } label: {
                    Label("Screen Recording", systemImage: "record.circle")
                }
                .buttonStyle(.glass)
                .controlSize(.large)
                .background(ScreenFrameReader(frameInScreen: $screenRecordingButtonFrame))
            }

            Spacer()
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
