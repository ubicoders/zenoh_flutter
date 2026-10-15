# App guide

The app has three screens. **Session** is where it starts. When a session opens, the app moves on to **Topics**. Tap a topic there to open it in the **Viewer**.

The app does not connect by itself when it starts. It loads the last saved settings, always shows the **peer** tab first (peer mode opens even when no router is found), and waits for you to press the button. Switching to **client** or **router** brings back the fields you last used there.

## Session

The first control picks the mode: **peer**, **client** or **router**. The line under it says what the mode does. Each mode keeps its own fields, so you can switch modes and back without losing what you typed.

| Mode | Use it when |
|---|---|
| **peer** (default) | Devices on the same LAN should find each other by multicast, or you want to join a mesh through a known router. |
| **client** | You know the router's address. This device connects to it and listens on nothing. |
| **router** | This phone should be the hub that other devices connect to. |

### Address fields

Every address in the form has three parts:

- **Protocol**: `tcp`, `udp` or `ws`. Changing it resets the port to 7447 for tcp and udp, and to 8000 for ws.
- **Host**: an IP address or host name.
- **Port**: 1–65535.

### client

- **Connect to**: the router (or peer) to connect to. Required. On Android the default is `tcp` / `10.0.2.2` / `7447`, which is the host computer as seen from the emulator. On other platforms the default host is `127.0.0.1`.
- Client mode always turns multicast scouting off.

### peer

- **Multicast scouting** (on by default): finds other zenoh nodes on the LAN. On Android and iOS a warning under the switch says it is blocked on the Android emulator, and on iOS without an entitlement. See [MULTICAST.md](MULTICAST.md).
- **Advanced** starts collapsed unless a router address is already filled in. It contains:
  - **Connect to (optional)**: one router or peer to connect to directly. Leave **Host** empty to rely on scouting alone.
  - **Listen on (optional, any combination)**: `tcp`, `udp` and `ws` rows. When a row's switch is on, it listens on `0.0.0.0` (all interfaces) at that port. Port `0` means "any free port" and the field shows `any`. Defaults: tcp 0, udp 0 and ws 8000, all on.

### router

- **Listen on (any combination)**: `tcp`, `udp` and `ws` rows. Defaults: tcp 7447 on, udp 7447 on, ws 8000 off. At least one row must be on (otherwise the form shows "Enable at least one listener."), and port 0 is not allowed here.
- **Reachable on Wi-Fi at**: the addresses other devices can use to reach this one. The app builds them from the device's first non-loopback IPv4 address and the rows that are on. It shows `no network` when the device has no such address. You can select the text to copy it.
- **Multicast scouting** (Announce on LAN): off by default.
- **Connect to other routers (optional)**: fill in protocol, host and port, then press **+** to add the router to the list. The bin icon removes an entry.

### All modes

- **Discovery scope** (default `**`): the key expression that the Topics screen subscribes to. `**` matches every key. Required.
- **Port rule**: an enabled `ws` row cannot use the same port as an enabled `tcp` row, because WebSocket runs over TCP. When they clash, the ws row shows `same port as tcp`. tcp and udp may share a port.

### Opening the session

- The button reads **Connect** (client), **Open session** (peer) or **Start router** (router). It is disabled while a field shows an error, and while a connection attempt is running.
- Pressing it saves the settings on the device and opens the session. If a session is already open, the app closes it first. To apply changes to an open session, press the button again.
- The status line under the button shows `disconnected`, `connecting…`, a summary of the open session (for example `client · tcp/10.0.2.2:7447` or `peer · scouting · ws:8000`), or the error message.
- Once the session is open, the app goes to Topics. When you come back here, **Disconnect** closes the session and **Topics** returns to the list.
- The receipt icon in the top bar opens the **Session log**. It lists system events, newest first: sessions opening and closing (including the exact zenoh config that was sent), discovery starting or failing, and viewers subscribing. Received data is not logged. **Clear** empties the log.

## Topics

- The strip under the title shows the session state and summary. Tap it to go back to Session.
- The header reads `Listening on <scope> · N topics · N s`, where the last number is the time since discovery started. If discovery stops, the header reads `Discovery stopped` and a **Restart** button appears.
- Each row is one key expression that has sent at least one sample since discovery started. Rows are sorted by key. Each row shows:
  - the key expression;
  - the rate in Hz: the samples received for that key during the last second;
  - the type chip (see below) and the size of the last sample.
- A row that gets no sample for 10 s is dimmed and shows `— Hz`. After 60 s without samples, the row is removed.
- The list is cleared when the session closes or the discovery scope changes.
- **Subscribe to a key expression…** at the bottom opens the Viewer for any key expression you type, including ones that are not in the list and ones with wildcards such as `demo/**`.

### Type chip

The chip says how the app will draw the payload: `json`, `text`, `image/jpeg`, `image/png`, `protobuf`, `flatbuffers` or `binary`. It shows `…` until the first sample arrives.

- If the publisher set a zenoh encoding of `image/jpeg`, `image/png`, `application/json` or `text/plain`, the app uses it. It uses JSON and text only when the bytes really are valid JSON or UTF-8.
- A zenoh encoding of `application/protobuf` gives `protobuf`. The schema after the semicolon names the message, for example `application/protobuf;zenoh_demo.Imu`. Protobuf bytes do not say what they are, so without this encoding they are treated like any other bytes and usually show as `binary`.
- A zenoh encoding of `application/flatbuffers` gives `flatbuffers`. zenoh has no built-in FlatBuffers encoding, so the publisher writes this string itself, with the root table after the semicolon, for example `application/flatbuffers;zenoh_demo.Imu`. FlatBuffers bytes do not say what they are either, so without this encoding they usually show as `binary`.
- Otherwise the app looks at the bytes. A JPEG or PNG signature means an image. Valid UTF-8 that parses as JSON is `json`. Other UTF-8 text is `text`. Anything else is `binary`. An empty payload counts as text.
- The type is detected once, from the first non-empty sample. If a publisher changes format, close the viewer and open it again. The Topics list keeps the old type until the row expires.

