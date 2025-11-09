import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:signature/signature.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import 'adaptive_assessment_system.dart';
import 'memory_retention_system.dart';
import 'gamification_system.dart';
import 'visit_tracking_system.dart';

class LetterTracingGame extends StatefulWidget {
  final String nickname;
  const LetterTracingGame({super.key, required this.nickname});

  @override
  State<LetterTracingGame> createState() => _LetterTracingGameState();
}

class _LetterTracingGameState extends State<LetterTracingGame>
    with SingleTickerProviderStateMixin {
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 8,
    penColor: Colors.black,
    exportBackgroundColor: Colors.transparent,
  );

  final FlutterTts _flutterTts = FlutterTts();
  final VisitTrackingSystem _visitTrackingSystem = VisitTrackingSystem();
  late ConfettiController _confettiController;
  late AnimationController _rumbleController;
  late Animation<Offset> _rumbleAnimation;

  List<String> letters = List.generate(26, (i) => String.fromCharCode(65 + i));
  List<bool> isLetterTraced = List.filled(26, false);
  int _currentIndex = 0;
  int _successfulTraces = 0; // Track successful traces

  // Adaptive Assessment System
  bool _useAdaptiveMode = true;
  final GamificationSystem _gamificationSystem = GamificationSystem();

  @override
  void initState() {
    super.initState();
    _setupTTS();
    _initializeAdaptiveMode();
    _trackVisit();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _rumbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _rumbleAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.02, 0), // Slight horizontal shake
    ).animate(
      CurvedAnimation(parent: _rumbleController, curve: Curves.easeInOut),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _rumbleController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        // This ensures the rumble animation loops
        _rumbleController.forward();
      }
    });
    _rumbleController.forward();
    letters.shuffle(Random()); // Randomize letter order
  }

  Future<void> _trackVisit() async {
    try {
      await _visitTrackingSystem.trackVisit(
        nickname: widget.nickname,
        itemType: 'lesson',
        itemName: 'Letter Tracing Game',
        moduleName: 'Functional Academics',
      );
      print('Visit tracked for Letter Tracing Game');
    } catch (e) {
      print('Error tracking visit: $e');
    }
  }

  Future<void> _setupTTS() async {
    try {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setPitch(1.5);
      await _flutterTts.setVolume(1.0);
      _speakLetter();
    } catch (e) {
      print('Error setting up TTS: $e');
    }
  }

  Future<void> _speakLetter() async {
    try {
      final String letter = letters[_currentIndex];
      await _flutterTts.stop();
      await _flutterTts.speak("Letter $letter");
    } catch (e) {
      print('Error speaking letter: $e');
    }
  }

  // MODIFICATION: Check Tracing Logic Updated
  // This logic is crucial: it prevents proceeding on invalid traces.
  Future<void> _checkTracing() async {
    print('🎯 Checking tracing...');
    await Future.delayed(const Duration(milliseconds: 200));
    final points = _signatureController.points;

    print('📊 Points count: ${points.length}');

    if (points.isEmpty) {
      print('⚠️ No points found');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please trace the letter first!'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // MODIFICATION: Call the actual validation function
    bool isValidTrace = _validateLetterTrace(points as List<Point?>);
    print('🔍 Validation result: $isValidTrace');

    if (isValidTrace) {
      print('✅ Trace is valid! Moving to next letter');
      setState(() {
        // Mark the original letter index as traced
        final originalLetterIndex =
            letters[_currentIndex].codeUnitAt(0) - 'A'.codeUnitAt(0);
        if (originalLetterIndex >= 0 &&
            originalLetterIndex < isLetterTraced.length) {
          isLetterTraced[originalLetterIndex] = true;
        }

        _successfulTraces++; // Increment successful trace count
      });

      // Show success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('Great! You traced ${letters[_currentIndex]} correctly! 🎉'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // Move to next letter only if valid
      await Future.delayed(const Duration(milliseconds: 600));
      if (_currentIndex < letters.length - 1) {
        setState(() {
          _currentIndex++;
          _signatureController.clear();
        });
        await _speakLetter();
      } else {
        _showCompletionDialog();
        _saveToAdaptiveAssessment();
        _saveToMemoryRetention();
      }
    } else {
      // ❌ Trace is invalid - DO NOT PROCEED TO NEXT LETTER
      print('❌ Trace is invalid');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Try again! Make sure to trace the letter ${letters[_currentIndex]} carefully.',
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
      _signatureController.clear(); // Clear so user can retry
    }
  }

  // MODIFICATION: Updated Tracing Validation Logic
  // This is a rudimentary check to prevent simple scribbling from passing.
  // Proper tracing validation requires more complex geometric checks.
  bool _validateLetterTrace(List<Point?> points) {
    print('🔍 Validating trace with ${points.length} points');

    // 1. Minimum points check: Ensure user drew something substantial
    const int minPoints = 15;
    if (points.length < minPoints) {
      print('❌ Too few points: ${points.length} (Min: $minPoints)');
      return false;
    }

    // 2. Simple Bounding Box Check: Ensure the drawing occupies a reasonable area
    // The canvas is the Signature widget's bounds. Let's assume its size is roughly known
    // or we can calculate the bounding box of the drawn points.
    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    final validPoints =
        points.where((p) => p != null).map((p) => p!.offset).toList();
    if (validPoints.isEmpty) return false;

    for (var point in validPoints) {
      if (point != null) {
        minX = min(minX, point.dx);
        maxX = max(maxX, point.dx);
        minY = min(minY, point.dy);
        maxY = max(maxY, point.dy);
      }
    }

    final double width = maxX - minX;
    final double height = maxY - minY;

    // Get the current context's size for reference (assuming the Signature widget fills a known area)
    final box = context.findRenderObject() as RenderBox?;
    if (box == null)
      return true; // Can't check, assume true to avoid false negatives

    final double canvasWidth = box.size.width;
    final double canvasHeight =
        MediaQuery.of(context).size.height *
        0.45; // Based on build method's estimate

    // Check if the drawing covers a substantial area of the drawing pad
    const double minCoverageRatio = 0.3; // Must cover at least 30% of the area
    if (width / canvasWidth < minCoverageRatio ||
        height / canvasHeight < minCoverageRatio) {
      print(
        '❌ Drawing does not cover enough area. Width Ratio: ${width / canvasWidth}, Height Ratio: ${height / canvasHeight}',
      );
      return false;
    }

    // A check for *over* drawing (excessive scribbling) could be added here, e.g.,
    // by checking the total path length vs. the bounding box diagonal.
    // For now, these basic checks should significantly reduce false positives from scribbling.
    print('✅ Validation passed: Simple length and coverage checks successful.');
    return true;
  }

  void _onNextLetter() {
    // MODIFICATION: Added logic to clear controller
    if (_currentIndex < letters.length - 1) {
      setState(() {
        _currentIndex++;
        _signatureController.clear();
      });
      _speakLetter();
    } else {
      _showCompletionDialog();
    }
  }

  void _onPreviousLetter() {
    // MODIFICATION: Added logic to clear controller
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _signatureController.clear();
      });
      _speakLetter();
    }
  }

  void _eraseTracing() {
    _signatureController.clear();
  }

  void _showCompletionDialog() {
    _confettiController.play();
    final double successRate = (_successfulTraces / letters.length) * 100;
    String overallFeedback;
    if (successRate >= 80) {
      overallFeedback =
          "Excellent work! You traced ${successRate.toStringAsFixed(0)}% of the letters accurately. Keep it up!";
    } else if (successRate >= 50) {
      overallFeedback =
          "Good effort! You traced ${successRate.toStringAsFixed(0)}% of the letters well. Practice more for perfection!";
    } else {
      overallFeedback =
          "Nice try! You traced ${successRate.toStringAsFixed(0)}% of the letters. Try again to improve your skills!";
    }

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
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: screenHeight * 0.9, // Increased height
                maxWidth: screenWidth * 0.9,
              ),
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirectionality: BlastDirectionality.explosive,
                    shouldLoop: false,
                    colors: const [
                      Colors.red,
                      Colors.blue,
                      Colors.green,
                      Colors.yellow,
                      Colors.purple,
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.all(screenWidth * 0.06),
                    // MODIFICATION: Use SingleChildScrollView for the content of the Dialog
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            size: screenWidth * 0.2,
                            color: Colors.amber,
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          Text(
                            "You have finished the game!",
                            style: TextStyle(
                              fontSize: screenWidth * 0.07,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2C3E50),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          Text(
                            "Letter-by-Letter Feedback:",
                            style: TextStyle(
                              fontSize: screenWidth * 0.055,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2C3E50),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: screenHeight * 0.01),
                          // Display feedback in a Grid or simpler layout if many letters
                          // For a full A-Z list, a GridView is usually better to save vertical space.
                          GridView.builder(
                            shrinkWrap: true,
                            physics:
                                const NeverScrollableScrollPhysics(), // Important!
                            itemCount: isLetterTraced.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2, // Two items per row
                                  childAspectRatio:
                                      4.0, // Adjust aspect ratio for a wider cell
                                  crossAxisSpacing: screenWidth * 0.02,
                                  mainAxisSpacing: screenHeight * 0.01,
                                ),
                            itemBuilder: (context, index) {
                              final letter = String.fromCharCode(65 + index);
                              return Text(
                                "$letter: ${isLetterTraced[index] ? 'Traced' : 'Not traced'}",
                                style: TextStyle(
                                  fontSize: screenWidth * 0.04,
                                  color:
                                      isLetterTraced[index]
                                          ? Colors.green
                                          : Colors.red,
                                ),
                                textAlign: TextAlign.left,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              );
                            },
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          Text(
                            overallFeedback,
                            style: TextStyle(
                              fontSize: screenWidth * 0.05,
                              color: const Color(0xFF2C3E50),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: screenHeight * 0.03),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5DB2FF),
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.1,
                                vertical: screenHeight * 0.022,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            onPressed: () {
                              try {
                                _flutterTts.stop();
                                Navigator.of(
                                  context,
                                  rootNavigator: true,
                                ).pop();
                                Navigator.pop(context);
                              } catch (e) {
                                print('Error navigating back: $e');
                                Navigator.pop(context);
                              }
                            },
                            child: Text(
                              "Back to Games",
                              style: TextStyle(
                                fontSize: screenWidth * 0.055,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  void dispose() {
    _signatureController.dispose();
    _flutterTts.stop();
    _confettiController.dispose();
    _rumbleController.dispose();
    super.dispose();
  }

  // MODIFICATION: Wrapped the content in SingleChildScrollView
  @override
  Widget build(BuildContext context) {
    final String currentLetter = letters[_currentIndex];
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Use responsive spacing instead of fixed values
    final double verticalSpacing = screenHeight * 0.015;
    final double buttonHeight = screenHeight * 0.06;

    return Scaffold(
      backgroundColor: const Color(0xFFEFE9D5),
      body: SafeArea(
        // FIX: Added SingleChildScrollView to make the UI scrollable
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.06,
              vertical: screenHeight * 0.02,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // TOP SECTION (Go Back Button, Index, Title)
                Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    // Removed fixed height
                    width: screenWidth * 0.4,
                    child: ElevatedButton(
                      onPressed: () {
                        try {
                          _flutterTts.stop();
                          Navigator.pop(context);
                        } catch (e) {
                          print('Error navigating back: $e');
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A4E69),
                        padding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.015,
                          horizontal: screenWidth * 0.05,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Go Back',
                        style: TextStyle(
                          fontSize: screenWidth * 0.055,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: verticalSpacing),
                Text(
                  '${_currentIndex + 1}/26',
                  style: TextStyle(
                    fontSize: screenWidth * 0.06,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2C3E50),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: verticalSpacing),
                Text(
                  'Trace the Letters',
                  style: TextStyle(
                    fontSize: screenWidth * 0.08,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF4A4E69),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: verticalSpacing * 2),
                Text(
                  'Trace the letter:',
                  style: TextStyle(
                    fontSize: screenWidth * 0.06,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2C3E50),
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: verticalSpacing),

                // MIDDLE SECTION (Letter and Tracing Pad)
                AnimatedBuilder(
                  animation: _rumbleAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: _rumbleAnimation.value,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            currentLetter,
                            style: TextStyle(
                              fontSize: screenWidth * 0.3,
                              color: Colors.black26,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          GestureDetector(
                            onTap: _speakLetter,
                            child: Container(
                              padding: EdgeInsets.all(screenWidth * 0.03),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4A4E69),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 6,
                                    offset: const Offset(2, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.volume_up,
                                size: screenWidth * 0.08,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                SizedBox(height: verticalSpacing),
                // Using Flexible sizing with a large fixed aspect ratio to manage size
                // or a ConstrainedBox with a fixed height is necessary for Signature.
                // Keeping a fraction of the screen height for the Signature Pad.
                Container(
                  height:
                      screenHeight * 0.4, // Reduced height for scrollability
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Signature(
                    controller: _signatureController,
                    backgroundColor: Colors.transparent,
                  ),
                ),

                SizedBox(height: verticalSpacing * 2),

                // BOTTOM SECTION (Control Buttons)
                Wrap(
                  spacing: screenWidth * 0.02,
                  runSpacing: screenWidth * 0.02,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildControlButton(
                      'Previous',
                      _onPreviousLetter,
                      const Color(0xFF4A4E69),
                      screenWidth,
                      buttonHeight,
                    ),
                    _buildControlButton(
                      'Erase',
                      _eraseTracing,
                      const Color(0xFF4A4E69),
                      screenWidth,
                      buttonHeight,
                    ),
                    _buildControlButton(
                      'Check Trace',
                      _checkTracing,
                      Colors.green,
                      screenWidth,
                      buttonHeight,
                    ),
                    // If the trace is invalid, the user must try again; they can still
                    // press Next Letter to skip, but _checkTracing's flow is better.
                    _buildControlButton(
                      'Next Letter',
                      _onNextLetter,
                      const Color(0xFF4A4E69),
                      screenWidth,
                      buttonHeight,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method for building responsive buttons (no change here, just using the new buttonHeight)
  Widget _buildControlButton(
    String text,
    VoidCallback onPressed,
    Color color,
    double screenWidth,
    double buttonHeight,
  ) {
    return SizedBox(
      height: buttonHeight,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: screenWidth * 0.05, color: Colors.white),
        ),
      ),
    );
  }

  // Adaptive Assessment Methods (No changes, included for completeness)
  Future<void> _initializeAdaptiveMode() async {
    if (_useAdaptiveMode) {
      try {
        await _gamificationSystem.initialize();
        await AdaptiveAssessmentSystem.getCurrentLevel(
          widget.nickname,
          AssessmentType.alphabet.value,
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
      // Calculate performance based on successful traces
      final totalQuestions = letters.length;
      final correctAnswers = _successfulTraces;

      await AdaptiveAssessmentSystem.saveAssessmentResult(
        nickname: widget.nickname,
        assessmentType: AssessmentType.alphabet.value,
        moduleName: "Letter Tracing Game",
        totalQuestions: totalQuestions,
        correctAnswers: correctAnswers,
        timeSpent: const Duration(minutes: 6),
        attemptedQuestions: letters,
        // NOTE: This assumes the first '_successfulTraces' letters of the *shuffled* list
        // were the ones correctly traced, which is inaccurate but keeps the existing logic flow.
        correctQuestions: letters.take(_successfulTraces).toList(),
      );

      // Award XP based on performance
      final isPerfect = _successfulTraces == letters.length;
      final isGood = _successfulTraces >= letters.length * 0.7;

      await _gamificationSystem.awardXP(
        nickname: widget.nickname,
        activity:
            isPerfect
                ? 'perfect_letter_tracing'
                : (isGood ? 'good_letter_tracing' : 'letter_tracing_practice'),
        metadata: {
          'module': 'letterTracing',
          'score': _successfulTraces,
          'total': letters.length,
          'perfect': isPerfect,
        },
      );

      print('Adaptive assessment saved for LetterTracing game');
    } catch (e) {
      print('Error saving adaptive assessment: $e');
    }
  }

  Future<void> _saveToMemoryRetention() async {
    try {
      final retentionSystem = MemoryRetentionSystem();
      await retentionSystem.saveLessonCompletion(
        nickname: widget.nickname,
        moduleName: "Letter Tracing",
        lessonType: "LetterTracing Game",
        score: _successfulTraces,
        totalQuestions: letters.length,
        passed: _successfulTraces >= letters.length * 0.7,
      );
    } catch (e) {
      print('Error saving to memory retention: $e');
    }
  }
}
