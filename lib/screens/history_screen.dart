import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../theme/text_styles.dart';
import '../models/hadith.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/deviceid_service.dart'; // Import the DeviceIDService
import 'package:firebase_crashlytics/firebase_crashlytics.dart'; // Import Firebase Crashlytics

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
    _diagnoseProblem(); // Call the diagnostic function
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
      // Get the device ID instead of user ID
      final String deviceId = await DeviceIDService.getDeviceID();
      print('Loading history for device: $deviceId');

      // Query only this device's history
      Query query = FirebaseFirestore.instance
          .collection('qa_history')
          .where('deviceId', isEqualTo: deviceId);

      print('Created query with deviceId filter');

      query = query.orderBy('timestamp', descending: true);
      print('Added ordering by timestamp');

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

      if (snapshot.docs.isEmpty) {
        print('No documents found matching the criteria');
      } else {
        print('First document data: ${snapshot.docs.first.data()}');
      }

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

  Future<void> _diagnoseProblem() async {
    try {
      final deviceId = await DeviceIDService.getDeviceID();
      FirebaseCrashlytics.instance.log("HISTORY_DEBUG: Device ID: $deviceId");
      
      // Check if collection exists
      final snapshot = await FirebaseFirestore.instance
          .collection('qa_history')
          .limit(1)
          .get();
      
      FirebaseCrashlytics.instance.log("HISTORY_DEBUG: Collection exists: ${snapshot.docs.isNotEmpty}");
      
      // Try device ID query
      final deviceSnapshot = await FirebaseFirestore.instance
          .collection('qa_history')
          .where('deviceId', isEqualTo: deviceId)
          .limit(1)
          .get();
      
      FirebaseCrashlytics.instance.log("HISTORY_DEBUG: Found with device ID: ${deviceSnapshot.docs.length}");
      
      if (deviceSnapshot.docs.isNotEmpty) {
        final doc = deviceSnapshot.docs.first.data();
        FirebaseCrashlytics.instance.log("HISTORY_DEBUG: Sample doc: ${doc['question'] ?? 'No question'}");
      }
    } catch (error) {
      FirebaseCrashlytics.instance.recordError(error, StackTrace.current, reason: "History diagnostic");
    }
  }

  Future<void> _clearAllHistory() async {
    try {
      final String deviceId = await DeviceIDService.getDeviceID();

      // Get all documents for this device
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('qa_history')
          .where('deviceId', isEqualTo: deviceId)
          .get();

      // Create a batch to delete multiple documents efficiently
      final WriteBatch batch = FirebaseFirestore.instance.batch();

      // Add each document to the batch deletion
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      // Commit the batch
      await batch.commit();

      // Update local state if needed
      setState(() {
        _documents.clear();
        _lastDocument = null;
        _hasMore = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All history cleared')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error clearing history: $e')),
      );
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Search History', style: AppTextStyles.titleText),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: _clearAllHistory, // Call the method we just added
            tooltip: 'Clear all history',
          ),
        ],
      ),
      body: widget.firestoreService == null
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