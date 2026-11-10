import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../classes/cita_telemedicina.dart';
import '../../classes/mensaje_teleconsulta.dart';
import '../../classes/rol_actor.dart';
import '../../data/cita_repository.dart';
import '../../services/p2p/realtime_p2p_session.dart';

class VideoCallTwoUsersScreen extends StatefulWidget {
  final CitaTelemedicina cita;
  final RolActor rolActual;
  final VoidCallback onConsultaCompletada;

  const VideoCallTwoUsersScreen({
    super.key,
    required this.cita,
    required this.rolActual,
    required this.onConsultaCompletada,
  });

  @override
  State<VideoCallTwoUsersScreen> createState() =>
      _VideoCallTwoUsersScreenState();
}

class _VideoCallTwoUsersScreenState extends State<VideoCallTwoUsersScreen> {
  late TextEditingController _roomCodeCtrl;
  late TextEditingController _agoraAppIdCtrl;
  late TextEditingController _wsSignalingCtrl;
  final TextEditingController _chatInputCtrl = TextEditingController();
  final ScrollController _chatScrollCtrl = ScrollController();

  bool _conectadoEnLlamada = false;
  bool _remotoConectado = false;
  bool _micActivo = true;
  bool _camaraActiva = true;
  bool _altavozActivo = true;
  bool _compartiendoSignos = true;
  bool _inicializandoPreview = false;
  bool _uniendoASala = false;
  int _segundosLlamada = 0;
  int? _remoteUid;
  Timer? _timer;
  Timer? _chatSyncTimer;

  RtcEngine? _agoraEngine;
  RealtimeP2PSession? _webrtcSession;
  List<MensajeTeleconsulta> _mensajesChat = [];

  @override
  void initState() {
    super.initState();
    _roomCodeCtrl = TextEditingController(text: widget.cita.codigoSala);
    _agoraAppIdCtrl = TextEditingController();
    _wsSignalingCtrl = TextEditingController();
    _cargarMensajesSala();
    _prepararHardwareLocal();
  }

