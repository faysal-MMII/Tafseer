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
          crossAxisAlignment: CrossAxisAlignment.start,
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
              padding: EdgeInsets.all(12),
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
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 14,
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