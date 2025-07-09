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
  // Modern blue theme colors
  static const Color primaryBlue = Color(0xFF4A90E2);
  static const Color lightBlue = Color(0xFF81B3D2);
  static const Color backgroundColor = Color(0xFFF8FBFF);
  static const Color cardColor = Colors.white;

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
      backgroundColor: backgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [backgroundColor, Color(0xFFEEF7FF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
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

                      SizedBox(height: 16),
                      
                      _buildToolCard(
                        title: 'Digital Tasbeeh',
                        description: 'Count your dhikr and track your spiritual progress',
                        icon: Icons.favorite,
                        color: Color(0xFF28C76F),
                        onTap: () {
                          // TODO: Navigate to Tasbeeh screen when implemented
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Digital Tasbeeh coming soon!'),
                              backgroundColor: primaryBlue,
                            ),
                          );
                        },
                      ),

                      SizedBox(height: 16),
                      
                      _buildToolCard(
                        title: 'Islamic Calendar',
                        description: 'View important Islamic dates and events',
                        icon: Icons.calendar_today,
                        color: Color(0xFFFF6B35),
                        onTap: () {
                          // TODO: Navigate to Islamic Calendar when implemented
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Islamic Calendar coming soon!'),
                              backgroundColor: primaryBlue,
                            ),
                          );
                        },
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

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
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
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
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