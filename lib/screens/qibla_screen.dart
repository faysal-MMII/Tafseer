import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/qibla_service.dart';
import '../services/analytics_service.dart';
import '../services/prayer_time_service.dart';
import '../theme/theme_provider.dart';
import 'package:timezone/timezone.dart' as tz;

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

class _QiblaScreenState extends State<QiblaScreen> with WidgetsBindingObserver, TickerProviderStateMixin {
  bool _isCalibrating = true;
  String _error = '';
  double _qiblaAngle = 0;
  String _locationName = '';
  PrayerTimeService? _prayerService;
  
  // Animation controllers for enhanced effects
  late AnimationController _pulseController;
  late AnimationController _starController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _starAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAnimations();
    _initialize();
    _logScreenView();
    
    // Listen to qibla stream 
    widget.qiblaService.qiblaStream.listen((angle) {
      setState(() {
        _qiblaAngle = angle;
      });
    });
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _starController = AnimationController(
      duration: Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _starAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _starController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    _starController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
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
      
      // Initialize prayer service for theme calculations
      try {
        _prayerService = PrayerTimeService();
        // Try common initialization method names - adjust based on your actual PrayerTimeService
        // await _prayerService!.initialize(); // Try this if you have an initialize() method
        // await _prayerService!.getCurrentLocation(); // Or this if you have getCurrentLocation()
        print("Prayer service initialized for theme calculations");
      } catch (prayerError) {
        print("Could not initialize prayer service: $prayerError");
        // Continue without prayer service - will fall back to static themes
      }
      
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

  // Get current hour in user's actual timezone
  int _getCurrentHourInUserTimezone() {
    try {
      final now = tz.TZDateTime.now(tz.local);
      return now.hour;
    } catch (e) {
      print("Error getting timezone-aware hour: $e");
      return DateTime.now().hour;
    }
  }

  Gradient _getTimeBasedGradient() {
    final hour = _getCurrentHourInUserTimezone();
    
    // More logical transition times
    if (hour >= 4 && hour < 7) {
      // Dawn/Fajr colors (4:30 AM - 7:00 AM)
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF1a237e), 
          Color(0xFF3949ab), 
          Color(0xFF7986cb),
          Color(0xFFc5cae9), 
        ],
      );
    } else if (hour >= 7 && hour < 12) {
      // Morning colors (7:00 AM - 11:30 AM)
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF0277bd), 
          Color(0xFF29b6f6), 
          Color(0xFF81d4fa), 
          Color(0xFFe1f5fe), 
        ],
      );
    } else if (hour >= 12 && hour < 15) {
      // Dhuhr colors (11:30 AM - 2:30 PM)
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF3e2723), 
          Color(0xFF8d6e63), 
          Color(0xFFd7ccc8), 
          Color(0xFFf5f5dc), 
        ],
      );
    } else if (hour >= 15 && hour < 18) {
      // Asr colors (2:30 PM - 6:00 PM)
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFe65100), 
          Color(0xFFff9800), 
          Color(0xFFffcc02), 
          Color(0xFFfff3e0), 
        ],
      );
    } else if (hour >= 18 && hour < 20) {
      // Maghrib colors (6:00 PM - 8:00 PM)
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFbf360c),
          Color(0xFFf4511e),
          Color(0xFFff8a65),
          Color(0xFFffccbc),
        ],
      );
    } else {
      // Night colors (8:00 PM - 4:30 AM)
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF000051),
          Color(0xFF1a237e),
          Color(0xFF303f9f),
          Color(0xFF3f51b5),
        ],
      );
    }
  }

  Color _getTextColor() {
    final hour = _getCurrentHourInUserTimezone();
    if (hour >= 7 && hour < 19) {
      return Colors.black87;
    } else {
      return Colors.white;
    }
  }

  bool _isNightTime() {
    final hour = _getCurrentHourInUserTimezone();
    return hour >= 20 || hour < 5;
  }

  // Build stars for night time
  List<Widget> _buildStars() {
    return List.generate(30, (index) {
      final random = math.Random(index);
      return AnimatedBuilder(
        animation: _starAnimation,
        builder: (context, child) {
          return Positioned(
            top: random.nextDouble() * 200 + 100,
            left: random.nextDouble() * MediaQuery.of(context).size.width,
            child: Opacity(
              opacity: _starAnimation.value * random.nextDouble(),
              child: Icon(
                Icons.star,
                size: random.nextDouble() * 3 + 2,
                color: Colors.white,
              ),
            ),
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    final textColor = _getTextColor();
    final cardColor = Colors.white.withOpacity(0.9);
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Qibla Compass',
          style: GoogleFonts.poppins(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: textColor),
            onPressed: _initialize,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: _getTimeBasedGradient()),
        child: Stack(
          children: [
            if (_isNightTime()) ..._buildStars(),
            
            SafeArea(
              child: _error.isNotEmpty
                  ? _buildErrorView(textColor, cardColor)
                  : _isCalibrating
                      ? _buildCalibrationView(textColor)
                      : _buildCompassView(textColor, cardColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalibrationView(Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: textColor),
          SizedBox(height: 24),
          Text(
            'Calibrating compass...',
            style: TextStyle(fontSize: 18, color: textColor),
          ),
          SizedBox(height: 12),
          Text(
            'Please wave your device in a figure-8 pattern',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(Color textColor, Color cardColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 72,
                color: Colors.red[400],
              ),
              SizedBox(height: 24),
              Text(
                'Error',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              SizedBox(height: 16),
              Text(
                _error,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                icon: Icon(Icons.refresh),
                label: Text('Try Again'),
                onPressed: _initialize,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4A90E2),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompassView(Color textColor, Color cardColor) {
    return StreamBuilder<double>(
      stream: widget.qiblaService.compassStream,
      builder: (context, snapshot) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 52),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'LOCATION',
                    style: TextStyle(
                      color: textColor.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.location_on,
                    color: textColor.withOpacity(0.8),
                    size: 16,
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 8),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Text(
                  _locationName.isNotEmpty ? _locationName : 'Loading location...',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            
            SizedBox(height: 32),
            
            Expanded(
              child: Center(
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 280,
                            height: 280,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.9),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                  offset: Offset(0, 15),
                                ),
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.5),
                                  blurRadius: 20,
                                  spreadRadius: -5,
                                  offset: Offset(0, -5),
                                ),
                              ],
                            ),
                          ),
                          
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
                          
                          Transform.rotate(
                            angle: _qiblaAngle * (math.pi / 180),
                            child: Container(
                              width: 40,
                              height: 120,
                              child: CustomPaint(
                                painter: EnhancedCompassNeedlePainter(),
                              ),
                            ),
                          ),
                          
                          Positioned(
                            right: 80,
                            child: Transform.rotate(
                              angle: -_qiblaAngle * (math.pi / 180),
                              child: Container(
                                width: 35,
                                height: 35,
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  border: Border.all(color: Color(0xFF4A90E2), width: 2),
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    '🕋',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            
            Container(
              margin: EdgeInsets.symmetric(horizontal: 24),
              padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Text(
                _getDirectionText(_qiblaAngle),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            
            SizedBox(height: 40),
          ],
        );
      },
    );
  }
  
  String _getDirectionText(double angle) {
    if (angle >= 355 || angle < 5) {
      return "You are facing Qibla ✨";
    } else if (angle >= 180) {
      return "Turn to your left ←";
    } else {
      return "Turn to your right →";
    }
  }
}

class EnhancedCompassNeedlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    final needlePaint = Paint()
      ..shader = LinearGradient(
        colors: [Color(0xFFd32f2f), Color(0xFF2196f3)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    final needlePath = Path();
    needlePath.moveTo(center.dx, center.dy - size.height / 2);
    needlePath.lineTo(center.dx - 10, center.dy);
    needlePath.lineTo(center.dx + 10, center.dy);
    needlePath.close();
    
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3);
    
    canvas.drawPath(needlePath.shift(Offset(2, 2)), shadowPaint);
    canvas.drawPath(needlePath, needlePaint);
    
    final centerPaint = Paint()
      ..color = Color(0xFF4A90E2)
      ..style = PaintingStyle.fill;
    
    final centerBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawCircle(center, 8, centerPaint);
    canvas.drawCircle(center, 8, centerBorderPaint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}