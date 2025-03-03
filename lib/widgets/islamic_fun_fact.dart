import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'dart:async';
import 'dart:math';
import 'package:latlong2/latlong.dart';
import '../models/islamic_fact.dart';
import '../data/islamic_months.dart';
import '../data/islamic_facts_data.dart';
import '../services/tracking_service.dart';
import './fact_display.dart';

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
      // Get recent interactions from tracking service
      final interactions = await UserInteractionTracker.getRecentInteractions();
      
      if (mounted) {
        setState(() {
          _recentInteractions = interactions;
        });
        
        // Force update facts after loading interactions
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
        // If no interactions yet, use general facts
        if (_recentInteractions.isEmpty) {
          _currentFacts = IslamicFactsData.generalFacts;
        } else {
          // Use personalized facts based on interactions
          _currentFacts = IslamicFactsData.getPersonalizedFacts(
            userLocation: _userLocation,
            recentInteractions: _recentInteractions,
            recentSearches: [], // You can add search history here if needed
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
        _initializeFacts(); // This will select appropriate facts based on _showingMonthFact
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
    // Add null safety check
    if (_currentFacts.isEmpty) {
      return Container(); // Or some fallback widget
    }
    
    return Container(
      margin: EdgeInsets.symmetric(vertical: 20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF0F0F0)],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFD1D1D1),
            offset: Offset(5, 5),
            blurRadius: 10,
          ),
          BoxShadow(
            color: Colors.white,
            offset: Offset(-5, -5),
            blurRadius: 10,
          ),
        ],
      ),
      child: FactDisplay(
        fact: _currentFacts[_currentFactIndex],
        subtitle: _showingMonthFact
            ? 'Current Islamic Month: ${IslamicMonths.months[_hijriDate.hMonth]}'
            : _recentInteractions.isNotEmpty
                ? 'Based on your interests: ${_recentInteractions.first}'
                : 'General Islamic Fact',
      ),
    );
  }
}