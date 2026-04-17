# Permiso

`Permiso` is a macOS 26+ Swift package that opens a privacy pane in System Settings and shows a floating drag helper for the host app.

## API

```swift
import Permiso

@MainActor
func showAccessibilityHelper() {
    PermisoAssistant.shared.present(panel: .accessibility)
}
```

Supported panels:

- `.accessibility`
- `.screenRecording`

## Sample

Open `Sample/PermisoSample.xcodeproj` in Xcode and run the app.
