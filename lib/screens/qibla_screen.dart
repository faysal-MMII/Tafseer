import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../services/qibla_service.dart';
import '../services/analytics_service.dart';

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
    return Scaffold(
      backgroundColor: Color(0xFF001333), // Dark blue background like screenshot
      appBar: AppBar(
        backgroundColor: Color(0xFF001333),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.amber[100]),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.amber[100]),
            onPressed: _initialize,
          ),
        ],
      ),
      body: _error.isNotEmpty
          ? _buildErrorView()
          : _isCalibrating
              ? _buildCalibrationView()
              : _buildCompassView(),
    );
  }

  Widget _buildCalibrationView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 24),
          Text(
            'Calibrating compass...',
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
          SizedBox(height: 12),
          Text(
            'Please wave your device in a figure-8 pattern',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
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
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            SizedBox(height: 16),
            Text(
              _error,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              icon: Icon(Icons.refresh),
              label: Text('Try Again'),
              onPressed: _initialize,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompassView() {
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
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.location_on,
                    color: Colors.grey[400],
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
                  color: Color(0xFF0E2552),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  _locationName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
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
                        color: Colors.white,
                      ),
                    ),
                    
                    // Direction labels
                    Positioned(
                      top: 20,
                      child: Text('N', style: TextStyle(color: Colors.grey[400], fontSize: 20)),
                    ),
                    Positioned(
                      right: 20,
                      child: Text('E', style: TextStyle(color: Colors.grey[400], fontSize: 20)),
                    ),
                    Positioned(
                      bottom: 20,
                      child: Text('S', style: TextStyle(color: Colors.grey[400], fontSize: 20)),
                    ),
                    Positioned(
                      left: 20,
                      child: Text('W', style: TextStyle(color: Colors.grey[400], fontSize: 20)),
                    ),
                    
                    // Needle (using Transform to rotate it)
                    Transform.rotate(
                      angle: _qiblaAngle * (math.pi / 180),
                      child: Container(
                        width: 40,
                        height: 120,
                        child: CustomPaint(
                          painter: CompassNeedlePainter(),
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
                            border: Border.all(color: Colors.amber, width: 1),
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
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                _getDirectionText(_qiblaAngle),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 20,
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
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Draw the needle pointing north (orange)
    final needlePaint = Paint()..color = Colors.orange[300]!;
    
    final needlePath = Path();
    needlePath.moveTo(center.dx, center.dy - size.height / 2); // Top point
    needlePath.lineTo(center.dx - 8, center.dy); // Left point
    needlePath.lineTo(center.dx + 8, center.dy); // Right point
    needlePath.close();
    
    canvas.drawPath(needlePath, needlePaint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}