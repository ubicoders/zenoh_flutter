# Multicast scouting on mobile

Zenoh peers and routers find each other with **multicast scouting**: a small scout
message is sent to the multicast group `224.0.0.224` on UDP port `7446`, and every
Zenoh node on the same LAN replies. That is how a peer with no configured address
still joins the mesh.

In peer mode, the app shows this warning under the **Multicast scouting** switch
on Android and iOS:

> Blocked on the Android emulator and on iOS without an entitlement.

This page explains what is blocked, why, and what to do about it.

## What works without any special setup

| Device | Multicast scouting | Unicast connect to a router (`tcp/host:7447`) |
|---|---|---|
| Physical Android phone on Wi-Fi | works | works |
| Android emulator | **blocked** | works via `10.0.2.2` |
| iPhone / iPad, no entitlement | **blocked** | works |
| iPhone / iPad, with entitlement | works | works |
| Linux / macOS / Windows desktop | works | works |

Unicast TCP, UDP and WebSocket connections are never affected. If scouting is
blocked, the app simply needs to be told where the router is.

## Android emulator

The emulator does not put the virtual phone on your LAN. It sits behind a
built-in NAT where the host machine appears as `10.0.2.2`. Unicast traffic is
forwarded through that NAT, but multicast packets are dropped in both
directions, so a scout never leaves the emulator and the router's replies never
arrive.

There is no emulator setting that changes this.

**What to do:** use client mode, whose **Connect to** default on Android is
already `tcp` / `10.0.2.2` / `7447`. Or stay in peer mode, open **Advanced** and
enter `10.0.2.2` as the host under **Connect to (optional)**; `tcp` and port
`7447` are already filled in. The **Multicast scouting** switch can stay on; it
just finds nothing.

A physical Android phone on the same Wi-Fi as the router needs nothing extra.
Multicast works and no permission is required.

## iOS

Since iOS 14 the OS refuses multicast and broadcast sockets unless the app
carries the `com.apple.developer.networking.multicast` entitlement. Without it,
joining the multicast group fails, zenoh logs an error, and scouting finds
nothing. Connecting to a router by unicast still works.

Separately, iOS 14+ asks the user for **Local Network** permission the first
time the app talks to a LAN address. `ios/Runner/Info.plist` already contains
`NSLocalNetworkUsageDescription`, which is what makes that prompt appear. If the
user denies it, connections to LAN addresses fail silently.

**What to do without the entitlement:** same as the emulator. Use client mode,
or peer mode with the router's address under **Advanced** > **Connect to
(optional)**.

### Getting the multicast entitlement

Apple grants this entitlement per app on request. It is not a checkbox you can
simply turn on in Xcode.

1. Sign in with the Apple Developer account that owns the app's bundle ID.
2. Submit the request form at
   <https://developer.apple.com/contact/request/networking-multicast>.
   Describe why the app needs multicast; local discovery of robots or sensors
   on the same network is a typical accepted reason. Approval usually takes a
   few days to a couple of weeks.
3. Once approved, the **Multicast Networking** capability appears for your App
   ID at <https://developer.apple.com/account/resources/identifiers/list>.
   Enable it there.
4. Add the key to the Runner target's entitlements file
   (`ios/Runner/Runner.entitlements`, create it via Xcode's
   *Signing & Capabilities* tab if it does not exist):

   ```xml
   <key>com.apple.developer.networking.multicast</key>
   <true/>
   ```

5. Regenerate the provisioning profile so it includes the capability, then
   rebuild.

The entitlement is checked against the provisioning profile, so debug builds on
your own device need the approval too. There is no way to test multicast on iOS
before Apple grants it.

## Disabling scouting entirely

If a device will always connect to a known router, turn the **Multicast
scouting** switch off (peer and router mode; client mode always has it off).
This stops the periodic scout messages, which is slightly cleaner on networks
where multicast is blocked, and is required on iOS if you want to avoid the
zenoh error log line at startup. The app passes this through to zenoh as
`scouting/multicast/enabled: false`, and always sends `false` in client mode.

## Summary

- Scouting is a convenience for flat LANs. It is not needed to talk to a router.
- Emulator: always connect to `tcp/10.0.2.2:7447`, the client-mode default on
  Android.
- iOS: request the entitlement only if iPhones must discover routers on their
  own. Otherwise give them the router address.
