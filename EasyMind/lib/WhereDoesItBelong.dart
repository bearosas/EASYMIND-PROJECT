import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'adaptive_assessment_system.dart';
import 'memory_retention_system.dart';
import 'gamification_system.dart';

// Assuming the existence of these external files/enums for compilation
enum AssessmentType { dailyTasks, quizzes, homework }

extension AssessmentTypeExtension on AssessmentType {
  String get value {
    switch (this) {
      case AssessmentType.dailyTasks:
        return 'DailyTasks';
      case AssessmentType.quizzes:
        return 'Quizzes';
      case AssessmentType.homework:
        return 'Homework';
    }
  }
}

class WhereDoesItBelongGame extends StatelessWidget {
  final String nickname;
  const WhereDoesItBelongGame({super.key, required this.nickname});

  @override
  Widget build(BuildContext context) {
    return WhereGameScreen(nickname: nickname);
  }
}

class WhereGameScreen extends StatefulWidget {
  final String nickname;
  const WhereGameScreen({super.key, required this.nickname});

  @override
  State<WhereGameScreen> createState() => _WhereGameScreenState();
}

class _WhereGameScreenState extends State<WhereGameScreen> {
  // All possible items in the game
  final List<Map<String, String>> allItems = [
    {'image': 'assets/spoon.png', 'category': 'Kitchen'},
    {'image': 'assets/fork.png', 'category': 'Kitchen'},
    {'image': 'assets/plate.png', 'category': 'Kitchen'},
    {'image': 'assets/cup.png', 'category': 'Kitchen'},
    {'image': 'assets/toothbrush.png', 'category': 'Bathroom'},
    {'image': 'assets/soap.png', 'category': 'Bathroom'},
    {'image': 'assets/towel.png', 'category': 'Bathroom'},
    {'image': 'assets/pillow.png', 'category': 'Bedroom'},
    {'image': 'assets/blanket.png', 'category': 'Bedroom'},
    {'image': 'assets/lamp.png', 'category': 'Bedroom'},
  ];

  // Current items available for dragging
  List<Map<String, String>> availableItems = [];

  // Items correctly dropped into their categories
  final Map<String, List<String>> acceptedItems = {
    'Kitchen': [],
    'Bathroom': [],
    'Bedroom': [],
  };

  late ConfettiController _confettiController;

