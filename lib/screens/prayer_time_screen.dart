import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/prayer_time_service.dart';
import '../services/analytics_service.dart';
import '../theme/text_styles.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:flutter/services.dart'; // Import for SystemSound and HapticFeedback

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
  
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  
  // Date offset to handle navigation between days
  int _dateOffset = 0;
  
  @override
  void initState() {
    super.initState();
    _logScreenView();
    _updateTimeRemaining();
    
    // Update prayer times for the current date
    _updatePrayerTimesForSelectedDate();
  }
  
  @override
  void dispose() {
    _cityController.dispose();
    _countryController.dispose();
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
  
  // Navigate to previous day
  void _goToPreviousDay() {
    setState(() {
      _dateOffset--;
      _updatePrayerTimesForSelectedDate();
    });
  }
  
  // Navigate to next day
  void _goToNextDay() {
    setState(() {
      _dateOffset++;
      _updatePrayerTimesForSelectedDate();
    });
  }
  
  // Reset to today
  void _goToToday() {
    setState(() {
      _dateOffset = 0;
      _updatePrayerTimesForSelectedDate();
    });
  }
  
  // Update prayer times based on selected date
  Future<void> _updatePrayerTimesForSelectedDate() async {
    final DateTime selectedDate = DateTime.now().add(Duration(days: _dateOffset));
    await widget.prayerTimeService.getPrayerTimesForDate(selectedDate);
    _updateTimeRemaining();
  }
  
  void _showLocationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _cityController,
              decoration: InputDecoration(
                labelText: 'City',
                hintText: 'Enter city name',
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _countryController,
              decoration: InputDecoration(
                labelText: 'Country',
                hintText: 'Enter country name',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final city = _cityController.text.trim();
              final country = _countryController.text.trim();
              
              if (city.isNotEmpty && country.isNotEmpty) {
                Navigator.pop(context);
                
                setState(() {
                  // Show loading spinner
                });
                
                await widget.prayerTimeService.saveLocation(city, country);
                
                setState(() {
                  _updateTimeRemaining();
                });
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prayerTimes = widget.prayerTimeService.prayerTimes;
    final today = DateTime.now().add(Duration(days: _dateOffset));
    
    // Get Islamic date using hijri package
    final hijri = HijriCalendar.fromDate(today);
    final islamicDate = "${_getIslamicMonthName(hijri.hMonth)} ${hijri.hDay}, ${hijri.hYear} AH";
    
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
            icon: Icon(Icons.location_on, color: Colors.amber[100]),
            onPressed: _showLocationDialog,
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.amber[100]),
            onPressed: () async {
              setState(() {});
              await widget.prayerTimeService.getPrayerTimes();
              setState(() {
                _updateTimeRemaining();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Date header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios, color: Colors.orange[300]),
                  onPressed: _goToPreviousDay,
                ),
                Column(
                  children: [
                    GestureDetector(
                      onTap: _goToToday,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.orange[300]!),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _dateOffset == 0 ? 'TODAY' : 'GO TO TODAY',
                          style: TextStyle(
                            color: Colors.orange[300],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '${today.day}${_getDaySuffix(today.day)} ${_getMonthName(today.month)}',
                      style: TextStyle(
                        color: Colors.orange[300],
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      islamicDate,
                      style: TextStyle(
                        color: Colors.orange[300],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward_ios, color: Colors.orange[300]),
                  onPressed: _goToNextDay,
                ),
              ],
            ),
          ),
          
          SizedBox(height: 24),
          
          // Prayer times list
          Expanded(
            child: prayerTimes.isEmpty
                ? Center(child: CircularProgressIndicator(color: Colors.orange[300]))
                : ListView.builder(
                    physics: NeverScrollableScrollPhysics(),
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
                      final isNext = widget.prayerTimeService.nextPrayer != null && 
                                     prayer.name == widget.prayerTimeService.nextPrayer!.name;
                      
                      return _buildPrayerCard(prayer, isNext);
                    },
                  ),
          ),

          // Bottom spacer for better UI balance
          SizedBox(height: 16),
        ],
      ),
    );
  }
  
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
    
    // Month index is 1-based in HijriCalendar, but array is 0-based
    return islamicMonths[month - 1];
  }
  
  Widget _buildPrayerCard(PrayerTime prayer, bool isNext) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Color(0xFF0E2552), // Dark blue like in screenshot
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Simple bullet point instead of circle
          Text('•', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(width: 16),
          // Prayer name
          Expanded(
            child: Text(
              prayer.name,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // Prayer time
          Text(
            prayer.formattedTime,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}