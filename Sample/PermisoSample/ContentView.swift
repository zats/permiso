import Permiso
import SwiftUI

struct ContentView: View {
    @State private var accessibilityButtonFrame = CGRect.zero
    @State private var screenRecordingButtonFrame = CGRect.zero

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Permiso")
                .font(.system(size: 28, weight: .semibold))

            Text("Open a privacy panel and show a drag helper for this app.")
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Button("Accessibility") {
                    PermisoAssistant.shared.present(
                        panel: .accessibility,
                        sourceFrameInScreen: accessibilityButtonFrame
                    )
                }
                .background(ScreenFrameReader(frameInScreen: $accessibilityButtonFrame))

                Button("Screen Recording") {
                    PermisoAssistant.shared.present(
                        panel: .screenRecording,
                        sourceFrameInScreen: screenRecordingButtonFrame
                    )
                }
                .background(ScreenFrameReader(frameInScreen: $screenRecordingButtonFrame))
            }

            Spacer()
        }
        .padding(24)
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
