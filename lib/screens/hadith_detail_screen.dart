import 'package:flutter/material.dart';
import '../theme/text_styles.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';

class HadithDetailScreen extends StatelessWidget {
  final Map<String, dynamic> hadith;
  final String searchQuery;
  
  const HadithDetailScreen({
    Key? key,
    required this.hadith,
    this.searchQuery = '',
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final theme = Theme.of(context);
    final accentColor = isDark ? Colors.cyanAccent : Color(0xFF2D5F7C);
    
    return Scaffold(
      backgroundColor: isDark ? Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        title: Text(
          'Hadith ${hadith['number']}',
          style: theme.appBarTheme.titleTextStyle,
        ),
        iconTheme: IconThemeData(
          color: accentColor,
        ),
      ),
      body: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
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
                  border: isDark 
                    ? Border.all(color: Colors.grey[800]!, width: 1) 
                    : null,
                ),
                child: Column(
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
                          'Hadith ${hadith['number']}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Divider(
                      color: isDark ? Colors.grey[800] : Colors.grey[300],
                    ),
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? Color(0xFF252525) : Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark 
                            ? Colors.grey[700]! 
                            : Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        hadith['text'] ?? 'No text available',
                        style: TextStyle(
                          height: 1.5,
                          fontSize: 16,
                          color: isDark ? Colors.white : Color(0xFF333333),
                        ),
                      ),
                    ),
                    if (searchQuery.isNotEmpty) ...[
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Search: "$searchQuery"',
                          style: TextStyle(
                            fontSize: 12,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ],
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