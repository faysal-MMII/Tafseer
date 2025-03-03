import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../theme/text_styles.dart';
import '../models/hadith.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryScreen extends StatefulWidget {
  final FirestoreService? firestoreService;

  const HistoryScreen({
    super.key,
    this.firestoreService,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const int _pageSize = 10;
  final TextEditingController _searchController = TextEditingController();
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  bool _isLoading = false;
  List<DocumentSnapshot> _documents = [];
  String _searchQuery = '';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMoreData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadMoreData();
    }
  }

  Future<void> _loadMoreData() async {
    if (!_hasMore || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get the current user ID
      final String? userId = FirebaseAuth.instance.currentUser?.uid;
      print('Loading history for user: $userId');
      
      // If no user is logged in, handle appropriately
      if (userId == null) {
        setState(() {
          _isLoading = false;
          print('No user logged in, cannot load history');
        });
        return;
      }

      // Query only the current user's history
      Query query = FirebaseFirestore.instance
          .collection('qa_history')
          .where('userId', isEqualTo: userId)  // Filter by user ID
          .orderBy('timestamp', descending: true);

      print('Query created with user filter: $userId');
      
      if (_searchQuery.isNotEmpty) {
        // Apply similarity search
        query = query.where('searchableTerms', arrayContains: _searchQuery.toLowerCase());
        print('Added search filter: $_searchQuery');
      }

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
        print('Added pagination after document');
      }

      query = query.limit(_pageSize);
      print('Executing query with limit: $_pageSize');

      final QuerySnapshot snapshot = await query.get();
      print('Query executed. Got ${snapshot.docs.length} results');

      setState(() {
        _documents.addAll(snapshot.docs);
        _hasMore = snapshot.docs.length == _pageSize;
        if (snapshot.docs.isNotEmpty) {
          _lastDocument = snapshot.docs.last;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading data: $e');
      print('Error stack trace: ${StackTrace.current}');
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _documents.clear();
      _lastDocument = null;
      _hasMore = true;
    });
    await _loadMoreData();
  }

  Future<void> _deleteEntry(DocumentSnapshot doc) async {
    try {
      await FirebaseFirestore.instance
          .collection('qa_history')
          .doc(doc.id)
          .delete();
      
      setState(() {
        _documents.remove(doc);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entry deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting entry: $e')),
      );
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _documents.clear();
      _lastDocument = null;
      _hasMore = true;
    });
    _loadMoreData();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Search History', style: AppTextStyles.titleText),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: user == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'You need to be logged in to view history',
                    style: AppTextStyles.englishText,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signInAnonymously();
                      setState(() {}); // Refresh the UI
                    },
                    child: Text('Login Anonymously'),
                  ),
                ],
              ),
            )
          : widget.firestoreService == null
              ? Center(
                  child: Text(
                    'History not available offline',
                    style: AppTextStyles.englishText,
                  ),
                )
              : SafeArea(  // Add SafeArea
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search history...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onChanged: _onSearchChanged,
                        ),
                      ),
                      Expanded(  // This should now work properly with SafeArea
                        child: RefreshIndicator(
                          onRefresh: _refresh,
                          child: _documents.isEmpty && !_isLoading
                              ? const Center(
                                  child: Text('No search history yet'),
                                )
                              : ListView.builder(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _documents.length + (_isLoading ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (index == _documents.length) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }

                                    final doc = _documents[index];
                                    final data = doc.data() as Map<String, dynamic>;
                                    return Dismissible(
                                      key: Key(doc.id),
                                      background: Container(
                                        color: Colors.red,
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.only(right: 16),
                                        child: const Icon(
                                          Icons.delete,
                                          color: Colors.white,
                                        ),
                                      ),
                                      direction: DismissDirection.endToStart,
                                      onDismissed: (_) => _deleteEntry(doc),
                                      child: _buildHistoryCard(data),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> data) {
    final question = data['question'] as String? ?? '';
    final answer = data['answer'] as String? ?? '';

    // Handle different data types for quranVerses
    List<String> quranVerses = [];
    if (data['quranVerses'] is List) {
      quranVerses = List<String>.from(
        (data['quranVerses'] as List).map((item) {
          // Handle if item is a Map or a String
          if (item is Map) {
            return item.toString(); // Convert Map to String
          } else {
            return item.toString(); // Already a String or convertible
          }
        })
      );
    }

    // Handle different data types for hadiths
    List<Map<String, dynamic>> hadiths = [];
    if (data['hadiths'] is List) {
      hadiths = (data['hadiths'] as List).map((item) {
        if (item is Map<String, dynamic>) {
          return item; // Already a Map
        } else if (item is String) {
          // Create a Map with the String as 'text'
          return {'text': item};
        } else {
          // Fall back to empty Map with empty text
          return {'text': ''};
        }
      }).toList().cast<Map<String, dynamic>>();
    }

    final timestamp = data['timestamp'] as Timestamp?;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFE6E6E6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ExpansionTile(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question,
              style: AppTextStyles.englishText.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (timestamp != null)
              Text(
                _formatTimestamp(timestamp),
                style: AppTextStyles.englishText.copyWith(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Answer:',
                  style: AppTextStyles.titleText.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(answer, style: AppTextStyles.englishText),
                if (quranVerses.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Quran Verses:',
                    style: AppTextStyles.titleText.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ...quranVerses.map((verse) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(verse, style: AppTextStyles.englishText),
                      )),
                ],
                if (hadiths.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Hadiths:',
                    style: AppTextStyles.titleText.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ...hadiths.map((hadith) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          hadith['text'] ?? '',
                          style: AppTextStyles.englishText,
                        ),
                      )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}