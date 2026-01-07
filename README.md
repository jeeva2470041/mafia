# Flutter Mafia Game – Offline P2P + Solo Bots

This app implements a Mafia/Werewolf game with two modes:
- Offline P2P (Local Wi-Fi/Hotspot via nearby_connections)
- Solo Mode with AI Bots (no internet)

Architecture strictly separates:
- Game Logic (The Brain) — `GameManager`
- Communication Layer (The Cable) — `GameCommunication` interface and `P2PCommunication`
- UI (screens) — interacts only with `GameManager`

## Quick Start

```powershell
# From workspace root
flutter pub get
flutter run
```

## File Structure

- lib/models: `player.dart`, `game_state.dart`
- lib/game: `game_manager.dart`, `bot_controller.dart`, `game_rules.dart`
- lib/network: `game_communication.dart`, `p2p_communication.dart`
- lib/ui: `lobby_screen.dart`, `game_screen.dart`, `voting_screen.dart`

## Notes
- UI never performs business logic or direct networking.
- Bots perform night and voting actions with a 3-second delay.
- P2P implementation uses Nearby Connections; host is the single source of truth.
