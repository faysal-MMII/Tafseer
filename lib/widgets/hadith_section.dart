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
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';

class LoadingIndicator extends StatelessWidget {
  final String message;

  const LoadingIndicator({
    Key? key,
    this.message = 'Loading...',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
  final bool isDarkMode; // Add this parameter

  HadithSection({
    this.query,
    required this.hadiths,
    required this.openAiService,
    this.firestoreService,
    this.isDarkMode = false, // Default to light mode
  });

  @override
  _HadithSectionState createState() => _HadithSectionState();
}

class _HadithSectionState extends State<HadithSection> {
  late OpenAiService _openAiService;
  late final HadithService _hadithService;

  bool _isLoading = true; // Start with loading true
  bool _isFetching = false; 
  List<Hadith> _retrievedHadiths = [];
  Map<String, dynamic>? _response; // Make nullable

  @override
  void initState() {
    super.initState();
    print('=== HadithSection Debug ===');
    print('OpenAI Service: ${widget.openAiService}');
    print('=========================');

    print('Initializing HadithSection with query: ${widget.query}');

    _hadithService = HadithService();  
    _hadithService.openAiService = widget.openAiService;  
    _openAiService = widget.openAiService;

    if (widget.query != null) {
      _fetchResults();
    }
  }

  Future<void> _fetchResults() async {
    print('=== FETCH RESULTS START ===');

    if (widget.query == null) {
      print('Query is null, returning');
      return;
    }

    if (_isFetching) {
      print('Already fetching, returning');
      return;
    }

    _isFetching = true;
    setState(() => _isLoading = true);

    try {
      print('Starting hadith search for query: ${widget.query}');
      final hadiths = await _hadithService.searchHadiths(widget.query!);
      print('Retrieved ${hadiths.length} hadiths');

      final response = await _openAiService.generateResponse(widget.query!);
      if (mounted) {
        setState(() {
          _response = response; // Store the response
          _retrievedHadiths = hadiths;
        });
      }
    } catch (e) {
      print('Error in _fetchResults: $e');
    } finally {
      print('Resetting loading states');
      _isFetching = false;
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }

    print('=== FETCH RESULTS END ===');
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = widget.isDarkMode; // Get dark mode state

    // Skip if no hadiths
    if (widget.hadiths.isEmpty && _retrievedHadiths.isEmpty) {
      return Container();
    }

    final accentColor = isDarkMode ? Color(0xFF81B3D2) : Color(0xFF2D5F7C);

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[200], // Use theme-dependent color
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
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
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
                
                if (_response != null && _response!['hadith_results']['answer'] != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDarkMode 
                        ? Color(0xFF252525) 
                        : Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _response!['hadith_results']['answer'],
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: isDarkMode ? Color(0xFFE0E0E0) : Color(0xFF424242),
                      ),
                    ),
                  ),
                ],
                
                if (widget.hadiths.isNotEmpty) ...[
                  SizedBox(height: 20),
                  Text(
                    'Referenced Hadiths',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                  SizedBox(height: 12),
                  ...widget.hadiths.map((hadith) => _buildHadithItem(context, hadith, accentColor)).toList(),
                ],
              ],
            ),
    );
  }

  Widget _buildHadithItem(BuildContext context, Hadith hadith, Color accentColor) {
    final isDark = widget.isDarkMode;
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF252525) : Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark 
            ? Color(0xFF353535) 
            : Color(0xFFE0E0E0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hadith.narrator != null && hadith.narrator!.isNotEmpty) ...[
            Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Narrator: ${hadith.narrator}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                  fontSize: 13,
                ),
              ),
            ),
          ],
          
          Text(
            hadith.text,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: isDark ? Color(0xFFE0E0E0) : Color(0xFF424242),
            ),
          ),
          
          if (hadith.grade != null && hadith.grade!.isNotEmpty) ...[
            SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? Color(0xFF1A1A1A) : Color(0xFFEEEEEE),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Grade: ${hadith.grade}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Color(0xFFAAAAAA) : Color(0xFF777777),
                  ),
                ),
              ),
            ),
          ],
          
          if (hadith.arabicText != null && hadith.arabicText!.isNotEmpty) ...[
            SizedBox(height: 16),
            Divider(
              color: isDark ? Color(0xFF353535) : Color(0xFFEEEEEE),
            ),
            SizedBox(height: 8),
            Text(
              hadith.arabicText!,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'Scheherazade',
                fontSize: 18,
                height: 1.5,
                color: isDark ? Color(0xFFE0E0E0) : Color(0xFF424242),
              ),
            ),
          ],
        ],
      ),
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