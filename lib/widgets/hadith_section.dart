import 'package:flutter/material.dart';
import '../services/hadith_service.dart';

class HadithSection extends StatefulWidget {
  final String? query;
  const HadithSection({super.key, this.query});

  @override
  State<HadithSection> createState() => _HadithSectionState();
}

class _HadithSectionState extends State<HadithSection> {
  final HadithService _hadithService = HadithService();
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
          // Hadith Guidance Header
          const Text(
            'Hadith Guidance',
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
          else if (_response?.containsKey('hadith_results') ?? false) ...[
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
                _response!['hadith_results']['answer'] ?? '',
                style: const TextStyle(
                  fontFamily: 'Noto Serif',
                  fontSize: 16,
                  height: 1.6,
                  color: Color(0xFF333333),
                ),
              ),
            ),

            // Relevant Hadiths Section
            if ((_response!['hadith_results']['hadiths'] as List?)?.isNotEmpty ?? false) ...[
              const SizedBox(height: 20),
              const Text(
                'Relevant Hadiths',
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
                  children: (_response!['hadith_results']['hadiths'] as List)
                      .map((hadith) => Container(
                            margin: const EdgeInsets.only(bottom: 15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '**Collection: ${hadith['collection']} | Reference: ${hadith['reference']}**',
                                  style: const TextStyle(
                                    fontFamily: 'Noto Serif',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF666666),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  hadith['text'],
                                  style: const TextStyle(
                                    fontFamily: 'Noto Serif',
                                    fontSize: 16,
                                    height: 1.6,
                                    color: Color(0xFF333333),
                                  ),
                                ),
                              ],
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
  void didUpdateWidget(HadithSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != null && widget.query!.isNotEmpty) {
      _searchHadiths(widget.query!);
    }
  }

  Future<void> _searchHadiths(String query) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _hadithService.searchHadiths(query);
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