# OpenBubbles Light

An Android fork of [OpenBubbles](https://github.com/OpenBubbles/openbubbles-app) with a monochrome interface inspired by the [Light Phone III SDK examples](https://github.com/lightphone/light-sdk/tree/main/examples).

- Flat conversation list with large text, unread dots, and SEARCH / NEW / MENU controls.
- Black and white themes, square message surfaces, a quieter conversation header, and a text SEND button.
- Existing OpenBubbles messaging, attachments, replies, search, archives, settings, and account setup remain connected to the original services.
- New Android installs start with the **Light** skin in dark mode. Existing saved skins are preserved. Choose **Settings → Appearance → App Skin → Light** to switch; use App Theme to choose dark, light, or system appearance.
- The `light` Android flavor installs as **OpenBubbles Light** (`com.openbubbles.messaging.light`) alongside the official app, with its own account setup and local data.

This is a Flutter Android app with a Light-inspired interface, not a Light SDK tool or an official Light product. The Kotlin/Compose SDK cannot directly replace OpenBubbles' Flutter UI. Inter is used from OpenBubbles' existing bundled fonts; Light's proprietary Akkurat font is not redistributed. See [design sources](docs/LIGHT_DESIGN.md), [build and validation instructions](docs/LIGHT_BUILD.md), and the [component preview](tool/light_preview/README.md).

## Build

Use Flutter **3.24.0**, Java **21**, Android SDK **36**, Rust, and Protobuf, as in the upstream build environment. Clone recursively, configure the upstream build prerequisites, then:

```sh
flutter pub get
flutter build apk --flavor light --debug --target-platform android-arm64
```

The APK is written to `build/app/outputs/flutter-apk/app-light-debug.apk`. Release builds need your own signing key configured in `android/key.properties`; neither official OpenBubbles signing keys nor Apple service credentials are included. The fork's build workflow produces a downloadable debug APK when its build succeeds.

For UI-only validation without Android, Rust, or an Apple account:

```sh
cd tool/light_preview
flutter pub get
flutter test
```

---

# OpenBubbles

OpenBubbles is an open-source and cross-platform ecosystem of apps aimed to bring Apple platform services to Android and Windows! With OpenBubbles, you'll be able to send messages, media, and much more to your friends and family.

**Please note that OpenBubbles requires access to a Mac and an Apple ID to function!

Key Features:

- Send/receive emoji reactions 
- Send formatted messages (bold, italic, etc)
- Edit messages
- Unsend messages 
- Call your friends on FaceTime
- Answer calls from your friends on FaceTime
- See friends' locations on FindMy
- Join and Sync iCloud Shared Albums
- See typing indicators
- Receive stickers
- Create and manage group chats
- Add an icon to personalize your group chat 
- Send images and videos
- Forward SMS and MMS to/from connected Macs or other devices with OpenBubbles 

If you need help setting up the app, have any issues or feature requests, or just want to come hang out, feel free to join our Discord, linked below! We hope you enjoy using the app!

## Useful links

* Our Website: [here](https://openbubbles.app)
* Discord: [here](https://discord.gg/98fWS4AQqN)!
    - We highly encourage users to join to get in direct communication with the developers and community
* GitHub: [here](https://github.com/OpenBubbles)
    - Please submit any issues with the app here so we can properly track them! Remember to search before opening a ticket :)

## Getting Started

[Quickstart](https://openbubbles.app/quickstart.html)
