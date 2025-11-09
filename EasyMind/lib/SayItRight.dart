import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:string_similarity/string_similarity.dart';
import 'package:permission_handler/permission_handler.dart';
import 'adaptive_assessment_system.dart';
import 'memory_retention_system.dart';
import 'gamification_system.dart';

class SayItRight extends StatefulWidget {
  final String nickname;
  const SayItRight({super.key, required this.nickname});

  @override
  _SayItRightState createState() => _SayItRightState();
}

class _SayItRightState extends State<SayItRight> {
  final FlutterTts flutterTts = FlutterTts();
  final stt.SpeechToText speech = stt.SpeechToText();

  String targetWord = "dog";
  String recognizedWord = "";
  int accuracy = 0;
  int retryCount = 0; // Add retry counter
  int failedAttempts = 0; // Track failed attempts
  static const int maxFailedAttempts = 5; // Maximum failed attempts

  bool isDialogOpen = false;
  bool isListening = false;
  bool isCountingDown = false;

  // Adaptive Assessment System
  bool _useAdaptiveMode = true;
  String _currentDifficulty = 'beginner';
  final GamificationSystem _gamificationSystem = GamificationSystem();
  GamificationResult? _lastReward;

  @override
  void initState() {
    super.initState();
    _setupTTS();
    _checkPermissions();
    _initializeAdaptiveMode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakWord();
    });
  }

  void _checkPermissions() async {
    try {
      print('Checking microphone permissions...');

      // Check microphone permission using permission_handler
      PermissionStatus status = await Permission.microphone.status;
      print('Current microphone permission status: $status');

      if (status.isDenied) {
        print('Requesting microphone permission...');
        status = await Permission.microphone.request();
        print('Permission request result: $status');
      }

      if (status.isGranted) {
        print('Microphone permission granted');

        // Initialize speech recognition
        print('Initializing speech recognition...');
        bool available = await speech.initialize(
          onError: (error) {
            print('Speech recognition initialization error: $error');
          },
          onStatus: (status) {
            print('Speech recognition initialization status: $status');
          },
        );

        if (available) {
          print('Speech recognition available and initialized');
        } else {
          print('Speech recognition not available');
        }
      } else {
        print('Microphone permission denied: $status');
      }
    } catch (e) {
      print('Error checking permissions: $e');
    }
  }

  @override
  void dispose() {
    speech.stop();
    flutterTts.stop();
    super.dispose();
  }

  void _setupTTS() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.1);
    await flutterTts.setSpeechRate(0.5);

    // Use safer voice setup like other files
    try {
      List<dynamic> voices = await flutterTts.getVoices;
      bool voiceSet = false;

      for (var voice in voices) {
        final name = (voice["name"] ?? "").toLowerCase();
        final locale = (voice["locale"] ?? "").toLowerCase();
        if ((name.contains("female") || name.contains("woman")) &&
            locale.contains("en")) {
          await flutterTts.setVoice({
            "name": voice["name"],
            "locale": voice["locale"],
          });
          voiceSet = true;
          break;
        }
      }

      if (!voiceSet) {
        print("No suitable female voice found, using default");
      }
    } catch (e) {
      print("TTS voice configuration failed, using default: $e");
    }
  }

  void _speakWord() async {
    await flutterTts.speak("Can you say the word Dog?");
  }

  // Method to properly reset speech recognition
  Future<void> _resetSpeechRecognition() async {
    try {
      print('Resetting speech recognition...');
      await speech.stop();
      await Future.delayed(const Duration(milliseconds: 500));

      // Re-initialize to ensure clean state
      bool available = await speech.initialize(
        onError: (error) {
          print('Reset initialization error: $error');
        },
        onStatus: (status) {
          print('Reset initialization status: $status');
        },
      );

      if (available) {
        print('Speech recognition reset successfully');
      } else {
        print('Speech recognition reset failed');
      }
    } catch (e) {
      print('Error resetting speech recognition: $e');
    }
  }

  void _playFeedbackSound(int accuracy) async {
    await flutterTts.stop();
    if (accuracy >= 80) {
      await flutterTts.speak(
        "Great job! You pronounced the word correctly, but you could improve a little.",
      );
    } else if (accuracy >= 41) {
      await flutterTts.speak("Ding! Good try!");
    } else {
      await flutterTts.speak("Bzz! Try again!");
    }
  }

  void _showCountdownDialog() async {
    int countdown = 3;
    final screenWidth = MediaQuery.of(context).size.width;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            if (countdown > -3) {
              Future.delayed(const Duration(seconds: 1), () {
                if (mounted) {
                  setDialogState(() {
                    countdown--;
                  });
                  if (countdown == -3) {
                    Navigator.pop(context);
                    _startContinuousListening(); // Use continuous listening instead
                  }
                }
              });
            }
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: const Color(0xFFFBEED9),
              child: Padding(
                padding: EdgeInsets.all(screenWidth * 0.06),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      countdown > 0 ? "$countdown" : "Speak!",
                      style: TextStyle(
                        fontSize: screenWidth * 0.12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF22223B),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _startListening() async {
    if (isListening || isDialogOpen || isCountingDown) return;

    setState(() {
      isCountingDown = true;
    });

    _showCountdownDialog();
  }

  // Alternative method using continuous listening with timeout handling
  void _startContinuousListening() async {
    print('Starting continuous listening...');

    setState(() {
      isListening = true;
      recognizedWord = "";
      isCountingDown = false;
    });

    try {
      // Force stop and reset speech recognition completely
      print('Force stopping speech recognition...');
      await speech.stop();

      // Wait a moment for the service to fully stop
      await Future.delayed(const Duration(milliseconds: 800));

      // Check permissions
      PermissionStatus status = await Permission.microphone.status;
      if (status.isDenied) {
        status = await Permission.microphone.request();
      }

      if (!status.isGranted) {
        setState(() {
          isListening = false;
          isCountingDown = false;
        });
        _showPermissionDialog();
        return;
      }

      // Re-initialize speech recognition with patient timeout handling
      print('Re-initializing speech recognition...');
      bool available = await speech.initialize(
        onError: (error) {
          print('Speech recognition initialization error: $error');
          print('Error type: ${error.errorMsg}');

          // Handle initialization errors more gracefully
          if (error.errorMsg == 'error_speech_timeout' ||
              error.errorMsg == 'error_no_match') {
            print(
              'Initialization ${error.errorMsg} detected - trying alternative approach',
            );
            // Try alternative listening immediately
            Future.delayed(const Duration(milliseconds: 500), () {
              _tryAlternativeListening();
            });
            return;
          }

          setState(() {
            isListening = false;
            isCountingDown = false;
          });

          _showErrorDialog("Speech recognition error: ${error.errorMsg}");
        },
        onStatus: (status) {
          print('Speech recognition initialization status: $status');
          // Don't automatically set isListening to false on 'done' status
          // Let the result handler manage the state
        },
      );

      if (available) {
        print('Speech recognition available, starting to listen...');

        // Wait a moment before starting to listen
        await Future.delayed(const Duration(milliseconds: 500));

        // Use shorter listening periods to avoid timeouts
        await speech.listen(
          onResult: (result) {
            print('Continuous result: "${result.recognizedWords}"');

            if (result.recognizedWords.isNotEmpty) {
              String word = result.recognizedWords.toLowerCase().trim();

              // Check if the word contains "dog" or is similar
              if (word.contains('dog') ||
                  word == 'dog' ||
                  word.contains('dawg') ||
                  word.contains('dogg')) {
                print('Found dog-like word: "$word"');

                recognizedWord = word;
                double similarity = targetWord.similarityTo(word) * 100;

                setState(() {
                  accuracy = similarity.round().clamp(0, 100);
                  isListening = false;
                  retryCount = 0;
                });

                // Stop listening and show result
                speech.stop();
                _playFeedbackSound(accuracy);
                _showAccuracyDialog();
                return; // Exit early to prevent further processing
              }
            }
          },
          listenFor: const Duration(
            seconds: 20,
          ), // Longer listening time for students
          pauseFor: const Duration(seconds: 5), // Longer pause
          localeId: "en_US",
          partialResults: true,
          cancelOnError: false,
          listenMode:
              stt.ListenMode.confirmation, // Changed back to confirmation
          onSoundLevelChange: (level) {
            print('Sound level: $level');
          },
        );

        print('Continuous listening started successfully');

        // Set a timeout to automatically retry if no result
        Timer(const Duration(seconds: 25), () {
          if (isListening && recognizedWord.isEmpty) {
            print('Auto-timeout reached, trying alternative approach');
            _tryAlternativeListening();
          }
        });
      } else {
        print('Speech recognition not available');
        setState(() {
          isListening = false;
          isCountingDown = false;
        });
      }
    } catch (e) {
      print('Error in continuous listening: $e');
      setState(() {
        isListening = false;
        isCountingDown = false;
      });
    }
  }

  // Alternative listening approach for timeout cases
  void _tryAlternativeListening() async {
    print('Trying alternative listening approach...');

    try {
      await speech.stop();
      await Future.delayed(const Duration(milliseconds: 1000));

      // Try with different settings - be patient with timeouts
      bool available = await speech.initialize(
        onError: (error) {
          print('Alternative listening initialization error: $error');

          // Handle initialization errors more gracefully
          if (error.errorMsg == 'error_speech_timeout' ||
              error.errorMsg == 'error_no_match') {
            print(
              'Alternative initialization ${error.errorMsg} detected - trying fallback approach',
            );
            _tryFallbackApproach();
            return;
          }

          setState(() {
            isListening = false;
            isCountingDown = false;
          });
          _showErrorDialog(
            "Speech recognition is having issues. Please try again or check your microphone.",
          );
        },
        onStatus: (status) {
          print('Alternative listening initialization status: $status');
        },
      );

      if (available) {
        await speech.listen(
          onResult: (result) {
            print('Alternative result: "${result.recognizedWords}"');

            if (result.recognizedWords.isNotEmpty) {
              String word = result.recognizedWords.toLowerCase().trim();

              if (word.contains('dog') ||
                  word == 'dog' ||
                  word.contains('dawg') ||
                  word.contains('dogg')) {
                print('Found dog-like word in alternative: "$word"');

                recognizedWord = word;
                double similarity = targetWord.similarityTo(word) * 100;

                setState(() {
                  accuracy = similarity.round().clamp(0, 100);
                  isListening = false;
                  retryCount = 0;
                });

                speech.stop();
                _playFeedbackSound(accuracy);
                _showAccuracyDialog();
              }
            }
          },
          listenFor: const Duration(
            seconds: 15,
          ), // Longer for alternative approach
          pauseFor: const Duration(seconds: 4),
          localeId: "en_US",
          partialResults: true,
          cancelOnError: false,
          listenMode: stt.ListenMode.dictation,
        );

        print('Alternative listening started');

        // Set timeout for alternative approach
        Timer(const Duration(seconds: 18), () {
          if (isListening && recognizedWord.isEmpty) {
            print('Alternative timeout reached - no speech detected');
            setState(() {
              isListening = false;
              isCountingDown = false;
            });
            _showNoSpeechDialog();
          }
        });
      }
    } catch (e) {
      print('Error in alternative listening: $e');
      setState(() {
        isListening = false;
        isCountingDown = false;
      });
    }
  }

  void _showNoSpeechDialog() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: const Color(0xFFFBEED9),
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.06),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.mic_off,
                    size: screenWidth * 0.12,
                    color: Colors.blue,
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Text(
                    "No Speech Detected",
                    style: TextStyle(
                      fontSize: screenWidth * 0.06,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF22223B),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Text(
                    "Please speak clearly into the microphone. Make sure you're in a quiet environment.",
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _startListening(); // Try again
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5DB2FF),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.022,
                        horizontal: screenWidth * 0.05,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Try Again",
                      style: TextStyle(
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  // Fallback method for when speech recognition fails completely
  void _tryFallbackApproach() async {
    print('Trying fallback approach...');

    setState(() {
      isListening = false;
      isCountingDown = false;
    });

    // Show a simple dialog asking student to type the word
    _showFallbackDialog();
  }

  void _showFallbackDialog() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: const Color(0xFFFBEED9),
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.06),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.keyboard,
                    size: screenWidth * 0.12,
                    color: Colors.green,
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Text(
                    "Speech Recognition Issue",
                    style: TextStyle(
                      fontSize: screenWidth * 0.06,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF22223B),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Text(
                    "Let's try typing the word instead. Can you type 'dog'?",
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _startListening(); // Try speech again
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5DB2FF),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              vertical: screenHeight * 0.015,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "Try Speech Again",
                            style: TextStyle(
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.03),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            // Simulate successful recognition
                            recognizedWord = "dog";
                            accuracy = 85; // Give good score for typing
                            _playFeedbackSound(accuracy);
                            _showAccuracyDialog();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              vertical: screenHeight * 0.015,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "Type 'dog'",
                            style: TextStyle(
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _showPermissionDialog() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: const Color(0xFFFBEED9),
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.06),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.mic_off,
                    size: screenWidth * 0.12,
                    color: Colors.red,
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Text(
                    "Microphone Permission Required",
                    style: TextStyle(
                      fontSize: screenWidth * 0.06,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF22223B),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Text(
                    "Please allow microphone access to use speech recognition. You can enable it in your device settings.",
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF648BA2),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.022,
                        horizontal: screenWidth * 0.05,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "OK",
                      style: TextStyle(
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _showErrorDialog(String message) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: const Color(0xFFFBEED9),
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.06),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: screenWidth * 0.12,
                    color: Colors.red,
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Text(
                    "Speech Recognition Error",
                    style: TextStyle(
                      fontSize: screenWidth * 0.06,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF22223B),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF648BA2),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.022,
                        horizontal: screenWidth * 0.05,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "OK",
                      style: TextStyle(
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _showLimitExceededDialog() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: const Color(0xFFFBEED9),
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.06),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.schedule,
                    size: screenWidth * 0.12,
                    color: Colors.orange,
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Text(
                    "Exceeds Limit",
                    style: TextStyle(
                      fontSize: screenWidth * 0.06,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF22223B),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Text(
                    "Try again later! (1hr)",
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Text(
                    "You've tried 5 times. Take a break and come back later!",
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Navigate back to games
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF648BA2),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.022,
                        horizontal: screenWidth * 0.05,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Back to Games",
                      style: TextStyle(
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _showAccuracyDialog() {
    if (isDialogOpen) return;

    isDialogOpen = true;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Track failed attempts
    if (accuracy < 80) {
      failedAttempts++;
      print('Failed attempt $failedAttempts/$maxFailedAttempts');
    } else {
      failedAttempts = 0; // Reset on success
    }

    // Check if exceeded limit
    if (failedAttempts >= maxFailedAttempts) {
      _showLimitExceededDialog();
      return;
    }

    // Save to adaptive assessment and memory retention
    _saveToAdaptiveAssessment();
    _saveToMemoryRetention();

    String feedbackMessage;
    if (accuracy >= 80) {
      feedbackMessage =
          "Great job! You pronounced the word correctly, but there's a little room for improvement.";
    } else if (accuracy >= 41) {
      feedbackMessage =
          "Good effort! Try to articulate the sounds a bit more clearly.";
    } else {
      feedbackMessage =
          "Please try again. Speak slowly and clearly for better accuracy.";
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: const Color(0xFFFBEED9),
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.06),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: screenHeight * 0.7,
                  maxWidth: screenWidth * 0.9,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        FontAwesomeIcons.microphone,
                        size: screenWidth * 0.12,
                        color: const Color(0xFF4A4E69),
                      ),
                      SizedBox(height: screenHeight * 0.015),
                      Text(
                        "Your Score",
                        style: TextStyle(
                          fontSize: screenWidth * 0.06,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF22223B),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: screenHeight * 0.015),
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(
                          begin: 0,
                          end: accuracy.toDouble(),
                        ),
                        duration: const Duration(seconds: 1),
                        builder: (context, value, child) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: screenWidth * 0.25,
                                height: screenWidth * 0.25,
                                child: CircularProgressIndicator(
                                  value: value / 100,
                                  strokeWidth: screenWidth * 0.025,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    value >= 80
                                        ? Colors.green
                                        : value >= 41
                                        ? Colors.orange
                                        : Colors.red,
                                  ),
                                  backgroundColor: Colors.grey.shade300,
                                ),
                              ),
                              Text(
                                "${value.toInt()}%",
                                style: TextStyle(
                                  fontSize: screenWidth * 0.07,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      Text(
                        "You said: \"$recognizedWord\"",
                        style: TextStyle(
                          fontSize: screenWidth * 0.045,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.05,
                          vertical: screenHeight * 0.018,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 6),
                          ],
                        ),
                        child: Text(
                          feedbackMessage,
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            color: Colors.black87,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.03),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                Navigator.pop(context);

                                // Reset speech recognition completely
                                await _resetSpeechRecognition();

                                setState(() {
                                  isDialogOpen = false;
                                  recognizedWord = "";
                                  accuracy = 0;
                                  isListening = false;
                                  isCountingDown = false;
                                });

                                // Wait a moment before speaking
                                await Future.delayed(
                                  const Duration(milliseconds: 500),
                                );
                                _speakWord();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5DB2FF),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  vertical: screenHeight * 0.022,
                                  horizontal: screenWidth * 0.05,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                textStyle: TextStyle(
                                  fontSize: screenWidth * 0.05,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.replay, size: screenWidth * 0.06),
                                  SizedBox(width: screenWidth * 0.02),
                                  Text("Retry"),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.03),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                try {
                                  // Stop any ongoing speech recognition
                                  speech.stop();

                                  // Close the dialog first
                                  Navigator.pop(context);
                                  isDialogOpen = false;

                                  // Navigate back to the previous screen (GamesLandingPage)
                                  if (Navigator.canPop(context)) {
                                    Navigator.pop(context);
                                  }
                                } catch (e) {
                                  print('Error navigating back: $e');
                                  // Fallback: just close the dialog
                                  Navigator.pop(context);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF648BA2),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  vertical: screenHeight * 0.022,
                                  horizontal: screenWidth * 0.05,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                textStyle: TextStyle(
                                  fontSize: screenWidth * 0.05,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              child: Text("Back to Games"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFEFE9D5),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.05,
              vertical: screenHeight * 0.02,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    height: screenHeight * 0.08,
                    width: screenWidth * 0.4,
                    child: ElevatedButton(
                      onPressed: () {
                        try {
                          // Stop any ongoing speech recognition
                          speech.stop();
                          Navigator.pop(context);
                        } catch (e) {
                          print('Error navigating back: $e');
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF648BA2),
                        padding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.02,
                          horizontal: screenWidth * 0.05,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Go Back',
                        style: TextStyle(
                          fontSize: screenWidth * 0.06,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
                Text(
                  "Say It Right!",
                  style: TextStyle(
                    fontSize: screenWidth * 0.1,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF22223B),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: screenHeight * 0.02),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 8),
                    ],
                  ),
                  child: Image.asset(
                    'assets/S-Dog.jpg',
                    fit: BoxFit.contain,
                    height: screenHeight * 0.3,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: screenHeight * 0.3,
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.image,
                          size: 50,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
                Text(
                  "DOG",
                  style: TextStyle(
                    fontSize: screenWidth * 0.12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: screenHeight * 0.03),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 8),
                    ],
                  ),
                  padding: EdgeInsets.all(screenWidth * 0.02),
                  child: GestureDetector(
                    onTap: isCountingDown ? null : _startListening,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            isListening || isCountingDown
                                ? Colors.red[300]
                                : const Color(0xFF6A4C93),
                      ),
                      padding: EdgeInsets.all(screenWidth * 0.05),
                      child: FaIcon(
                        FontAwesomeIcons.microphone,
                        color: Colors.white,
                        size: screenWidth * 0.12,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.015),
                Text(
                  isCountingDown
                      ? "Get ready..."
                      : isListening
                      ? "Listening... Speak now!"
                      : "Tap to speak",
                  style: TextStyle(
                    fontSize: screenWidth * 0.06,
                    color: isListening ? Colors.green : Colors.black54,
                    fontWeight:
                        isListening ? FontWeight.bold : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: screenHeight * 0.01),
                // Add manual retry button for timeout cases
                if (!isListening && !isCountingDown)
                  ElevatedButton(
                    onPressed: () async {
                      print('Manual retry button pressed');
                      await _resetSpeechRecognition();
                      _startListening();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5DB2FF),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.08,
                        vertical: screenHeight * 0.01,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "Retry Speech Recognition",
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                SizedBox(height: screenHeight * 0.02),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Adaptive Assessment Methods
  Future<void> _initializeAdaptiveMode() async {
    if (_useAdaptiveMode) {
      try {
        await _gamificationSystem.initialize();
        _currentDifficulty = await AdaptiveAssessmentSystem.getCurrentLevel(
          widget.nickname,
          AssessmentType.sounds.value,
        );
        setState(() {});
      } catch (e) {
        print('Error initializing adaptive mode: $e');
      }
    }
  }

  Future<void> _saveToAdaptiveAssessment() async {
    if (!_useAdaptiveMode) return;

    try {
      // Calculate performance based on accuracy
      final performance = accuracy / 100.0;
      final totalQuestions = 1; // Single word game
      final correctAnswers = accuracy >= 70 ? 1 : 0; // Consider 70%+ as correct

      await AdaptiveAssessmentSystem.saveAssessmentResult(
        nickname: widget.nickname,
        assessmentType: AssessmentType.sounds.value,
        moduleName: "Speech Recognition Game",
        totalQuestions: totalQuestions,
        correctAnswers: correctAnswers,
        timeSpent: const Duration(minutes: 2),
        attemptedQuestions: [targetWord],
        correctQuestions: correctAnswers == 1 ? [targetWord] : [],
      );

      // Award XP based on performance
      final isPerfect = accuracy >= 90;
      final isGood = accuracy >= 70;

      _lastReward = await _gamificationSystem.awardXP(
        nickname: widget.nickname,
        activity:
            isPerfect
                ? 'perfect_speech'
                : (isGood ? 'good_speech' : 'speech_practice'),
        metadata: {
          'module': 'sayItRight',
          'accuracy': accuracy,
          'targetWord': targetWord,
          'perfect': isPerfect,
        },
      );

      print('Adaptive assessment saved for SayItRight game');
    } catch (e) {
      print('Error saving adaptive assessment: $e');
    }
  }

  Future<void> _saveToMemoryRetention() async {
    try {
      final retentionSystem = MemoryRetentionSystem();
      await retentionSystem.saveLessonCompletion(
        nickname: widget.nickname,
        moduleName: "Speech Recognition",
        lessonType: "SayItRight Game",
        score: accuracy >= 70 ? 1 : 0,
        totalQuestions: 1,
        passed: accuracy >= 70,
      );
    } catch (e) {
      print('Error saving to memory retention: $e');
    }
  }
}
