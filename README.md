# Atlas

A Shazam-style iOS app: one tap from Control Center → silent listening → drop-down notification with the translated transcript → tap to open the session in the app.

Named after the Titan who holds up the heavens.

## Architecture

- **Atlas** (iOS app, SwiftUI) — Pipeline + history UI. Runs the audio session, speech, translation, and Live Activity orchestration. Stays alive in the background via `UIBackgroundModes = audio`.
- **AtlasControls** (Widget extension) — Control Center tile + Live Activity UI (Dynamic Island + Lock Screen) + Stop button.
- **AtlasShared** (Swift package) — shared intents, Live Activity attributes, App Group constants, deep-link parsing.

Activation flow:

```
Control Center tap → StartListeningIntent → app launches briefly → audio session
+ Live Activity bootstrap → app drops to background → mic indicator stays on →
ASR + on-device Translation stream into Live Activity → Stop button (or 5s silence
/ 3 min cap) → save session, end Live Activity, post completion notification → tap
notification → SessionDetailView.
```

## Project layout

```
atlas/
├── project.yml                  XcodeGen spec
├── Atlas/                       Main app
│   ├── AtlasApp.swift
│   ├── Views/                   BootstrapView, History, SessionDetail, Settings
│   ├── Audio/                   AVAudioEngine + session config
│   ├── Speech/                  SFSpeechRecognizer (iOS 18) / SpeechAnalyzer (iOS 26)
│   ├── Translation/             Apple Translation hosted in a hidden UIWindow
│   ├── LiveActivity/            ActivityKit start/update/end
│   ├── Notifications/           Completion banner + delegate routing
│   ├── Storage/                 SwiftData @Model
│   ├── Pipeline/                SessionPipeline + StopCoordinator
│   ├── Resources/Info.plist
│   ├── Assets.xcassets/
│   └── Atlas.entitlements
├── AtlasControls/               Widget extension
│   ├── AtlasControlBundle.swift
│   ├── StartListeningControl.swift
│   ├── AtlasListeningLiveActivity.swift
│   ├── Info.plist
│   └── AtlasControls.entitlements
└── AtlasShared/                 Local Swift package
    └── Sources/AtlasShared/
        ├── AppGroup.swift
        ├── AtlasListeningAttributes.swift
        ├── StartListeningIntent.swift
        ├── StopListeningIntent.swift
        └── DeepLink.swift
```

## Generating the Xcode project

This repo does not check in a `.xcodeproj`. Generate it with [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```sh
brew install xcodegen
xcodegen generate
open Atlas.xcodeproj
```

## Configuring signing

In Xcode, select both the `Atlas` and `AtlasControls` targets and set your team. The bundle identifiers are:

- App: `com.atlas.app`
- Widget extension: `com.atlas.app.controls`
- App Group (must be enabled on both): `group.com.atlas.app`

You will need to add the App Group capability on both targets after the first generate.

## Running

Requires:

- Xcode 16+
- A physical iPhone running iOS 18+ (Simulator does not support Live Activities, Translation, mic capture, or Control Center tiles)
- Apple Developer Program enrolment (to install on a physical device)

Steps:

1. `xcodegen generate`
2. Open `Atlas.xcodeproj`, set team on both targets, enable App Group `group.com.atlas.app` on both.
3. Build & run on device.
4. On the device: Settings → Control Center → add the **Atlas** tile.
5. Open the app once to grant Microphone, Speech Recognition, and Notifications permissions, and pick a target language in Settings.
6. Play some foreign-language speech on the device's speaker, pull down Control Center, tap Atlas.
7. The mic indicator turns on, a Live Activity appears in the Dynamic Island / Lock Screen with a live preview and a Stop button.
8. Tap Stop (or wait for the 5s silence auto-stop). A notification banner drops down with the translated transcript. Tap it to open the session.

## Limitations

- **Sub-second launch flash on activation** — Apple only gives first-party apps the private path that starts the mic without any launch event. Our `BootstrapView` is intentionally minimal but cannot be invisible.
- **Translation framework is SwiftUI-only.** We host an invisible 1×1 SwiftUI view in an off-screen `UIWindow` so `.translationTask` stays alive while the app is backgrounded. This is undocumented but works.
- **Hard cap of 3 minutes per session** to stay well inside ActivityKit + audio-session reasonable limits.
- **`SpeechAnalyzer` (iOS 26) path** currently routes through `SFSpeechRecognizer` until the iOS 26 surface is finalized.
