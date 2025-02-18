import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../theme/text_styles.dart';

class FAQSection extends StatefulWidget {
  @override
  _FAQSectionState createState() => _FAQSectionState();
}

class _FAQSectionState extends State<FAQSection> {
  List<Map<String, dynamic>> faqs = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadFAQData();
  }

  Future<void> loadFAQData() async {
    try {
      final String response = await rootBundle.loadString('assets/data/faq_data.json');
      final data = await json.decode(response);

      setState(() {
        faqs = List<Map<String, dynamic>>.from(data['muslim_faq']) +
               List<Map<String, dynamic>>.from(data['revert_faq']);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
      print('Error loading FAQ data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Text(
          'Error loading FAQs: $error', 
          style: AppTextStyles.englishText.copyWith(color: Colors.red),
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 20),
      padding: EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFE6E6E6)],
        ),
        borderRadius: BorderRadius.circular(8),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Frequently Asked Questions for Muslims',
            style: AppTextStyles.titleText.copyWith(fontSize: 24),
          ),
          SizedBox(height: 20),
          _buildFAQList(faqs),
        ],
      ),
    );
  }

  Widget _buildFAQList(List<Map<String, dynamic>> faqs) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Column(
        children: faqs.map((faq) => _buildFAQItem(faq)).toList(),
      ),
    );
  }

  Widget _buildFAQItem(Map<String, dynamic> faq) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            faq['question'],
            style: AppTextStyles.englishText.copyWith(fontWeight: FontWeight.bold),
          ),
          children: [
            Container(
              padding: EdgeInsets.all(16),
              width: double.infinity,
              child: Text(
                faq['answer'],
                style: AppTextStyles.englishText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
