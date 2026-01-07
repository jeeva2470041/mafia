// Offline P2P implementation using nearby_connections
// Host is the single source of truth; clients send actions only.

import 'dart:convert';
import 'dart:typed_data';

import 'package:nearby_connections/nearby_connections.dart';

import '../models/game_state.dart';
import 'game_communication.dart';

class P2PCommunication implements GameCommunication {
  static const String typeField = '_msg_type';
  static const String typeState = 'state';
  static const String typeAction = 'action';

  final Strategy _strategy = Strategy.P2P_POINT_TO_POINT;
  final Set<String> _connectedEndpoints = {};

  Function(GameState)? _onState;
  Function(Map<String, dynamic>)? _onAction;

  final bool isHost;
  final String serviceId;

  P2PCommunication({required this.isHost, required this.serviceId});

  // Start advertising (host)
  Future<void> startHosting(String name) async {
    if (!isHost) return;
    try {
      await Nearby().startAdvertising(
        name,
        _strategy,
        onConnectionInitiated: (id, info) {
          Nearby().acceptConnection(
            id,
            onPayLoadRecieved: (eid, payload) => _handlePayload(eid, payload),
            onPayloadTransferUpdate: (eid, update) {},
          );
        },
        onConnectionResult: (id, status) {
          if (status == Status.CONNECTED) {
            _connectedEndpoints.add(id);
          }
        },
        onDisconnected: (id) {
          _connectedEndpoints.remove(id);
        },
        serviceId: serviceId,
      );
    } catch (e) {
      print('Nearby Error: $e');
    }
  }

  // Start discovering (client)
  Future<void> startDiscovery(String name) async {
    if (isHost) return;
    try {
      await Nearby().startDiscovery(
        name,
        _strategy,
        onEndpointFound: (id, name, serviceId) {
          Nearby().requestConnection(name, id, onConnectionInitiated: (eid, _) {
            Nearby().acceptConnection(
              eid,
              onPayLoadRecieved: (from, payload) =>
                  _handlePayload(from, payload),
              onPayloadTransferUpdate: (from, update) {},
            );
          }, onConnectionResult: (eid, status) {
            if (status == Status.CONNECTED) {
              _connectedEndpoints.add(eid);
            }
          }, onDisconnected: (eid) {
            _connectedEndpoints.remove(eid);
          });
        },
        onEndpointLost: (id) {},
        serviceId: serviceId,
      );
    } catch (e) {
      print('Nearby Error: $e');
    }
  }

  void _handlePayload(String from, Payload payload) {
    final bytes = payload.bytes;
    if (bytes == null) return;

    try {
      final jsonStr = utf8.decode(bytes);
      final map = json.decode(jsonStr) as Map<String, dynamic>;

      final type = map[typeField];
      if (type == typeState) {
        final state = GameState.fromJson(map['data']);
        _onState?.call(state);
      } else if (type == typeAction) {
        _onAction?.call(map['data']);
      }
    } catch (e) {
      print('Payload Error: $e');
    }
  }

  @override
  Future<void> sendGameState(GameState state) async {
    if (!isHost) return;
    final msg = {
      typeField: typeState,
      'data': state.toJson(),
    };
    final bytes = Uint8List.fromList(utf8.encode(json.encode(msg)));
    for (final id in _connectedEndpoints) {
      await Nearby().sendBytesPayload(id, bytes);
    }
  }

  @override
  Future<void> sendAction(Map<String, dynamic> action) async {
    final msg = {
      typeField: typeAction,
      'data': action,
    };
    final bytes = Uint8List.fromList(utf8.encode(json.encode(msg)));
    for (final id in _connectedEndpoints) {
      await Nearby().sendBytesPayload(id, bytes);
    }
  }

  @override
  void onGameStateReceived(Function(GameState) callback) {
    _onState = callback;
  }

  @override
  void onActionReceived(Function(Map<String, dynamic>) callback) {
    _onAction = callback;
  }

  void disconnect() {
    Nearby().stopAdvertising();
    Nearby().stopDiscovery();
    Nearby().stopAllEndpoints();
    _connectedEndpoints.clear();
  }
}
