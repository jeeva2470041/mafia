# 🎰 Omerta: City of Deception

**A Flutter LAN multiplayer Mafia/Werewolf game with AI bots and dynamic networking**

A fully offline LAN-based social deduction game supporting multiple simultaneous game rooms with public/private access, QR code sharing, and AI-powered single-player mode.

---

## ✨ Key Features

### **Multiplayer (LAN)**
- **Multi-room hosting**: Multiple hosts can run simultaneously on the same WiFi (dynamic TCP port allocation)
- **UDP discovery** (port 41234): Real-time room broadcast with automatic timeout detection
- **TCP peer-to-peer** (dynamic ports): Host-authoritative game state with reliable JSON messaging
- **Public & Private Rooms**: 
  - Public: Anyone can join
  - Private: 4-digit PIN protection (stored on host only, never broadcast)
- **QR Code Sharing**: `ip:port|pin` format for easy room access
- **Manual IP Fallback**: Join by IP address when discovery fails
- **Player Limits**: 5–10 players per room

### **Solo Mode**
- AI-controlled bots with strategic gameplay
- Flexible player count (2–10 total including you)
- Same roles and win conditions as multiplayer

### **UI/UX**
- Dark crimson theme with smooth animations
- Animated Flutter splash (after native splash)
- Mobile-first responsive design
- Real-time player status and room info
- Material Design icons and navigation

### **Cross-Platform**
- ✅ Android (primary target)
- ✅ Windows (desktop)
- ⚠️ Web (UI only — LAN networking disabled)
- ✅ iOS support (untested)

---

## 🎮 Game Mechanics

### **Roles**
- **Mafia** (killers): Eliminate civilians at night
- **Civilians** (townspeople): Identify and eliminate mafia during day votes
- **Sheriff** (optional): Revealed civilian with special voting power

### **Win Conditions**
- **Civilians Win**: Eliminate all mafia
- **Mafia Wins**: Match/exceed civilian count
- **Sheriff Special**: Survives to endgame (rare)

### **Phases**
1. **Day**: Discussion & voting (civilian majority votes out suspect)
2. **Night**: Mafia kills a civilian
3. **Repeat** until one faction wins

---

## 📁 Project Structure

```
lib/
├── game/
│   ├── game_manager.dart      # Central state management (ChangeNotifier)
│   ├── bot_controller.dart    # AI decision logic
│   ├── game_rules.dart        # Role assignment, win conditions
│   └── ...
├── network/
│   ├── lan_communication.dart # UDP discovery + TCP p2p (multi-port support)
│   └── game_communication.dart # Communication interface
├── models/
│   ├── game_state.dart        # GamePhase, GameStatus enums
│   ├── player.dart            # Player role and state
│   └── ...
├── screens/
│   ├── home_screen.dart       # Main menu (Solo / LAN options)
│   ├── name_entry_screen.dart # Host: room & PIN setup
│   ├── room_discovery_screen.dart # Client: browse/join rooms
│   ├── lobby_screen.dart      # Pre-game lobby (host controls, IP:port display)
│   ├── game_screen.dart       # Game phase UI
│   ├── splash_screen.dart     # Animated intro (2s duration)
│   └── ...
├── widgets/
│   ├── room_tile.dart         # Room card (with lock icon for private)
│   ├── player_card.dart       # Player info display
│   └── ...
└── assets/
    ├── images/icon.png        # App icon (used for launcher & splash)
    └── images/background.png  # Background gradient

pubspec.yaml                   # Dependencies & asset configuration
```

---

## 🛠 Setup & Development

### **Prerequisites**
- Flutter SDK 3.0+ (Dart 2.17+)
- Android SDK (for APK) or Windows SDK (for desktop)
- Xcode (optional, for iOS)

### **Installation**

```bash
# Clone and setup
git clone <repo-url>
cd mafia
flutter pub get

# Generate launcher icons and native splash
flutter pub run flutter_launcher_icons
flutter pub run flutter_native_splash:create

# Verify setup
flutter doctor
```

### **Run**

```bash
# Android device/emulator
flutter run -d <device-id>

# Windows desktop
flutter run -d windows

# Web (UI only, LAN disabled)
flutter run -d chrome
```

### **Build**

```bash
# Android APK (split by architecture)
flutter build apk --release --split-per-abi

# Output: build/app/outputs/flutter-apk/
#  - app-armeabi-v7a-release.apk
#  - app-arm64-v8a-release.apk
#  - app-x86_64-release.apk

# Windows executable
flutter build windows --release
# Output: build/windows/runner/Release/
```

---

## 🌐 Networking Architecture

### **UDP Discovery (Port 41234)**

**Broadcast Payload** (every 2 seconds from host):
```json
{
  "type": "room_broadcast",
  "room": {
    "hostId": "device-uuid",
    "hostName": "Sam",
    "roomName": "Mafia Room",
    "hostIp": "192.168.1.100",
    "hostPort": 52341,         // Dynamic TCP port
    "playerCount": 3,
    "maxPlayers": 10,
    "inProgress": false,
    "isPrivate": false
  }
}
```

**Note**: PIN is **NOT broadcast** — it's stored on the host and validated during TCP join only.

### **TCP Communication (Dynamic Ports)**

**Server Binding**:
- Host: `ServerSocket.bind(anyIPv4, 0)` → OS assigns available port
- Actual port stored in `RoomInfo.hostPort` and broadcast via UDP

**Client Connection**:
- Client receives room info (including `hostPort`) from UDP discovery
- Connects: `Socket.connect(hostIp, hostPort)`

**Message Format** (line-delimited JSON):
```json
{"type":"join_request","playerId":"p1","playerName":"Sam","pin":"1234"}
{"type":"join_accepted","playerId":"p1"}
{"type":"game_state","phase":"day","..."}
```

