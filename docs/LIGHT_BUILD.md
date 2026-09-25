# Build and validate OpenBubbles Light

The production app is the original OpenBubbles Flutter/Rust application with an additional Light skin. No sample contacts or sample messages are injected into the production database.

## Android build

Prerequisites match the upstream repository: Flutter 3.24.0 (Dart 3.5), Java 21, Android SDK platform/build tools 36, Rust/Cargo, and the Protobuf compiler. The Gradle build installs its required NDK when Android SDK licenses have been accepted. Allow substantial disk space for native dependencies and Rust build artifacts.

```sh
git clone --recurse-submodules --branch codex/light-phone-ui https://github.com/dav12072018/openbubbles-app.git
cd openbubbles-app
flutter pub get
flutter build apk --flavor light --debug --target-platform android-arm64
```

Upstream's debug workflow prepares development FairPlay certificate fixtures before compiling Rust. See the **Set up fake Fairplay keys** step in [the build workflow](../.github/workflows/build.yml) for the exact public fixtures and filenames; production service credentials are not distributed by this fork.

Output: `build/app/outputs/flutter-apk/app-light-debug.apk`.

```sh
adb install -r build/app/outputs/flutter-apk/app-light-debug.apk
```

This flavor uses package `com.openbubbles.messaging.light`, so it does not overwrite the official app or share its local data. Complete OpenBubbles' existing account/device setup in this installation. Sending and receiving still depend on upstream's Apple account and Mac/device registration requirements.

For a release build, configure your own `android/key.properties` and signing keystore, then use `--release`. The official signing keys are not included. Keep the same private signing key for subsequent updates to your installation.

## Skin and brightness

New Android installations default to **Light**. A saved App Skin preference is retained. To change it, open **MENU → Settings → Appearance Settings → App Skin**. The other skins remain available. **App Theme** controls dark, light, or system brightness, independently of the skin. Existing selected themes and dynamic-color preferences are retained for use when switching back to another skin; Light consistently uses its monochrome palette.

The Light header's overflow menu retains call/email and chat actions. FaceTime actions remain in conversation details. Long-press a conversation to select it; the bottom actions support read/unread, archive, pin, mute, and delete. Recently deleted conversations use the upstream recovery dialog.

## Checks

```sh
flutter analyze --no-pub --no-fatal-infos --no-fatal-warnings lib
cd tool/light_preview
flutter pub get
flutter test
```

The main application contains pre-existing analyzer warnings and deprecated API notices. Full-repository analysis also traverses upstream submodule examples and the stale integration test driver; use `lib` to check production Dart code.

The isolated preview package imports the actual production theme, inbox row, message surface, and compact composer viewport. Its fixture screens deliberately do not initialize native services. See its README for visual render commands, tested sizes, and accessibility coverage. Rendered fixture images are **component previews**, not evidence of a signed-in Android session.

## Device checks before daily use

On a configured Android device, verify account setup, incoming notification/background delivery, text and attachment send/receive, group sender labels, replies, search, archive/recovery, and switching skins/brightness. Check the keyboard, multiline drafts, and attachments on the Light Phone III's short display. Physical Light Phone III/LightOS installation and official SDK tool approval are separate from the visual adaptation.
