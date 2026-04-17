# Permiso

![](assets/screen.gif)

## API

```swift
import Permiso

@MainActor
func showAccessibilityHelper() {
    PermisoAssistant.shared.present(panel: .accessibility)
}
```
