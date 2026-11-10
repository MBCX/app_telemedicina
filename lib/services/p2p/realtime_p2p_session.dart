import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../classes/mensaje_teleconsulta.dart';
import '../mqtt/mqtt_signaling_factory.dart';
import 'p2p_signaling_stub.dart'
    if (dart.library.html) 'p2p_signaling_web.dart';

class RealtimeP2PSession {
  final String roomId;
  final String citaId;
  final String localAuthor;
  final String localRole;
  final VoidCallback onStateChanged;
  final void Function(MensajeTeleconsulta msg) onChatMessageReceived;

  final String peerId =
      'PEER-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(99999)}';

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  MediaStream? _localStream;
  MediaStream? _remoteStream;
  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;

  MqttClient? _mqttClient;
  StreamSubscription<List<MqttReceivedMessage<MqttMessage?>>>? _mqttSub;
  WebSocketChannel? _wsChannel;
  void Function(Map<String, dynamic>)? _sendBroadcast;
  Timer? _helloTimer;

  bool _localRendererInitialized = false;
  bool _remoteRendererInitialized = false;
  bool _isDisposed = false;
  Future<void>? _initPreviewFuture;

  bool isLocalVideoReady = false;
  bool isLocalAudioReady = false;
  bool isRemoteConnected = false;
  bool isRemoteVideoAvailable = false;
  bool isSignalingOnline = false;
  bool micEnabled = true;
  bool cameraEnabled = true;
  bool speakerphoneEnabled = true;

  bool _signaledRemoteCam = true;

  String? remotePeerId;
  String? remotePeerName;
  String? remotePeerRole;
  String? mediaErrorMessage;

  List<MediaDeviceInfo> videoDevices = [];
  List<MediaDeviceInfo> audioInputDevices = [];
  String? selectedVideoDeviceId;
  String? selectedAudioDeviceId;

  bool _makingOffer = false;
  bool _ignoreOffer = false;
  bool _isSettingRemoteAnswerPending = false;
  final List<RTCIceCandidate> _pendingCandidates = [];
  final Set<String> _processedMessageIds = {};

  bool get isDisposed => _isDisposed;
  bool get isLocalRendererInitialized =>
      !_isDisposed &&
      _localRendererInitialized &&
      localRenderer.textureId != null;
  bool get isRemoteRendererInitialized =>
      !_isDisposed &&
      _remoteRendererInitialized &&
      remoteRenderer.textureId != null;

  String get _mqttTopic =>
      'telesalud_rd_v2/rooms/${roomId.trim().toUpperCase()}/signaling';

  RealtimeP2PSession({
    required this.roomId,
    required this.citaId,
    required this.localAuthor,
    required this.localRole,
    required this.onStateChanged,
    required this.onChatMessageReceived,
  });

  Future<void> _ensureRenderersInitialized() async {
    if (_isDisposed) return;
    if (!_localRendererInitialized) {
      await localRenderer.initialize();
      if (_isDisposed) {
        await localRenderer.dispose();
        return;
      }
      _localRendererInitialized = true;
    }
    if (!_remoteRendererInitialized) {
      await remoteRenderer.initialize();
      if (_isDisposed) {
        await remoteRenderer.dispose();
        return;
      }
      _remoteRendererInitialized = true;
    }
  }

  Future<void> initializePreviewOnly() async {
    if (_isDisposed) return;
    if (_initPreviewFuture != null) {
      await _initPreviewFuture;
      return;
    }
    final completer = Completer<void>();
    _initPreviewFuture = completer.future;
    try {
      await _ensureRenderersInitialized();
      if (_isDisposed) return;
      await _enumerateMediaDevices();
      if (_isDisposed) return;
      await _initLocalMedia();
    } finally {
      if (!completer.isCompleted) {
        completer.complete();
      }
      _initPreviewFuture = null;
    }
  }

