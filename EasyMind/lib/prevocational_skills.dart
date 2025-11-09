import 'package:flutter/material.dart';
import 'shapes_activity_page.dart'; // Existing activity
import 'daily_tasks_module.dart'; // ← Placeholder for the new module page

class PreVocationalSkillsPage extends StatelessWidget {
  final String nickname;
  const PreVocationalSkillsPage({super.key, required this.nickname});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFE9D5),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width < 400 ? 12.0 : 20.0,
            vertical: MediaQuery.of(context).size.width < 400 ? 20.0 : 30.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  height: MediaQuery.of(context).size.width < 400 ? 50 : 60,
                  width: MediaQuery.of(context).size.width < 400 ? 140 : 180,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF648BA2),
                      padding: EdgeInsets.symmetric(
                        vertical: MediaQuery.of(context).size.width < 400 ? 12 : 15,
                        horizontal: MediaQuery.of(context).size.width < 400 ? 16 : 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Go Back',
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width < 400 ? 20 : 25,
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
              Expanded(
                child: ListView(
                  children: [
                    _buildImageCard(
                      context,
                      'assets/measuring.png',
                      labelText: 'Shapes Activity',
                      destination: ShapesActivityPage(nickname: nickname),
                    ),
                    _buildImageCard(
                      context,
                      'assets/daily.png',
                      labelText: 'Daily Tasks',
                      destination:
                          DailyTasksModulePage(nickname: nickname),
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

  Widget _buildImageCard(
    BuildContext context,
    String imagePath, {
    String? labelText,
    Widget? destination,
  }) {
    // Balanced, SPED-friendly color combinations
    final Map<String, Map<String, Color>> moduleColors = {
      'Shapes Activity': {
        'background': Color(0xFFEDF5EF),  // Soft sage
        'border': Color(0xFF779885),      // Muted forest
      },
      'Daily Tasks': {
        'background': Color(0xFFEDF4FA),  // Gentle blue
        'border': Color(0xFF6B8DAB),      // Muted blue-gray
      },
    };

    // Module-specific icons
    final Map<String, IconData> moduleIcons = {
      'Shapes Activity': Icons.category,
      'Daily Tasks': Icons.check_circle_outline,
    };

    final colors = moduleColors[labelText ?? ''] ?? {
      'background': Color(0xFFEDF5EF),
      'border': Color(0xFF779885),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => destination ?? 
                Scaffold(
                  appBar: AppBar(title: const Text("Coming Soon")),
                  body: const Center(
                    child: Text("Content will be added here."),
                  ),
                ),
            ),
          );
        },
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
                      labelText ?? '',
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
