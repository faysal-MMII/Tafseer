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
import '../widgets/shimmer_loading_effect.dart';

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
          FormattedText( // Use FormattedText here
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

  HadithSection({
    this.query,
    required this.hadiths,
    required this.openAiService,
    this.firestoreService,
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

  Widget _buildHadithItem(Hadith hadith) {
    print('Building hadith item for: ${hadith.text}');
    return HadithCard(
      hadith: hadith,
      showExpandButton: true,
    );
  }

  Widget _buildResults() {
    if (_response == null) {
      return FormattedText( // Use FormattedText here
        'No results available',
        style: AppTextStyles.englishText,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormattedText( // Use FormattedText here
          'Hadith Guidance',
          style: AppTextStyles.titleText,
        ),
        SizedBox(height: 16),
        ExpandableExplanation(
          text: _response!['hadith_results']['answer'] ?? 'No explanation available',            
          style: AppTextStyles.englishText,
        ),
        SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
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
      child: FormattedText( // Use FormattedText here
        errorMessage ?? 'Error fetching hadiths.',
        style: AppTextStyles.englishText.copyWith(color: Color(0xFFC0392B)),
      ),
    );
  }
}