  Future<void> start({required String wsSignalingUrl}) async {
    if (_isDisposed) return;
    if (_initPreviewFuture != null) {
      await _initPreviewFuture;
    }
    if (_isDisposed) return;

    await _ensureRenderersInitialized();
    if (_isDisposed) return;

    if (_localStream == null) {
      await _enumerateMediaDevices();
      if (_isDisposed) return;
      await _initLocalMedia();
      if (_isDisposed) return;
    }

    await _createPeerConnection();
    if (_isDisposed) return;

    await _connectSignaling(wsSignalingUrl);
    if (_isDisposed) return;

    _sendSignal({
      'type': 'join',
      'name': localAuthor,
      'role': localRole,
      'cam': cameraEnabled,
      'mic': micEnabled,
    });

    _helloTimer?.cancel();
    _helloTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_isDisposed && !isRemoteConnected) {
        _sendSignal({
          'type': 'join',
          'name': localAuthor,
          'role': localRole,
          'cam': cameraEnabled,
          'mic': micEnabled,
        });
      }
    });
  }

  Future<void> _enumerateMediaDevices() async {
    if (_isDisposed) return;
    try {
      final devices = await navigator.mediaDevices.enumerateDevices();
      if (_isDisposed) return;
      List<MediaDeviceInfo> uniqueByKind(String kind) {
        final seen = <String>{};
        return devices
            .where((d) => d.kind == kind && d.deviceId.isNotEmpty)
            .where((d) => seen.add(d.deviceId))
            .toList();
      }

      videoDevices = uniqueByKind('videoinput');
      audioInputDevices = uniqueByKind('audioinput');

      if (!videoDevices.any((d) => d.deviceId == selectedVideoDeviceId)) {
        selectedVideoDeviceId = videoDevices.isNotEmpty
            ? videoDevices.first.deviceId
            : null;
      }
      if (!audioInputDevices.any((d) => d.deviceId == selectedAudioDeviceId)) {
        selectedAudioDeviceId = audioInputDevices.isNotEmpty
            ? audioInputDevices.first.deviceId
            : null;
      }
    } catch (_) {}
  }

  Future<void> _initLocalMedia() async {
    if (_isDisposed) return;
    mediaErrorMessage = null;
    try {
      final videoConstraints = <String, dynamic>{
        'facingMode': 'user',
        'width': {'ideal': 1280, 'min': 640},
        'height': {'ideal': 720, 'min': 480},
        'frameRate': {'ideal': 30},
        if (selectedVideoDeviceId != null && selectedVideoDeviceId!.isNotEmpty)
          'deviceId': selectedVideoDeviceId,
      };
      final audioConstraints = <String, dynamic>{
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
        if (selectedAudioDeviceId != null && selectedAudioDeviceId!.isNotEmpty)
          'deviceId': selectedAudioDeviceId,
      };

      final stream = await navigator.mediaDevices.getUserMedia({
        'audio': audioConstraints,
        'video': videoConstraints,
      });
      if (_isDisposed) {
        for (final t in stream.getTracks()) {
          await t.stop();
        }
        await stream.dispose();
        return;
      }

      _localStream = stream;
      if (isLocalRendererInitialized) {
        localRenderer.srcObject = _localStream;
      }
      isLocalVideoReady =
          isLocalRendererInitialized &&
          _localStream!.getVideoTracks().isNotEmpty;
      isLocalAudioReady = _localStream!.getAudioTracks().isNotEmpty;
      cameraEnabled = isLocalVideoReady;
      micEnabled = isLocalAudioReady;

      if (!kIsWeb) {
        try {
          await Helper.setSpeakerphoneOn(true);
        } catch (_) {}
      }
      await _enumerateMediaDevices();
      if (!_isDisposed) onStateChanged();
    } catch (e) {
      if (_isDisposed) return;
      try {
        final stream = await navigator.mediaDevices.getUserMedia({
          'audio': true,
          'video': true,
        });
        if (_isDisposed) {
          for (final t in stream.getTracks()) {
            await t.stop();
          }
          await stream.dispose();
          return;
        }
        _localStream = stream;
        if (isLocalRendererInitialized) {
          localRenderer.srcObject = _localStream;
        }
        isLocalVideoReady =
            isLocalRendererInitialized &&
            _localStream!.getVideoTracks().isNotEmpty;
        isLocalAudioReady = _localStream!.getAudioTracks().isNotEmpty;
        cameraEnabled = isLocalVideoReady;
        micEnabled = isLocalAudioReady;
        await _enumerateMediaDevices();
        if (!_isDisposed) onStateChanged();
      } catch (_) {
        if (_isDisposed) return;
        try {
          final stream = await navigator.mediaDevices.getUserMedia({
            'audio': true,
            'video': false,
          });
          if (_isDisposed) {
            for (final t in stream.getTracks()) {
              await t.stop();
            }
            await stream.dispose();
            return;
          }
          _localStream = stream;
          if (isLocalRendererInitialized) {
            localRenderer.srcObject = _localStream;
          }
          cameraEnabled = false;
          isLocalVideoReady = false;
          isLocalAudioReady = _localStream!.getAudioTracks().isNotEmpty;
          micEnabled = isLocalAudioReady;
          mediaErrorMessage = 'Cámara no detectada o sin permisos. Conectado en modo micrófono.';
          if (!_isDisposed) onStateChanged();
        } catch (err) {
          if (_isDisposed) return;
          cameraEnabled = false;
          micEnabled = false;
          isLocalVideoReady = false;
          isLocalAudioReady = false;
          mediaErrorMessage =
              'Permiso de cámara/micrófono denegado o hardware no disponible: $err';
          onStateChanged();
        }
      }
    }
  }

  Future<void> switchCamera() async {
    if (_isDisposed || _localStream == null) return;
    final videoTracks = _localStream!.getVideoTracks();
    if (videoTracks.isEmpty) return;
    try {
      if (!kIsWeb) {
        await Helper.switchCamera(videoTracks.first);
        if (!_isDisposed) onStateChanged();
        return;
      }
      await _enumerateMediaDevices();
      if (_isDisposed) return;
      if (videoDevices.length > 1) {
        final currentIdx = videoDevices.indexWhere(
          (d) => d.deviceId == selectedVideoDeviceId,
        );
        final nextIdx = (currentIdx + 1) % videoDevices.length;
        await selectVideoDevice(videoDevices[nextIdx].deviceId);
      }
    } catch (_) {}
  }

  Future<void> selectVideoDevice(String deviceId) async {
    if (_isDisposed) return;
    selectedVideoDeviceId = deviceId;
    await _replaceLocalMediaTracks();
  }

  Future<void> selectAudioDevice(String deviceId) async {
    if (_isDisposed) return;
    selectedAudioDeviceId = deviceId;
    await _replaceLocalMediaTracks();
  }

  Future<void> _replaceLocalMediaTracks() async {
    if (_isDisposed) return;
    final oldStream = _localStream;
    await _initLocalMedia();
    if (_isDisposed) return;

    if (_peerConnection != null && _localStream != null) {
      final senders = await _peerConnection!.getSenders();
      for (final track in _localStream!.getTracks()) {
        track.enabled = track.kind == 'video' ? cameraEnabled : micEnabled;
        RTCRtpSender? matchingSender;
        for (final s in senders) {
          if (s.track?.kind == track.kind) {
            matchingSender = s;
            break;
          }
        }
        if (matchingSender != null) {
          await matchingSender.replaceTrack(track);
        } else {
          await _peerConnection!.addTrack(track, _localStream!);
        }
      }
    }

    if (oldStream != null) {
      for (final t in oldStream.getTracks()) {
        await t.stop();
      }
      await oldStream.dispose();
    }
    if (!_isDisposed) onStateChanged();
  }

  Future<void> _createPeerConnection() async {
    if (_isDisposed) return;
    final config = <String, dynamic>{
      'sdpSemantics': 'unified-plan',
      'iceCandidatePoolSize': 10,
      'iceServers': [
        {
          'urls': [
            'stun:stun.l.google.com:19302',
            'stun:stun1.l.google.com:19302',
            'stun:stun2.l.google.com:19302',
            'stun:stun3.l.google.com:19302',
            'stun:stun.cloudflare.com:3478',
          ],
        },
        {
          'urls': [
            'turn:openrelay.metered.ca:80',
            'turn:openrelay.metered.ca:443',
            'turn:openrelay.metered.ca:443?transport=tcp',
          ],
          'username': 'openrelayproject',
          'credential': 'openrelayproject',
        },
      ],
    };

    final pc = await createPeerConnection(config);
    if (_isDisposed) {
      await pc.close();
      return;
    }
    _peerConnection = pc;

    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        if (_isDisposed) return;
        await _peerConnection!.addTrack(track, _localStream!);
      }
    } else {
      await _peerConnection!.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
      );
      await _peerConnection!.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
      );
    }

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      if (_isDisposed) return;
      if (candidate.candidate != null && candidate.candidate!.isNotEmpty) {
        _sendSignal({
          'type': 'candidate',
          'candidate': {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          },
        });
      }
    };

    _peerConnection!.onTrack = (RTCTrackEvent event) async {
      if (_isDisposed || !isRemoteRendererInitialized) return;
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams.first;
        if (!_isDisposed && isRemoteRendererInitialized) {
          remoteRenderer.srcObject = _remoteStream;
        }
      } else {
        _remoteStream ??= await createLocalMediaStream('remote_stream');
        if (_isDisposed || !isRemoteRendererInitialized) return;
        await _remoteStream!.addTrack(event.track);
        if (!_isDisposed && isRemoteRendererInitialized) {
          remoteRenderer.srcObject = _remoteStream;
        }
      }

      if (event.track.kind == 'video') {
        isRemoteVideoAvailable = _signaledRemoteCam;
      }

      isRemoteConnected = true;
      if (!_isDisposed) onStateChanged();
    };

    _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      if (_isDisposed) return;
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        isRemoteConnected = true;
        if (!_isDisposed) onStateChanged();
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
        isRemoteConnected = false;
        if (!_isDisposed) onStateChanged();
      }
    };

    _peerConnection!.onIceConnectionState = (RTCIceConnectionState state) {
      if (_isDisposed) return;
      if (state == RTCIceConnectionState.RTCIceConnectionStateConnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
        isRemoteConnected = true;
        if (!_isDisposed) onStateChanged();
      } else if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        _peerConnection?.restartIce();
      }
    };

    _peerConnection!.onDataChannel = (RTCDataChannel channel) {
      if (_isDisposed) return;
      _setupDataChannel(channel);
    };

    final dcInit = RTCDataChannelInit()..ordered = true;
    final dc = await _peerConnection!.createDataChannel(
      'teleconsulta_chat',
      dcInit,
    );
    if (!_isDisposed) {
      _setupDataChannel(dc);
    }
  }

  void _setupDataChannel(RTCDataChannel channel) {
    _dataChannel = channel;
    _dataChannel!.onMessage = (RTCDataChannelMessage data) {
      if (_isDisposed) return;
      try {
        final map = jsonDecode(data.text) as Map<String, dynamic>;
        if (map['type'] == 'chat') {
          final msg = MensajeTeleconsulta(
            citaId: citaId,
            autor: map['autor']?.toString() ?? 'Participante',
            rolAutor: map['rolAutor']?.toString() ?? 'Remoto',
            texto: map['texto']?.toString() ?? '',
            fechaHora:
                DateTime.tryParse(map['fechaHora']?.toString() ?? '') ??
                DateTime.now(),
          );
          onChatMessageReceived(msg);
        } else if (map['type'] == 'media_state') {
          if (map['cam'] is bool) {
            _signaledRemoteCam = map['cam'] as bool;
            isRemoteVideoAvailable = _signaledRemoteCam;
          }
          onStateChanged();
        }
      } catch (_) {}
    };
  }

  Future<void> _connectSignaling(String wsSignalingUrl) async {
    if (_isDisposed) return;
    if (kIsWeb) {
      _sendBroadcast = WebSignalingHelper.connectBroadcastChannel(
        channelName: roomId.trim().toUpperCase(),
        onMessage: _handleSignalMessage,
      );
    }

    await _connectMqttSignaling();
    if (_isDisposed) return;

    if (wsSignalingUrl.trim().isNotEmpty) {
      try {
        final uri = Uri.parse(wsSignalingUrl.trim());
        _wsChannel = WebSocketChannel.connect(uri);
        _wsChannel!.stream.listen((raw) {
          if (_isDisposed) return;
          try {
            final map = jsonDecode(raw.toString()) as Map<String, dynamic>;
            if (map['roomId']?.toString().toUpperCase() ==
                roomId.trim().toUpperCase()) {
              _handleSignalMessage(map);
            }
          } catch (_) {}
        }, onError: (_) {});
      } catch (_) {}
    }
  }

  Future<void> _connectMqttSignaling() async {
    if (_isDisposed) return;
    try {
      final client = createPlatformMqttClient(
        'telesalud_${peerId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')}',
      );
      client.logging(on: false);
      client.onConnected = () {
        if (_isDisposed) return;
        isSignalingOnline = true;
        onStateChanged();
      };
      client.onDisconnected = () {
        if (_isDisposed) return;
        isSignalingOnline = false;
        onStateChanged();
      };

      final connMess = MqttConnectMessage()
          .withClientIdentifier(
            'telesalud_${peerId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')}',
          )
          .startClean()
          .withWillQos(MqttQos.atLeastOnce);
      client.connectionMessage = connMess;

      await client.connect();
      if (_isDisposed) {
        client.disconnect();
        return;
      }

      if (client.connectionStatus?.state == MqttConnectionState.connected) {
        _mqttClient = client;
        isSignalingOnline = true;
        client.subscribe(_mqttTopic, MqttQos.atLeastOnce);
        _mqttSub = client.updates?.listen((messages) {
          if (_isDisposed) return;
          for (final recMess in messages) {
            final pubMess = recMess.payload as MqttPublishMessage;
            final payloadBytes = pubMess.payload.message;
            final pt = utf8.decode(payloadBytes, allowMalformed: true);
            try {
              final map = jsonDecode(pt) as Map<String, dynamic>;
              if (map['roomId']?.toString().toUpperCase() ==
                  roomId.trim().toUpperCase()) {
                _handleSignalMessage(map);
              }
            } catch (_) {}
          }
        });
        onStateChanged();
      }
    } catch (_) {
      if (_isDisposed) return;
      isSignalingOnline = kIsWeb;
      onStateChanged();
    }
  }

  void _sendSignal(Map<String, dynamic> payload) {
    if (_isDisposed) return;
    final msgId =
        '${peerId}_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(99999)}';
    final envelope = <String, dynamic>{
      ...payload,
      'roomId': roomId.trim().toUpperCase(),
      'senderId': peerId,
      'senderName': localAuthor,
      'senderRole': localRole,
      'msgId': msgId,
    };
    _processedMessageIds.add(msgId);
    final encoded = jsonEncode(envelope);

    _sendBroadcast?.call(envelope);

    if (_mqttClient != null &&
        _mqttClient!.connectionStatus?.state == MqttConnectionState.connected) {
      try {
        final builder = MqttClientPayloadBuilder();
        builder.addUTF8String(encoded);
        _mqttClient!.publishMessage(
          _mqttTopic,
          MqttQos.atLeastOnce,
          builder.payload!,
        );
      } catch (_) {}
    }

    try {
      _wsChannel?.sink.add(encoded);
    } catch (_) {}
  }

  bool _isPolitePeer(String otherPeerId) {
    return peerId.compareTo(otherPeerId) < 0;
  }

  Future<void> _handleSignalMessage(Map<String, dynamic> data) async {
    if (_isDisposed) return;
    final senderId = data['senderId']?.toString();
    final msgId = data['msgId']?.toString();
    if (senderId == null || senderId == peerId) return;
    if (msgId != null && !_processedMessageIds.add(msgId)) return;

    remotePeerId = senderId;
    remotePeerName = data['senderName']?.toString() ?? remotePeerName;
    remotePeerRole = data['senderRole']?.toString() ?? remotePeerRole;

    final type = data['type']?.toString();
    if (_peerConnection == null) return;

    if (type == 'join') {
      if (data['cam'] is bool) {
        _signaledRemoteCam = data['cam'] as bool;
        isRemoteVideoAvailable = _signaledRemoteCam;
      }

      _sendSignal({
        'type': 'ready',
        'name': localAuthor,
        'role': localRole,
        'cam': cameraEnabled,
        'mic': micEnabled,
      });

      if (!_isPolitePeer(senderId)) {
        Future.delayed(const Duration(milliseconds: 250), () {
          if (!_isDisposed) _negotiateOffer();
        });
      }
      if (!_isDisposed) onStateChanged();
    } else if (type == 'ready') {
      if (data['cam'] is bool) {
        _signaledRemoteCam = data['cam'] as bool;
        isRemoteVideoAvailable = _signaledRemoteCam;
      }

      if (!_isPolitePeer(senderId)) {
        Future.delayed(const Duration(milliseconds: 250), () {
          if (!_isDisposed) _negotiateOffer();
        });
      }
      if (!_isDisposed) onStateChanged();
    } else if (type == 'offer') {
      final sdp = data['sdp']?.toString();
      if (sdp == null) return;

      final polite = _isPolitePeer(senderId);
      final signalingState = _peerConnection!.signalingState;
      final offerCollision =
          _makingOffer ||
          _isSettingRemoteAnswerPending ||
          (signalingState != null &&
              signalingState != RTCSignalingState.RTCSignalingStateStable);

      _ignoreOffer = !polite && offerCollision;
      if (_ignoreOffer) return;

      try {
        if (offerCollision) {
          await _peerConnection!.setLocalDescription(
            RTCSessionDescription('', 'rollback'),
          );
        }
      } catch (_) {}
      if (_isDisposed) return;

      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(sdp, 'offer'),
      );
      if (_isDisposed) return;

      await _flushPendingCandidates();
      if (_isDisposed) return;

      final answer = await _peerConnection!.createAnswer({
        'offerToReceiveAudio': 1,
        'offerToReceiveVideo': 1,
      });
      if (_isDisposed) return;

      await _peerConnection!.setLocalDescription(answer);
      if (_isDisposed) return;

      _sendSignal({
        'type': 'answer',
        'sdp': answer.sdp,
        'cam': cameraEnabled,
        'mic': micEnabled,
      });
      isRemoteConnected = true;
      onStateChanged();
    } else if (type == 'answer') {
      final sdp = data['sdp']?.toString();
      if (sdp == null) return;
      if (data['cam'] is bool) {
        _signaledRemoteCam = data['cam'] as bool;
        isRemoteVideoAvailable = _signaledRemoteCam;
      }
      try {
        _isSettingRemoteAnswerPending = true;
        await _peerConnection!.setRemoteDescription(
          RTCSessionDescription(sdp, 'answer'),
        );
      } finally {
        _isSettingRemoteAnswerPending = false;
      }
      if (_isDisposed) return;
      await _flushPendingCandidates();
      if (_isDisposed) return;
      isRemoteConnected = true;
      onStateChanged();
    } else if (type == 'candidate') {
      if (_ignoreOffer) return;
      final candMap = data['candidate'] as Map<String, dynamic>?;
      if (candMap == null) return;
      final candidate = RTCIceCandidate(
        candMap['candidate']?.toString(),
        candMap['sdpMid']?.toString(),
        candMap['sdpMLineIndex'] is int
            ? candMap['sdpMLineIndex'] as int
            : int.tryParse(candMap['sdpMLineIndex']?.toString() ?? '0'),
      );
      final remoteDesc = await _peerConnection!.getRemoteDescription();
      if (_isDisposed) return;
      if (remoteDesc != null) {
        try {
          await _peerConnection!.addCandidate(candidate);
        } catch (_) {}
      } else {
        _pendingCandidates.add(candidate);
      }
    } else if (type == 'media_state') {
      if (data['cam'] is bool) {
        _signaledRemoteCam = data['cam'] as bool;
        isRemoteVideoAvailable = _signaledRemoteCam;
      }
      onStateChanged();
    } else if (type == 'chat') {
      final msg = MensajeTeleconsulta(
        citaId: citaId,
        autor: data['autor']?.toString() ?? 'Participante',
        rolAutor: data['rolAutor']?.toString() ?? 'Remoto',
        texto: data['texto']?.toString() ?? '',
        fechaHora:
            DateTime.tryParse(data['fechaHora']?.toString() ?? '') ??
            DateTime.now(),
      );
      onChatMessageReceived(msg);
    } else if (type == 'leave') {
      isRemoteConnected = false;
      isRemoteVideoAvailable = false;
      if (isRemoteRendererInitialized) {
        remoteRenderer.srcObject = null;
      }
      onStateChanged();
    }
  }

  Future<void> _flushPendingCandidates() async {
    if (_isDisposed || _peerConnection == null) return;
    final copy = List<RTCIceCandidate>.from(_pendingCandidates);
    _pendingCandidates.clear();
    for (final c in copy) {
      if (_isDisposed) return;
      try {
        await _peerConnection!.addCandidate(c);
      } catch (_) {}
    }
  }

  Future<void> _negotiateOffer() async {
    if (_isDisposed || _peerConnection == null || _makingOffer) return;
    try {
      _makingOffer = true;
      final offer = await _peerConnection!.createOffer({
        'offerToReceiveAudio': 1,
        'offerToReceiveVideo': 1,
      });
      if (_isDisposed) return;
      await _peerConnection!.setLocalDescription(offer);
      if (_isDisposed) return;
      _sendSignal({
        'type': 'offer',
        'sdp': offer.sdp,
        'cam': cameraEnabled,
        'mic': micEnabled,
      });
    } catch (_) {
    } finally {
      _makingOffer = false;
    }
  }

  void sendChatMessage(MensajeTeleconsulta msg) {
    if (_isDisposed) return;
    final payload = {
      'type': 'chat',
      'autor': msg.autor,
      'rolAutor': msg.rolAutor,
      'texto': msg.texto,
      'fechaHora': msg.fechaHora.toIso8601String(),
    };

    if (_dataChannel != null &&
        _dataChannel!.state == RTCDataChannelState.RTCDataChannelOpen) {
      try {
        _dataChannel!.send(RTCDataChannelMessage(jsonEncode(payload)));
      } catch (_) {}
    }
    _sendSignal(payload);
  }

  void toggleMic(bool enabled) {
    if (_isDisposed) return;
    micEnabled = enabled;
    if (_localStream != null) {
      for (final track in _localStream!.getAudioTracks()) {
        track.enabled = enabled;
      }
    }
    _notifyMediaState();
    onStateChanged();
  }

  void toggleCamera(bool enabled) {
    if (_isDisposed) return;
    cameraEnabled = enabled;
    if (_localStream != null) {
      for (final track in _localStream!.getVideoTracks()) {
        track.enabled = enabled;
      }
    }
    _notifyMediaState();
    onStateChanged();
  }

  Future<void> toggleSpeakerphone(bool enabled) async {
    if (_isDisposed) return;
    speakerphoneEnabled = enabled;
    if (!kIsWeb) {
      try {
        await Helper.setSpeakerphoneOn(enabled);
      } catch (_) {}
    }
    if (_remoteStream != null) {
      for (final track in _remoteStream!.getAudioTracks()) {
        track.enabled = enabled;
      }
    }
    if (!_isDisposed) onStateChanged();
  }

  void _notifyMediaState() {
    if (_isDisposed) return;
    final payload = {
      'type': 'media_state',
      'cam': cameraEnabled,
      'mic': micEnabled,
    };
    if (_dataChannel != null &&
        _dataChannel!.state == RTCDataChannelState.RTCDataChannelOpen) {
      try {
        _dataChannel!.send(RTCDataChannelMessage(jsonEncode(payload)));
      } catch (_) {}
    }
    _sendSignal(payload);
  }

  Future<void> dispose() async {
    if (_isDisposed) return;
    _helloTimer?.cancel();
    _sendSignal({'type': 'leave'});
    _isDisposed = true;
    isLocalVideoReady = false;
    isRemoteConnected = false;
    isRemoteVideoAvailable = false;

    if (kIsWeb) {
      WebSignalingHelper.closeBroadcastChannel(roomId.trim().toUpperCase());
    }
    await _mqttSub?.cancel();
    try {
      _mqttClient?.disconnect();
    } catch (_) {}
    try {
      await _wsChannel?.sink.close();
    } catch (_) {}
    try {
      await _dataChannel?.close();
    } catch (_) {}
    try {
      await _peerConnection?.close();
    } catch (_) {}
    if (_localStream != null) {
      for (final t in _localStream!.getTracks()) {
        await t.stop();
      }
      await _localStream!.dispose();
      _localStream = null;
    }
    if (_remoteStream != null) {
      for (final t in _remoteStream!.getTracks()) {
        await t.stop();
      }
      await _remoteStream!.dispose();
      _remoteStream = null;
    }
    if (_localRendererInitialized) {
      _localRendererInitialized = false;
      try {
        localRenderer.srcObject = null;
        await localRenderer.dispose();
      } catch (_) {}
    }
    if (_remoteRendererInitialized) {
      _remoteRendererInitialized = false;
      try {
        remoteRenderer.srcObject = null;
        await remoteRenderer.dispose();
      } catch (_) {}
    }
  }
}
