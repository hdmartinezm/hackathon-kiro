import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../models/audio_result.dart';
import '../config/app_config.dart';

class AudioScreen extends StatefulWidget {
  const AudioScreen({super.key});

  @override
  State<AudioScreen> createState() => _AudioScreenState();
}

class _AudioScreenState extends State<AudioScreen> {
  final AudioService _audioService = AudioService();
  bool _isRecording = false;
  bool _isProcessing = false;
  int _countdown = AppConfig.recordingDurationSeconds;
  String _statusMessage = 'Presiona para grabar el llanto de tu bebé';

  Future<void> _startRecording() async {
    setState(() {
      _isRecording = true;
      _countdown = AppConfig.recordingDurationSeconds;
      _statusMessage = 'Grabando...';
    });

    try {
      await _audioService.startRecording();
      _startCountdown();
    } catch (e) {
      setState(() {
        _isRecording = false;
        _statusMessage = 'Error al iniciar grabación: $e';
      });
    }
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || !_isRecording) return false;
      setState(() {
        _countdown--;
      });
      if (_countdown <= 0) {
        _stopAndAnalyze();
        return false;
      }
      return true;
    });
  }

  Future<void> _stopAndAnalyze() async {
    setState(() {
      _isRecording = false;
      _isProcessing = true;
      _statusMessage = 'Procesando audio...';
    });

    try {
      final audioData = await _audioService.stopRecording();

      if (audioData == null || audioData.isEmpty) {
        setState(() {
          _isProcessing = false;
          _statusMessage = 'No se pudo grabar audio. Intente de nuevo.';
        });
        return;
      }

      setState(() {
        _statusMessage = 'Analizando llanto...';
      });

      final result = await _audioService.analyzeAudio(audioData);

      if (mounted) {
        Navigator.pushNamed(context, '/audio-result', arguments: result);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error: $e';
        });
        _showErrorDialog('Error al analizar audio: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Análisis de Audio'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Countdown circle
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isRecording
                      ? Colors.red.withOpacity(0.1)
                      : const Color(0xFF9C27B0).withOpacity(0.1),
                  border: Border.all(
                    color: _isRecording
                        ? Colors.red
                        : const Color(0xFF9C27B0),
                    width: 4,
                  ),
                ),
                child: Center(
                  child: _isProcessing
                      ? const CircularProgressIndicator()
                      : _isRecording
                          ? Text(
                              '$_countdown',
                              style: const TextStyle(
                                fontSize: 72,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            )
                          : Icon(
                              Icons.mic,
                              size: 80,
                              color: const Color(0xFF9C27B0),
                            ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 48),
              if (!_isRecording && !_isProcessing)
                ElevatedButton.icon(
                  onPressed: _startRecording,
                  icon: const Icon(Icons.mic),
                  label: const Text('Iniciar Grabación'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9C27B0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
              if (_isRecording)
                ElevatedButton.icon(
                  onPressed: _stopAndAnalyze,
                  icon: const Icon(Icons.stop),
                  label: const Text('Detener'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                  ),
                ),
              const SizedBox(height: 24),
              Text(
                'La grabación dura ${AppConfig.recordingDurationSeconds} segundos',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
