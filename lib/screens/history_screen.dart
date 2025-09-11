import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../theme/text_styles.dart';
import '../models/hadith.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/deviceid_service.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/markdown_text.dart';

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

  // MATCHING HOME SCREEN COLORS
  static const Color primaryBlue = Color(0xFF4A90E2);
  static const Color lightBlue = Color(0xFF81B3D2);
  static const Color backgroundColor = Colors.white;
  static const Color cardColor = Color(0xFFF0F7FF);
  static const Color softAccent = Color(0xFFA4D4F5);

  @override
  void initState() {
    super.initState();
    _diagnoseProblem();
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

  String _classifyError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') || errorString.contains('timeout')) {
      return 'network_timeout';
    } else if (errorString.contains('connection')) {
      return 'connection_failed';
    } else if (errorString.contains('permission') || errorString.contains('denied')) {
      return 'permission_denied';
    } else if (errorString.contains('quota')) {
      return 'quota_exceeded';
    } else if (errorString.contains('unavailable')) {
      return 'service_unavailable';
    } else {
      return 'unknown_error';
    }
  }

  String _getSpecificErrorMessage(String errorType, String operation) {
    switch (errorType) {
      case 'network_timeout':
        return 'Request timed out while $operation. Check your internet connection and try again.';
      case 'connection_failed':
        return 'Failed to connect to server while $operation. Verify your internet connection.';
      case 'permission_denied':
        return 'Access denied while $operation. Please check your account permissions.';
      case 'quota_exceeded':
        return 'Service quota exceeded while $operation. Please try again later.';
      case 'service_unavailable':
        return 'Service temporarily unavailable while $operation. Please try again in a few minutes.';
      default:
        return 'An unexpected error occurred while $operation. Please try again.';
    }
  }

  // UPDATED _loadMoreData() with fallback timestamp handling
  Future<void> _loadMoreData() async {
    if (!_hasMore || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final String deviceId = await DeviceIDService.getDeviceID();

      Query query = FirebaseFirestore.instance
          .collection('qa_history')
          .where('deviceId', isEqualTo: deviceId)
          .orderBy('timestamp', descending: true); // Primary sort key

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      query = query.limit(_pageSize);

      final QuerySnapshot snapshot = await query.get();
      List<DocumentSnapshot> fetchedDocs = snapshot.docs;

      // Filter and sort client-side, using clientTimestamp as a fallback
      List<DocumentSnapshot> filteredAndSortedDocs = fetchedDocs;

      if (_searchQuery.isNotEmpty) {
        final searchWords = _searchQuery.toLowerCase().trim().split(' ')
            .where((word) => word.isNotEmpty).toList();

        filteredAndSortedDocs = fetchedDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final question = (data['question'] as String? ?? '').toLowerCase();
          final answer = (data['answer'] as String? ?? '').toLowerCase();

          return searchWords.every((word) =>
            question.contains(word) || answer.contains(word));
        }).toList();
      }

      _sortDocuments(filteredAndSortedDocs);

      setState(() {
        _documents.addAll(filteredAndSortedDocs);
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

      if (mounted) {
        final errorType = _classifyError(e);
        final errorMessage = _getSpecificErrorMessage(errorType, 'loading search history');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    errorMessage,
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: _refresh,
            ),
          ),
        );
      }
    }
  }

  // New helper method for client-side sorting
  void _sortDocuments(List<DocumentSnapshot> docs) {
    docs.sort((a, b) {
      final dataA = a.data() as Map<String, dynamic>;
      final dataB = b.data() as Map<String, dynamic>;

      final timestampA = (dataA['timestamp'] as Timestamp?) ?? (dataA['clientTimestamp'] as Timestamp?);
      final timestampB = (dataB['timestamp'] as Timestamp?) ?? (dataB['clientTimestamp'] as Timestamp?);

      if (timestampA == null && timestampB == null) return 0;
      if (timestampA == null) return 1;
      if (timestampB == null) return -1;

      return timestampB.compareTo(timestampA);
    });
  }


  Future<void> _diagnoseProblem() async {
    try {
      final deviceId = await DeviceIDService.getDeviceID();
      FirebaseCrashlytics.instance.log("HISTORY_DEBUG: Device ID: $deviceId");

      final snapshot = await FirebaseFirestore.instance
          .collection('qa_history')
          .limit(1)
          .get();

      FirebaseCrashlytics.instance.log("HISTORY_DEBUG: Collection exists: ${snapshot.docs.isNotEmpty}");

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
    } catch (error, stackTrace) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace, reason: "History diagnostic");
    }
  }

  Future<void> _clearAllHistory() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange[600]),
            const SizedBox(width: 12),
            Text(
              'Clear History',
              style: GoogleFonts.poppins(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete all search history? This action cannot be undone.',
          style: GoogleFonts.poppins(
            color: Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.black54,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await _performClearHistory();
            },
            child: Text(
              'Clear All',
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performClearHistory() async {
    try {
      final String deviceId = await DeviceIDService.getDeviceID();

      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('qa_history')
          .where('deviceId', isEqualTo: deviceId)
          .get();

      final WriteBatch batch = FirebaseFirestore.instance.batch();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      setState(() {
        _documents.clear();
        _lastDocument = null;
        _hasMore = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'All history cleared',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: primaryBlue,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) {
        final errorType = _classifyError(e);
        final errorMessage = _getSpecificErrorMessage(errorType, 'clearing history');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
        SnackBar(
          content: Text(
            'Entry deleted',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: primaryBlue,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) {
        final errorType = _classifyError(e);
        final errorMessage = _getSpecificErrorMessage(errorType, 'deleting an entry');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _documents.clear();
      _lastDocument = null;
      _hasMore = true;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchQuery == query) {
        _loadMoreData();
      }
    });
  }

  List<String> _extractQuranVerses(dynamic data) {
    if (data == null) return [];

    List<String> verses = [];

    if (data is List) {
      for (var item in data) {
        if (item == null) continue;

        String verseText = '';
        String reference = '';

        if (item is Map<String, dynamic>) {
          if (item.containsKey('text')) {
            verseText = item['text']?.toString() ?? '';
          } else if (item.containsKey('translations') && item['translations'] is List && item['translations'].isNotEmpty) {
            verseText = item['translations'][0]['text']?.toString() ?? '';
          }

          if (item.containsKey('verse_key')) {
            reference = item['verse_key']?.toString() ?? '';
          } else if (item.containsKey('reference')) {
            reference = item['reference']?.toString() ?? '';
          }

          if (verseText.isNotEmpty && reference.isNotEmpty) {
            verses.add(reference);
          } else if (reference.isNotEmpty) {
            verses.add(reference);
          }
        } else if (item is String && item.isNotEmpty) {
          final regex = RegExp(r'\(([^)]+)\)$');
          final match = regex.firstMatch(item);
          if (match != null && match.group(1) != null && match.group(1) != 'null') {
            verses.add(match.group(1)!);
          } else if (!item.contains('null')) {
            verses.add(item);
          }
        }
      }
    }

    return verses.where((v) => v.isNotEmpty && !v.contains('null')).toList();
  }

  List<Map<String, dynamic>> _extractHadiths(dynamic data) {
    if (data == null || data is! List) return [];

    return (data).where((item) => item != null).map((item) {
      if (item is Map<String, dynamic>) {
        return item;
      } else if (item is String && item.isNotEmpty && !item.contains('null')) {
        return {'text': item};
      }
      return null;
    }).where((item) => item != null).cast<Map<String, dynamic>>().toList();
  }

  // Method to format the timestamp with relative time
  String _formatTimestamp(Map<String, dynamic> data) {
    // Try server timestamp first
    Timestamp? timestamp = data['timestamp'] as Timestamp?;

    // Fall back to client timestamp if server timestamp is null
    timestamp ??= data['clientTimestamp'] as Timestamp?;

    if (timestamp == null) {
      return 'Unknown date';
    }

    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    // Show relative time for recent entries
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      // Show full date for older entries
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  // Widget to build the history card
  Widget _buildHistoryCard(Map<String, dynamic> data) {
    final question = data['question'] as String? ?? '';
    final answer = data['answer'] as String? ?? '';

    final quranVerses = _extractQuranVerses(data['quranVerses']);
    final hadiths = _extractHadiths(data['hadiths']);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cardColor.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          expansionTileTheme: const ExpansionTileThemeData(
            backgroundColor: Colors.transparent,
            collapsedBackgroundColor: Colors.transparent,
            iconColor: primaryBlue,
            collapsedIconColor: primaryBlue,
          ),
        ),
        child: ExpansionTile(
          title: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryBlue.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.help_outline,
                        color: primaryBlue,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        question,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _formatTimestamp(data), // Pass the entire data map
                  style: GoogleFonts.poppins(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: softAccent.withOpacity(0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.lightbulb_outline, color: primaryBlue, size: 16),
                            SizedBox(width: 8),
                            Text(
                              'Answer:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: primaryBlue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        MarkdownText(
                          text: answer,
                          color: Colors.black87,
                          fontSize: 14,
                        ),
                      ],
                    ),
                  ),
                  if (quranVerses.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        Icon(Icons.menu_book, color: primaryBlue, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Quran Verses:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: primaryBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: quranVerses.map((ref) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: primaryBlue.withOpacity(0.3)),
                        ),
                        child: Text(
                          ref,
                          style: GoogleFonts.poppins(
                            color: primaryBlue,
                            fontSize: 12,
                          ),
                        ),
                      )).toList(),
                    ),
                  ],
                  if (hadiths.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        Icon(Icons.format_quote, color: primaryBlue, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Hadiths:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: primaryBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...hadiths.map((hadith) {
                      final hadithText = hadith['text'] ?? '';
                      final displayedText = hadithText; // No truncation
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: MarkdownText(
                          text: displayedText,
                          color: Colors.black87,
                          fontSize: 13,
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
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
          'Search History',
          style: GoogleFonts.poppins(
            color: primaryBlue,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: primaryBlue),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever, color: primaryBlue),
            onPressed: _clearAllHistory,
            tooltip: 'Clear all history',
          ),
        ],
      ),
      body: widget.firestoreService == null
        ? Center(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor.withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: cardColor.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_off,
                    color: Colors.grey[600],
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'History not available offline',
                    style: GoogleFonts.poppins(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        : SafeArea(
            child: Column(
              children: [
                // Search Field
                Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFf0f9ff), Color(0xFFe0f2fe)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: softAccent.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 10,
                        color: Colors.black.withOpacity(0.05),
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.poppins(
                      color: Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search history...',
                      hintStyle: GoogleFonts.poppins(
                        color: Colors.grey[500],
                      ),
                      prefixIcon: const Icon(Icons.search, color: primaryBlue),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(18),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: primaryBlue,
                    onRefresh: _refresh,
                    child: _documents.isEmpty && !_isLoading
                      ? Center(
                          child: Container(
                            margin: const EdgeInsets.all(20),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: cardColor.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: cardColor.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.history,
                                  color: Colors.grey[600],
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No search history yet',
                                  style: GoogleFonts.poppins(
                                    color: Colors.black87,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Your previous searches will appear here',
                                  style: GoogleFonts.poppins(
                                    color: Colors.black54,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.only(
                            left: 16,
                            right: 16,
                            top: 16,
                            bottom: MediaQuery.of(context).padding.bottom + 16,
                          ),
                          itemCount: _documents.length + (_isLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _documents.length) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                                  ),
                                ),
                              );
                            }

                            final doc = _documents[index];
                            final data = doc.data() as Map<String, dynamic>;
                            return Dismissible(
                              key: Key(doc.id),
                              background: Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.red[400],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                  size: 28,
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
}