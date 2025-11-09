import 'package:flutter/material.dart';
import 'PictureStoryReading.dart'; // Make sure this file exists
import 'SoftLoudSoundsPage.dart'; // Make sure this file exists
import 'TexttoSpeech.dart'; // ✅ Import your TTS + STT file

class CommunicationSkillsPage extends StatelessWidget {
  final String nickname;
  const CommunicationSkillsPage({super.key, required this.nickname});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFE9D5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Go Back Button
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
                      'assets/story.png',
                      PictureStoryReading(nickname: nickname),
                      'Picture Story Reading',
                    ),
                    _buildImageCard(
                      context,
                      'assets/Sounds.webp',
                      SoftLoudSoundsPage(nickname: nickname),
                      'Soft & Loud Sounds',
                    ),
                    _buildImageCard(
                      context,
                      'assets/communication.png',
                      LearningMaterialsPage(nickname: nickname),
                      'Text to Speech Learning',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Image card builder
  Widget _buildImageCard(
    BuildContext context,
    String imagePath,
    Widget destination,
    String labelText,
  ) {
    // Balanced, SPED-friendly color combinations
    final Map<String, Map<String, Color>> moduleColors = {
      'Picture Story Reading': {
        'background': Color(0xFFEDF5EF),  // Soft sage
        'border': Color(0xFF779885),      // Muted forest
      },
      'Soft & Loud Sounds': {
        'background': Color(0xFFF7EFE2),  // Warm cream
        'border': Color(0xFF9C8574),      // Warm taupe
      },
      'Text to Speech Learning': {
        'background': Color(0xFFEDF4FA),  // Gentle blue
        'border': Color(0xFF6B8DAB),      // Muted blue-gray
      },
    };

    // Module-specific icons
    final Map<String, IconData> moduleIcons = {
      'Picture Story Reading': Icons.auto_stories,
      'Soft & Loud Sounds': Icons.volume_up,
      'Text to Speech Learning': Icons.record_voice_over,
    };

    final colors = moduleColors[labelText] ?? {
      'background': Color(0xFFEDF5EF),
      'border': Color(0xFF779885),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => destination),
        ),
        child: Container(
          height: 140,
          decoration: BoxDecoration(
            color: colors['background'],
            borderRadius: BorderRadius.circular(20),
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
                  moduleIcons[labelText] ?? Icons.school,
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
                      labelText,
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
