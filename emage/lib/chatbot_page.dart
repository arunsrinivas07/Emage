import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'widgets/speech_button.dart';
import 'services/api_service.dart';
import 'hospitals_page.dart' hide AmbulanceScreen;
import 'find a donor.dart' hide HospitalsPage;
import 'doctors_page.dart' hide HospitalsPage;
import 'home_page.dart';
import 'ambulance_page.dart' hide HospitalsPage;
import 'widgets/navigation.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  _ChatbotPageState createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final TextEditingController _textController = TextEditingController();
  final FlutterTts _flutterTts = FlutterTts();
  final ScrollController _scrollController = ScrollController();
  
  final List<ChatMessage> _messages = [];
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isLoading = false;
  int _currentIndex = 2;
  bool _isDisposed = false; // Add disposal flag

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initTts();
    _addWelcomeMessage();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _fadeController.dispose();
    _slideController.dispose();
    _flutterTts.stop();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    _messages.add(
      ChatMessage(
        text: "Hello! I'm EMAGE Bot, your medical emergency assistant. I can help you with first aid instructions, emergency procedures, and medical guidance. How can I assist you today?",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setStartHandler(() {
        if (mounted && !_isDisposed) {
          setState(() {
            _isSpeaking = true;
          });
        }
      });

      _flutterTts.setCompletionHandler(() {
        if (mounted && !_isDisposed) {
          setState(() {
            _isSpeaking = false;
          });
        }
      });

      _flutterTts.setErrorHandler((message) {
        if (mounted && !_isDisposed) {
          setState(() {
            _isSpeaking = false;
          });
        }
      });
    } catch (e) {
      debugPrint('TTS initialization error: $e');
    }
  }

  Future<void> _speak(String text) async {
    try {
      if (text.isNotEmpty && !_isDisposed) {
        await _flutterTts.speak(text);
      }
    } catch (e) {
      debugPrint('TTS speak error: $e');
    }
  }

  Future<void> _stopSpeaking() async {
    try {
      await _flutterTts.stop();
      if (mounted && !_isDisposed) {
        setState(() {
          _isSpeaking = false;
        });
      }
    } catch (e) {
      debugPrint('TTS stop error: $e');
    }
  }

  void _navigateToPage(int index) {
    if (index == _currentIndex) return;
    
    HapticFeedback.lightImpact();
    setState(() {
      _currentIndex = index;
    });
    
    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HospitalsPage()),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DoctorPage()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FindaDonor()),
        );
        break;
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AmbulanceScreen()),
        );
        break;
    }
  }

  void _navigateBack() {
    HapticFeedback.lightImpact();
    Navigator.pop(context);
  }

  void _processTextInput(String text) async {
    if (text.trim().isEmpty || _isDisposed) return;

    if (mounted) {
      setState(() {
        _messages.add(ChatMessage(
          text: text,
          isUser: true,
          timestamp: DateTime.now(),
        ));
        _isLoading = true;
        _textController.clear();
      });
    }

    _scrollToBottom();

    try {
      final response = await _apiService.processQuery(text);
      if (mounted && !_isDisposed) {
        setState(() {
          _messages.add(ChatMessage(
            text: response.response,
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isLoading = false;
        });
        
        _scrollToBottom();
        _speak(response.response);
      }
    } catch (e) {
      debugPrint('API error: $e');
      if (mounted && !_isDisposed) {
        setState(() {
          _messages.add(ChatMessage(
            text: 'Sorry, I encountered an error. Please try again.',
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    if (!_isDisposed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients && mounted) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                // Header Section
                Container(
                  margin: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2DD4BF), Color(0xFF0D9488)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2DD4BF).withOpacity(0.3),
                        blurRadius: 15.r,
                        spreadRadius: 1.r,
                        offset: Offset(0, 8.h),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header Row
                      Container(
                        padding: EdgeInsets.all(20.w),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: _navigateBack,
                              child: Container(
                                width: 36.w,
                                height: 36.w,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.arrow_back_ios_new,
                                    color: Colors.white,
                                    size: 18.sp,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Text(
                                "EMAGE Bot",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 36.w,
                              height: 36.w,
                              child: Icon(
                                Icons.auto_awesome,
                                color: Colors.white,
                                size: 18.sp,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Bot Info Section
                      Container(
                        padding: EdgeInsets.only(
                          left: 20.w,
                          right: 20.w,
                          bottom: 20.w,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(3.w),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 2.w,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 25.r,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                child: Icon(
                                  Icons.smart_toy_rounded,
                                  color: Colors.white,
                                  size: 24.sp,
                                ),
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Medical Assistant",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 12.w, vertical: 4.h),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(15.r),
                                    ),
                                    child: Text(
                                      "Emergency Response & First Aid",
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Chat Messages Area
                Expanded(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 16.w),
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12.r,
                          offset: Offset(0, 4.h),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Messages List
                        Expanded(
                          child: ListView.builder(
                            controller: _scrollController,
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message = _messages[index];
                              return _buildChatBubble(message);
                            },
                          ),
                        ),

                        // Loading indicator
                        if (_isLoading)
                          Container(
                            margin: EdgeInsets.only(bottom: 16.h),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(12.w),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2DD4BF).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: SizedBox(
                                    width: 20.w,
                                    height: 20.w,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF2DD4BF),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Text(
                                  'EMAGE Bot is thinking...',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14.sp,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 16.h),

                // Input Section
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16.w),
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12.r,
                        offset: Offset(0, 4.h),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Text Input Field
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(15.r),
                          ),
                          child: TextField(
                            controller: _textController,
                            decoration: InputDecoration(
                              hintText: _isListening
                                  ? 'Listening... Speak your query'
                                  : 'Type your medical question...',
                              border: InputBorder.none,
                              hintStyle: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 14.sp,
                              ),
                            ),
                            style: TextStyle(fontSize: 16.sp),
                            maxLines: null,
                            textCapitalization: TextCapitalization.sentences,
                          ),
                        ),
                      ),

                      SizedBox(width: 8.w),

                      // Send Button
                      GestureDetector(
                        onTap: () {
                          if (_textController.text.isNotEmpty) {
                            HapticFeedback.lightImpact();
                            _processTextInput(_textController.text);
                          }
                        },
                        child: Container(
                          width: 44.w,
                          height: 44.w,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2DD4BF), Color(0xFF0D9488)],
                            ),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 20.sp,
                          ),
                        ),
                      ),

                      SizedBox(width: 8.w),

                      // Speech Button
                      SpeechButton(
                        onTextReceived: (text) {
                          if (mounted && !_isDisposed) {
                            setState(() {
                              _isListening = false;
                            });
                            _processTextInput(text);
                          }
                        },
                        onResponseReceived: (response) {
                          // This is handled in _processTextInput
                        },
                        onListeningChanged: (isListening) {
                          if (mounted && !_isDisposed) {
                            setState(() {
                              _isListening = isListening;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16.h),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Navigation(
        currentIndex: _currentIndex,
        onTap: _navigateToPage,
        onEmergencyTap: () {
          HapticFeedback.lightImpact();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        },
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    final isUser = message.isUser;
    final bubbleColor = isUser 
        ? const Color(0xFFCD1C18)
        : const Color(0xFF2DD4BF);

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: bubbleColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.smart_toy_rounded,
                color: bubbleColor,
                size: 18.sp,
              ),
            ),
            SizedBox(width: 8.w),
          ],
          
          Flexible(
            child: Column(
              crossAxisAlignment: isUser 
                  ? CrossAxisAlignment.end 
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: isUser 
                        ? bubbleColor
                        : bubbleColor.withOpacity(0.1),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16.r),
                      topRight: Radius.circular(16.r),
                      bottomLeft: Radius.circular(isUser ? 16.r : 4.r),
                      bottomRight: Radius.circular(isUser ? 4.r : 16.r),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.text,
                        style: TextStyle(
                          color: isUser ? Colors.white : Colors.grey.shade800,
                          fontSize: 16.sp,
                          height: 1.4.h,
                        ),
                      ),
                      
                      if (!isUser) ...[
                        SizedBox(height: 8.h),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                if (_isSpeaking) {
                                  _stopSpeaking();
                                } else {
                                  _speak(message.text);
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 6.h,
                                ),
                                decoration: BoxDecoration(
                                  color: bubbleColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(15.r),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _isSpeaking
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      color: bubbleColor,
                                      size: 16.sp,
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      _isSpeaking ? 'Stop' : 'Play',
                                      style: TextStyle(
                                        color: bubbleColor,
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                
                SizedBox(height: 4.h),
                
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          
          if (isUser) ...[
            SizedBox(width: 8.w),
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: bubbleColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.person_rounded,
                color: bubbleColor,
                size: 18.sp,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}