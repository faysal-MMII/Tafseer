import 'package:flutter/material.dart';
import '../services/hadith_service.dart';
import '../theme/text_styles.dart';
import '../models/hadith.dart';
import '../widgets/responsive_layout.dart';

class HadithScreen extends StatefulWidget {
  @override
  _HadithScreenState createState() => _HadithScreenState();
}

class _HadithScreenState extends State<HadithScreen> {
  final HadithService _hadithService = HadithService();
  final TextEditingController _searchController = TextEditingController();
  List<Hadith> _currentHadiths = [];
  List<Map<String, dynamic>> _filteredHadiths = [];
  bool _isLoading = false;
  String? _error;
  String _collectionName = '';

  // List of Nawawi's 40 Hadith
  final List<Map<String, dynamic>> hadiths = List.generate(
    40,  
    (index) => {
      "number": index + 1,
      "name": "Hadith ${index + 1}",
    },
  );

  @override
  void initState() {
    super.initState();
    _loadHadith(1); // Load first hadith by default
    _filteredHadiths = hadiths;
    _loadCollectionName();
  }

  Future<void> _loadCollectionName() async {
    await _hadithService.loadHadithData();
    setState(() {
      _collectionName = _hadithService.getCollectionName();
    });
  }

  void _filterHadiths(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredHadiths = hadiths;
      } else {
        _filteredHadiths = hadiths.where((hadith) {
          final numberStr = hadith["number"].toString();
          final nameStr = hadith["name"].toString().toLowerCase();
          final searchStr = query.toLowerCase();
          return numberStr.contains(searchStr) || nameStr.contains(searchStr);
        }).toList();
      }
    });
  }

  Future<void> _loadHadith(int hadithNumber) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final hadith = await _hadithService.fetchHadith(hadithNumber);
      setState(() {
        _currentHadiths = [hadith];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text('Hadith', style: AppTextStyles.titleText),  
      ),
      body: ResponsiveLayout(
        child: isSmallScreen
          ? Column(
              children: [
                _buildSearchPanel(),
                Expanded(child: _buildContentPanel()),
              ],
            )
          : Row(
              children: [
                Container(
                  width: 250,
                  child: _buildSearchPanel(),
                ),
                Expanded(child: _buildContentPanel()),
              ],
            ),
      ),
    );
  }

  Widget _buildSearchPanel() {
    return Container(
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search Hadiths...',
                prefixIcon: Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterHadiths('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              ),
              onChanged: _filterHadiths,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredHadiths.length,
              itemBuilder: (context, index) {
                final hadith = _filteredHadiths[index];
                return ListTile(
                  dense: true,
                  title: Text(
                    '${hadith["number"]}. ${hadith["name"]}',
                    style: AppTextStyles.englishText,
                  ),
                  onTap: () => _loadHadith(hadith["number"]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentPanel() {
    return _isLoading
      ? Center(child: CircularProgressIndicator())
      : _error != null
        ? Center(child: Text('Error: $_error', style: AppTextStyles.englishText.copyWith(color: Colors.red)))
        : ListView.builder(
            itemCount: _currentHadiths.length,
            itemBuilder: (context, index) {
              final hadith = _currentHadiths[index];
              return Card(
                margin: EdgeInsets.all(8),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hadith ${hadith.hadithNumber}',
                        style: AppTextStyles.titleText.copyWith(
                          fontSize: 20,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        hadith.text,
                        style: AppTextStyles.englishText,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}