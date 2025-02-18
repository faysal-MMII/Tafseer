import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'dart:async';
import 'dart:math';
import '../models/islamic_fact.dart';
import '../data/islamic_months.dart';
import '../data/islamic_facts_data.dart';
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

  @override
  void initState() {
    super.initState();
    _hijriDate = HijriCalendar.now();
    _updateCurrentFacts();
    _setupTimer();
  }

  void _setupTimer() {
    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
      if (mounted) {
        setState(() {
          _showingMonthFact = !_showingMonthFact;
          _updateCurrentFacts();
        });
      }
    });
  }

  void _updateCurrentFacts() {
    _currentFacts = _showingMonthFact
        ? IslamicFactsData.getMonthlyFacts(_hijriDate.hMonth)
        : IslamicFactsData.generalFacts;
    _currentFactIndex = _random.nextInt(_currentFacts.length);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            : 'General Islamic Fact',
      ),
    );
  }
}