// lib/widgets/speech_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/api_service.dart';

class SpeechButton extends StatefulWidget {
  final Function(String) onTextReceived;
  final Function(String) onResponseReceived;
  final Function(bool)? onListeningChanged; // Add callback for listening state

  const SpeechButton({
    super.key,
    required this.onTextReceived,
    required this.onResponseReceived,
    this.onListeningChanged,
  });

  @override
  _SpeechButtonState createState() => _SpeechButtonState();
}

class _SpeechButtonState extends State<SpeechButton> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isInitialized = false;
  bool _isDisposed = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _stopListening();
    super.dispose();
  }

  // Initialize speech recognition
  Future<void> _initSpeech() async {
  if (_isDisposed) return;
  
  try {
    // Check permission first before initializing speech
    var permissionStatus = await Permission.microphone.status;
    if (!permissionStatus.isGranted) {
      debugPrint('Speech initialization skipped: No microphone permission');
      return;
    }
    
    bool available = await _speech.initialize(
      onStatus: (status) {
        debugPrint('Speech status: $status');
        if (!_isDisposed && mounted) { // Add mounted check
          if (status == 'done' || status == 'notListening') {
            _updateListeningState(false);
          }
        }
      },
      onError: (errorNotification) {
        debugPrint('Speech error: $errorNotification');
        if (!_isDisposed && mounted) { // Add mounted check
          _updateListeningState(false);
        }
      },
    );
    
    if (!_isDisposed && mounted) {
      setState(() {
        _isInitialized = available;
      });
    }
    
  } catch (e) {
    debugPrint('Speech initialization error: $e');
    if (!_isDisposed && mounted) {
      setState(() {
        _isInitialized = false;
      });
    }
  }
}

  void _updateListeningState(bool isListening) {
    if (_isDisposed) return;
    
    if (mounted) {
      setState(() {
        _isListening = isListening;
      });
    }
    
    // Notify parent widget about listening state change
    widget.onListeningChanged?.call(isListening);
  }

  void _stopListening() {
    try {
      if (_speech.isListening) {
        _speech.stop();
      }
      _updateListeningState(false);
    } catch (e) {
      debugPrint('Error stopping speech recognition: $e');
    }
  }

  // Toggle listening
  Future<void> _toggleListening() async {
    if (_isDisposed) return;

    if (!_isListening) {
      // Start listening
      if (!_isInitialized) {
        await _initSpeech();
        if (!_isInitialized) {
          debugPrint('Cannot start listening: Speech not initialized');
          return;
        }
      }

      try {
        _updateListeningState(true);
        
        await _speech.listen(
          onResult: (result) async {
            if (_isDisposed) return;
            
            if (result.finalResult) {
              _updateListeningState(false);
              
              String recognizedText = result.recognizedWords.trim();
              if (recognizedText.isNotEmpty) {
                widget.onTextReceived(recognizedText);
                
                try {
                  final response = await _apiService.processQuery(recognizedText);
                  if (!_isDisposed) {
                    widget.onResponseReceived(response.response);
                  }
                } catch (e) {
                  debugPrint('Error processing voice input: $e');
                  if (!_isDisposed) {
                    widget.onResponseReceived('Sorry, I encountered an error. Please try again.');
                  }
                }
              }
            }
          },
          listenFor: const Duration(seconds: 30), // Set maximum listening duration
          pauseFor: const Duration(seconds: 3),   // Set pause detection
          partialResults: true,
        );
      } catch (e) {
        debugPrint('Error starting speech recognition: $e');
        _updateListeningState(false);
      }
    } else {
      // Stop listening
      _stopListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isInitialized ? _toggleListening : null,
      child: Container(
        width: 44.w,
        height: 44.w,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isInitialized 
                ? [const Color(0xFF2DD4BF), const Color(0xFF0D9488)]
                : [Colors.grey.shade400, Colors.grey.shade500],
          ),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(
          _isListening ? Icons.mic : Icons.mic_none,
          color: Colors.white,
          size: 20.sp,
        ),
      ),
    );
  }
}