import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../services/analytics_service.dart';
import '../services/prayer_time_service.dart';
import '../services/qibla_service.dart';
import '../theme/theme_provider.dart';
import 'prayer_time_screen.dart';
import './qibla_screen.dart';

class IslamicToolsScreen extends StatefulWidget {
  final PrayerTimeService prayerTimeService;
  final QiblaService qiblaService;
  final AnalyticsService? analyticsService;

  IslamicToolsScreen({
    required this.prayerTimeService,
    required this.qiblaService,
    this.analyticsService,
  });

  @override
  _IslamicToolsScreenState createState() => _IslamicToolsScreenState();
}

class _IslamicToolsScreenState extends State<IslamicToolsScreen> {
  // Updated colors to match home screen
  static const Color primaryBlue = Color(0xFF4A90E2);
  static const Color lightBlue = Color(0xFF81B3D2);
  static const Color backgroundColor = Colors.white; // Pure white background
  static const Color cardColor = Color(0xFFF0F7FF); // Glassy blue for boxes

  @override
  void initState() {
    super.initState();
    _logScreenView();
  }

  Future<void> _logScreenView() async {
    widget.analyticsService?.logScreenView(
      screenName: 'Islamic Tools',
      screenClass: 'IslamicToolsScreen',
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    // Match HomeScreen theme colors exactly
    final backgroundColor = isDark ? Color(0xFF001333) : Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = isDark ? Color(0xFF001333) : Colors.white;
    final accentColor = isDark ? Color(0xFF1F9881) : Color(0xFF2D5F7C);
    final primaryTextColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;
    final cardColor = isDark ? Color(0xFF0E2552) : Colors.grey[50];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Islamic Tools',
          style: TextStyle(color: primaryTextColor),
        ),
        backgroundColor: surfaceColor,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white70 : Colors.blueGrey[800]),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              'Select a Tool',
              style: TextStyle(
                color: primaryTextColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 32),
            
            // Prayer Times Card
            _buildToolCard(
              title: 'Prayer Times',
              description: 'Get accurate prayer times based on your location',
              icon: Icons.access_time,
              isDark: isDark,
              accentColor: accentColor,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
              cardColor: cardColor,
              onTap: () {
                widget.analyticsService?.logFeatureUsed('prayer_time_screen');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PrayerTimeScreen(
                      prayerTimeService: widget.prayerTimeService,
                      analyticsService: widget.analyticsService,
                    ),
                  ),
                );
              },
            ),
            
            SizedBox(height: 16),
            
            // Qibla Compass Card
            _buildToolCard(
              title: 'Qibla Compass',
              description: 'Find the direction to Mecca for your prayers',
              icon: Icons.explore,
              isDark: isDark,
              accentColor: accentColor,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
              cardColor: cardColor,
              onTap: () {
                widget.analyticsService?.logFeatureUsed('qibla_screen');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QiblaScreen(
                      qiblaService: widget.qiblaService,
                      analyticsService: widget.analyticsService,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        // Glassy blue box like home screen
        color: cardColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cardColor.withOpacity(0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 25,
            color: primaryBlue.withOpacity(0.15),
            offset: Offset(0, 8),
          ),
          // Inner glow for glassmorphism
          BoxShadow(
            blurRadius: 15,
            color: Colors.white.withOpacity(0.2),
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_back,
                color: primaryBlue,
                size: 20,
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Islamic Tools',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
                Text(
                  'Essential tools for your daily worship',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolCard({
    required String title,
    required String description,
    required IconData icon,
    required bool isDark,
    required Color accentColor,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required Color? cardColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: isDark ? Border.all(color: Colors.grey[800]!, width: 1) : null,
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.1),
              blurRadius: isDark ? 8 : 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: accentColor.withOpacity(0.3)),
              ),
              child: Icon(
                icon,
                color: accentColor,
                size: 28,
              ),
            ),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: accentColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}