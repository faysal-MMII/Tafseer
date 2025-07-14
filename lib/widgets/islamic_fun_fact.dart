import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'dart:async';
import 'dart:math';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/islamic_fact.dart';
import '../data/islamic_months.dart';
import '../data/islamic_facts_data.dart';
import '../services/tracking_service.dart';
import '../theme/theme_provider.dart';

class IslamicFunFact extends StatefulWidget {
  @override
  _IslamicFunFactState createState() => _IslamicFunFactState();
}

class _IslamicFunFactState extends State<IslamicFunFact> {
  late HijriCalendar _hijriDate;
  late List<IslamicFact> _currentFacts;
  late int _currentFactIndex;
  Timer? _timer;
  bool _showingMonthFact = true;
  final Random _random = Random();
  bool _isDisposed = false;
  LatLng? _userLocation;
  List<String> _recentInteractions = [];

  @override
  void initState() {
    super.initState();
    _hijriDate = HijriCalendar.now();
    _loadUserData();
    _initializeFacts();
    _setupTimer();
  }

  Future<void> _loadUserData() async {
    try {
      final interactions = await UserInteractionTracker.getRecentInteractions();

      if (mounted) {
        setState(() {
          _recentInteractions = interactions;
        });

        _updateFacts();
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  void _initializeFacts() {
    try {
      if (_showingMonthFact) {
        _currentFacts = IslamicFactsData.getMonthlyFacts(_hijriDate.hMonth);
      } else {
        if (_recentInteractions.isEmpty) {
          _currentFacts = IslamicFactsData.generalFacts;
        } else {
          _currentFacts = IslamicFactsData.getPersonalizedFacts(
            userLocation: _userLocation,
            recentInteractions: _recentInteractions,
            recentSearches: [],
          );
        }
      }

      _currentFactIndex = _currentFacts.isEmpty ? 0 : _random.nextInt(_currentFacts.length);
    } catch (e) {
      print('Error initializing facts: $e');
      _currentFacts = IslamicFactsData.generalFacts;
      _currentFactIndex = 0;
    }
  }

  void _setupTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
      _updateFacts();
    });
  }

  void _updateFacts() {
    if (!mounted || _isDisposed) {
      _timer?.cancel();
      return;
    }

    try {
      setState(() {
        _showingMonthFact = !_showingMonthFact;
        _initializeFacts();
      });
    } catch (e) {
      print('Error updating facts: $e');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final accentColor = isDarkMode ? Color(0xFF1F9881) : Color(0xFF2D5F7C);

    if (_currentFacts.isEmpty) {
      return Container(); // Or some fallback widget
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header section with icon
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lightbulb_outline,
                color: accentColor,
                size: 24,
              ),
            ),
            SizedBox(width: 12),
            Text(
              "Islamic Fun Fact",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        
        // Title
        Text(
          _currentFacts[_currentFactIndex].title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Color(0xFFE0E0E0) : Color(0xFF424242),
          ),
        ),
        SizedBox(height: 8),
        
        // Content
        Text(
          _currentFacts[_currentFactIndex].description,
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: isDarkMode ? Color(0xFFCCCCCC) : Color(0xFF666666),
          ),
        ),
        
        SizedBox(height: 12),
        
        // Subtitle (month or general fact)
        Text(
          _showingMonthFact
              ? 'Current Islamic Month: ${IslamicMonths.months[_hijriDate.hMonth]}'
              : _recentInteractions.isNotEmpty
                  ? 'Based on your interests: ${_recentInteractions.first}'
                  : 'General Islamic Fact',
          style: TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}