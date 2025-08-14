import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'dart:async';
import 'dart:math';
import 'package:provider/provider.dart';
import '../models/islamic_fact.dart';
import '../data/islamic_months.dart';
import '../data/islamic_facts_data.dart';
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
  final Random _random = Random();
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _hijriDate = HijriCalendar.now();
    _initializeFacts();
    _setupTimer();
  }

  void _initializeFacts() {
    try {
      // Get random facts from our simplified data structure
      _currentFacts = IslamicFactsData.getRandomFacts(10);
      
      if (_currentFacts.isEmpty) {
        _currentFacts = IslamicFactsData.allFacts;
      }

      _currentFactIndex = _currentFacts.isEmpty ? 0 : _random.nextInt(_currentFacts.length);
    } catch (e) {
      print('Error initializing facts: $e');
      _currentFacts = IslamicFactsData.allFacts;
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
        // Get a new random set of facts
        _currentFacts = IslamicFactsData.getRandomFacts(10);
        if (_currentFacts.isNotEmpty) {
          _currentFactIndex = _random.nextInt(_currentFacts.length);
        }
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
      ],
    );
  }
}