import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'adaptive_assessment_system.dart';
import 'memory_retention_system.dart';
import 'gamification_system.dart';

class MatchSoundPage extends StatefulWidget {
  final String nickname;
  const MatchSoundPage({super.key, required this.nickname});

  @override
  State<MatchSoundPage> createState() => _MatchSoundPageState();
}

class _MatchSoundPageState extends State<MatchSoundPage>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _mainPlayer = AudioPlayer();
  final List<AudioPlayer> _optionPlayers = List.generate(
    4,
    (_) => AudioPlayer(),
  );
  final FlutterTts _flutterTts = FlutterTts();

  final String mainSound = 'sound/dog_bark.mp3';
  final List<String> optionSounds = [
    'sound/bark1.mp3',
    'sound/bark2.mp3',
    'sound/dog_bark.mp3', // correct match
    'sound/bark3.mp3',
  ];
  final List<String> dogImages = [
    'assets/dogg.jpg',
    'assets/dogg.jpg',
    'assets/dogg.jpg',
    'assets/dogg.jpg',
  ];

  late AnimationController _animationController;
  late Animation<double> _waveAnimation;
  int? _selectedOption;
  int _score = 0;
  bool _isDialogOpen = false;
  
  // Adaptive Assessment System
  bool _useAdaptiveMode = true;
  String _currentDifficulty = 'beginner';
  final GamificationSystem _gamificationSystem = GamificationSystem();
  GamificationResult? _lastReward;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _waveAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _setupTTS();
    _initializeAudioPlayers();
    _initializeAdaptiveMode();
  }

  void _initializeAudioPlayers() async {
    try {
      print('Initializing audio players...');
      
      // Test if we can access the audio files
      for (int i = 0; i < optionSounds.length; i++) {
        print('Testing audio file ${i + 1}: ${optionSounds[i]}');
        try {
          // Try to set source without playing
          await _optionPlayers[i].setSource(AssetSource(optionSounds[i]));
          print('Audio file ${i + 1} is accessible');
        } catch (e) {
          print('Audio file ${i + 1} failed: $e');
        }
      }
      
      print('Audio players initialization completed');
    } catch (e) {
      print('Error initializing audio players: $e');
    }
  }

  void _setupTTS() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.1);
    await _flutterTts.setSpeechRate(0.5);
    
    // Use a safer approach - don't set specific voice, let system choose
    // This avoids the "Voice name not found" error
    try {
      // Get available voices and use the first English female voice
      List<dynamic> voices = await _flutterTts.getVoices;
      bool voiceSet = false;
      
      for (var voice in voices) {
        final name = (voice["name"] ?? "").toLowerCase();
        final locale = (voice["locale"] ?? "").toLowerCase();
        if ((name.contains("female") || name.contains("woman")) &&
            locale.contains("en")) {
          await _flutterTts.setVoice({
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

  void _speakInstructions() async {
    await _flutterTts.stop();
    await _flutterTts.speak(
      "Listen to the sound and select the matching one below.",
    );
  }

  void _stopAllAudio() async {
    try {
      await _mainPlayer.stop();
      for (var player in _optionPlayers) {
        await player.stop();
      }
      await _flutterTts.stop();
    } catch (e) {
      print('Error stopping audio: $e');
    }
  }

  @override
  void dispose() {
    _stopAllAudio();
    _animationController.dispose();
    _mainPlayer.dispose();
    for (var player in _optionPlayers) {
      player.dispose();
    }
    _flutterTts.stop();
    super.dispose();
  }

  void _playMainSound() async {
    try {
      _stopAllAudio();
      await _mainPlayer.play(AssetSource(mainSound));
      _animationController.repeat(reverse: true);
      await Future.delayed(const Duration(seconds: 2));
      _animationController.stop();
      _animationController.reset();
    } catch (e) {
      print('Error playing main sound: $e');
    }
  }

  void _playOptionSound(int index) async {
    try {
      print('Playing option sound at index: $index');
      print('Sound path: ${optionSounds[index]}');
      
      _stopAllAudio();
      
      // Add a small delay to ensure previous audio is stopped
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Try to play the sound
      await _optionPlayers[index].play(AssetSource(optionSounds[index]));
      
      print('Successfully started playing option sound');
      
      setState(() {
        _selectedOption = index;
      });
    } catch (e) {
      print('Error playing option sound: $e');
      print('Error details: ${e.toString()}');
      
      // Try alternative approach
      try {
        print('Trying alternative audio player...');
        final tempPlayer = AudioPlayer();
        await tempPlayer.play(AssetSource(optionSounds[index]));
        await tempPlayer.dispose();
        print('Alternative player worked');
      } catch (e2) {
        print('Alternative player also failed: $e2');
      }
    }
  }

  void _confirmSelection() async {
    if (_isDialogOpen || _selectedOption == null) {
      if (_selectedOption == null) {
        await _flutterTts.speak("Please select an option first!");
      }
      return;
    }

    _isDialogOpen = true;
    if (optionSounds[_selectedOption!] == mainSound) {
      setState(() {
        _score++;
      });
      await _flutterTts.speak("Correct!");
      _showFeedbackDialog("Great job! You matched the sound correctly!");
      
      // Save to adaptive assessment and memory retention
      _saveToAdaptiveAssessment();
      _saveToMemoryRetention();
    } else {
      await _flutterTts.speak("Try again!");
      _showFeedbackDialog("Oops! That wasn't the right match. Try again.");
    }
  }

  void _showFeedbackDialog(String feedbackMessage) {
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
                        Icons.volume_up,
                        size: screenWidth * 0.12,
                        color: const Color(0xFF4A6C82),
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
                      Text(
                        "$_score",
                        style: TextStyle(
                          fontSize: screenWidth * 0.1,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
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
                              onPressed: () {
                                Navigator.pop(context);
                                setState(() {
                                  _isDialogOpen = false;
                                  _selectedOption = null;
                                });
                                _playMainSound();
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
                                  _stopAllAudio();
                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                  setState(() {
                                    _isDialogOpen = false;
                                  });
                                } catch (e) {
                                  print('Error navigating back: $e');
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
    ).then((_) {
      setState(() {
        _isDialogOpen = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isIpad = screenWidth >= 600;
    final double boxSize = isIpad ? screenWidth * 0.25 : screenWidth * 0.35;
    final double imageSize = isIpad ? screenWidth * 0.22 : screenWidth * 0.3;

    return Scaffold(
      backgroundColor: const Color(0xFFF0EBD8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
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
                        _stopAllAudio();
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
                'Match The Sound',
                style: TextStyle(
                  fontSize: screenWidth * 0.08,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF4A6C82),
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: screenHeight * 0.015),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      'Listen to the sound and select the matching one below.',
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        color: const Color.fromARGB(255, 0, 0, 0),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  IconButton(
                    icon: Icon(
                      Icons.volume_up,
                      size: screenWidth * 0.08,
                      color: const Color.fromARGB(255, 0, 0, 0),
                    ),
                    onPressed: _speakInstructions,
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.03),
              Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _waveAnimation,
                    builder: (context, child) {
                      return Container(
                        width: screenWidth * 0.2 * _waveAnimation.value,
                        height: screenWidth * 0.2 * _waveAnimation.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blueAccent.withOpacity(0.2),
                        ),
                      );
                    },
                  ),
                  AnimatedBuilder(
                    animation: _waveAnimation,
                    builder: (context, child) {
                      return Container(
                        width: screenWidth * 0.15 * _waveAnimation.value,
                        height: screenWidth * 0.15 * _waveAnimation.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blueAccent.withOpacity(0.3),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    iconSize: screenWidth * 0.15,
                    icon: const Icon(Icons.play_circle_filled_rounded),
                    color: const Color(0xFF4A6C82),
                    onPressed: _playMainSound,
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.04),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      2,
                      (index) => _buildImageButton(index, boxSize, imageSize),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      2,
                      (index) =>
                          _buildImageButton(index + 2, boxSize, imageSize),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  SizedBox(
                    width: screenWidth * 0.5,
                    child: ElevatedButton(
                      onPressed: _confirmSelection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A6C82),
                        padding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.02,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Confirm Selection',
                        style: TextStyle(
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.02),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageButton(int index, double boxSize, double imageSize) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.02),
      child: GestureDetector(
        onTap: () => _playOptionSound(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          height: boxSize,
          width: boxSize,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white,
                _selectedOption == index
                    ? Colors.blue.shade100
                    : Colors.grey.shade100,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  _selectedOption == index
                      ? Colors.blue.shade400
                      : Colors.grey.shade200,
              width: _selectedOption == index ? 3.0 : 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(2, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    dogImages[index],
                    height: imageSize,
                    width: imageSize,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: imageSize,
                        width: imageSize,
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
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  Icons.volume_up_rounded,
                  size: MediaQuery.of(context).size.width * 0.08,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
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
      // Calculate performance based on score
      final performance = _score / 1.0; // Single round game
      final totalQuestions = 1;
      final correctAnswers = _score;
      
      await AdaptiveAssessmentSystem.saveAssessmentResult(
        nickname: widget.nickname,
        assessmentType: AssessmentType.sounds.value,
        moduleName: "Sound Matching Game",
        totalQuestions: totalQuestions,
        correctAnswers: correctAnswers,
        timeSpent: const Duration(minutes: 3),
        attemptedQuestions: ['Sound matching'],
        correctQuestions: correctAnswers == 1 ? ['Sound matching'] : [],
      );
      
      // Award XP based on performance
      final isPerfect = _score == 1;
      
      _lastReward = await _gamificationSystem.awardXP(
        nickname: widget.nickname,
        activity: isPerfect ? 'perfect_sound_match' : 'sound_match_practice',
        metadata: {
          'module': 'matchTheSound',
          'score': _score,
          'perfect': isPerfect,
        },
      );
      
      print('Adaptive assessment saved for MatchTheSound game');
    } catch (e) {
      print('Error saving adaptive assessment: $e');
    }
  }

  Future<void> _saveToMemoryRetention() async {
    try {
      final retentionSystem = MemoryRetentionSystem();
      await retentionSystem.saveLessonCompletion(
        nickname: widget.nickname,
        moduleName: "Sound Recognition",
        lessonType: "MatchTheSound Game",
        score: _score,
        totalQuestions: 1,
        passed: _score == 1,
      );
    } catch (e) {
      print('Error saving to memory retention: $e');
    }
  }
}