  @override
  void didUpdateWidget(covariant VideoCallTwoUsersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cita.id != widget.cita.id) {
      _roomCodeCtrl.text = widget.cita.codigoSala;
      _cargarMensajesSala();
    }
  }

  Future<void> _prepararHardwareLocal() async {
    if (_webrtcSession != null || _inicializandoPreview) return;
    setState(() => _inicializandoPreview = true);

    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      await [Permission.microphone, Permission.camera].request();
    }

    final soyMedico = widget.rolActual == RolActor.medico;
    final nombreLocal =
        soyMedico ? widget.cita.medicoAsignado : widget.cita.nombrePaciente;

    late final RealtimeP2PSession session;
    session = RealtimeP2PSession(
      roomId: _roomCodeCtrl.text.trim().isEmpty
          ? widget.cita.codigoSala
          : _roomCodeCtrl.text.trim(),
      citaId: widget.cita.id,
      localAuthor: nombreLocal,
      localRole: widget.rolActual.etiqueta,
      onStateChanged: () {
        if (mounted && _webrtcSession == session && !session.isDisposed) {
          setState(() {
            _remotoConectado = session.isRemoteConnected;
            _camaraActiva = session.cameraEnabled;
            _micActivo = session.micEnabled;
          });
        }
      },
      onChatMessageReceived: (msg) async {
        await CitaRepository.agregarMensajeSala(msg);
        await _cargarMensajesSala();
        _scrollToBottom();
      },
    );

    _webrtcSession = session;
    await session.initializePreviewOnly();
    if (mounted && _webrtcSession == session && !session.isDisposed) {
      setState(() {
        _inicializandoPreview = false;
        _camaraActiva = session.cameraEnabled;
        _micActivo = session.micEnabled;
      });
    }
  }

  Future<void> _cargarMensajesSala() async {
    final mensajes = await CitaRepository.obtenerMensajesSala(widget.cita.id);
    if (mounted) {
      setState(() => _mensajesChat = mensajes);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _chatSyncTimer?.cancel();
    _cerrarMotoresVideo();
    _roomCodeCtrl.dispose();
    _agoraAppIdCtrl.dispose();
    _wsSignalingCtrl.dispose();
    _chatInputCtrl.dispose();
    _chatScrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _cerrarMotoresVideo() async {
    if (_webrtcSession != null) {
      final oldSession = _webrtcSession;
      _webrtcSession = null;
      await oldSession!.dispose();
    }
    if (_agoraEngine != null) {
      final oldEngine = _agoraEngine;
      _agoraEngine = null;
      await oldEngine!.leaveChannel();
      await oldEngine.release();
    }
  }

  Future<void> _unirseASala() async {
    final codigoLimpio = _roomCodeCtrl.text.trim().toUpperCase();
    if (codigoLimpio.isEmpty) return;
    if (_uniendoASala) return;

    setState(() => _uniendoASala = true);

    try {
      _roomCodeCtrl.text = codigoLimpio;
      widget.cita.codigoSala = codigoLimpio;
      await CitaRepository.guardarCita(widget.cita);

      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS)) {
        await [Permission.microphone, Permission.camera].request();
      }

      final soyMedico = widget.rolActual == RolActor.medico;
      final nombreLocal =
          soyMedico ? widget.cita.medicoAsignado : widget.cita.nombrePaciente;
      final appId = _agoraAppIdCtrl.text.trim();

      if (appId.isNotEmpty) {
        try {
          if (mounted) {
            setState(() {
              _webrtcSession = null;
            });
          }
          await _cerrarMotoresVideo();
          final engine = createAgoraRtcEngine();
          await engine.initialize(
            RtcEngineContext(
              appId: appId,
              channelProfile: ChannelProfileType.channelProfileCommunication,
            ),
          );
          engine.registerEventHandler(
            RtcEngineEventHandler(
              onUserJoined: (connection, remoteUid, elapsed) {
                if (mounted) {
                  setState(() {
                    _remoteUid = remoteUid;
                    _remotoConectado = true;
                  });
                }
              },
              onUserOffline: (connection, remoteUid, reason) {
                if (mounted) {
                  setState(() {
                    _remoteUid = null;
                    _remotoConectado = false;
                  });
                }
              },
            ),
          );
          await engine.enableVideo();
          await engine.enableAudio();
          await engine.startPreview();
          await engine.joinChannel(
            token: '',
            channelId: widget.cita.codigoSala,
            uid: 0,
            options: const ChannelMediaOptions(
              publishCameraTrack: true,
              publishMicrophoneTrack: true,
              autoSubscribeAudio: true,
              autoSubscribeVideo: true,
            ),
          );
          _agoraEngine = engine;
        } catch (_) {
          _agoraEngine = null;
        }
      }

      if (_agoraEngine == null) {
        if (_webrtcSession == null ||
            _webrtcSession!.isDisposed ||
            _webrtcSession!.roomId.toUpperCase() != codigoLimpio) {
          final oldSession = _webrtcSession;
          if (mounted) {
            setState(() {
              _webrtcSession = null;
              _remotoConectado = false;
            });
          } else {
            _webrtcSession = null;
          }
          await Future<void>.delayed(Duration.zero);
          if (oldSession != null) {
            await oldSession.dispose();
          }

          late final RealtimeP2PSession newSession;
          newSession = RealtimeP2PSession(
            roomId: codigoLimpio,
            citaId: widget.cita.id,
            localAuthor: nombreLocal,
            localRole: widget.rolActual.etiqueta,
            onStateChanged: () {
              if (mounted &&
                  _webrtcSession == newSession &&
                  !newSession.isDisposed) {
                setState(() {
                  _remotoConectado = newSession.isRemoteConnected;
                  _camaraActiva = newSession.cameraEnabled;
                  _micActivo = newSession.micEnabled;
                });
              }
            },
            onChatMessageReceived: (msg) async {
              await CitaRepository.agregarMensajeSala(msg);
              await _cargarMensajesSala();
              _scrollToBottom();
            },
          );
          await newSession.initializePreviewOnly();
          if (!mounted) {
            await newSession.dispose();
            return;
          }
          setState(() {
            _webrtcSession = newSession;
          });
        }
        await _webrtcSession!
            .start(wsSignalingUrl: _wsSignalingCtrl.text.trim());
      }

      if (!mounted) return;
      setState(() {
        _conectadoEnLlamada = true;
        _micActivo = _webrtcSession?.micEnabled ?? true;
        _camaraActiva = _webrtcSession?.cameraEnabled ?? true;
      });

      final msgConexion = MensajeTeleconsulta(
        citaId: widget.cita.id,
        autor: nombreLocal,
        rolAutor: widget.rolActual.etiqueta,
        texto: 'Se ha conectado a la sala de videoconferencia $codigoLimpio.',
        fechaHora: DateTime.now(),
      );
      await CitaRepository.agregarMensajeSala(msgConexion);
      _webrtcSession?.sendChatMessage(msgConexion);
      await _cargarMensajesSala();

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() => _segundosLlamada++);
        }
      });

      _chatSyncTimer?.cancel();
      _chatSyncTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        _cargarMensajesSala();
      });
    } finally {
      if (mounted) {
        setState(() => _uniendoASala = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollCtrl.hasClients) {
        _chatScrollCtrl.animateTo(
          _chatScrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _colgarLlamada() async {
    _timer?.cancel();
    _chatSyncTimer?.cancel();
    final oldSession = _webrtcSession;
    final oldEngine = _agoraEngine;
    setState(() {
      _webrtcSession = null;
      _agoraEngine = null;
      _conectadoEnLlamada = false;
      _remotoConectado = false;
      _segundosLlamada = 0;
    });
    await Future<void>.delayed(Duration.zero);
    if (oldSession != null) {
      await oldSession.dispose();
    }
    if (oldEngine != null) {
      await oldEngine.leaveChannel();
      await oldEngine.release();
    }
    widget.onConsultaCompletada();
    await _prepararHardwareLocal();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Teleconsulta finalizada y registrada en el expediente clínico. Puede proceder con la emisión de recetas y órdenes.',
        ),
      ),
    );
  }

  Future<void> _enviarMensaje(String nombreLocal) async {
    final texto = _chatInputCtrl.text.trim();
    if (texto.isEmpty) return;
    _chatInputCtrl.clear();

    final msg = MensajeTeleconsulta(
      citaId: widget.cita.id,
      autor: nombreLocal,
      rolAutor: widget.rolActual.etiqueta,
      texto: texto,
      fechaHora: DateTime.now(),
    );
    await CitaRepository.agregarMensajeSala(msg);
    _webrtcSession?.sendChatMessage(msg);
    await _cargarMensajesSala();
    _scrollToBottom();
  }

  String _formatearTiempo(int totalSegundos) {
    final min = (totalSegundos ~/ 60).toString().padLeft(2, '0');
    final seg = (totalSegundos % 60).toString().padLeft(2, '0');
    return '$min:$seg';
  }

  Widget _buildRemoteVideoView(bool soyMedico, String nombreRemoto) {
    if (_agoraEngine != null && _remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _agoraEngine!,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: widget.cita.codigoSala),
        ),
      );
    }

    final session = _webrtcSession;
    final isRemoteStreamReady = session != null &&
        !session.isDisposed &&
        session.isRemoteRendererInitialized &&
        _remotoConectado &&
        session.remoteRenderer.srcObject != null;
    final isVideoEnabled =
        isRemoteStreamReady && session.isRemoteVideoAvailable;

    if (isRemoteStreamReady) {
      return Stack(
        fit: StackFit.expand,
        children: [
          RTCVideoView(
            session.remoteRenderer,
            key: ValueKey('remote_${session.peerId}_${session.remoteRenderer.textureId}'),
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          ),
          if (!isVideoEnabled)
            Container(
              color: const Color(0xFF101820),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 54,
                    backgroundColor: Colors.white24,
                    child: Icon(
                      soyMedico ? Icons.person : Icons.medical_information,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    session.remotePeerName ?? nombreRemoto,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Audio conectado - Cámara remota desactivada',
                    style: TextStyle(color: Colors.amberAccent, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Cédula verificada: ${widget.cita.cedula} | ${widget.cita.ars}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  if (_compartiendoSignos) ...[
                    const SizedBox(height: 18),
                    _buildSignosOverlay(),
                  ],
                ],
              ),
            ),
          if (isVideoEnabled && _compartiendoSignos)
            Positioned(
              top: 14,
              left: 14,
              right: 14,
              child: _buildSignosOverlay(),
            ),
          if (isVideoEnabled)
            Positioned(
              left: 16,
              bottom: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.fiber_manual_record,
                        color: Colors.greenAccent, size: 12),
                    const SizedBox(width: 6),
                    Text(
                      session.remotePeerName ?? nombreRemoto,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            Text(
              'Esperando al participante remoto en la sala "${widget.cita.codigoSala}"...',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Comparte el código "${widget.cita.codigoSala}" con el médico o paciente. Funciona entre distintos navegadores, celulares o computadoras remotas conectadas a Internet.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignosOverlay() {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        Chip(
          avatar: const Icon(Icons.favorite, color: Colors.red, size: 18),
          label: Text('FC: ${widget.cita.frecuenciaCardiaca} bpm'),
        ),
        Chip(
          avatar: const Icon(Icons.speed, color: Colors.blue, size: 18),
          label: Text('PA: ${widget.cita.presionArterial} mmHg'),
        ),
        Chip(
          avatar: const Icon(Icons.air, color: Colors.teal, size: 18),
          label: Text('SpO2: ${widget.cita.saturacionOxigeno}%'),
        ),
        Chip(
          avatar: const Icon(Icons.thermostat, color: Colors.orange, size: 18),
          label: Text(
            'Temp: ${widget.cita.temperaturaCorporal.toStringAsFixed(1)} °C',
          ),
        ),
      ],
    );
  }

  Widget _buildLocalPreviewCard(String nombreLocal) {
    if (_agoraEngine != null && _camaraActiva) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AgoraVideoView(
          controller: VideoViewController(
            rtcEngine: _agoraEngine!,
            canvas: const VideoCanvas(uid: 0),
          ),
        ),
      );
    }

    final session = _webrtcSession;
    final isLocalStreamReady = session != null &&
        !session.isDisposed &&
        session.isLocalRendererInitialized &&
        session.isLocalVideoReady &&
        session.localRenderer.srcObject != null;

    if (isLocalStreamReady) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            RTCVideoView(
              session.localRenderer,
              key: ValueKey('local_${session.peerId}_${session.localRenderer.textureId}'),
              mirror: true,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
            if (!_camaraActiva)
              Container(
                color: Colors.grey[900],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.videocam_off,
                        color: Colors.white, size: 32),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        'Tú ($nombreLocal)',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (_camaraActiva)
              Positioned(
                left: 6,
                right: 6,
                bottom: 4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _micActivo ? Icons.mic : Icons.mic_off,
                        color: _micActivo
                            ? Colors.greenAccent
                            : Colors.redAccent,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Tú ($nombreLocal)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          _camaraActiva ? Icons.videocam : Icons.videocam_off,
          color: Colors.white,
          size: 32,
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            'Tú ($nombreLocal)',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectingScreen(String nombreLocal) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 320,
            height: 240,
            decoration: BoxDecoration(
              color: const Color(0xFF101820),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF005A9C), width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF005A9C).withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: _buildLocalPreviewCard(nombreLocal),
          ),
          const SizedBox(height: 40),
          const CircularProgressIndicator(
            color: Color(0xFF005A9C),
            strokeWidth: 3,
          ),
          const SizedBox(height: 24),
          const Text(
            'Uniéndose a la sala...',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Estableciendo conexión encriptada de audio y video P2P.',
            style: TextStyle(fontSize: 15, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final soyMedico = widget.rolActual == RolActor.medico;
    final nombreLocal =
        soyMedico ? widget.cita.medicoAsignado : widget.cita.nombrePaciente;
    final nombreRemoto =
        soyMedico ? widget.cita.nombrePaciente : widget.cita.medicoAsignado;
    final isWide = MediaQuery.of(context).size.width >= 950;

    if (_uniendoASala) {
      return _buildConnectingScreen(nombreLocal);
    }

    if (!_conectadoEnLlamada) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.videocam_rounded,
                          size: 36,
                          color: Color(0xFF005A9C),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            'Sala de Teleconsulta Remota P2P',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Conexión de video y voz en tiempo real entre dispositivos remotos o pestañas para el expediente ${widget.cita.id}.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 230,
                      decoration: BoxDecoration(
                        color: const Color(0xFF101820),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.blueGrey.shade700),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_inicializandoPreview)
                            const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(color: Colors.white),
                                SizedBox(height: 10),
                                Text(
                                  'Inicializando cámara y micrófono...',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            )
                          else
                            _buildLocalPreviewCard(nombreLocal),
                          Positioned(
                            bottom: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () {
                                      setState(() => _micActivo = !_micActivo);
                                      _webrtcSession?.toggleMic(_micActivo);
                                    },
                                    icon: Icon(
                                      _micActivo ? Icons.mic : Icons.mic_off,
                                      color: _micActivo
                                          ? Colors.white
                                          : Colors.redAccent,
                                    ),
                                    tooltip: 'Probar Micrófono',
                                  ),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () {
                                      setState(
                                          () => _camaraActiva = !_camaraActiva);
                                      _webrtcSession
                                          ?.toggleCamera(_camaraActiva);
                                    },
                                    icon: Icon(
                                      _camaraActiva
                                          ? Icons.videocam
                                          : Icons.videocam_off,
                                      color: _camaraActiva
                                          ? Colors.white
                                          : Colors.redAccent,
                                    ),
                                    tooltip: 'Probar Cámara',
                                  ),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () =>
                                        _webrtcSession?.switchCamera(),
                                    icon: const Icon(
                                      Icons.cameraswitch,
                                      color: Colors.white,
                                    ),
                                    tooltip: 'Cambiar Cámara',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_webrtcSession?.mediaErrorMessage != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.orange.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: Colors.deepOrange),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _webrtcSession!.mediaErrorMessage!,
                                style: const TextStyle(fontSize: 12.5),
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                final oldSession = _webrtcSession;
                                setState(() {
                                  _webrtcSession = null;
                                });
                                await Future<void>.delayed(Duration.zero);
                                if (oldSession != null) {
                                  await oldSession.dispose();
                                }
                                await _prepararHardwareLocal();
                              },
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if ((_webrtcSession?.videoDevices.length ?? 0) > 1 ||
                        (_webrtcSession?.audioInputDevices.length ?? 0) >
                            1) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if ((_webrtcSession?.videoDevices.length ?? 0) > 1)
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _webrtcSession!.videoDevices.any(
                                        (d) =>
                                            d.deviceId ==
                                            _webrtcSession!
                                                .selectedVideoDeviceId)
                                    ? _webrtcSession!.selectedVideoDeviceId
                                    : null,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Cámara de Video',
                                  prefixIcon: Icon(Icons.camera_alt_outlined),
                                  isDense: true,
                                ),
                                items: _webrtcSession!.videoDevices
                                    .map(
                                      (d) => DropdownMenuItem(
                                        value: d.deviceId,
                                        child: Text(
                                          d.label.isNotEmpty
                                              ? d.label
                                              : 'Cámara ${d.deviceId}',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    _webrtcSession?.selectVideoDevice(val);
                                  }
                                },
                              ),
                            ),
                          if ((_webrtcSession?.videoDevices.length ?? 0) > 1 &&
                              (_webrtcSession?.audioInputDevices.length ?? 0) >
                                  1)
                            const SizedBox(width: 10),
                          if ((_webrtcSession?.audioInputDevices.length ?? 0) >
                              1)
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _webrtcSession!.audioInputDevices
                                        .any((d) =>
                                            d.deviceId ==
                                            _webrtcSession!
                                                .selectedAudioDeviceId)
                                    ? _webrtcSession!.selectedAudioDeviceId
                                    : null,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Micrófono',
                                  prefixIcon: Icon(Icons.mic_none),
                                  isDense: true,
                                ),
                                items: _webrtcSession!.audioInputDevices
                                    .map(
                                      (d) => DropdownMenuItem(
                                        value: d.deviceId,
                                        child: Text(
                                          d.label.isNotEmpty
                                              ? d.label
                                              : 'Micrófono ${d.deviceId}',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    _webrtcSession?.selectAudioDevice(val);
                                  }
                                },
                              ),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextField(
                      controller: _roomCodeCtrl,
                      decoration: InputDecoration(
                        labelText:
                            'Código de Sala Clínica (Compartir con el otro participante)',
                        prefixIcon: const Icon(Icons.meeting_room),
                        suffixIcon: IconButton(
                          tooltip: 'Copiar código de sala',
                          icon: const Icon(Icons.copy),
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: _roomCodeCtrl.text.trim()),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Código de sala copiado al portapapeles'),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: const Text(
                        'Configuración Avanzada de Red (Señalización Cloud Automática Activa)',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      children: [
                        const SizedBox(height: 6),
                        TextField(
                          controller: _wsSignalingCtrl,
                          decoration: const InputDecoration(
                            labelText:
                                'Servidor WebSocket Adicional (Opcional)',
                            hintText:
                                'Vacío = Broker Cloud EMQX WSS + STUN/TURN automático',
                            prefixIcon: Icon(Icons.hub_outlined),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _agoraAppIdCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Agora RTC App ID (Opcional)',
                            hintText:
                                'Dejar vacío para usar motor WebRTC P2P con STUN/TURN',
                            prefixIcon: Icon(Icons.settings_input_antenna),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Participante local: $nombreLocal (${widget.rolActual.etiqueta})',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                              'Señalización Remota: Cloud MQTT over WSS + TURN Relay Activo'),
                          Text(
                            'Servicio: ${widget.cita.especialidad} | ${widget.cita.ars}',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1E9E6A),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _unirseASala,
                      icon: const Icon(Icons.video_call),
                      label: const Text(
                        'Entrar a la Sala de Videoconferencia Ahora',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final videoPanel = Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: _buildRemoteVideoView(soyMedico, nombreRemoto),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: Container(
            width: 195,
            height: 140,
            decoration: BoxDecoration(
              color:
                  _camaraActiva ? const Color(0xFF005A9C) : Colors.grey[900],
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [
                BoxShadow(color: Colors.black45, blurRadius: 8),
              ],
            ),
            child: _buildLocalPreviewCard(nombreLocal),
          ),
        ),
      ],
    );

    final chatYControlesPanel = Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: const Row(
              children: [
                Icon(Icons.chat_outlined, size: 18, color: Color(0xFF005A9C)),
                SizedBox(width: 8),
                Text(
                  'Bitácora y Mensajería de Teleconsulta en Vivo',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _chatScrollCtrl,
              padding: const EdgeInsets.all(14),
              itemCount: _mensajesChat.length,
              itemBuilder: (context, index) {
                final msg = _mensajesChat[index];
                final esMio = msg.autor == nombreLocal;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Align(
                    alignment:
                        esMio ? Alignment.centerRight : Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: esMio
                              ? const Color(0xFF005A9C).withValues(alpha: 0.1)
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: esMio
                                ? const Color(0xFF005A9C).withValues(alpha: 0.3)
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${msg.autor} (${msg.rolAutor})',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Color(0xFF005A9C),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              msg.texto,
                              style: const TextStyle(fontSize: 13.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatInputCtrl,
                    onSubmitted: (_) => _enviarMensaje(nombreLocal),
                    decoration: const InputDecoration(
                      hintText:
                          'Escribir nota clínica o mensaje en la sesión...',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: () => _enviarMensaje(nombreLocal),
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Wrap(
              spacing: 10,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                IconButton.filledTonal(
                  style: IconButton.styleFrom(
                    backgroundColor:
                        _micActivo ? null : Colors.red.withValues(alpha: 0.18),
                  ),
                  onPressed: () {
                    setState(() => _micActivo = !_micActivo);
                    _webrtcSession?.toggleMic(_micActivo);
                    _agoraEngine?.muteLocalAudioStream(!_micActivo);
                  },
                  icon: Icon(
                    _micActivo ? Icons.mic : Icons.mic_off,
                    color: _micActivo ? null : Colors.red[800],
                  ),
                  tooltip: 'Silenciar / Activar Micrófono',
                ),
                IconButton.filledTonal(
                  style: IconButton.styleFrom(
                    backgroundColor: _camaraActiva
                        ? null
                        : Colors.red.withValues(alpha: 0.18),
                  ),
                  onPressed: () {
                    setState(() => _camaraActiva = !_camaraActiva);
                    _webrtcSession?.toggleCamera(_camaraActiva);
                    _agoraEngine?.muteLocalVideoStream(!_camaraActiva);
                  },
                  icon: Icon(
                    _camaraActiva ? Icons.videocam : Icons.videocam_off,
                    color: _camaraActiva ? null : Colors.red[800],
                  ),
                  tooltip: 'Encender / Apagar Cámara',
                ),
                IconButton.filledTonal(
                  onPressed: () {
                    _webrtcSession?.switchCamera();
                    _agoraEngine?.switchCamera();
                  },
                  icon: const Icon(Icons.cameraswitch),
                  tooltip: 'Cambiar Cámara',
                ),
                IconButton.filledTonal(
                  style: IconButton.styleFrom(
                    backgroundColor: _altavozActivo
                        ? null
                        : Colors.orange.withValues(alpha: 0.2),
                  ),
                  onPressed: () {
                    setState(() => _altavozActivo = !_altavozActivo);
                    _webrtcSession?.toggleSpeakerphone(_altavozActivo);
                    _agoraEngine?.muteAllRemoteAudioStreams(!_altavozActivo);
                  },
                  icon: Icon(
                    _altavozActivo ? Icons.volume_up : Icons.volume_off,
                    color: _altavozActivo ? null : Colors.orange[900],
                  ),
                  tooltip: 'Activar / Silenciar Audio Remoto',
                ),
                IconButton.filledTonal(
                  onPressed: () => setState(
                      () => _compartiendoSignos = !_compartiendoSignos),
                  icon: const Icon(Icons.monitor_heart),
                  tooltip: 'Mostrar / Ocultar Telemetría de Signos Vitales',
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red[700],
                  ),
                  onPressed: _colgarLlamada,
                  icon: const Icon(Icons.call_end),
                  label: const Text('Concluir Teleconsulta'),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Column(
      children: [
        Container(
          color: Colors.black87,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Icon(
                Icons.fiber_manual_record,
                color: Colors.redAccent,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'SESIÓN ACTIVA | ${_formatearTiempo(_segundosLlamada)} | Sala: ${widget.cita.codigoSala} | Exp: ${widget.cita.id}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Chip(
                backgroundColor:
                    _remotoConectado ? Colors.green[700] : Colors.orange[700],
                label: Text(
                  _remotoConectado
                      ? '2/2 Conectados en Vivo (Audio/Video)'
                      : '1/2 Esperando par remoto en ${widget.cita.codigoSala}...',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: isWide
              ? Row(
                  children: [
                    Expanded(flex: 7, child: videoPanel),
                    Expanded(flex: 5, child: chatYControlesPanel),
                  ],
                )
              : Column(
                  children: [
                    Expanded(flex: 3, child: videoPanel),
                    Expanded(flex: 2, child: chatYControlesPanel),
                  ],
                ),
        ),
      ],
    );
  }
}