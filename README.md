# zenoh_flutter

A Flutter app for watching live Zenoh data on a phone. It opens a Zenoh session as a peer, client or router, and lists every key expression it receives on a discovery scope. For one key at a time, it shows the newest sample as formatted JSON, text, an image or a hex dump. It talks to Zenoh through the local FFI package [`packages/zenoh_dart`](packages/zenoh_dart/README.md), and it bundles `zenoh-c` built for Android and iOS.

## Screens

- **Session** (`/settings`, the start screen): pick the mode, its endpoints and the discovery scope, then open the session. A status line and a session log show what happened. When you press the button, the settings are saved on the device (`shared_preferences`, key `session_settings_v1`). The app always starts on the **peer** tab, which opens a session even when no router is found; the saved fields of every mode are restored when you switch to it.
- **Topics** (`/topics`): every key expression seen on the discovery scope (default `**`), with its payload type, last size and publish rate. A row dims after 10 s without data and disappears after 60 s. You can also subscribe to any key expression by hand.
- **Viewer** (`/view`, with the key expression passed as the route argument): one card updated in place, the PUB HZ, DRAW HZ and LAST meters, a pause button, and long-press to copy the payload. Protobuf and FlatBuffers samples with a known schema are decoded and shown as JSON, and an image inside a protobuf message is drawn.

[docs/APP_GUIDE.md](docs/APP_GUIDE.md) explains every control and has a troubleshooting list.

## Zenoh modes

| Mode | What the app configures | Use it when |
|---|---|---|
| **peer** (default) | Multicast scouting on. Under **Advanced**: an optional address to connect to, plus tcp and udp listeners on any free port and a ws listener on 8000 | Devices on one LAN should find each other |
| **client** | One address to connect to. No listeners, scouting off | You know the router's address |
| **router** | tcp 7447 and udp 7447 listeners (ws 8000 optional), scouting off by default, optional other routers to connect to | The phone itself should be the hub |

Multicast scouting does not work on the Android emulator, or on iOS without the multicast entitlement. On those devices, give the app an explicit address: use client mode, or peer mode with **Advanced** > **Connect to (optional)**. The emulator reaches the host computer at `10.0.2.2`. On Android, client mode starts with `tcp/10.0.2.2:7447`; on other platforms it starts with `127.0.0.1`. See [docs/MULTICAST.md](docs/MULTICAST.md).

## Native Zenoh libraries

The app bundles prebuilt `zenoh-c` binaries. Each version is built into `packages/zenoh_dart/native/<platform>/<version>/` with the build script for its platform:

```bash
bash .claude/skills/zenoh-build-android/build_zenoh_android.sh <version>      # Linux or macOS: Rust, cargo-ndk and the Android NDK
bash .claude/skills/zenoh-build-ios/build_zenoh_ios.sh <version>          # macOS with Xcode only
```

Then one version is activated for the app with the `zenoh-activate-libs` skill script:

```bash
bash .claude/skills/zenoh-activate-libs/copy_zenoh_libs.sh <version>          # Android (default)
bash .claude/skills/zenoh-activate-libs/copy_zenoh_libs.sh <version> ios      # iOS
bash .claude/skills/zenoh-activate-libs/copy_zenoh_libs.sh <version> all      # both
```

Platform-specific build instructions:

- [docs/BUILD_ANDROID.md](docs/BUILD_ANDROID.md) – build `libzenohc.so` with `bash .claude/skills/zenoh-build-android/build_zenoh_android.sh <version>`, or by hand with `cargo ndk` (Linux or macOS), and copy it into `android/app/src/main/jniLibs/`.
- [docs/BUILD_IOS.md](docs/BUILD_IOS.md) – build `zenohc.xcframework` with `bash .claude/skills/zenoh-build-ios/build_zenoh_ios.sh <version>` (macOS + Xcode only) and vendor it through `packages/zenoh_dart/ios/zenoh_dart.podspec`.
- [docs/MULTICAST.md](docs/MULTICAST.md) – why multicast scouting is blocked on the Android emulator and on iOS, how to get the iOS multicast entitlement, and what to do instead.