## Viewer

The Viewer subscribes to one key expression with its own subscription. The top bar shows the key expression, the type chip and the pause button.

### Meters

- **PUB HZ**: how many samples arrived during the last second. This is the rate at which the publisher's samples reach this device.
- **DRAW HZ**: how many times per second the card showed a new sample. The screen is updated at most every 33 ms with the newest sample, so this value tops out at about 30. When the publisher is faster, the samples between two updates are counted but not drawn. DRAW HZ drops to 0 while the viewer is paused.
- **LAST**: the size of the sample on screen.

### The card

The app updates one card in place:

- **json**: pretty-printed. Scroll sideways to read long lines.
- **text**: wrapped. An empty sample shows `(empty payload)`.
- **image**: scaled to fit the card. Images larger than 200 KB are decoded in the background, so a spinner shows until the first one is ready. If the bytes are not a valid image, the card shows `cannot decode image`.
- **protobuf**: when the schema names a message the app knows (the ones in `tools/proto/demo.proto`: `zenoh_demo.Imu`, `zenoh_demo.Image` and `zenoh_demo.Raw`), the sample is decoded and shown as pretty-printed JSON. An image inside the message, such as the JPEG in a `zenoh_demo.Image`, is drawn. When the schema is missing or names an unknown message, the card shows the schema name and a hex dump like **binary**.
- **flatbuffers**: when the schema names a table the app knows (the one in `tools/fbs/demo.fbs`: `zenoh_demo.Imu`), the sample is decoded and shown as pretty-printed JSON. When the schema is missing or names an unknown table, the card shows the schema name and a hex dump like **binary**.
- **binary**: a hex dump of the first 64 bytes, with an ASCII column and the total size.
- Text and JSON longer than 64 K characters are cut off on screen. Copying still gives you the whole payload.

The line under the card reads `#count · time`. The count is the number of samples received since the viewer opened. The time is when the sample on screen was received.

With a wildcard key expression, the card shows whichever matching key sent last, and PUB HZ counts all of them. Only use a wildcard here for keys that carry the same kind of data.

### Pause and copy

- **Pause** freezes the card and shows `PAUSED`. Samples keep arriving, so PUB HZ and the count keep changing. **Resume** jumps to the newest sample.
- **Long-press** the card to copy the payload. Text and JSON are copied as text. Images and binary are copied as one hex string. A short `Copied` message confirms it.

If the session closes while you are viewing, the card is replaced by `Session closed`. The viewer does not subscribe again by itself.

The app is not told when a router goes away. The strip still shows the session as open, PUB HZ falls to 0, and the card keeps the last sample.

## Troubleshooting

**No topics appear** (`Waiting for samples on **…`)
- Something has to publish. A key appears only after a sample arrives.
- Check that the discovery scope covers the key. For example, `test/**` does not match `demo/x`.
- Open the session log. Look for `Discovery listening on <scope>`, or for an error such as an invalid discovery scope.
- To get test data, run `python3 tools/test_publisher.py` on the computer that runs the router (it needs `pip install eclipse-zenoh protobuf flatbuffers pillow`). It connects to `tcp/localhost:7447`.

**Connection fails on the Android emulator**
- Use `10.0.2.2`, the host computer. Inside the emulator, `127.0.0.1` and `localhost` mean the emulator itself.
- Use client mode, where the default host is already `10.0.2.2`. Or, in peer mode, open **Advanced** and enter `10.0.2.2` under **Connect to (optional)**.
- Check that the router listens on that protocol and port (tcp 7447 by default). The status line and the session log show the error.

**Connection fails on a physical phone**
- The default host on Android (`10.0.2.2`) only works in the emulator, and `127.0.0.1` is the phone itself. Enter the LAN address of the computer that runs the router, and keep the phone on the same Wi-Fi.
- On iOS, allow **Local Network** access for the app. If it is denied, connections to LAN addresses fail without a clear error.

**Peer finds nothing**
- Multicast scouting does not work on the Android emulator, or on iOS without the multicast entitlement. Multicast also does not cross subnets, and many guest or company Wi-Fi networks block it.
- Open **Advanced** and enter the router under **Connect to (optional)**, or use client mode. See [MULTICAST.md](MULTICAST.md).

**ws port clash**
- The button stays disabled, and the ws row shows `same port as tcp`. Give ws its own port (the default is 8000), or turn off one of the two rows.
- If router or peer mode fails to open with a listen error, another program on the device may already use that port. Pick another port.

**Session closed while viewing**
- The viewer shows `Session closed` if the session ends while it is open, and does not subscribe again.
- Tap the connection strip to go back to Session. Open the session again, then open the topic again from Topics.
- `Subscription closed` means the subscription ended on its own. `Subscribe failed` shows the error, for example an invalid key expression.
- If the router stopped and data does not come back when it is up again, press the button on Session to reopen the session.

**The button is greyed out**
- A field shows an error. Common causes: an empty host or discovery scope, a port outside 1–65535 (0–65535 for peer listen rows), no listen row on in router mode, or the ws/tcp port clash.
