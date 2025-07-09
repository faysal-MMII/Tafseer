import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/prayer_time_service.dart';
import '../services/analytics_service.dart';
import '../theme/text_styles.dart';
import '../theme/theme_provider.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:flutter/services.dart';

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
  String _currentLocation = 'Current Location';
  bool _isLoadingLocation = false;
  bool _isLoadingPrayerTimes = false;
  
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _logScreenView();
    _updateTimeRemaining();
    _loadCurrentLocation();
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
  
  void _updateTimeRemaining() {
    setState(() {
      _timeUntilNextPrayer = widget.prayerTimeService.getTimeUntilNextPrayer();
    });
  }
  
  // Removed all broken date navigation methods and cache
  
  Future<void> _loadCurrentLocation() async {
    // Load current location display name
    setState(() {
      _currentLocation = 'Current Location'; // Will be enhanced with actual location
    });
  }
  
  // Modern location selection with auto-refresh
  void _showModernLocationSearch(bool isDark, Color accentColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF0E2552) : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[400] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: accentColor, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Choose Your Location',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: isDark ? Colors.white70 : Colors.black54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Search field - removed non-functional search
            // Only show manual entry and popular cities that actually work
            
            // Manual Entry Option
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: _buildLocationOption(
                icon: Icons.edit_location,
                title: 'Enter Your Location',
                subtitle: 'Type your city and country',
                accentColor: accentColor,
                isDark: isDark,
                onTap: () {
                  Navigator.pop(context);
                  _showManualLocationEntry(isDark, accentColor);
                },
              ),
            ),
            
            SizedBox(height: 30),
            
            // Popular cities
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Popular Cities',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
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
                  _buildPopularCityChip('Mecca', 'Saudi Arabia', accentColor, isDark),
                  _buildPopularCityChip('Istanbul', 'Turkey', accentColor, isDark),
                  _buildPopularCityChip('London', 'UK', accentColor, isDark),
                  _buildPopularCityChip('New York', 'USA', accentColor, isDark),
                  _buildPopularCityChip('Lagos', 'Nigeria', accentColor, isDark),
                  _buildPopularCityChip('Dubai', 'UAE', accentColor, isDark),
                ],
              ),
            ),
            
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLocationOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accentColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF1A3A5C) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey[600]! : Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: accentColor, size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: isDark ? Colors.white30 : Colors.black26,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPopularCityChip(String city, String country, Color accentColor, bool isDark) {
    return Container(
      margin: EdgeInsets.only(right: 12),
      child: ActionChip(
        label: Text('$city, $country'),
        onPressed: () async {
          Navigator.pop(context);
          await _setLocationAndRefresh(city, country, accentColor);
        },
        backgroundColor: isDark ? Color(0xFF1A3A5C) : Colors.grey[100],
        labelStyle: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 13,
        ),
        side: BorderSide(
          color: isDark ? Colors.grey[500]! : Colors.grey[300]!,
        ),
      ),
    );
  }
  
  // Removed _useCurrentLocation method - was just a placeholder
  
  void _showManualLocationEntry(bool isDark, Color accentColor) {
    final cityController = TextEditingController();
    final countryController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Color(0xFF0E2552) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Enter Location',
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: cityController,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                labelText: 'City',
                labelStyle: TextStyle(color: accentColor),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: accentColor),
                ),
                filled: true,
                fillColor: isDark ? Color(0xFF1A3A5C) : Colors.grey[50],
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: countryController,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                labelText: 'Country',
                labelStyle: TextStyle(color: accentColor),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: accentColor),
                ),
                filled: true,
                fillColor: isDark ? Color(0xFF1A3A5C) : Colors.grey[50],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () async {
              final city = cityController.text.trim();
              final country = countryController.text.trim();
              
              if (city.isNotEmpty && country.isNotEmpty) {
                Navigator.pop(context);
                await _setLocationAndRefresh(city, country, accentColor);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: isDark ? Colors.black : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Set Location'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _setLocationAndRefresh(String city, String country, Color accentColor) async {
    setState(() {
      _isLoadingLocation = true;
      _isLoadingPrayerTimes = true;
      _currentLocation = '$city, $country';
    });
    
    try {
      await widget.prayerTimeService.saveLocation(city, country);
      await _refreshPrayerTimes();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location set to $city, $country'),
            backgroundColor: accentColor,
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
      });
    }
  }
  
  Future<void> _refreshPrayerTimes() async {
    setState(() {
      _isLoadingPrayerTimes = true;
    });
    
    try {
      await widget.prayerTimeService.getPrayerTimes();
      _updateTimeRemaining();
    } finally {
      setState(() {
        _isLoadingPrayerTimes = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final prayerTimes = widget.prayerTimeService.prayerTimes;
    final today = DateTime.now();
    
    // Match HomeScreen theme colors exactly
    final backgroundColor = isDark ? Color(0xFF001333) : Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = isDark ? Color(0xFF001333) : Colors.white;
    final accentColor = isDark ? Color(0xFF1F9881) : Color(0xFF2D5F7C);
    final primaryTextColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;
    final cardColor = isDark ? Color(0xFF0E2552) : Colors.grey[50];
    
    // Get Islamic date using hijri package
    final hijri = HijriCalendar.fromDate(today);
    final islamicDate = "${_getIslamicMonthName(hijri.hMonth)} ${hijri.hDay}, ${hijri.hYear} AH";
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: isDark ? Colors.white70 : Colors.blueGrey[800]),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Prayer Times',
          style: TextStyle(color: primaryTextColor),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: accentColor),
            onPressed: () async {
              await _refreshPrayerTimes();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Smart Location Card (Modern UI)
          Container(
            margin: EdgeInsets.all(16),
            child: InkWell(
              onTap: () => _showModernLocationSearch(isDark, accentColor),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: isDark ? Border.all(color: Colors.grey[700]!, width: 1) : null,
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _isLoadingLocation
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                              ),
                            )
                          : Icon(Icons.location_on, color: accentColor, size: 20),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentLocation,
                            style: TextStyle(
                              color: primaryTextColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Tap to change location',
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 13,
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
            ),
          ),
          
          // Date header (today only - remove broken navigation)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              children: [
                Text(
                  '${today.day}${_getDaySuffix(today.day)} ${_getMonthName(today.month)}',
                  style: TextStyle(
                    color: primaryTextColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  islamicDate,
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Next prayer info
          if (_timeUntilNextPrayer.isNotEmpty && widget.prayerTimeService.nextPrayer != null)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accentColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule, color: accentColor),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Next: ${widget.prayerTimeService.nextPrayer!.name}',
                          style: TextStyle(
                            color: primaryTextColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'in $_timeUntilNextPrayer',
                          style: TextStyle(
                            color: secondaryTextColor,
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
          
          // Prayer times list
          Expanded(
            child: _isLoadingPrayerTimes
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Loading prayer times...',
                          style: TextStyle(color: secondaryTextColor),
                        ),
                      ],
                    ),
                  )
                : prayerTimes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.schedule, size: 48, color: secondaryTextColor),
                            SizedBox(height: 16),
                            Text(
                              'No prayer times available',
                              style: TextStyle(color: secondaryTextColor),
                            ),
                            SizedBox(height: 8),
                            TextButton(
                              onPressed: () => _showModernLocationSearch(isDark, accentColor),
                              child: Text('Set your location'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        physics: AlwaysScrollableScrollPhysics(),
                        itemCount: 5, // Only show the 5 main prayers
                        itemBuilder: (context, index) {
                          // Filter for only the main 5 prayers
                          final prayers = prayerTimes.where((p) => 
                              p.name == "Fajr" || 
                              p.name == "Dhuhr" || 
                              p.name == "Asr" || 
                              p.name == "Maghrib" || 
                              p.name == "Isha").toList();
                          
                          if (index >= prayers.length) return Container();
                          
                          final prayer = prayers[index];
                          // Highlight next prayer for today
                          final isNext = widget.prayerTimeService.nextPrayer != null && 
                                         prayer.name == widget.prayerTimeService.nextPrayer!.name;
                          
                          return _buildPrayerCard(prayer, isNext, isDark, accentColor, primaryTextColor, cardColor);
                        },
                      ),
          ),

          // Bottom spacer for better UI balance
          SizedBox(height: 16),
        ],
      ),
    );
  }
  
  // Removed _getCurrentPrayerTimes method - using service directly
  
  // Helper function to get day suffix (1st, 2nd, 3rd, etc.)
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
  
  // Helper function to get month name
  String _getMonthName(int month) {
    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return monthNames[month - 1];
  }
  
  // Method to get Islamic month name
  String _getIslamicMonthName(int month) {
    const islamicMonths = [
      'Muharram',
      'Safar',
      'Rabi al-Awwal',
      'Rabi al-Thani',
      'Jumada al-Awwal',
      'Jumada al-Thani',
      'Rajab',
      'Sha\'ban',
      'Ramadan',
      'Shawwal',
      'Dhu al-Qi\'dah',
      'Dhu al-Hijjah'
    ];
    
    return islamicMonths[month - 1];
  }
  
  Widget _buildPrayerCard(PrayerTime prayer, bool isNext, bool isDark, Color accentColor, Color textColor, Color? cardColor) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: isNext 
          ? Border.all(color: accentColor, width: 2) 
          : (isDark ? Border.all(color: Colors.grey[700]!, width: 1) : null),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: isDark ? 6 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Prayer icon or indicator
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isNext ? accentColor : (isDark ? Colors.white70 : Colors.grey[400]),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 16),
          // Prayer name
          Expanded(
            child: Text(
              prayer.name,
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: isNext ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
          // Prayer time
          Text(
            prayer.formattedTime,
            style: TextStyle(
              color: isNext ? accentColor : textColor,
              fontSize: 18,
              fontWeight: isNext ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}