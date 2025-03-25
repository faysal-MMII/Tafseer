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
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: Color(0xFF001333), // Dark blue background like screenshot
      appBar: AppBar(
        title: Text('Islamic Tools'),
        backgroundColor: Color(0xFF001333),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select a Tool',
              style: TextStyle(
                color: Colors.amber[100],
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
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Color(0xFF0E2552),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[800],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
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
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white70,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
