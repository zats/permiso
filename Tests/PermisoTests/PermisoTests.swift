import Testing
@testable import Permiso

@Suite("PermisoPanel")
struct PermisoTests {
    @Test("Accessibility deep link")
    func accessibilityURL() {
        #expect(PermisoPanel.accessibility.settingsURL.absoluteString == "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility")
    }

    @Test("Screen Recording deep link")
    func screenRecordingURL() {
        #expect(PermisoPanel.screenRecording.settingsURL.absoluteString == "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_ScreenCapture")
    }
}
