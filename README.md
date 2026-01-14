# Mafia Game (Flutter)

:crossed_swords: **Mafia — Offline LAN (UDP/TCP) multiplayer + Solo bots**

This repository contains a Flutter game that supports local offline multiplayer over LAN (UDP-based room discovery + TCP for reliable game sync) and a solo mode with AI bots.

---

## 🔑 Key Features

- **Fully offline LAN multiplayer**
  - UDP broadcast discovery (port 41234)
  - TCP server/client communication (dynamic ports assigned by OS)
  - Host-authoritative: host keeps canonical game state and broadcasts state updates
  - **Ready/Wait system**: All players must mark themselves ready before host can start
  - **Lobby chat**: In-room text messaging before game starts
  - **Host disconnect handling**: Clients notified and redirected when host leaves
- **Solo mode** with AI-controlled bots (no networking required)
- **QR / IP-based join fallback** (scan QR or enter host IP:port to connect directly)
- Animated in-app splash + native splash (Android/iOS)
- Cross-platform: Android, Windows (desktop), Web (UI only — LAN not supported in browser)

---

## 🆕 Recent Updates

### Ready/Wait System
- Each player has a ready status displayed in the lobby
- Clients tap "READY" button to toggle their ready state
- Host can only start game when all players are ready
- Ready count displayed: "X/Y READY"

### Lobby Chat
- Floating chat button (FAB) in lobby
- Send messages to all players before game starts
- Messages show sender name and are styled differently for your own messages

### Host Powers
- **Kick Players**: Host can remove players from lobby before game starts
- **Moderator Assignment**: Assign/unassign moderator role
- **Start Control**: Host can only start when minimum 5 players and all ready

### Host Disconnect Handling
- **In Lobby**: Clients automatically notified when host disconnects, dialog shown with reason
- **During Game**: Game immediately ends if host disconnects, all players returned to home
- Automatic navigation back to home screen with error message

### Game State Safety
- **No Late Joins**: Clients attempting to join after game starts receive "Game already in progress" rejection
- **Host Disconnect Protection**: Game cannot continue without host, all players notified immediately

### Dynamic TCP Ports
- TCP server now binds to port 0 (OS-assigned dynamic port)
- Port number included in room discovery broadcasts
- QR codes encode full `IP:PORT` for connection

---

## 📁 Project structure (important files)

- lib/
  - game/
    - game_manager.dart — central game state and logic (ChangeNotifier)
    - bot_controller.dart — bot behavior
    - game_rules.dart — role setup & win conditions
  - network/
    - lan_communication.dart — UDP discovery + TCP client/server implementation
    - game_communication.dart — interface for communication layer
  - ui/
    - home_screen.dart, player_setup_screen.dart, lobby_screen.dart, game_screen.dart
    - how_to_play_screen.dart — rules and role descriptions
  - models/
    - player.dart — Player model with id, name, role, isReady, etc.
    - game_state.dart — GamePhase, GameMode, GameConfig enums

- assets/
  - images/icon.png — app icon (used for launcher & splash)
  - images/background.png

---

## 🛠 Development setup

Requirements:
- Flutter 3.x/4.x SDK
- Android SDK (for building APK)
- Windows tooling (if targeting desktop)

Commands:

- Install dependencies

  ```bash
  flutter pub get
  ```

- Static analysis

  ```bash
  flutter analyze
  ```

- Run (Windows desktop)

  ```bash
  flutter run -d windows
  ```

- Run (Android emulator or device)

  ```bash
  flutter run -d <device-id>
  ```

- Build release APK (split per ABI)

  ```bash
  flutter build apk --release --split-per-abi
  ```

- Build Windows executable

  ```bash
  flutter build windows --release
  ```

---

## 🧭 Networking details (LAN)

### UDP Discovery
- Host broadcasts a JSON message containing RoomInfo every 2 seconds to UDP port **41234**
- Broadcast includes: room name, host name, player count, max players, **TCP port**, privacy flag
- Clients listen on UDP port **41234** and parse broadcasts to show available rooms

