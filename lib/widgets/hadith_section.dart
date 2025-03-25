import 'package:flutter/material.dart';
import '../services/hadith_service.dart';
import '../services/openai_service.dart';
import '../models/hadith.dart';
import '../theme/text_styles.dart';
import '../services/firestore_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'hadith_card.dart';
import 'expandable_explanation.dart';
import '../widgets/formatted_text.dart';

class LoadingIndicator extends StatelessWidget {
  final String message;
  final bool isDarkMode;

  const LoadingIndicator({
    Key? key,
    this.message = 'Loading...',
    this.isDarkMode = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Color(0xFF0E2552) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          FormattedText(
            message,
            style: AppTextStyles.englishText,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class HadithSection extends StatefulWidget {
  final String? query;
  final List<Hadith> hadiths;
  final OpenAiService openAiService;
  final FirestoreService? firestoreService;
  final bool isDarkMode;

  HadithSection({
    this.query,
    required this.hadiths,
    required this.openAiService,
    this.firestoreService,
    this.isDarkMode = false,
  });

  @override
  _HadithSectionState createState() => _HadithSectionState();
}

class _HadithSectionState extends State<HadithSection> {
  late OpenAiService _openAiService;
  late final HadithService _hadithService;

  bool _isLoading = true;
  bool _isFetching = false; 
  List<Hadith> _retrievedHadiths = [];
  Map<String, dynamic>? _response;

  @override
  void initState() {
    super.initState();
    _hadithService = HadithService();  
    _hadithService.openAiService = widget.openAiService;  
    _openAiService = widget.openAiService;

    if (widget.query != null) {
      _fetchResults();
    }
  }

  Future<void> _fetchResults() async {
    if (widget.query == null) {
      return;
    }

    if (_isFetching) {
      return;
    }

    _isFetching = true;
    setState(() => _isLoading = true);

    try {
      final response = await _openAiService.generateResponse(widget.query!);
      if (mounted) {
        setState(() {
          _response = response;
        });
      }
    } catch (e) {
      print('Error in _fetchResults: $e');
    } finally {
      _isFetching = false;
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Updated clean markdown formatting function
  String _cleanMarkdownFormatting(String text) {
    text = text.replaceAllMapped(
      RegExp(r'\*\*(.*?)\*\*'), 
      (match) => match.group(1) ?? ''
    );

    text = text.replaceAllMapped(
      RegExp(r'__(.*?)__'), 
      (match) => match.group(1) ?? ''
    );

    text = text.replaceAllMapped(
      RegExp(r'\*(.*?)\*'), 
      (match) => match.group(1) ?? ''
    );

    text = text.replaceAllMapped(
      RegExp(r'_(.*?)_'), 
      (match) => match.group(1) ?? ''
    );

    // Remove numbered lists with period
    text = text.replaceAll(RegExp(r'^\d+\.\s+', multiLine: true), '');

    // Remove bullet points
    text = text.replaceAll(RegExp(r'^\s*[\*\-\•]\s+', multiLine: true), '');

    return text.trim();
  }

  Widget _buildResults() {
    final isDark = widget.isDarkMode;
    final accentColor = isDark ? Color(0xFF1F9881) : Color(0xFF2D5F7C);
    final textColor = isDark ? Color(0xFFE0E0E0) : Color(0xFF424242);

    if (_response == null) {
      return Text(
        'No results available',
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.menu_book,
                color: accentColor,
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Hadith Guidance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Color(0xFF0A1F4C) : Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SingleChildScrollView( // Add this wrapper
            child: Text(
              _cleanMarkdownFormatting(_response!['hadith_results']['answer'] ?? 'No explanation available'), // Clean the explanation
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: textColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF0E2552) : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: _isLoading
          ? LoadingIndicator(
              message: 'Searching for guidance...',
              isDarkMode: isDark,
            )
          : _buildResults(),
    );
  }

  Widget _buildErrorBox([String? errorMessage]) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFADBD8),
        borderRadius: BorderRadius.circular(8),
        border: const Border(
          left: BorderSide(
            color: Color(0xFFE74C3C),
            width: 4,
          ),
        ),
      ),
      child: FormattedText(
        errorMessage ?? 'Error fetching hadiths.',
        style: AppTextStyles.englishText.copyWith(color: Color(0xFFC0392B)),
      ),
    );
  }
}