## Running

```bash
flutter pub get
flutter run -d <device>
```

### Android emulator

```bash
flutter emulators                                   # list available emulators
flutter emulators --launch Medium_Phone_API_36.1    # start it (boots in ~10 s)
flutter devices                                     # wait until "emulator-5554" shows up
flutter run -d emulator-5554                        # build and run the app on it
```

Inside the emulator, `10.0.2.2` is the host machine. The app starts in peer mode, and scouting finds nothing in the emulator. Switch to **client**: its default `tcp/10.0.2.2:7447` reaches a router running on the same computer. Or stay in peer mode and enter `10.0.2.2` under **Advanced** > **Connect to (optional)**.

### Router

Unless the phone runs in router mode itself, a Zenoh router must be reachable from the device. The router runs standalone, outside this repo (for example in a container from the `eclipse/zenoh` image), and listens on `tcp/7447`, `udp/7447` and `ws/8000`. On a physical phone, enter the LAN address of the router's computer.

### Test data

With the router up, publish sample topics so every card type in the app has data:

```bash
pip install eclipse-zenoh protobuf flatbuffers pillow   # once
python3 tools/test_publisher.py                         # test/imu, test/cam, test/raw (protobuf), test/temperature (FlatBuffers), test/topic (text)
```

The script connects to `tcp/localhost:7447`, so run it on the router's machine. It publishes `test/imu` at 50 Hz as a protobuf `zenoh_demo.Imu`, `test/temperature` at 50 Hz as the same IMU sample in a FlatBuffers `zenoh_demo.Imu`, `test/topic` at 2 Hz as the text `hello world <unix seconds>`, `test/cam` at 30 Hz as a `zenoh_demo.Image` holding a 320x240 JPEG (only when Pillow is installed), and `test/raw` at 5 Hz as a `zenoh_demo.Raw` holding 256 bytes. Each protobuf topic sets the zenoh encoding `application/protobuf;zenoh_demo.<Message>`. zenoh has no built-in FlatBuffers encoding, so `test/temperature` sets `application/flatbuffers;zenoh_demo.Imu`. The viewer picks the decoder from that schema name.

The protobuf messages are defined in `tools/proto/demo.proto` and the FlatBuffers table in `tools/fbs/demo.fbs`. `bash tools/gen_messages.sh` generates `tools/demo_pb2.py` and `tools/demo_generated.py` for the script, and the Dart bindings in `lib/proto/` and `lib/fbs/` for the app. All outputs are committed, so run it only after changing a `.proto` or `.fbs` file. Only `test/topic` is plain text.

## Project layout

- `lib/main.dart` – app entry point, routes and theme.
- `lib/fbs/` – generated Dart FlatBuffers bindings for `tools/fbs/demo.fbs`. Do not edit them; run `bash tools/gen_messages.sh` instead.
- `lib/pages/` – the Session, Topics and Viewer screens.
- `lib/proto/` – generated Dart protobuf bindings for `tools/proto/demo.proto`. Do not edit them; run `bash tools/gen_messages.sh` instead.
- `lib/session/` – session settings (load, save, validation, conversion to `ZenohConfig`), the app-wide session controller and its log.
- `lib/topics/` – topic discovery, payload type detection, the 1 s rate counter and display formatting.
- `lib/widgets/` – connection strip, endpoint and listen-row editors, payload card, rate meter, session log sheet.
- `packages/zenoh_dart/` – the FFI package: Dart API, generated bindings, versioned native binaries and the iOS podspec. See [its README](packages/zenoh_dart/README.md).
- `docs/` – app guide, Android and iOS build guides, multicast notes.
- `tools/` – `test_publisher.py`, the message definitions in `proto/demo.proto` and `fbs/demo.fbs`, `gen_messages.sh`, and the generated `demo_pb2.py` and `demo_generated.py`.
- `.claude/skills/` – Claude Code skills `zenoh-build-android`, `zenoh-build-ios` and `zenoh-activate-libs`, each holding its script. Claude Code picks them up automatically in this repo; run the scripts directly with `bash .claude/skills/<skill>/<script> <version>`.
