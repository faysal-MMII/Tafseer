import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/text_styles.dart';
import 'dart:convert';
import 'hadith_detail_screen.dart';
import '../theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

class HadithScreen extends StatefulWidget {
  @override
  _HadithScreenState createState() => _HadithScreenState();
}

class _HadithScreenState extends State<HadithScreen> {
  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic>? _selectedHadith;
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _hadiths = [];
  List<Map<String, dynamic>> _filteredHadiths = [];

  static const Color primaryBlue = Color(0xFF4A90E2);
  static const Color lightBlue = Color(0xFF81B3D2);
  static const Color backgroundColor = Colors.white;
  static const Color cardColor = Color(0xFFF0F7FF);
  static const Color softAccent = Color(0xFFA4D4F5);

  @override
  void initState() {
    super.initState();
    _loadAllHadiths();
  }

  Future<void> _loadAllHadiths() async {
    try {
      setState(() => _isLoading = true);

      final String jsonString = await rootBundle.loadString('assets/data/nawawi.json');
      final data = json.decode(jsonString);

      _hadiths = List<Map<String, dynamic>>.from(
        data['hadiths']['hadiths'].map((h) => {
          'number': h['hadith'],
          'text': h['text'],
        })
      );

      _filteredHadiths = List.from(_hadiths);

      if (_hadiths.isNotEmpty) {
        _selectedHadith = _hadiths.first;
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterHadiths(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredHadiths = _hadiths;
      } else {
        _filteredHadiths = _hadiths.where((hadith) {
          final number = hadith['number'].toString();
          final text = hadith['text'].toString().toLowerCase();
          final searchLower = query.toLowerCase();
          return number.contains(searchLower) || text.contains(searchLower);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                ),
              )
            : _error != null
                ? Center(
                    child: Container(
                      margin: EdgeInsets.all(20),
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Text(
                        _error!,
                        style: GoogleFonts.poppins(
                          color: Colors.red[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : Column(
                    children: [
                      _buildHeader(),
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFf0f9ff), Color(0xFFe0f2fe)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: softAccent.withOpacity(0.3)),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 10,
                              color: Colors.black.withOpacity(0.05),
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: GoogleFonts.poppins(
                            color: Colors.black87,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search Hadiths...',
                            hintStyle: GoogleFonts.poppins(
                              color: Colors.grey[500],
                            ),
                            prefixIcon: Icon(Icons.search, color: primaryBlue),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(18),
                          ),
                          onChanged: _filterHadiths,
                        ),
                      ),
                      SizedBox(height: 16),
                      Expanded(
                        child: _buildLayout(),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cardColor.withOpacity(0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 25,
            color: primaryBlue.withOpacity(0.15),
            offset: Offset(0, 8),
          ),
          BoxShadow(
            blurRadius: 15,
            color: Colors.white.withOpacity(0.2),
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_back,
                color: primaryBlue,
                size: 20,
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hadith',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
                Text(
                  'As compiled by Imam Nawawi',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayout() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return isSmallScreen
        ? _buildMobileLayout()
        : _buildDesktopLayout();
  }

  Widget _buildMobileLayout() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredHadiths.length,
      itemBuilder: (context, index) {
        final hadith = _filteredHadiths[index];
        return Container(
          margin: EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: _selectedHadith == hadith 
              ? cardColor.withOpacity(0.9) 
              : cardColor.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _selectedHadith == hadith 
                ? primaryBlue.withOpacity(0.5) 
                : cardColor.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            title: Text(
              'Hadith ${hadith['number']}',
              style: GoogleFonts.poppins(
                color: _selectedHadith == hadith ? primaryBlue : Colors.black87,
                fontWeight: _selectedHadith == hadith ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            onTap: () {
              setState(() => _selectedHadith = hadith);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HadithDetailScreen(
                    hadith: hadith,
                    searchQuery: _searchController.text,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Container(
          width: 200,
          decoration: BoxDecoration(
            color: cardColor.withOpacity(0.8),
            border: Border(
              right: BorderSide(color: softAccent.withOpacity(0.5), width: 1),
            ),
          ),
          child: ListView.builder(
            itemCount: _filteredHadiths.length,
            itemBuilder: (context, index) {
              final hadith = _filteredHadiths[index];
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _selectedHadith == hadith 
                    ? cardColor.withOpacity(0.9) 
                    : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: _selectedHadith == hadith 
                    ? Border.all(color: primaryBlue.withOpacity(0.5), width: 1)
                    : null,
                ),
                child: ListTile(
                  title: Text(
                    'Hadith ${hadith['number']}',
                    style: GoogleFonts.poppins(
                      color: _selectedHadith == hadith ? primaryBlue : Colors.black87,
                      fontWeight: _selectedHadith == hadith ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  onTap: () => setState(() => _selectedHadith = hadith),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: Container(
            color: backgroundColor,
            child: _selectedHadith == null
              ? Center(
                  child: Text(
                    'Select a hadith',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[700],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: cardColor.withOpacity(0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryBlue.withOpacity(0.1),
                          blurRadius: 15,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: primaryBlue.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.menu_book,
                                color: primaryBlue,
                                size: 20,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Hadith ${_selectedHadith!['number']}',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: primaryBlue,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Divider(color: Colors.grey[300]),
                        SizedBox(height: 16),
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _selectedHadith!['text'],
                            style: GoogleFonts.poppins(
                              height: 1.5,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}