### **Fallback Mechanisms**
- **Manual IP Entry**: `192.168.1.100:52341` (port optional, defaults to 41235)
- **QR Code**: Encodes `ip:port|pin` (pin only for private rooms)

### **Multi-Host Support**
Each host gets a unique dynamic TCP port from the OS, allowing multiple rooms on the same WiFi:

```
Room 1: 192.168.1.100:52341
Room 2: 192.168.1.100:52342
Room 3: 192.168.1.100:52343
```

---

## 🔒 Security & Privacy

- **Private Rooms**: 4-digit PIN protection
  - PIN stored locally on host only
  - Never transmitted in UDP broadcasts
  - Validated server-side during TCP join
- **No Authentication**: Relies on LAN isolation (local WiFi only)
- **No Data Persistence**: Game state cleared after session ends

---

## 📱 QR & IP Join

### **Host (Lobby Screen)**
- Displays: `<ip>:<port>` with copy-to-clipboard
- QR Icon: Shows encoded QR with `ip:port|pin` format
- PIN Display: Only shown for private rooms

### **Client (Room Discovery)**
- **Auto-discover**: UDP broadcasts from same subnet
- **Join by IP**: Manual entry field accepts:
  - `192.168.1.100` (uses default port 41235)
  - `192.168.1.100:52341` (uses specified port)
- **Scan QR**: Camera-based QR decoder
  - Public: `192.168.1.100:52341`
  - Private: `192.168.1.100:52341|1234`
- **PIN Prompt**: Auto-shown for private rooms

---

## 🎨 Icon & Splash Screens

### **App Icon**
- Source: `assets/images/icon.png` (square, 1024x1024 recommended)
- Generated via `flutter_launcher_icons` plugin
- Adaptive icon support (Android 8+)
- Background color: `#0A0A0A` (dark)

### **Native Splash**
- Platform-specific (iOS + Android)
- Generated via `flutter_native_splash` plugin
- Color: `#0A0A0A`
- Shows app icon centered

### **Flutter Animated Splash** (`lib/screens/splash_screen.dart`)
- Plays immediately after native splash
- Animations:
  - Logo: Fade + scale (radial gradient backdrop)
  - Text: Fade in staggered
- Duration: 2 seconds total
- Auto-navigates to Home screen

---

## ⚙️ Permissions & Configuration

### **Android** (AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.CAMERA" />
```

### **iOS** (Info.plist)
```xml
<key>NSCameraUsageDescription</key>
<string>Camera is needed to scan QR codes for room joining</string>
<key>NSLocalNetworkUsageDescription</key>
<string>Required for local network device discovery</string>
<key>NSBonjourServices</key>
<array>
  <string>_tcp</string>
  <string>_udp</string>
</array>
```

### **pubspec.yaml** (Asset Configuration)
```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/images/

flutter_launcher_icons:
  image_path: "assets/images/icon.png"
  adaptive_icon_background: "#0A0A0A"

flutter_native_splash:
  color: "#0A0A0A"
  image: assets/images/icon.png
```

---

## ✅ Testing Checklist

- [ ] `flutter analyze` passes (no errors)
- [ ] Host Android device & Windows can both run app
- [ ] Create room on Windows (check logs: "Hosting started at IP:PORT")
- [ ] Android on same WiFi auto-discovers room within 3 seconds
- [ ] Join discovered room → Lobby loads with player count
- [ ] Test private room (PIN entry prompt appears)
- [ ] QR scan works: `ip:port|pin` encoded correctly
- [ ] Manual IP join works with and without port
- [ ] Solo bots game completes (night/day cycle)
- [ ] Build APK: `flutter build apk --split-per-abi` succeeds
- [ ] Test on actual Android device (not just emulator)

---

## 🐞 Troubleshooting

### **No Rooms Discovered**
1. **Same WiFi?** Both devices must be on identical network (e.g., `MyWiFi-5G`)
2. **Firewall?** Windows Defender may block UDP/TCP:
   - Temporarily disable OR
   - Add app to firewall whitelist
3. **Subnet?** If mixed IPv4/IPv6, ensure both are IPv4 (192.168.x.x)
4. **Fallback**: Use "Join by IP" with host IP shown in lobby

### **QR Scan Fails**
- Ensure QR camera permission granted
- Check QR format: `ip:port` or `ip:port|pin`
- Use manual IP entry as backup

### **Connection Timeout**
- Host machine firewall blocking TCP
- Port in use: Try restarting host
- Check host logs for bind errors

### **App Crash on Join**
- Verify host hasn't started game yet
- Check room isn't full (max 10 players)
- Re-check PIN for private rooms

---

## 🚀 Performance & Optimization

- **UDP Broadcast Interval**: 2 seconds (balance discovery vs. network load)
- **Room Timeout**: 6 seconds (removes stale rooms)
- **TCP Message Size**: Typically <1KB per message
- **Player Limit**: 10 max (consensus with game rules)
- **Icon Tree-Shaking**: Material icons reduced 99% (9KB vs 1.6MB)

---

## 📝 Code Style & Conventions

- **Language**: Dart with null safety (`<4.0.0`)
- **State Management**: Provider (ChangeNotifier)
- **JSON Serialization**: Manual (no code generation)
- **Naming**: camelCase for variables, PascalCase for classes
- **Linting**: `flutter_lints` ^2.0.0

---


## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Ensure `flutter analyze` passes
5. Push to branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request with testing details

---

## 🔗 Related Resources

- [Flutter Docs](https://flutter.dev/docs)
- [Socket Networking](https://dart.dev/guides/libraries/io)
- [Mafia Game Rules](https://en.wikipedia.org/wiki/Mafia_(party_game))
- [Material Design](https://material.io/)



