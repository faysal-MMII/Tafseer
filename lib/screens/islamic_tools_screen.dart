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
    return Scaffold(
      backgroundColor: backgroundColor, // Pure white background
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Only Prayer Times - Digital Tasbeeh and Islamic Calendar REMOVED
                    _buildToolCard(
                      title: 'Prayer Times',
                      description: 'Get accurate prayer times based on your location',
                      icon: Icons.access_time,
                      color: primaryBlue,
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
                    
                    // Only Qibla Compass - Digital Tasbeeh and Islamic Calendar REMOVED  
                    _buildToolCard(
                      title: 'Qibla Compass',
                      description: 'Find the direction to Mecca for your prayers',
                      icon: Icons.explore,
                      color: lightBlue,
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
                    // Digital Tasbeeh and Islamic Calendar REMOVED as requested
                  ],
                ),
              ),
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
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          // Glassy blue boxes like home screen
          color: cardColor.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: cardColor.withOpacity(0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
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
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
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
              color: color,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}