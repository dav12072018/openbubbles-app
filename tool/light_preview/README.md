# Light component preview and checks

## Interactive local demo

`demo_main.dart` runs a separate, interactive demo with in-memory sample conversations. Open a thread, type a message and press SEND, search, create a conversation, or use MENU to switch appearance and reset the sample data. Messages stay in this demo and are discarded on reload. It does not initialize accounts, network clients, or messaging services.

NEW starts with a recipient picker. Type a name, phone number, or email to filter the fictional sample contacts; select a suggestion or add a complete phone number/email with + or Enter. Keep adding recipients for a group, remove any with ×, then press NEXT to write a message. NEXT also includes a complete address still in the field. The Android app uses OpenBubbles’ existing picker and the device’s actual contacts.

Open **Image preview** to inspect received and sent sample images. Tap an image for a full-screen view with pinch/pan, zoom buttons, and reset. The original 640 × 400 color-and-geometry test image makes changes in color or aspect ratio easy to spot. In any conversation, **+** opens your device's file picker; choose images, review/remove the draft thumbnails, then SEND, with or without text. Up to 10 images can be selected at once, at 20 MiB each. Browser-decodable JPEG, PNG, WebP and GIF files work; unsupported formats show an error. Your files stay in browser memory and are never uploaded; the sample conversation is cleared on reload/reset. This exercises the local demo, not authenticated Android message delivery.

When the draft is empty, the microphone starts a **local browser voice recording**. Browser microphone permission is requested only when you press it. STOP opens review controls to PLAY, CANCEL, or SEND into the local sample conversation; sent voice notes can be played again. During playback, STOP ends playback; PLAY starts again from the beginning. Recordings stay in memory, are never uploaded, and disappear on reset or reload. Use localhost or HTTPS for browser microphone access. The demo uses the production plain-text message surface and small sender captions; incoming messages align left and sent messages align right.

On desktop the demo uses a 360 × 413 phone viewport; on smaller screens it fills the available window. The original screenshot fixtures and component checks remain separate.

In a desktop browser, tapping the message field opens a clickable **preview keyboard** underneath the composer. You can also type with your computer keyboard. Shift, numbers/symbols, space, return and backspace edit the draft; HIDE or Escape dismisses the keyboard without clearing the message. This is a simulator control, not an Android keyboard replacement. Android and mobile browsers use the device's default keyboard; the desktop preview is suppressed when a system keyboard inset is present.

```sh
flutter pub get
flutter build web --web-renderer html --pwa-strategy=none --target demo_main.dart
python3 -m http.server 8765 --bind 127.0.0.1 --directory build/web
```

Open `http://127.0.0.1:8765`. The HTML renderer avoids CanvasKit CDN downloads. Offline caching is disabled, and startup unregisters an older Flutter worker only when its scope and script match this demo; an already controlled tab reloads once to use the fresh assets. Other workers and browser caches are untouched. `assets/fonts/Inter.ttf` is a symlink to the existing repository font, not a second font copy. For live development, use `flutter run -d web-server --web-port 8765 --web-renderer html --target demo_main.dart`.

## Component checks and static previews

This small Flutter package imports the production `light_theme.dart`, `light_conversation_row.dart`, and `light_message_surface.dart` files directly. It needs only Flutter, so it can exercise the visual components without the main app's native messaging, Firebase, Rust, and database dependencies.

The preview is a **component lab with fictional sample data**, not a screenshot of the complete running Android app. Its heading, actions, and composer are fixture scaffolding matched to the implemented inbox (48 dp header; 54 dp SEARCH / NEW / MENU bar) and conversation (56 dp header; back/more actions; attachment and SEND composer). Live app integration, authentication, message sync, and sending require separate Android checks.

From this directory, using Flutter 3.24.0:

```sh
flutter pub get
flutter test
node test/web_startup_test.mjs
bash render_previews.sh
```

The last command writes real Flutter renders to `previews/`, at logical sizes 360 × 413 (the SDK's Light Phone III preview canvas) and 360 × 800, with a 3× pixel ratio. Each image is visibly labelled as a sample-data component preview. The script runs each capture in a fresh test-engine process to avoid a Flutter 3.24 glyph-atlas capture problem. Set `FLUTTER_BIN` if Flutter is not on your PATH.

Checks cover monochrome colors and text/action contrast, both brightness modes, large accessibility text at 1.6×, short and tall screens, scrolling to the final row/message, row callbacks, unread/pinned/muted/selected semantics, and message contrast/direction/selection. Tests import the production `LightComposerViewport` and mirror its non-flex constrained integration to verify that the send action remains reachable on the short display with a 200 dp keyboard, attachments, reply content, and 1.6× text. A tall-screen regression ensures a short composer leaves all remaining height to the transcript. The preview loads Inter directly from the app's existing font file and Material Icons from Flutter's bundle.

Demo interaction checks inject a fake microphone adapter and cover record/stop/cancel/review/play/send, permission failure and late permission cancellation, and group sender alignment. Automated checks never activate a real microphone. The web implementation uses browser `getUserMedia`, `MediaRecorder`, and local blob playback without additional packages.

Recipient checks cover name/email/phone autocomplete, multiple selections, removal, duplicate prevention, manual addresses, pending-address inclusion, validation, cancellation, and reaching NEXT above the keyboard at 360 × 413 with 1.6× text.

Image checks use an injected file picker and real PNG bytes to cover preview/removal, image-only and mixed-text sends, received/sent alignment, fullscreen zoom, decoding errors, and compact keyboard layouts without opening personal files.

Desktop keyboard checks cover mouse focus, sending above the keyboard, hiding/reopening without losing a draft, system-keyboard suppression, compact layouts, text selection replacement, Unicode backspace, case and symbol keys.
