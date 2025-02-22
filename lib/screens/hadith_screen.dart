import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/text_styles.dart';
import 'dart:convert';
import 'hadith_detail_screen.dart';

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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text('Hadith'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
        ? Center(child: CircularProgressIndicator())
        : _error != null
          ? Center(child: Text(_error!, style: TextStyle(color: Colors.red)))
          : Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Hadith: As compiled by Imam Nawawi',
                    style: AppTextStyles.titleText.copyWith(
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search Hadiths...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: _filterHadiths,
                  ),
                ),
                Expanded(
                  child: isSmallScreen
                    ? _buildMobileLayout()
                    : _buildDesktopLayout(),
                ),
              ],
            ),
    );
  }

  Widget _buildMobileLayout() {
    return ListView.builder(
      itemCount: _filteredHadiths.length,
      itemBuilder: (context, index) {
        final hadith = _filteredHadiths[index];
        return ListTile(
          selected: _selectedHadith == hadith,
          title: Text(
            'Hadith ${hadith['number']}',
            style: AppTextStyles.englishText,
          ),
          onTap: () {
            setState(() => _selectedHadith = hadith);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HadithDetailScreen(hadith: hadith),
              ),
            );
          },
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
            border: Border(right: BorderSide(color: Colors.grey.shade300)),
          ),
          child: ListView.builder(
            itemCount: _filteredHadiths.length,
            itemBuilder: (context, index) {
              final hadith = _filteredHadiths[index];
              return ListTile(
                selected: _selectedHadith == hadith,
                title: Text(
                  'Hadith ${hadith['number']}',
                  style: AppTextStyles.englishText,
                ),
                onTap: () => setState(() => _selectedHadith = hadith),
              );
            },
          ),
        ),
        Expanded(
          child: _selectedHadith == null
            ? Center(child: Text('Select a hadith'))
            : SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hadith ${_selectedHadith!['number']}',
                      style: AppTextStyles.titleText.copyWith(fontSize: 24),
                    ),
                    SizedBox(height: 16),
                    Text(
                      _selectedHadith!['text'],
                      style: AppTextStyles.englishText.copyWith(
                        height: 1.5,
                        fontSize: 16,
                      ),
                    ),
                  ],
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