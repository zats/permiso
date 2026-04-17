# Permiso

![](assets/screen.gif)
Codex releases a brilliant way to guide users around privacy permissions through the Settings app, [see here](https://x.com/trpfsu/status/2044882275100250444)

## API

```swift
import Permiso

@MainActor
func showAccessibilityHelper() {
    PermisoAssistant.shared.present(panel: .accessibility)
}
```
