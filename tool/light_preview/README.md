# Light component preview and checks

This small Flutter package imports the production `light_theme.dart`, `light_conversation_row.dart`, and `light_message_surface.dart` files directly. It needs only Flutter, so it can exercise the visual components without the main app's native messaging, Firebase, Rust, and database dependencies.

The preview is a **component lab with fictional sample data**, not a screenshot of the complete running Android app. Its heading, actions, and composer are fixture scaffolding matched to the implemented inbox (48 dp header; 54 dp SEARCH / NEW / MENU bar) and conversation (56 dp header; back/more actions; attachment and SEND composer). Live app integration, authentication, message sync, and sending require separate Android checks.

From this directory, using Flutter 3.24.0:

```sh
flutter pub get
flutter test
bash render_previews.sh
```

The last command writes real Flutter renders to `previews/`, at logical sizes 360 × 413 (the SDK's Light Phone III preview canvas) and 360 × 800, with a 3× pixel ratio. Each image is visibly labelled as a sample-data component preview. The script runs each capture in a fresh test-engine process to avoid a Flutter 3.24 glyph-atlas capture problem. Set `FLUTTER_BIN` if Flutter is not on your PATH.

Checks cover monochrome colors and text/action contrast, both brightness modes, large accessibility text at 1.6×, short and tall screens, scrolling to the final row/message, row callbacks, unread/pinned/muted/selected semantics, and message contrast/direction/selection. A test also imports the production `LightComposerViewport` to verify that the send action remains reachable on the short display with a 200 dp keyboard, attachments, reply content, and 1.6× text. The Inter and Material Icons fonts used by the main app are loaded for the preview.