### TCP Communication
- Host opens a TCP server on a **dynamic port** (OS-assigned) and accepts client sockets
- All game actions and state sync use JSON over TCP with line-delimited messages
- Message types include:
  - `join_request` / `join_accepted` / `join_rejected` — player connection
  - `state_update` — full game state sync
  - `set_ready` / `player_ready` — ready state changes
  - `chat` / `chat_broadcast` — lobby chat messages
  - `room_closed` — host disconnect notification

### Fallback when discovery fails
- Manual "Join by IP:Port" dialog
- QR Code contains host IP and port (e.g., `192.168.1.100:54321`) for direct connection

### Important Notes
- Devices must be on the same network (same WiFi/subnet)
- Firewalls on host machines may block UDP/TCP — temporarily disable or allow the app during testing

---

## 📱 QR & IP Join

- **Host**: In the **Lobby** the host's local IP:Port is shown (tap to copy). Tap QR icon to show a QR code containing the connection info.
- **Client**: In **Find Room** screen, choose "JOIN BY IP ADDRESS" or "SCAN QR". Scanning the QR attempts a direct TCP connect.

---

## 🎮 Lobby Features

### Player List
- Shows all connected players with ready status indicator (green dot = ready)
- Host badge and "YOU" badge for identification
- Moderator assignment option for host
- **Kick button** (host only) - Remove players before game starts

### Ready System
- **Clients**: Tap "TAP WHEN READY" button to toggle ready state
- **Host**: Start button disabled until all players are ready
- Button shows "NEED X MORE AGENTS" or "WAITING FOR ALL TO BE READY"

### Lobby Chat
- Tap floating chat button (bottom right) to open chat panel
- Type messages to communicate with other players
- Messages persist during lobby session

### Host Controls
- **Kick Players**: Tap person_remove icon on any player card (except yourself)
- **Assign Moderator**: Tap gavel icon to toggle moderator role
- **Start Game**: Only enabled when 5+ players and all ready

---

## 🎨 Icon & Splash

- App icon is `assets/images/icon.png` and launcher icons were generated via `flutter_launcher_icons`.
- Native splash screens were generated with `flutter_native_splash` (color set to #0A0A0A and using the same icon).
- The Flutter animated splash (`lib/screens/splash_screen.dart`) plays right after native splash and then navigates to the Home screen.

---

## ⚙️ Android / iOS permissions

- Android: CAMERA (for QR scan) is declared in AndroidManifest; INTERNET is also required.
- iOS: NSCameraUsageDescription added to Info.plist.

---

## ✅ Testing checklist

- [ ] Verify `flutter analyze` shows no errors
- [ ] Host on Windows and confirm UDP broadcasts appear (logs show "Hosting started: ... at IP:PORT")
- [ ] On Android device (same WiFi), open Find Room and verify host appears
- [ ] If no discovery results, use "Join by IP" with the host IP:Port displayed in the lobby
- [ ] Test QR scan to confirm it reads IP:Port and connects
- [ ] Test ready system: client toggles ready, host sees ready count update
- [ ] Test lobby chat: send messages between host and client
- [ ] Test kick functionality: host kicks a player and verify they're disconnected
- [ ] Test host disconnect in lobby: close host app and verify client gets notification
- [ ] Test host disconnect during game: close host app during gameplay and verify all clients exit to home
- [ ] Test late join rejection: try to join a room after game has started
- [ ] Test solo mode (bots) with different player counts

---

## 🐞 Troubleshooting

- **No discovery results:**
  - Ensure both devices are on the same WiFi and same subnet (e.g., both 192.168.1.x)
  - Check host firewall (Windows Defender) settings — allow the app or temporarily disable firewall
  - Try the **Join by IP** fallback using the host IP:Port displayed in the lobby

- **QR scan fails to connect:**
  - Check format `ip:port` encoded in QR
  - Use manual IP:Port entry as backup

- **"Room is full" or "Game in progress" errors:**
  - Room has reached max players or game already started
  - Ask host to create a new room

- **Client stuck after host leaves:**
  - This should now show a disconnect dialog automatically
  - If stuck, force close and rejoin

---

## 🧩 Contributing

1. Fork the repo
2. Create a feature branch
3. Add tests where appropriate and ensure `flutter analyze` passes
4. Open a PR with clear description and testing steps

---



