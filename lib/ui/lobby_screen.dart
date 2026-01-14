import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../game/game_manager.dart';
import '../../models/game_state.dart';
import '../../models/player.dart';
import 'game_screen.dart';
import 'home_screen.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final TextEditingController _chatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Start P2P services if in offline mode
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final manager = context.read<GameManager>();
      if (manager.mode == GameMode.offlineP2P) {
        manager.startP2P();
      }
    });
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  void _showDisconnectDialog(GameManager manager) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 12),
            Text('DISCONNECTED', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          manager.disconnectReason ?? 'Connection to host was lost.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              manager.clearDisconnectState();
              manager.leaveLANRoom();
              Navigator.of(ctx).pop();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            },
            child: const Text('OK', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<GameManager>();

    // Handle disconnect
    if (manager.wasDisconnected && !manager.isHost) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showDisconnectDialog(manager);
        }
      });
    }

    // Auto-navigate to GameScreen if the host started the game
    if (manager.phase != GamePhase.lobby) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const GameScreen()),
          );
        }
      });
    }

    final canStart = manager.canStartGame;
    final config = manager.currentConfig;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          manager.mode == GameMode.soloBots ? 'SOLO LOBBY' : 'SYNDICATE LOBBY',
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              Colors.red.withOpacity(0.05),
              Colors.black,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    Text(
                      '${manager.players.length} CREW MEMBERS',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${manager.readyPlayerCount}/${manager.players.length} READY',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        color: manager.allPlayersReady
                            ? Colors.greenAccent
                            : Colors.amberAccent,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      canStart
                          ? 'READY TO INFILTRATE'
                          : manager.isOfflineMode
                              ? (manager.isHost
                                  ? manager.players.length < 5
                                      ? 'WAITING FOR ASSOCIATES...\n(THEY MUST CONNECT TO YOUR HOTSPOT)'
                                      : 'WAITING FOR ALL MEMBERS TO BE READY...'
                                  : 'WAITING FOR THE BOSS TO START...')
                              : manager.players.length < 5
                                  ? 'WAITING FOR AT LEAST 5 AGENTS...'
                                  : 'WAITING FOR ALL AGENTS TO BE READY...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color:
                            canStart ? Colors.greenAccent : Colors.amberAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Role Config Card
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red.withOpacity(0.1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildRoleChip(Icons.person_off, '${config.mafiaCount}',
                        'MAFIA', Colors.redAccent),
                    _buildRoleChip(Icons.medical_services,
                        '${config.doctorCount}', 'DOCTOR', Colors.greenAccent),
                    _buildRoleChip(Icons.search, '${config.detectiveCount}',
                        'INTEL', Colors.blueAccent),
                    _buildRoleChip(Icons.person, '${config.villagerCount}',
                        'CIVILIANS', Colors.grey),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'MANIFEST:',
                style: TextStyle(
                    color: Colors.white54,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    fontSize: 12),
              ),
              const SizedBox(height: 12),

              // Player list
              Expanded(
                child: ListView.builder(
                  itemCount: manager.players.length,
                  itemBuilder: (context, index) {
                    final player = manager.players[index];
                    final isMe = player.id == manager.localPlayerId;
                    final isPlayerHost = index == 0; // First player is host
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isMe
                            ? Colors.white.withOpacity(0.1)
                            : Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isMe
                              ? Colors.redAccent.withOpacity(0.3)
                              : Colors.white.withOpacity(0.05),
                        ),
                      ),
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                backgroundColor: player.isBot
                                    ? Colors.grey.shade800
                                    : Colors.redAccent.withOpacity(0.2),
                                child: Icon(
                                  player.isBot ? Icons.smart_toy : Icons.person,
                                  color: player.isBot
                                      ? Colors.white54
                                      : Colors.redAccent,
                                  size: 20,
                                ),
                              ),
                              // Ready indicator dot
                              if (!player.isBot)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: player.isReady
                                          ? Colors.greenAccent
                                          : Colors.grey,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.black,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  player.name.toUpperCase(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isMe ? Colors.white : Colors.white70,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                if (!player.isBot)
                                  Text(
                                    player.isReady ? 'READY' : 'NOT READY',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: player.isReady
                                          ? Colors.greenAccent
                                          : Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (isPlayerHost)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amberAccent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'HOST',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          if (isMe && !isPlayerHost) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'YOU',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                          if (isMe && isPlayerHost) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'YOU',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                          if (manager.currentConfig.isModeratorMode &&
                              player.id == manager.moderatorId) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amberAccent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'MODERATOR',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                          if (manager.isHost &&
                              manager.mode == GameMode.offlineP2P) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(Icons.gavel,
                                  color: player.id == manager.moderatorId
                                      ? Colors.greenAccent
                                      : Colors.amberAccent,
                                  size: 20),
                              tooltip: player.id == manager.moderatorId
                                  ? 'Unassign Moderator'
                                  : 'Assign as Moderator',
                              onPressed: () => manager.assignModerator(
                                  player.id == manager.moderatorId
                                      ? null
                                      : player.id),
                            ),
                            // Kick button (not for host themselves)
                            if (!isPlayerHost)
                              IconButton(
                                icon: const Icon(Icons.person_remove,
                                    color: Colors.redAccent, size: 20),
                                tooltip: 'Kick Player',
                                onPressed: () => _confirmKickPlayer(
                                    context, manager, player),
                              ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Start button / Ready button
              const SizedBox(height: 16),
              if (manager.isHost)
                ElevatedButton(
                  onPressed: canStart
                      ? () {
                          manager.startGame();
                          // Host navigates immediately
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                                builder: (_) => const GameScreen()),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    disabledBackgroundColor: Colors.grey.shade900,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 10,
                    shadowColor: Colors.redAccent.withOpacity(0.5),
                  ),
                  child: Text(
                    canStart
                        ? 'EXECUTE MISSION'
                        : manager.players.length < 5
                            ? 'NEED ${5 - manager.players.length} MORE AGENTS'
                            : 'WAITING FOR ALL TO BE READY',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, letterSpacing: 2),
                  ),
                )
              else ...[
                // Client Ready/Wait toggle button
                ElevatedButton(
                  onPressed: () {
                    final currentPlayer = manager.localPlayer;
                    if (currentPlayer != null) {
                      manager.setLocalPlayerReady(!currentPlayer.isReady);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: manager.localPlayer?.isReady == true
                        ? Colors.greenAccent
                        : Colors.amberAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 10,
                    shadowColor: (manager.localPlayer?.isReady == true
                            ? Colors.greenAccent
                            : Colors.amberAccent)
                        .withOpacity(0.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        manager.localPlayer?.isReady == true
                            ? Icons.check_circle
                            : Icons.hourglass_empty,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        manager.localPlayer?.isReady == true
                            ? 'READY - TAP TO UNREADY'
                            : 'TAP WHEN READY',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, letterSpacing: 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'WAITING FOR MISSION COMMANDER...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2),
                ),
              ],
            ],
          ),
        ),
      ),
      // Chat FAB
      floatingActionButton: manager.isOfflineMode
          ? FloatingActionButton(
              onPressed: () => _showChatPanel(context, manager),
              backgroundColor: Colors.redAccent,
              child: Stack(
                children: [
                  const Icon(Icons.chat, color: Colors.white),
                  if (manager.lobbyChatMessages.isNotEmpty)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            )
          : null,
    );
  }

  void _showChatPanel(BuildContext context, GameManager manager) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ChatPanel(
        manager: manager,
        chatController: _chatController,
      ),
    );
  }

  void _confirmKickPlayer(
      BuildContext context, GameManager manager, Player player) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.person_remove, color: Colors.redAccent),
            SizedBox(width: 12),
            Text('KICK PLAYER', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          'Remove ${player.name} from the lobby?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child:
                const Text('CANCEL', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              manager.kickPlayer(player.id);
              Navigator.of(ctx).pop();
            },
            child:
                const Text('KICK', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleChip(
      IconData icon, String count, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          count,
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        Text(
          label,
          style: const TextStyle(
              color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

/// Chat panel widget for lobby chat
class _ChatPanel extends StatefulWidget {
  final GameManager manager;
  final TextEditingController chatController;

  const _ChatPanel({
    required this.manager,
    required this.chatController,
  });

  @override
  State<_ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<_ChatPanel> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = widget.chatController.text.trim();
    if (text.isNotEmpty) {
      widget.manager.sendLobbyChatMessage(text);
      widget.chatController.clear();
      // Scroll to bottom after sending
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameManager>(
      builder: (context, manager, child) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.chat, color: Colors.redAccent),
                    const SizedBox(width: 12),
                    const Text(
                      'LOBBY CHAT',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white54),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white12, height: 1),
              // Messages
              Expanded(
                child: manager.lobbyChatMessages.isEmpty
                    ? const Center(
                        child: Text(
                          'No messages yet.\nSay hello to your crew!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white38),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: manager.lobbyChatMessages.length,
                        itemBuilder: (context, index) {
                          final msg = manager.lobbyChatMessages[index];
                          final isMe = msg.senderId == manager.localPlayerId;
                          return Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.7,
                              ),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? Colors.redAccent.withOpacity(0.3)
                                    : Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!isMe)
                                    Text(
                                      msg.senderName.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  Text(
                                    msg.text,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              // Input
              Container(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 8,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  border: const Border(
                    top: BorderSide(color: Colors.white12),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: widget.chatController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _sendMessage,
                      icon: const Icon(Icons.send, color: Colors.redAccent),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
