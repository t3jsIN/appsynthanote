// voice_recorder.dart - FIXED VERSION - Restoring working functionality
// ignore_for_file: avoid_web_libraries_in_flutter

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:math' show Random, sin, pi;
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:async';
import 'models.dart';
import 'firebase_service.dart';

// REAL Voice Recorder Widget - FIXED
class VoiceRecorderWidget extends StatefulWidget {
  final Function(VoiceNote) onVoiceNoteSaved;

  const VoiceRecorderWidget({
    super.key,
    required this.onVoiceNoteSaved,
  });

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget>
    with TickerProviderStateMixin {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isRecording = false;
  bool _isPlaying = false;
  String? _recordingPath;
  Duration _recordingDuration = Duration.zero;
  bool _isDisposed = false;

  // Web Audio API
  html.MediaRecorder? _mediaRecorder;
  final List<html.Blob> _recordedChunks = [];
  html.MediaStream? _mediaStream;

  // Waveform animation
  late AnimationController _waveController;
  final List<double> _waveformData = [];

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _waveController.dispose();
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    if (kIsWeb) {
      _mediaStream?.getTracks().forEach((track) => track.stop());
    }
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      // Unlock audio context for iOS FIRST
      if (kIsWeb) {
        await _unlockAudioContext();
      }

      // Request microphone permission
      if (!kIsWeb) {
        if (await Permission.microphone.request() != PermissionStatus.granted) {
          _showPermissionError();
          return;
        }
      }

      if (kIsWeb) {
        await _startWebRecording();
      } else {
        await _startMobileRecording();
      }

      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
        _waveformData.clear();
      });

      _startDurationTimer();
      _startWaveformAnimation();
    } catch (e) {
      _showRecordingError();
    }
  }

  Future<void> _unlockAudioContext() async {
    try {
      final audio = html.AudioElement();
      audio.src =
          'data:audio/wav;base64,UklGRigAAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQAAAAA=';
      await audio.play();
      audio.pause();
    } catch (e) {
      print('Audio context unlock failed: $e');
    }
  }

  Future<void> _startWebRecording() async {
    try {
      _mediaStream = await html.window.navigator.mediaDevices?.getUserMedia({
        'audio': {
          'echoCancellation': false,
          'noiseSuppression': false,
          'autoGainControl': false,
        }
      });

      if (_mediaStream == null) {
        throw Exception('Could not access microphone');
      }

      _recordedChunks.clear();

      // Safari-compatible codec selection
      final options = <String, dynamic>{};
      if (html.MediaRecorder.isTypeSupported('audio/webm;codecs=opus')) {
        options['mimeType'] = 'audio/webm;codecs=opus';
      } else if (html.MediaRecorder.isTypeSupported('audio/mp4')) {
        options['mimeType'] = 'audio/mp4';
      } else {
        options['mimeType'] = 'audio/webm';
      }

      _mediaRecorder = html.MediaRecorder(_mediaStream!, options);

      _mediaRecorder!.addEventListener('dataavailable', (event) {
        final data = (event as html.BlobEvent).data;
        if (data != null && data.size > 0) {
          _recordedChunks.add(data);
        }
      });

      _mediaRecorder!.start(100);
    } catch (e) {
      throw e;
    }
  }

  Future<void> _startMobileRecording() async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final Directory voiceDir = Directory('${appDocDir.path}/voice_notes');
    if (!await voiceDir.exists()) {
      await voiceDir.create(recursive: true);
    }

    final String filePath = path.join(
      voiceDir.path,
      'voice_${DateTime.now().millisecondsSinceEpoch}.m4a',
    );

    await _audioRecorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: filePath,
    );

    _recordingPath = filePath;
  }

  Future<void> _stopRecording() async {
    try {
      setState(() {
        _isRecording = false;
      });

      if (kIsWeb) {
        await _stopWebRecording();
      } else {
        await _stopMobileRecording();
      }

      // AUTO-SAVE the recording immediately
      _autoSave();
    } catch (e) {
      print('Stop recording error: $e');
    }
  }

  Future<void> _stopWebRecording() async {
    if (_mediaRecorder != null) {
      final completer = Completer<void>();

      _mediaRecorder!.addEventListener('stop', (event) {
        completer.complete();
      });

      _mediaRecorder!.stop();
      _mediaStream?.getTracks().forEach((track) => track.stop());

      await completer.future.timeout(const Duration(seconds: 5));

      if (_recordedChunks.isNotEmpty) {
        final blob = html.Blob(_recordedChunks);
        await _convertBlobToDataUrl(blob);
      }
    }
  }

  Future<void> _convertBlobToDataUrl(html.Blob blob) async {
    try {
      final audioBlob = html.Blob(_recordedChunks, 'audio/webm');
      final reader = html.FileReader();
      final completer = Completer<String>();

      reader.onLoad.listen((e) {
        final dataUrl = reader.result as String;
        completer.complete(dataUrl);
      });

      reader.onError.listen((e) {
        completer.completeError('FileReader error');
      });

      reader.readAsDataUrl(audioBlob);

      final dataUrl = await completer.future;
      _recordingPath = dataUrl; // Store the data URL directly
      print('✅ Recording stored as data URL: ${dataUrl.substring(0, 50)}...');
    } catch (e) {
      print('❌ Error converting blob: $e');
    }
  }

  Future<void> _stopMobileRecording() async {
    final recordedPath = await _audioRecorder.stop();
    _recordingPath = recordedPath;
  }

  void _startWaveformAnimation() {
    Future.doWhile(() async {
      if (!_isRecording || _isDisposed) return false;

      if (mounted) {
        setState(() {
          double audioLevel = _getCurrentAudioLevel();
          _waveformData.add(audioLevel);

          if (_waveformData.length > 40) {
            _waveformData.removeAt(0);
          }
        });
      }

      await Future.delayed(const Duration(milliseconds: 80));
      return _isRecording && !_isDisposed;
    });
  }

  double _getCurrentAudioLevel() {
    if (!_isRecording) return 0.1;

    final random = Random();
    double baseLevel = 0.3;
    double variation = random.nextDouble() * 0.7;

    int timeMs = DateTime.now().millisecondsSinceEpoch;
    double wave = (timeMs % 1000) / 1000.0;
    double naturalVariation = (sin(wave * 2 * pi) + 1) / 4;

    return (baseLevel + variation + naturalVariation).clamp(0.1, 1.0);
  }

  void _startDurationTimer() {
    Future.doWhile(() async {
      if (!_isRecording || _isDisposed) return false;

      if (mounted) {
        setState(() {
          _recordingDuration =
              _recordingDuration + const Duration(milliseconds: 100);
        });
      }

      await Future.delayed(const Duration(milliseconds: 100));
      return _isRecording && !_isDisposed;
    });
  }

  // FIXED AUTO-SAVE - This was missing!
  void _autoSave() {
    if (_recordingPath != null) {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      final voiceNote = VoiceNote(
        id: timestamp,
        filePath: _recordingPath!,
        title: 'Voice ${timestamp.substring(timestamp.length - 3)}',
        createdAt: DateTime.now(),
        durationMs: _recordingDuration.inMilliseconds,
      );

      // CALL THE CALLBACK TO SAVE THE VOICE NOTE
      widget.onVoiceNoteSaved(voiceNote);

      // Reset state but keep the recording for playback
      setState(() {
        // DON'T clear _recordingPath here - keep it for playback!
        if (kIsWeb) {
          _recordedChunks.clear();
        }
      });

      _showSuccessMessage();
    }
  }

  void _playDataUrl(String dataUrl) {
    try {
      final audio = html.AudioElement()..src = dataUrl;

      audio.onCanPlay.listen((_) {
        audio.play().then((_) {
          setState(() {
            _isPlaying = true;
          });
        });
      });

      audio.onEnded.listen((_) {
        setState(() {
          _isPlaying = false;
        });
      });

      audio.load();
    } catch (e) {
      print('Playback error: $e');
    }
  }

  Future<void> _playRecording() async {
    if (_recordingPath == null) return;

    try {
      if (_isPlaying) {
        await _audioPlayer.stop();
        setState(() {
          _isPlaying = false;
        });
        return;
      }

      if (kIsWeb &&
          (_recordingPath!.startsWith('blob:') ||
              _recordingPath!.startsWith('data:'))) {
        _playDataUrl(_recordingPath!);
      } else {
        if (kIsWeb) {
          await _audioPlayer.setUrl(_recordingPath!);
        } else {
          await _audioPlayer.setFilePath(_recordingPath!);
        }

        await _audioPlayer.play();

        setState(() {
          _isPlaying = true;
        });

        _audioPlayer.playerStateStream.listen((state) {
          if (mounted && !_isDisposed) {
            if (state.processingState == ProcessingState.completed) {
              setState(() {
                _isPlaying = false;
              });
            }
          }
        });
      }
    } catch (e) {
      setState(() {
        _isPlaying = false;
      });
      _showPlaybackError();
    }
  }

  Widget _buildWaveform() {
    if (_waveformData.isEmpty && !_isRecording && _recordingPath == null) {
      return const SizedBox(height: 40);
    }

    List<double> displayData = _waveformData.isEmpty
        ? List.generate(20, (index) => 0.2)
        : _waveformData;

    return SizedBox(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: displayData.asMap().entries.map((entry) {
          double value = entry.value;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 1),
            width: 2,
            height: 40 * value.clamp(0.1, 1.0),
            decoration: BoxDecoration(
              color: _isRecording
                  ? const Color(0xFFD4AF37)
                  : const Color(0xFF90EE90),
              borderRadius: BorderRadius.circular(1),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  void _showPermissionError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Microphone permission required to record audio'),
        backgroundColor: Color(0xFFFF6B6B),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showRecordingError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Failed to start recording. Please try again.'),
        backgroundColor: Color(0xFFFF6B6B),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showPlaybackError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Playback failed. Audio file may be corrupted.'),
        backgroundColor: Color(0xFFFF6B6B),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Voice note saved successfully!'),
        backgroundColor: Color(0xFF34C759),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Waveform display container
          if (_isRecording || _recordingPath != null) ...[
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5C97E),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  // Play/Pause button (only when recording is done)
                  if (_recordingPath != null && !_isRecording)
                    GestureDetector(
                      onTap: _playRecording,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          color: Color(0xFF121212),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: const Color(0xFFF8F8F8),
                          size: 20,
                        ),
                      ),
                    ),

                  if (_recordingPath != null && !_isRecording)
                    const SizedBox(width: 12),

                  // Timer
                  Text(
                    _formatDuration(_recordingDuration),
                    style: const TextStyle(
                      color: Color(0xFF121212),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Waveform visualization
                  Expanded(child: _buildWaveform()),

                  // Volume icon
                  const Icon(
                    Icons.volume_up,
                    color: Color(0xFF121212),
                    size: 18,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Stop/Delete button
              if (_isRecording || _recordingPath != null)
                GestureDetector(
                  onTap: () {
                    if (_isRecording) {
                      _stopRecording();
                    } else {
                      setState(() {
                        _recordingPath = null;
                        _recordingDuration = Duration.zero;
                        _waveformData.clear();
                        if (kIsWeb) {
                          _recordedChunks.clear();
                        }
                      });
                    }
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF6B6B),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isRecording ? Icons.stop : Icons.delete_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),

              if (_isRecording || _recordingPath != null)
                const SizedBox(width: 20),

              // Record button
              GestureDetector(
                onTap: _isRecording ? null : _startRecording,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _isRecording
                        ? const Color(0xFFFF6B6B)
                        : const Color(0xFFD4AF37),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mic,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Voice Note Player Widget - WORKING VERSION
class VoiceNotePlayerWidget extends StatefulWidget {
  final VoiceNote voiceNote;
  final VoidCallback onDelete;

  const VoiceNotePlayerWidget({
    super.key,
    required this.voiceNote,
    required this.onDelete,
  });

  @override
  State<VoiceNotePlayerWidget> createState() => _VoiceNotePlayerWidgetState();
}

class _VoiceNotePlayerWidgetState extends State<VoiceNotePlayerWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    _audioPlayer.dispose();
    super.dispose();
  }

  void _playDataUrlInPlayer(String dataUrl) {
    try {
      final audio = html.AudioElement()..src = dataUrl;

      audio.onCanPlay.listen((_) {
        audio.play().then((_) {
          setState(() {
            _isPlaying = true;
          });
        });
      });

      audio.onEnded.listen((_) {
        setState(() {
          _isPlaying = false;
        });
      });

      audio.onError.listen((e) {
        setState(() {
          _isPlaying = false;
        });
      });

      audio.load();
    } catch (e) {
      print('Playback error: $e');
    }
  }

  Future<void> _playPause() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.stop();
        setState(() {
          _isPlaying = false;
        });
        return;
      }

      final filePath = widget.voiceNote.filePath;

      // MOBILE-SPECIFIC AUDIO HANDLING
      if (kIsWeb) {
        if (filePath.startsWith('data:')) {
          // Use HTML5 Audio for data URLs on mobile
          await _playDataUrlMobile(filePath);
        } else if (filePath.startsWith('blob:')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Recording expired. Please record again.'),
              backgroundColor: Color(0xFFFF6B6B),
            ),
          );
          return;
        } else if (filePath.startsWith('https://')) {
          // Firebase URLs
          await _audioPlayer.setUrl(filePath);
          await _audioPlayer.play();
          setState(() {
            _isPlaying = true;
          });
        }
      } else {
        // Mobile native file playback
        final file = File(filePath);
        if (await file.exists()) {
          await _audioPlayer.setFilePath(filePath);
          await _audioPlayer.play();
          setState(() {
            _isPlaying = true;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Audio file not found'),
              backgroundColor: Color(0xFFFF6B6B),
            ),
          );
          return;
        }
      }

      // Listen for completion
      _audioPlayer.playerStateStream.listen((state) {
        if (mounted &&
            !_isDisposed &&
            state.processingState == ProcessingState.completed) {
          setState(() {
            _isPlaying = false;
          });
        }
      });
    } catch (e) {
      print('Playback error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Playback failed. Try recording again.'),
          backgroundColor: Color(0xFFFF6B6B),
        ),
      );
    }
  }

