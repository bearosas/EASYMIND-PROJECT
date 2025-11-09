import 'package:flutter/material.dart';
import 'LearnTheAlphabets.dart';
import 'RhymeAndRead.dart';
import 'LearnColors.dart';
import 'LearnShapes.dart';
import 'LearnMyFamily.dart'; // ✅ Import the My Family module
import 'package:flutter_tts/flutter_tts.dart'; // Add TTS package

class FunctionalAcademicsPage extends StatefulWidget {
  final String nickname;
  
  const FunctionalAcademicsPage({super.key, required this.nickname});

  @override
  _FunctionalAcademicsPageState createState() =>
      _FunctionalAcademicsPageState();
}

class _FunctionalAcademicsPageState extends State<FunctionalAcademicsPage> {
  final FlutterTts flutterTts = FlutterTts();
  final bool _isDisposed = false; // Track disposal state

  @override
  void initState() {
    super.initState();
    _setupTTS();
  }

  Future<void> _setupTTS() async {
    try {
      await flutterTts.setLanguage("en-US");
      await flutterTts.setSpeechRate(0.5); // Slower speech rate for clarity
      await flutterTts.setPitch(1.0); // Normal pitch
      await flutterTts.setVolume(1.0); // Full volume
    } catch (e) {
      print("TTS setup error: $e"); // Log error for debugging
    }
  }

  Future<void> _speakIntro(String module) async {
    if (_isDisposed) return; // Prevent calls after disposal
    try {
      await flutterTts.stop(); // Stop any previous speech
      await flutterTts.speak("Let's learn the $module");
      await flutterTts.awaitSpeakCompletion(
        true,
      ); // Wait for speech to complete
    } catch (e) {
      print("TTS speak error: $e"); // Log error for debugging
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFE9D5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Go Back Button (SPED-friendly size matching other pages)
              Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  height: 50,
                  width: 160,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF648BA2),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Go Back',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Let's Start Learning",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A4E69),
                ),
              ),
              const SizedBox(height: 16),

              // List of Cards
              Expanded(
                child: ListView(
                  children: [
                    _buildImageCard(
                      context,
                      'assets/alphabet.png',
                      LearnTheAlphabets(nickname: widget.nickname),
                      "alphabet", // Module name for TTS
                    ),
                    _buildImageCard(
                      context,
                      'assets/rhyme.png',
                      RhymeAndRead(nickname: widget.nickname),
                      "rhyme and read", // Module name for TTS
                    ),
                    _buildImageCard(
                      context,
                      'assets/color.png',
                      LearnColors(nickname: widget.nickname),
                      "colors", // Module name for TTS
                    ),
                    _buildImageCard(
                      context,
                      'assets/shape.png',
                      LearnShapes(nickname: widget.nickname),
                      "shapes", // Module name for TTS
                    ),
                    _buildImageCard(
                      context,
                      'assets/love_family.jpg', // ✅ Use existing family image
                      LearnMyFamily(nickname: widget.nickname),
                      "my family", // Module name for TTS
                    ), // ✅ Added card
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Learning module card with child-friendly design
  Widget _buildImageCard(
    BuildContext context,
    String imagePath,
    Widget destination,
    String moduleName,
  ) {
    // Balanced, SPED-friendly color combinations - not too bright, not too pale
    final Map<String, Map<String, Color>> moduleColors = {
      'alphabet': {
        'background': Color(0xFFEDF4FA), // Gentle blue-white
        'border': Color(0xFF6B8DAB),     // Muted blue-gray
      },
      'rhyme and read': {
        'background': Color(0xFFEDF5EF), // Soft sage
        'border': Color(0xFF779885),     // Muted forest
      },
      'colors': {
        'background': Color(0xFFF7EFE2), // Warm cream
        'border': Color(0xFF9C8574),     // Warm taupe
      },
      'shapes': {
        'background': Color(0xFFF2EDF5), // Gentle lavender
        'border': Color(0xFF8E7B9A),     // Muted purple
      },
      'my family': {
        'background': Color(0xFFF5EDF0), // Soft rose
        'border': Color(0xFF987E8A),     // Muted mauve
      },
    };

    // Module-specific icons
    final Map<String, IconData> moduleIcons = {
      'alphabet': Icons.abc,
      'rhyme and read': Icons.auto_stories,
      'colors': Icons.palette,
      'shapes': Icons.category,
      'my family': Icons.people,
    };

    final colors = moduleColors[moduleName] ?? {
      'background': Color(0xFFF8F4EC),
      'border': Color(0xFF6D9197),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: GestureDetector(
        onTap: () async {
          if (!_isDisposed) {
            try {
              await _speakIntro(moduleName);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => destination),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error playing sound: $e')),
              );
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => destination),
              );
            }
          }
        },
        child: Container(
          height: 140,
            decoration: BoxDecoration(
              color: colors['background'],
              borderRadius: BorderRadius.circular(20),
              // removed thick border/highlight; use subtle shadow only
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 20),
              // Icon section
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: colors['border']!.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colors['border']!.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: Icon(
                  moduleIcons[moduleName] ?? Icons.school,
                  size: 40,
                  color: colors['border'],
                ),
              ),
              const SizedBox(width: 20),
              // Text section
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      moduleName.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Comic Sans MS',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colors['border'],
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colors['border']!.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: colors['border']!.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            color: colors['border'],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Let's Learn!",
                            style: TextStyle(
                              fontFamily: 'Comic Sans MS',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colors['border'],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.star,
                            color: colors['border'],
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
            ],
          ),
        ),
      ),
    );
  }
}
