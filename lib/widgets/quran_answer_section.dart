import 'package:flutter/material.dart';
import '../theme/text_styles.dart';
import '../widgets/formatted_text.dart';

class QuranAnswerSection extends StatelessWidget {
  final String answer;
  
  const QuranAnswerSection({
    Key? key,
    required this.answer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Parse the answer to separate paragraphs
    List<String> paragraphs = _parseParagraphs(answer);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: paragraphs.map((paragraph) {
          // Check if this paragraph is a verse reference
          bool isVerse = paragraph.trim().startsWith("Verse ");
          
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isVerse)
                  // Verse icon for verse references
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(right: 12, top: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.menu_book,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                Expanded(
                  child: FormattedText(
                    paragraph,
                    style: isVerse 
                      ? AppTextStyles.englishText.copyWith(
                          fontStyle: FontStyle.italic,
                          color: const Color(0xFF4CAF50),
                          fontWeight: FontWeight.w500,
                        )
                      : AppTextStyles.englishText,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
  
  // Function to parse the answer into separate paragraphs
  List<String> _parseParagraphs(String text) {
    // First remove any numbering (like "1.", "2.", etc.)
    final cleanedText = text.replaceAll(RegExp(r'^\d+\.\s', multiLine: true), '');
    
    // Split by double newlines or by verse references
    List<String> paragraphs = [];
    
    // Check for verse references
    final RegExp versePattern = RegExp(r'Verse \d+:\d+');
    if (versePattern.hasMatch(cleanedText)) {
      // Split by verse references
      List<String> segments = cleanedText.split(versePattern);
      List<RegExpMatch> matches = versePattern.allMatches(cleanedText).toList();
      
      // Combine segments with verse references
      for (int i = 0; i < segments.length; i++) {
        String segment = segments[i].trim();
        if (segment.isNotEmpty) {
          paragraphs.add(segment);
        }
        
        if (i < matches.length) {
          paragraphs.add(matches[i].group(0)!);
        }
      }
    } else {
      // No verse references, just split by paragraphs
      paragraphs = cleanedText.split(RegExp(r'\n\s*\n'));
    }
    
    // Trim and remove empty paragraphs
    paragraphs = paragraphs.map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
    
    // If we ended up with nothing, return the original text
    return paragraphs.isEmpty ? [text] : paragraphs;
  }
}