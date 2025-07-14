import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/prayer_time_service.dart';
import '../services/analytics_service.dart';
import '../theme/text_styles.dart';
import '../theme/theme_provider.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:flutter/services.dart';
import 'dart:ui'; // Needed for BackdropFilter

class PrayerTimeScreen extends StatefulWidget {
  final PrayerTimeService prayerTimeService;
  final AnalyticsService? analyticsService;

  PrayerTimeScreen({
    required this.prayerTimeService,
    this.analyticsService,
  });

  @override
  _PrayerTimeScreenState createState() => _PrayerTimeScreenState();
}

class _PrayerTimeScreenState extends State<PrayerTimeScreen> {
  String _timeUntilNextPrayer = '';
  String _currentLocation = 'Getting location...';
  bool _isLoadingLocation = false;
  bool _isLoadingPrayerTimes = false;
  
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  // MATCHING HOME SCREEN COLORS
  static const Color primaryBlue = Color(0xFF4A90E2);
  static const Color lightBlue = Color(0xFF81B3D2);
  static const Color backgroundColor = Colors.white;
  static const Color cardColor = Color(0xFFF0F7FF);
  static const Color softAccent = Color(0xFFA4D4F5);
  
  Widget glassyBlueContainer({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xFF4A90E2).withOpacity(0.2), // translucent blue
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
  
  @override
  void initState() {
    super.initState();
    _logScreenView();
    _initializePrayerService();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _logScreenView() async {
    widget.analyticsService?.logScreenView(
      screenName: 'Prayer Times',
      screenClass: 'PrayerTimeScreen',
    );
  }
  
  Future<void> _initializePrayerService() async {
    setState(() {
      _isLoadingLocation = true;
      _isLoadingPrayerTimes = true;
    });
    
    try {
      final locationName = await widget.prayerTimeService.getLocationDisplayName();
      setState(() {
        _currentLocation = locationName;
      });
      
      _updateTimeRemaining();
      
    } catch (e) {
      print("Prayer service initialization failed: $e");
      setState(() {
        _currentLocation = "Tap to set location";
      });
    } finally {
      setState(() {
        _isLoadingLocation = false;
        _isLoadingPrayerTimes = false;
      });
    }
  }
  
  void _updateTimeRemaining() {
    setState(() {
      _timeUntilNextPrayer = widget.prayerTimeService.getTimeUntilNextPrayer();
    });
  }
  
  void _showModernLocationSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: primaryBlue, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Choose Your Location',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.black54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 16),
            
            Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: _buildLocationOption(
                      icon: Icons.edit_location,
                      title: 'Enter Your Location',
                      subtitle: 'Type your city and country',
                      onTap: () {
                        Navigator.pop(context);
                        _showManualLocationEntry();
                      },
                    ),
                  ),
                  
                  SizedBox(height: 30),
                  
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Popular Cities',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 12),
                  
                  Container(
                    height: 60,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        _buildPopularCityChip('Mecca', 'Saudi Arabia', 21.4225, 39.8262),
                        _buildPopularCityChip('Istanbul', 'Turkey', 41.0082, 28.9784),
                        _buildPopularCityChip('London', 'UK', 51.5074, -0.1278),
                        _buildPopularCityChip('New York', 'USA', 40.7128, -74.0060),
                        _buildPopularCityChip('Lagos', 'Nigeria', 6.5244, 3.3792),
                        _buildPopularCityChip('Dubai', 'UAE', 25.2048, 55.2708),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _refreshPrayerTimes() async {
    setState(() {
      _isLoadingPrayerTimes = true;
    });
    
    try {
      await widget.prayerTimeService.refreshPrayerTimes();
      _updateTimeRemaining();
    } finally {
      setState(() {
        _isLoadingPrayerTimes = false;
      });
    }
  }

  Widget _buildLocationOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: primaryBlue, size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.black26,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPopularCityChip(String city, String country, double lat, double lng) {
    return Container(
      margin: EdgeInsets.only(right: 12),
      child: ActionChip(
        label: Text('$city, $country'),
        onPressed: () async {
          Navigator.pop(context);
          await _setLocationByCoordinates(lat, lng, '$city, $country');
        },
        backgroundColor: Colors.grey[100],
        labelStyle: TextStyle(
          color: Colors.black87,
          fontSize: 13,
        ),
        side: BorderSide(color: Colors.grey[300]!),
      ),
    );
  }
  
  void _showManualLocationEntry() {
    final cityController = TextEditingController();
    final countryController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Enter Location',
          style: TextStyle(color: Colors.black87),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: cityController,
              style: TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                labelText: 'City',
                labelStyle: TextStyle(color: primaryBlue),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: primaryBlue),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: countryController,
              style: TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                labelText: 'Country',
                labelStyle: TextStyle(color: primaryBlue),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: primaryBlue),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () async {
              final city = cityController.text.trim();
              final country = countryController.text.trim();
              
              if (city.isNotEmpty && country.isNotEmpty) {
                Navigator.pop(context);
                await _setLocationManually(city, country);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Set Location'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _setLocationByCoordinates(double lat, double lng, String displayName) async {
    setState(() {
      _isLoadingLocation = true;
      _isLoadingPrayerTimes = true;
      _currentLocation = displayName;
    });
    
    try {
      await widget.prayerTimeService.setLocationByCoordinates(lat, lng, displayName);
      _updateTimeRemaining();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location set to $displayName'),
            backgroundColor: primaryBlue,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error setting location'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingLocation = false;
        _isLoadingPrayerTimes = false;
      });
    }
  }
  