// ADD this new method for mobile data URL playback:
// In voice_recorder.dart, REPLACE the _playDataUrlMobile method:

  Future<void> _playDataUrlMobile(String dataUrl) async {
    try {
      final audio = html.AudioElement();

      // iOS Safari requirements
      audio.preload = 'auto';
      audio.setAttribute('playsinline', 'true');
      audio.setAttribute('webkit-playsinline', 'true');
      audio.crossOrigin = 'anonymous';
      audio.controls = false;

      // Set source and load
      audio.src = dataUrl;
      audio.load();

      // Wait for load then play
      await Future.delayed(const Duration(milliseconds: 300));

      try {
        await audio.play();
        setState(() {
          _isPlaying = true;
        });

        audio.onEnded.listen((_) {
          setState(() {
            _isPlaying = false;
          });
        });
      } catch (playError) {
        print('iOS play error: $playError');
        throw Exception('iOS audio not supported');
      }
    } catch (e) {
      print('Mobile audio error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Audio not supported on this browser'),
          backgroundColor: Color(0xFFFF6B6B),
        ),
      );
    }
  }

  String _formatDuration(int milliseconds) {
    Duration duration = Duration(milliseconds: milliseconds);
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5C97E),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          // Play/Pause Button
          GestureDetector(
            onTap: _playPause,
            onLongPress: _playPause, // Add long press for mobile
            behavior: HitTestBehavior.opaque, // Better touch handling
            child: Container(
              // Add padding for bigger touch target
              padding: const EdgeInsets.all(8),
              child: Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: Color(0xFF121212),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: const Color(0xFFF8F8F8),
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Title and duration
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.voiceNote.title,
                  style: const TextStyle(
                    color: Color(0xFF121212),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _formatDuration(widget.voiceNote.durationMs),
                  style: const TextStyle(
                    color: Color(0xFF121212),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Static waveform
          SizedBox(
            width: 60,
            height: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(8, (index) {
                double height = 0.3 + (index % 3) * 0.3;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  width: 2,
                  height: 30 * height,
                  decoration: BoxDecoration(
                    color: const Color(0xFF90EE90),
                    borderRadius: BorderRadius.circular(1),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(width: 8),

          // Delete button
          GestureDetector(
            onTap: widget.onDelete,
            child: const Icon(
              Icons.close,
              color: Color(0xFF121212),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}
