import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
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
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final accentColor = isDark ? Color(0xFF1F9881) : Color(0xFF2D5F7C);

    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(accentColor),
        ),
      );
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
      margin: EdgeInsets.symmetric(horizontal: 8), // Match the search box horizontal padding
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark 
              ? Colors.black.withOpacity(0.5) 
              : Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: isDark ? 12 : 10,
            offset: Offset(0, 3),
          ),
        ],
        border: isDark ? Border.all(color: Colors.grey[800]!, width: 1) : null, // Subtle border for more depth
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Frequently Asked Questions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
          SizedBox(height: 16),
          ...faqs.map((faq) => _buildFAQItem(context, faq, isDark, accentColor)).toList(),
        ],
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, Map<String, dynamic> faq, bool isDark, Color accentColor) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF0A1F4C) : Color(0xFFF8F9FA), // Updated to blue shade
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Color(0xFF1A3366) : Color(0xFFE0E0E0),
          width: 1,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          title: Text(
            faq['question'],
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isDark ? Color(0xFFE0E0E0) : Color(0xFF424242),
            ),
          ),
          trailing: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.add,
              size: 18,
              color: accentColor,
            ),
          ),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          childrenPadding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
          children: [
            Divider(
              color: isDark ? Color(0xFF353535) : Color(0xFFEEEEEE),
              height: 24,
            ),
            Text(
              faq['answer'],
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: isDark ? Color(0xFFCCCCCC) : Color(0xFF666666),
              ),
            ),
          ],
        ),
      ),
    );
  }
}