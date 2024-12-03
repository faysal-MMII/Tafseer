import 'package:flutter/material.dart';
import '../services/quran_service.dart';

class QuranSection extends StatefulWidget {
  final String? query;
  const QuranSection({super.key, this.query});

  @override
  State<QuranSection> createState() => _QuranSectionState();
}

class _QuranSectionState extends State<QuranSection> {
  final QuranService _quranService = QuranService();
  bool _isLoading = false;
  Map<String, dynamic>? _response;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      margin: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFE6E6E6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD1D1D1),
            offset: const Offset(5, 5),
            blurRadius: 10,
          ),
          const BoxShadow(
            color: Colors.white,
            offset: Offset(-5, -5),
            blurRadius: 10,
          ),
        ],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quranic Evidence Header
          const Text(
            'Quranic Evidence',
            style: TextStyle(
              fontFamily: 'Noto Nastaliq Urdu',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 20),

          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            _buildErrorBox()
          else if (_response?.containsKey('quran_results') ?? false) ...[
            // Answer Section
            const Text(
              'Answer',
              style: TextStyle(
                fontFamily: 'Noto Serif',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 15),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _response!['quran_results']['answer'] ?? '',
                style: const TextStyle(
                  fontFamily: 'Noto Serif',
                  fontSize: 16,
                  height: 1.6,
                  color: Color(0xFF333333),
                ),
              ),
            ),

            // Relevant Verses Section
            if ((_response!['quran_results']['verses'] as List?)?.isNotEmpty ?? false) ...[
              const SizedBox(height: 20),
              const Text(
                'Relevant Verses',
                style: TextStyle(
                  fontFamily: 'Noto Serif',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF0F0F0), Color(0xFFCACACA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xFFBEBEBE),
                      offset: Offset(5, 5),
                      blurRadius: 10,
                      spreadRadius: -5,
                    ),
                    BoxShadow(
                      color: Colors.white,
                      offset: Offset(-5, -5),
                      blurRadius: 10,
                      spreadRadius: -5,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: (_response!['quran_results']['verses'] as List)
                      .map((verse) => Container(
                            margin: const EdgeInsets.only(bottom: 15),
                            child: Text(
                              verse,
                              style: const TextStyle(
                                fontFamily: 'Noto Serif',
                                fontSize: 16,
                                height: 1.6,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF333333),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildErrorBox() {
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
      child: Text(
        'Error: $_error',
        style: const TextStyle(color: Color(0xFFC0392B)),
      ),
    );
  }

  @override
  void didUpdateWidget(QuranSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != null && widget.query!.isNotEmpty) {
      _searchVerses(widget.query!);
    }
  }

  Future<void> _searchVerses(String query) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _quranService.searchVerses(query);
      setState(() {
        _response = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }
}