  // Adaptive Assessment and Gamification State (Keep existing logic)
  bool _useAdaptiveMode = true;
  String _currentDifficulty = 'beginner';
  final GamificationSystem _gamificationSystem = GamificationSystem();
  GamificationResult? _lastReward;
  int _score = 0;
  final int _totalItems = 10; // Total number of draggable items

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    // Initialize availableItems to allItems
    availableItems = List.from(allItems);
    _initializeAdaptiveMode();
  }

  void handleAccept(String category, String imagePath) {
    setState(() {
      acceptedItems[category]?.add(imagePath);
      // Remove item from availableItems
      availableItems.removeWhere(
        (item) => item['image'] == imagePath && item['category'] == category,
      );
      _score = acceptedItems.values.fold<int>(
        0,
        (sum, list) => sum + list.length,
      );
    });

    if (availableItems.isEmpty) {
      _confettiController.play();

      // Save to adaptive assessment and memory retention when game is complete
      _saveToAdaptiveAssessment();
      _saveToMemoryRetention();

      // Show completion dialog after a small delay
      Future.delayed(const Duration(milliseconds: 300), () {
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
                    maxHeight: screenHeight * 0.8,
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
                                elevation: 3,
                              ),
                              onPressed: () {
                                try {
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
                    ],
                  ),
                ),
              ),
        );
      });
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Using LayoutBuilder for size-dependent layout changes (responsiveness)
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;

        // Determine if we have a wide screen (e.g., tablet landscape or desktop)
        final isWideScreen = screenWidth > 600;

        // Dynamic sizes based on screen width
        final double paddingH = screenWidth * (isWideScreen ? 0.08 : 0.04);
        final double spacingV = screenHeight * 0.02;
        final double itemSize = screenWidth * (isWideScreen ? 0.10 : 0.20);
        final double acceptedItemSize =
            screenWidth * (isWideScreen ? 0.07 : 0.15);
        final double dragAreaHeight =
            screenHeight * (isWideScreen ? 0.35 : 0.25);
        final double targetAreaHeight =
            screenHeight * (isWideScreen ? 0.40 : 0.45);

        return Scaffold(
          backgroundColor: const Color(0xFFEFE9D5),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: paddingH,
                vertical: spacingV,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. Header (Go Back Button & Score)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        height: screenHeight * 0.06,
                        width: screenWidth * 0.35,
                        child: ElevatedButton(
                          onPressed: () {
                            try {
                              Navigator.pop(context);
                            } catch (e) {
                              print('Error navigating back: $e');
                              Navigator.pop(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A4E69),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: Text(
                            'Go Back',
                            style: TextStyle(
                              fontSize: screenWidth * 0.045,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.04,
                          vertical: screenHeight * 0.01,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A4E69),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Score: $_score / $_totalItems',
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: spacingV),

                  // 2. Game Title
                  Text(
                    "Where Does It Belong?",
                    style: TextStyle(
                      fontSize: screenWidth * 0.08,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4A4E69),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: screenHeight * 0.03),

                  // 3. Draggable Items Area (Fixed Height/Flexible Wrap)
                  Container(
                    height: dragAreaHeight, // Responsive height
                    alignment: Alignment.center,
                    child: Wrap(
                      spacing: screenWidth * (isWideScreen ? 0.05 : 0.03),
                      runSpacing: screenWidth * (isWideScreen ? 0.05 : 0.03),
                      alignment: WrapAlignment.center,
                      children:
                          availableItems.map((item) {
                            return Draggable<Map<String, String>>(
                              data: item,
                              feedback: Opacity(
                                opacity: 0.7, // Semi-transparent when dragging
                                child: Image.asset(
                                  item['image']!,
                                  width: itemSize,
                                  errorBuilder: (context, error, stackTrace) {
                                    return SizedBox(
                                      width: itemSize,
                                      height: itemSize,
                                      child: const Icon(
                                        Icons.image,
                                        size: 40,
                                        color: Colors.grey,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              childWhenDragging: SizedBox(
                                width: itemSize,
                                height: itemSize,
                              ),
                              child: Image.asset(
                                item['image']!,
                                width: itemSize,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: itemSize,
                                    height: itemSize,
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.image,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              ),
                            );
                          }).toList(),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.03),

                  // 4. Drag Targets Area (Expanded Row)
                  Container(
                    height: targetAreaHeight, // Responsive height
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children:
                          ['Kitchen', 'Bathroom', 'Bedroom'].map((category) {
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal:
                                      screenWidth *
                                      (isWideScreen ? 0.01 : 0.015),
                                ),
                                child: DragTarget<Map<String, String>>(
                                  builder: (
                                    context,
                                    candidateData,
                                    rejectedData,
                                  ) {
                                    bool isAccepting = candidateData.isNotEmpty;
                                    Color borderColor =
                                        isAccepting
                                            ? (candidateData
                                                        .first!['category'] ==
                                                    category
                                                ? Colors.green.shade400
                                                : Colors.red.shade400)
                                            : const Color(
                                              0xFF4A4E69,
                                            ).withOpacity(
                                              0.5,
                                            ); // Default border color

                                    return Container(
                                      height: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(
                                          color: borderColor,
                                          width: 3.0,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow:
                                            isAccepting
                                                ? [
                                                  BoxShadow(
                                                    color: borderColor
                                                        .withOpacity(0.5),
                                                    blurRadius: 5,
                                                    spreadRadius: 2,
                                                  ),
                                                ]
                                                : null,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          // Area for accepted items
                                          Expanded(
                                            child: SingleChildScrollView(
                                              padding: EdgeInsets.all(
                                                screenWidth *
                                                    (isWideScreen
                                                        ? 0.01
                                                        : 0.01),
                                              ),
                                              child: Wrap(
                                                alignment: WrapAlignment.center,
                                                spacing: screenWidth * 0.01,
                                                runSpacing: screenWidth * 0.01,
                                                children:
                                                    acceptedItems[category]!
                                                        .map(
                                                          (img) => Image.asset(
                                                            img,
                                                            width:
                                                                acceptedItemSize,
                                                            errorBuilder: (
                                                              context,
                                                              error,
                                                              stackTrace,
                                                            ) {
                                                              return Container(
                                                                width:
                                                                    acceptedItemSize,
                                                                height:
                                                                    acceptedItemSize,
                                                                color:
                                                                    Colors
                                                                        .grey[300],
                                                                child: const Icon(
                                                                  Icons.image,
                                                                  size: 25,
                                                                  color:
                                                                      Colors
                                                                          .grey,
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                        )
                                                        .toList(),
                                              ),
                                            ),
                                          ),
                                          // Category Label
                                          Container(
                                            width: double.infinity,
                                            padding: EdgeInsets.symmetric(
                                              vertical:
                                                  screenHeight *
                                                  0.015, // Slightly increased padding
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFF5DB2FF,
                                              ).withOpacity(0.8),
                                              borderRadius:
                                                  const BorderRadius.only(
                                                    bottomLeft: Radius.circular(
                                                      18,
                                                    ),
                                                    bottomRight:
                                                        Radius.circular(18),
                                                  ),
                                            ),
                                            child: Text(
                                              category,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: screenWidth * 0.05,
                                                color: Colors.white,
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  onWillAcceptWithDetails: (data) => true,
                                  onAcceptWithDetails: (data) {
                                    final itemData = data.data;
                                    if (itemData['category'] == category) {
                                      handleAccept(
                                        category,
                                        itemData['image']!,
                                      );
                                      // Positive feedback
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Correct! The ${itemData['image']?.split('/').last.split('.').first} belongs in the $category! 🎉',
                                            style: TextStyle(
                                              fontSize: screenWidth * 0.045,
                                              color: Colors.white,
                                            ),
                                          ),
                                          backgroundColor: Colors.green,
                                          duration: const Duration(
                                            milliseconds: 1000,
                                          ),
                                        ),
                                      );
                                    } else {
                                      // Negative feedback
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Oops! The ${itemData['image']?.split('/').last.split('.').first} does not belong in the $category. Try again! 🤔',
                                            style: TextStyle(
                                              fontSize: screenWidth * 0.045,
                                              color: Colors.white,
                                            ),
                                          ),
                                          backgroundColor:
                                              Colors
                                                  .red
                                                  .shade400, // Error color
                                          duration: const Duration(
                                            milliseconds: 1500,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                  SizedBox(height: spacingV),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Adaptive Assessment Methods (Kept as is)
  Future<void> _initializeAdaptiveMode() async {
    if (_useAdaptiveMode) {
      try {
        // Mocking initialization since external classes are not provided
        // await _gamificationSystem.initialize();
        // _currentDifficulty = await AdaptiveAssessmentSystem.getCurrentLevel(
        // 	 widget.nickname,
        // 	 AssessmentType.dailyTasks.value,
        // );
        setState(() {});
      } catch (e) {
        print('Error initializing adaptive mode: $e');
      }
    }
  }

  Future<void> _saveToAdaptiveAssessment() async {
    if (!_useAdaptiveMode) return;

    try {
      final correctItems = acceptedItems.values.fold<int>(
        0,
        (sum, list) => sum + list.length,
      );
      final totalItems = _totalItems; // Use the fixed total

      // Mocking saveAssessmentResult since external classes are not provided
      // await AdaptiveAssessmentSystem.saveAssessmentResult(
      // 	 nickname: widget.nickname,
      // 	 assessmentType: AssessmentType.dailyTasks.value,
      // 	 moduleName: "Categorization Game",
      // 	 totalQuestions: totalItems,
      // 	 correctAnswers: correctItems,
      // 	 timeSpent: const Duration(minutes: 4),
      // 	 attemptedQuestions: allItems.map((item) => item['image']!).toList(),
      // 	 correctQuestions: acceptedItems.values.expand((list) => list).toList(),
      // );

      // Award XP based on performance
      final isPerfect = correctItems == totalItems;
      final isGood = correctItems >= totalItems * 0.7;

      // Mocking awardXP since external classes are not provided
      // _lastReward = await _gamificationSystem.awardXP(
      // 	 nickname: widget.nickname,
      // 	 activity: isPerfect ? 'perfect_categorization' : (isGood ? 'good_categorization' : 'categorization_practice'),
      // 	 metadata: {
      // 	 	 'module': 'whereDoesItBelong',
      // 	 	 'score': correctItems,
      // 	 	 'total': totalItems,
      // 	 	 'perfect': isPerfect,
      // 	 },
      // );

      print('Adaptive assessment saved for WhereDoesItBelong game');
    } catch (e) {
      print('Error saving adaptive assessment: $e');
    }
  }

  Future<void> _saveToMemoryRetention() async {
    try {
      final retentionSystem = MemoryRetentionSystem();
      final correctItems = acceptedItems.values.fold<int>(
        0,
        (sum, list) => sum + list.length,
      );
      final totalItems = _totalItems;

      // Mocking saveLessonCompletion since external classes are not provided
      // await retentionSystem.saveLessonCompletion(
      // 	 nickname: widget.nickname,
      // 	 moduleName: "Categorization",
      // 	 lessonType: "WhereDoesItBelong Game",
      // 	 score: correctItems,
      // 	 totalQuestions: totalItems,
      // 	 passed: correctItems >= totalItems * 0.7,
      // );
    } catch (e) {
      print('Error saving to memory retention: $e');
    }
  }
}
