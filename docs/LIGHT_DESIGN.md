# Light Phone III visual reference

This fork adapts the visual language of the public [Light SDK](https://github.com/lightphone/light-sdk) to OpenBubbles' existing Flutter application. It is an independent Android app, not an official Light tool or a port to the Light SDK runtime.

Reference revision: `lightphone/light-sdk@57bbbd0d696693a7bf80c41d9fcd42301d802f39`.

## Source design system

The SDK implements a deliberately small, monochrome design system:

| Token | SDK value |
| --- | --- |
| Dark background / content / secondary | `#000000` / `#FFFFFF` / `#BBBBBB` |
| Light background / content / secondary | `#FFFFFF` / `#000000` / `#666666` |
| Layout grid | 27 columns, 31 rows |
| Horizontal grid unit | Screen width / 27 |
| Top bar | 3 grid units tall, 1 unit horizontal inset |
| Top bar title | Centered, maximum 18 units wide, Fine typography |
| Bottom action bar | 4 grid units tall, 2 units horizontal inset with multiple actions |
| Actions | Up to 3 items when any item is text; up to 5 icons |
| Icon size | 2 grid units |
| Example list row padding | 0.75 grid units vertically |
| Scrollbar | 1 dp rail, 5 dp rectangular thumb, 2-unit gutter |

Typography tokens are expressed against a 600 dp screen-height baseline. `LightText` multiplies font size, line height, and letter spacing by `screenHeightDp / 600`. The SDK previews use a 360 × 413 dp canvas (the phone has a 1080 × 1240 physical-pixel display).

| Role | Baseline font size | Weight | Line-height multiplier | Letter spacing |
| --- | --- | --- | --- | --- |
| Title | 115 | 300 | 1.10 | default |
| Subtitle | 52 | 400 | 1.20 | default |
| Heading | 38 | 400 | 1.35 | default |
| Copy | 30 | 400 | 1.50 | default |
| Button | 30 | 500 | 1.10 | 0.15 em |
| Paragraph | 24.5 | 400 | 1.25 | default |
| Fine / top bar | 25 | 400 | 1.15 | 0.03 em |
| Detail | 20 | 400 | 1.45 | default |
| Superfine | 16 | 400 | 1.20 | default |

On the reference preview, Copy is approximately 20.7 sp, Fine 17.2 sp, and Detail 13.8 sp. A Flutter adaptation should preserve these readable proportions while allowing Android accessibility text scaling and adapting to taller devices; blindly using the unscaled baseline values would make the text much too large.

## Patterns to carry into messaging

- Pure black or white canvas, flat surfaces, clear spacing, and single-color icons.
- Centered compact screen labels and a small number of explicit actions.
- Flat text-led lists: names, preview text, and small secondary details. The examples do not surround each row with a rounded card.
- Uppercase action labels with generous tracking; ordinary sentence case for content.
- Bottom action areas with large targets, no colored floating action buttons.
- Underlined fields instead of filled, pill-shaped inputs.
- No Material ripple in the SDK's `lightClickable`; haptic feedback follows the device preference.
- Full-screen centered messages for simple modal feedback, with a close action at the bottom.

These are visual references, not a reason to remove OpenBubbles functionality. Conversation selection, search, compose, unread indicators, message sending, attachments, accessibility, and system back navigation must remain functional. Sender/recipient distinctions should remain understandable without relying on color.

The transcript uses plain text without borders or outgoing fills. Incoming messages align left; sent messages align right. One-to-one conversations have no sender captions. Group messages show a smaller sender caption above every message, with “You” above outgoing messages. The empty composer exposes a microphone, switching to SEND for a text or attachment draft. Voice notes have explicit stop/cancel controls and a playback review before sending.

## Fonts, assets, and platform boundary

The SDK first looks for Akkurat in the phone's system fonts, then optionally checks bundled font resources, and otherwise uses Android's default family. **The repository does not include an Akkurat font license or font files.** Do not redistribute Akkurat without a separate license. This fork uses OpenBubbles' existing bundled Inter font as its sans-serif substitute.

The SDK repository is MIT licensed, copyright © 2026 The Light Phone. If SDK source or icon paths are copied or substantially adapted, retain the MIT copyright and permission notice with those assets. The Light brand/logo is unnecessary for this independent app. The SDK's generic icons live in `sdk/ui/src/main/res/drawable`; they are Android vector resources and would need conversion before direct Flutter use.

The SDK's screens, navigation, keyboard, and service APIs are Kotlin/Jetpack Compose components. Its build plugin also restricts Android APIs and third-party dependencies. They are not drop-in Flutter widgets, and adopting the SDK runtime would require a separate native rewrite and review of the messaging/networking stack. This fork therefore ports the visual concepts while preserving OpenBubbles' Flutter application and Android integrations. LightOS compatibility and installation must be tested independently; visual similarity does not establish official tool support.

## Primary references

- [Theme and typography](https://github.com/lightphone/light-sdk/blob/57bbbd0d696693a7bf80c41d9fcd42301d802f39/sdk/ui/src/main/kotlin/com/thelightphone/sdk/ui/LightTheme.kt)
- [Grid and text scaling](https://github.com/lightphone/light-sdk/blob/57bbbd0d696693a7bf80c41d9fcd42301d802f39/sdk/ui/src/main/kotlin/com/thelightphone/sdk/ui/LightGrid.kt)
- [Font selection](https://github.com/lightphone/light-sdk/blob/57bbbd0d696693a7bf80c41d9fcd42301d802f39/sdk/ui/src/main/kotlin/com/thelightphone/sdk/ui/LightFont.kt)
- [Top bar](https://github.com/lightphone/light-sdk/blob/57bbbd0d696693a7bf80c41d9fcd42301d802f39/sdk/ui/src/main/kotlin/com/thelightphone/sdk/ui/LightTopBar.kt)
- [Bottom bar](https://github.com/lightphone/light-sdk/blob/57bbbd0d696693a7bf80c41d9fcd42301d802f39/sdk/ui/src/main/kotlin/com/thelightphone/sdk/ui/LightBottomBar.kt)
- [UI demo](https://github.com/lightphone/light-sdk/tree/57bbbd0d696693a7bf80c41d9fcd42301d802f39/examples/ui-demo)
- [Authenticator example](https://github.com/lightphone/light-sdk/tree/57bbbd0d696693a7bf80c41d9fcd42301d802f39/examples/authenticator)
- [SDK overview and constraints](https://github.com/lightphone/light-sdk/blob/57bbbd0d696693a7bf80c41d9fcd42301d802f39/README.md)
- [SDK license](https://github.com/lightphone/light-sdk/blob/57bbbd0d696693a7bf80c41d9fcd42301d802f39/LICENSE)
