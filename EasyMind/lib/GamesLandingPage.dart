import 'package:flutter/material.dart';
import 'SayItRight.dart'; // ✅ Ensure this file exists
import 'MatchTheSound.dart'; // ✅ Ensure this file exists
import 'FormTheWord.dart'; // ✅ This must contain AppleWordGame
import 'WhereDoesItBelong.dart'; // ✅ Newly added
import 'LetterTracing.dart'; // ✅ Newly added tracing game
import 'flashcard_system.dart'; // ✅ Flashcard Game
import 'ColorMatchingGame.dart'; // ✅ Color Matching Game
import 'responsive_utils.dart';

class GamesLandingPage extends StatelessWidget {
  final String nickname;
  
  const GamesLandingPage({super.key, required this.nickname});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Softer, neutral background for better contrast with muted cards
      backgroundColor: const Color(0xFFF7F5EF),
      body: ResponsiveWidget(
        mobile: _buildMobileLayout(context),
        tablet: _buildTabletLayout(context),
        desktop: _buildDesktopLayout(context),
        largeDesktop: _buildLargeDesktopLayout(context),
      ),
    );
  }

  // Map titles to simple icons for SPED-friendly covers
  IconData _iconForTitle(String title) {
    final t = title.toLowerCase();
    if (t.contains('say') || t.contains('say it')) return Icons.record_voice_over;
    if (t.contains('match') || t.contains('sound')) return Icons.music_note;
    if (t.contains('form') || t.contains('word')) return Icons.text_fields;
    if (t.contains('belong') || t.contains('where')) return Icons.category;
    if (t.contains('trace') || t.contains('letter')) return Icons.create;
    if (t.contains('flash') || t.contains('card')) return Icons.auto_stories;
    if (t.contains('color')) return Icons.palette;
    return Icons.videogame_asset;
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Padding(
      padding: ResponsiveUtils.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBackButton(context),
          ResponsiveSpacing(mobileSpacing: 10),
          _buildTitle(context),
          ResponsiveSpacing(mobileSpacing: 20),
          Expanded(
            child: _buildGamesGrid(context, crossAxisCount: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Padding(
      padding: ResponsiveUtils.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBackButton(context),
          ResponsiveSpacing(mobileSpacing: 10),
          _buildTitle(context),
          ResponsiveSpacing(mobileSpacing: 20),
          Expanded(
            child: _buildGamesGrid(context, crossAxisCount: 2),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Padding(
      padding: ResponsiveUtils.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBackButton(context),
          ResponsiveSpacing(mobileSpacing: 10),
          _buildTitle(context),
          ResponsiveSpacing(mobileSpacing: 20),
          Expanded(
            child: _buildGamesGrid(context, crossAxisCount: 3),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeDesktopLayout(BuildContext context) {
    return Padding(
      padding: ResponsiveUtils.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBackButton(context),
          ResponsiveSpacing(mobileSpacing: 10),
          _buildTitle(context),
          ResponsiveSpacing(mobileSpacing: 20),
          Expanded(
            child: _buildGamesGrid(context, crossAxisCount: 4),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        height: ResponsiveUtils.getResponsiveIconSize(context, mobile: 50),
        width: ResponsiveUtils.getResponsiveIconSize(context, mobile: 150),
        child: ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF648BA2),
            padding: EdgeInsets.symmetric(
              vertical: ResponsiveUtils.getResponsiveSpacing(context, mobile: 15),
              horizontal: ResponsiveUtils.getResponsiveSpacing(context, mobile: 20),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 12),
              ),
            ),
          ),
          child: ResponsiveText(
            'Go Back',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            mobileFontSize: 20,
            tabletFontSize: 22,
            desktopFontSize: 24,
            largeDesktopFontSize: 26,
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ResponsiveText(
          "Games",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF4A4E69),
          ),
          mobileFontSize: 35,
          tabletFontSize: 40,
          desktopFontSize: 45,
          largeDesktopFontSize: 50,
        ),
      ],
    );
  }

  Widget _buildGamesGrid(BuildContext context, {required int crossAxisCount}) {
    return GridView(
      padding: ResponsiveUtils.getResponsivePadding(context),
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: ResponsiveUtils.getResponsiveSpacing(context, mobile: 20),
        mainAxisSpacing: ResponsiveUtils.getResponsiveSpacing(context, mobile: 20),
        childAspectRatio: ResponsiveUtils.isSmallScreen(context) ? 0.8 : 0.72,
      ),
      children: [
        _buildGameCard(
          imagePath: 'assets/sayitright.png',
          title: 'Say It Right',
          imageWidth: ResponsiveUtils.getResponsiveIconSize(context, mobile: 200),
          imageHeight: ResponsiveUtils.getResponsiveIconSize(context, mobile: 280),
          imageRadius: ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 15),
          cardColor: const Color(0xFFFCF5D9),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SayItRight(nickname: nickname),
              ),
            );
          },
          context: context,
        ),
        _buildGameCard(
          imagePath: 'assets/mth.png',
          title: 'Match The Sound',
          imageWidth: ResponsiveUtils.getResponsiveIconSize(context, mobile: 200),
          imageHeight: ResponsiveUtils.getResponsiveIconSize(context, mobile: 280),
          imageRadius: ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 15),
          cardColor: const Color(0xFFFBEAB4),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MatchSoundPage(nickname: nickname),
              ),
            );
          },
          context: context,
        ),
        _buildGameCard(
          imagePath: 'assets/d&d.png',
          title: 'Form The Word',
          imageWidth: ResponsiveUtils.getResponsiveIconSize(context, mobile: 200),
          imageHeight: ResponsiveUtils.getResponsiveIconSize(context, mobile: 280),
          imageRadius: ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 15),
          cardColor: const Color(0xFFFEF1D6),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AppleWordGame(nickname: nickname),
              ),
            );
          },
          context: context,
        ),
        _buildGameCard(
          imagePath: 'assets/board.png',
          title: 'Where Does It Belong',
          imageWidth: ResponsiveUtils.getResponsiveIconSize(context, mobile: 200),
          imageHeight: ResponsiveUtils.getResponsiveIconSize(context, mobile: 280),
          imageRadius: ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 15),
          cardColor: const Color(0xFFFDEFC8),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WhereDoesItBelongGame(nickname: nickname),
              ),
            );
          },
          context: context,
        ),
        _buildGameCard(
          imagePath: 'assets/pen.jpg',
          title: 'Letter Tracing',
          imageWidth: ResponsiveUtils.getResponsiveIconSize(context, mobile: 200),
          imageHeight: ResponsiveUtils.getResponsiveIconSize(context, mobile: 280),
          imageRadius: ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 15),
          cardColor: const Color(0xFFFCECC8),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LetterTracingGame(nickname: nickname),
              ),
            );
          },
          context: context,
        ),
        _buildGameCard(
          imagePath: 'assets/app.png',
          title: 'Flashcard Game',
          imageWidth: ResponsiveUtils.getResponsiveIconSize(context, mobile: 200),
          imageHeight: ResponsiveUtils.getResponsiveIconSize(context, mobile: 280),
          imageRadius: ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 15),
          cardColor: const Color(0xFFE8F5E8),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FlashcardGame(nickname: nickname),
              ),
            );
          },
          context: context,
        ),
        _buildGameCard(
          imagePath: 'assets/colors.png',
          title: 'Color Matching',
          imageWidth: ResponsiveUtils.getResponsiveIconSize(context, mobile: 200),
          imageHeight: ResponsiveUtils.getResponsiveIconSize(context, mobile: 280),
          imageRadius: ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 15),
          cardColor: const Color(0xFFF0E6FF),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ColorMatchingGame(nickname: nickname),
              ),
            );
          },
          context: context,
        ),
      ],
    );
  }

  Widget _buildGameCard({
    required String? imagePath,
    required String title,
    double imageWidth = 120,
    double imageHeight = 120,
    double imageRadius = 10,
    VoidCallback? onTap,
    Color cardColor = const Color(0xFFFCF5D9),
    required BuildContext context,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: ResponsiveUtils.getResponsiveIconSize(context, mobile: 280),
        height: ResponsiveUtils.getResponsiveIconSize(context, mobile: 380),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 20),
          ),
          // Softer, subtler shadow for a calm, kid-friendly look
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              spreadRadius: 0.5,
              blurRadius: 8,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: EdgeInsets.all(
          ResponsiveUtils.getResponsiveSpacing(context, mobile: 15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // SPED-friendly cover: a simple icon inside a soft rounded panel
            Container(
              width: imageWidth,
              height: imageHeight,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    cardColor.withOpacity(0.9),
                    cardColor.withOpacity(0.75),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(imageRadius),
              ),
              child: Center(
                child: Container(
                  // slightly larger inner panel for clearer initials / icon
                  width: imageWidth * 0.58,
                  height: imageWidth * 0.58,
                  decoration: BoxDecoration(
                    // Off-white panel (not pure white) to reduce glare
                    color: const Color(0xFFF7F7F5),
                    borderRadius: BorderRadius.circular(imageRadius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Use a single large icon (no initial letter) for clearer game affordance
                        Icon(
                          _iconForTitle(title),
                          // Make the icon prominent and centered for quick recognition
                          size: imageWidth * 0.42,
                          color: const Color(0xFF4A4E69),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            ResponsiveSpacing(mobileSpacing: 10),
            Flexible(
              child: ResponsiveText(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF4A4E69),
                    // small letter spacing for clarity
                    letterSpacing: 0.5,
                  ),
                  // Slightly larger titles for readability, but not oversized
                  mobileFontSize: 22,
                  tabletFontSize: 24,
                  desktopFontSize: 26,
                  largeDesktopFontSize: 28,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom widget to handle image loading with error fallback
class SafeImage extends StatelessWidget {
  final String imagePath;
  final double width;
  final double height;
  final double radius;

  const SafeImage({super.key, 
    required this.imagePath,
    required this.width,
    required this.height,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(
        imagePath,
        width: width,
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey,
            child: const Icon(Icons.error, color: Colors.red),
          );
        },
      ),
    );
  }
}
