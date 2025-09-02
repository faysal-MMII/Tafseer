import 'package:flutter/material.dart';
import '../theme/text_styles.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class HadithDetailScreen extends StatelessWidget {
  final Map<String, dynamic> hadith;
  final String searchQuery;

  static const Color primaryBlue = Color(0xFF4A90E2);
  static const Color lightBlue = Color(0xFF81B3D2);
  static const Color backgroundColor = Colors.white;
  static const Color cardColor = Color(0xFFF0F7FF);
  static const Color softAccent = Color(0xFFA4D4F5);
  
  const HadithDetailScreen({
    Key? key,
    required this.hadith,
    this.searchQuery = '',
  }) : super(key: key);

  // Method to create highlighted text
  Widget _buildHighlightedText(String text, String searchQuery) {
    if (searchQuery.isEmpty) {
      return Text(
        text,
        style: GoogleFonts.poppins(
          height: 1.6,
          fontSize: 16,
          color: Colors.black87,
        ),
      );
    }

    // Split search query into individual words
    final searchWords = searchQuery.toLowerCase().split(' ')
        .where((word) => word.trim().isNotEmpty)
        .toList();
    
    if (searchWords.isEmpty) {
      return Text(
        text,
        style: GoogleFonts.poppins(
          height: 1.6,
          fontSize: 16,
          color: Colors.black87,
        ),
      );
    }

    List<TextSpan> spans = [];
    String remainingText = text;
    
    while (remainingText.isNotEmpty) {
      int earliestIndex = remainingText.length;
      String foundWord = '';
      
      // Find the earliest occurrence of any search word
      for (String searchWord in searchWords) {
        int index = remainingText.toLowerCase().indexOf(searchWord.toLowerCase());
        if (index != -1 && index < earliestIndex) {
          earliestIndex = index;
          foundWord = searchWord;
        }
      }
      
      if (earliestIndex == remainingText.length) {
        // No more matches, add the rest as normal text
        spans.add(TextSpan(
          text: remainingText,
          style: GoogleFonts.poppins(
            height: 1.6,
            fontSize: 16,
            color: Colors.black87,
          ),
        ));
        break;
      } else {
        // Add text before the match
        if (earliestIndex > 0) {
          spans.add(TextSpan(
            text: remainingText.substring(0, earliestIndex),
            style: GoogleFonts.poppins(
              height: 1.6,
              fontSize: 16,
              color: Colors.black87,
            ),
          ));
        }
        
        // Add the highlighted match
        String actualMatch = remainingText.substring(earliestIndex, earliestIndex + foundWord.length);
        spans.add(TextSpan(
          text: actualMatch,
          style: GoogleFonts.poppins(
            height: 1.6,
            fontSize: 16,
            color: Colors.black87,
            backgroundColor: Colors.yellow.withOpacity(0.3),
            fontWeight: FontWeight.w600,
          ),
        ));
        
        // Continue with the rest of the text
        remainingText = remainingText.substring(earliestIndex + foundWord.length);
      }
    }
    
    return RichText(
      text: TextSpan(children: spans),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text(
          'Hadith ${hadith['number']}',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: IconThemeData(color: primaryBlue),
      ),
      body: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: cardColor.withOpacity(0.6),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withOpacity(0.15),
                      blurRadius: 30,
                      offset: Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.2),
                      blurRadius: 15,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [primaryBlue, lightBlue],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 15,
                                color: primaryBlue.withOpacity(0.4),
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.menu_book,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 16),
                        Text(
                          'Hadith ${hadith['number']}',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Divider(color: Colors.grey[300]),
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: softAccent.withOpacity(0.5),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _buildHighlightedText(
                        hadith['text'] ?? 'No text available',
                        searchQuery,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}