  Future<void> _setLocationManually(String city, String country) async {
    setState(() {
      _isLoadingLocation = true;
      _isLoadingPrayerTimes = true;
      _currentLocation = '$city, $country';
    });
    
    try {
      await widget.prayerTimeService.saveLocation(city, country);
      _updateTimeRemaining();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location set to $city, $country'),
            backgroundColor: primaryBlue,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error setting location'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingLocation = false;
        _isLoadingPrayerTimes = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final prayerTimes = widget.prayerTimeService.prayerTimes;
    final today = DateTime.now();
    
    final hijri = HijriCalendar.fromDate(today);
    final islamicDate = "${_getIslamicMonthName(hijri.hMonth)} ${hijri.hDay}, ${hijri.hYear} AH";
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.blueGrey[800]),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Prayer Times',
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: primaryBlue),
            onPressed: () async {
              await _refreshPrayerTimes();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: EdgeInsets.all(16),
            child: InkWell(
              onTap: () => _showModernLocationSearch(),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: cardColor.withOpacity(0.6),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withOpacity(0.15),
                      blurRadius: 30,
                      offset: Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.2),
                      blurRadius: 15,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _isLoadingLocation
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                              ),
                            )
                          : Icon(Icons.location_on, color: primaryBlue, size: 20),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentLocation,
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Tap to change location',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: primaryBlue,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              children: [
                Text(
                  '${today.day}${_getDaySuffix(today.day)} ${_getMonthName(today.month)}',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  islamicDate,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Add the glassy blue container here
          Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: glassyBlueContainer(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.search, color: Colors.white, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ask Islamic Questions',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Get answers from Quran and Hadith',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (_timeUntilNextPrayer.isNotEmpty && widget.prayerTimeService.nextPrayer != null)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryBlue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule, color: primaryBlue),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Next: ${widget.prayerTimeService.nextPrayer!.name}',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'in $_timeUntilNextPrayer',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          
          SizedBox(height: 16),
          
          Expanded(
            child: _isLoadingPrayerTimes
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Loading prayer times...',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  )
                : prayerTimes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.schedule, size: 48, color: Colors.black54),
                            SizedBox(height: 16),
                            Text(
                              'No prayer times available',
                              style: TextStyle(color: Colors.black54),
                            ),
                            SizedBox(height: 8),
                            TextButton(
                              onPressed: () => _showModernLocationSearch(),
                              child: Text('Set your location'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        physics: AlwaysScrollableScrollPhysics(),
                        itemCount: 5,
                        itemBuilder: (context, index) {
                          final prayers = prayerTimes.where((p) => 
                              p.name == "Fajr" || 
                              p.name == "Dhuhr" || 
                              p.name == "Asr" || 
                              p.name == "Maghrib" || 
                              p.name == "Isha").toList();
                          
                          if (index >= prayers.length) return Container();
                          
                          final prayer = prayers[index];
                          final isNext = widget.prayerTimeService.nextPrayer != null && 
                                         prayer.name == widget.prayerTimeService.nextPrayer!.name;
                          
                          return _buildPrayerCard(prayer, isNext);
                        },
                      ),
          ),

          SizedBox(height: 16),
        ],
      ),
    );
  }
  
  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) {
      return 'th';
    }
    switch (day % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }
  
  String _getMonthName(int month) {
    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return monthNames[month - 1];
  }
  
  String _getIslamicMonthName(int month) {
    const islamicMonths = [
      'Muharram', 'Safar', 'Rabi al-Awwal', 'Rabi al-Thani',
      'Jumada al-Awwal', 'Jumada al-Thani', 'Rajab', 'Sha\'ban',
      'Ramadan', 'Shawwal', 'Dhu al-Qi\'dah', 'Dhu al-Hijjah'
    ];
    
    return islamicMonths[month - 1];
  }
  
  Widget _buildPrayerCard(PrayerTime prayer, bool isNext) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: isNext 
          ? Border.all(color: primaryBlue, width: 2) 
          : Border.all(
              color: cardColor.withOpacity(0.5),
              width: 1,
            ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isNext ? primaryBlue : Colors.grey[400],
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              prayer.name,
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: isNext ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
          Text(
            prayer.formattedTime,
            style: TextStyle(
              color: isNext ? primaryBlue : Colors.black87,
              fontSize: 18,
              fontWeight: isNext ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}