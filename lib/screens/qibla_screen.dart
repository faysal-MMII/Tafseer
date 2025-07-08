import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../services/qibla_service.dart';
import '../services/analytics_service.dart';
import '../theme/theme_provider.dart';

class QiblaScreen extends StatefulWidget {
  final QiblaService qiblaService;
  final AnalyticsService? analyticsService;

  QiblaScreen({
    required this.qiblaService,
    this.analyticsService,
  });

  @override
  _QiblaScreenState createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> with WidgetsBindingObserver {
  bool _isCalibrating = true;
  String _error = '';
  double _qiblaAngle = 0;
  String _locationName = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
    _logScreenView();
    
    // Listen to qibla stream
    widget.qiblaService.qiblaStream.listen((angle) {
      setState(() {
        _qiblaAngle = angle;
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Recalculate when app comes to foreground
      _initialize();
    }
  }

  Future<void> _logScreenView() async {
    widget.analyticsService?.logScreenView(
      screenName: 'Qibla Compass',
      screenClass: 'QiblaScreen',
    );
  }

  Future<void> _initialize() async {
    setState(() {
      _isCalibrating = true;
      _error = '';
    });

    try {
      await widget.qiblaService.calculateQiblaDirection();
      _locationName = await widget.qiblaService.getLocationName();
      
      setState(() {
        _isCalibrating = false;
      });
    } catch (e) {
      setState(() {
        _isCalibrating = false;
        _error = e.toString();
      });
    }
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
        backgroundColor: surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: isDark ? Colors.white70 : Colors.blueGrey[800]),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: accentColor),
            onPressed: _initialize,
          ),
        ],
      ),
      body: _error.isNotEmpty
          ? _buildErrorView(primaryTextColor, secondaryTextColor, accentColor)
          : _isCalibrating
              ? _buildCalibrationView(primaryTextColor, secondaryTextColor)
              : _buildCompassView(isDark, primaryTextColor, secondaryTextColor, accentColor, cardColor),
    );
  }

  Widget _buildCalibrationView(Color primaryTextColor, Color secondaryTextColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: primaryTextColor),
          SizedBox(height: 24),
          Text(
            'Calibrating compass...',
            style: TextStyle(fontSize: 18, color: primaryTextColor),
          ),
          SizedBox(height: 12),
          Text(
            'Please wave your device in a figure-8 pattern',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: secondaryTextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(Color primaryTextColor, Color secondaryTextColor, Color accentColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 72,
              color: Colors.red[400],
            ),
            SizedBox(height: 24),
            Text(
              'Error',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryTextColor),
            ),
            SizedBox(height: 16),
            Text(
              _error,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: secondaryTextColor),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              icon: Icon(Icons.refresh),
              label: Text('Try Again'),
              onPressed: _initialize,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompassView(bool isDark, Color primaryTextColor, Color secondaryTextColor, Color accentColor, Color? cardColor) {
    return StreamBuilder<double>(
      stream: widget.qiblaService.compassStream,
      builder: (context, snapshot) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Location section with real location
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'LOCATION',
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.location_on,
                    color: secondaryTextColor,
                    size: 16,
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 8),
            
            // Location pill with real location
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: isDark ? Border.all(color: Colors.grey[800]!, width: 1) : null,
                ),
                child: Text(
                  _locationName.isNotEmpty ? _locationName : 'Loading location...',
                  style: TextStyle(
                    color: primaryTextColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            
            SizedBox(height: 32),
            
            // Compass
            Expanded(
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Compass circle
                    Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? Colors.white.withOpacity(0.9) : Colors.white,
                        border: isDark ? Border.all(color: Colors.grey[300]!, width: 2) : null,
                        boxShadow: [
                          BoxShadow(
                            color: isDark ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                    
                    // Direction labels
                    Positioned(
                      top: 20,
                      child: Text('N', style: TextStyle(color: Colors.grey[600], fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    Positioned(
                      right: 20,
                      child: Text('E', style: TextStyle(color: Colors.grey[600], fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    Positioned(
                      bottom: 20,
                      child: Text('S', style: TextStyle(color: Colors.grey[600], fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    Positioned(
                      left: 20,
                      child: Text('W', style: TextStyle(color: Colors.grey[600], fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    
                    // Needle (using Transform to rotate it)
                    Transform.rotate(
                      angle: _qiblaAngle * (math.pi / 180),
                      child: Container(
                        width: 40,
                        height: 120,
                        child: CustomPaint(
                          painter: CompassNeedlePainter(accentColor),
                        ),
                      ),
                    ),
                    
                    // Kaaba icon
                    Positioned(
                      right: 80,
                      child: Transform.rotate(
                        angle: -_qiblaAngle * (math.pi / 180),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            border: Border.all(color: accentColor, width: 2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            Icons.location_city,
                            color: accentColor,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Direction instruction
            Container(
              margin: EdgeInsets.symmetric(horizontal: 24),
              padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: isDark ? Border.all(color: Colors.grey[800]!, width: 1) : null,
              ),
              child: Text(
                _getDirectionText(_qiblaAngle),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: primaryTextColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            
            SizedBox(height: 40), // Extra space at bottom
          ],
        );
      },
    );
  }
  
  String _getDirectionText(double angle) {
    // Determine which direction to turn based on the qibla angle
    if (angle >= 355 || angle < 5) {
      return "You are facing Qibla";
    } else if (angle >= 180) {
      return "Turn to your left";
    } else {
      return "Turn to your right";
    }
  }
}

// Custom painter for the compass needle
class CompassNeedlePainter extends CustomPainter {
  final Color accentColor;
  
  CompassNeedlePainter(this.accentColor);
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Draw the needle pointing north
    final needlePaint = Paint()..color = accentColor;
    
    final needlePath = Path();
    needlePath.moveTo(center.dx, center.dy - size.height / 2); // Top point
    needlePath.lineTo(center.dx - 8, center.dy); // Left point
    needlePath.lineTo(center.dx + 8, center.dy); // Right point
    needlePath.close();
    
    canvas.drawPath(needlePath, needlePaint);
    
    // Draw center circle
    final centerPaint = Paint()..color = accentColor;
    canvas.drawCircle(center, 6, centerPaint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}