import 'package:flutter/material.dart';

class SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSearch;

  const SearchBox({
    Key? key,
    required this.controller,
    required this.onSearch,
  }) : super(key: key);

  void _handleSearch() {
    final query = controller.text.trim();
    if (query.isNotEmpty) {
      onSearch(query); // Call onSearch directly
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFFFFF), Color(0xFFF0F0F0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(6),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFFD1D1D1),
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
            child: TextField(
              controller: controller,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Salam Allaikum, how may I help you today?',
                hintStyle: TextStyle(
                  color: Colors.grey[600],
                  fontFamily: 'Noto Serif',
                  fontSize: 16,
                ),
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _handleSearch(), // Added this
            ),
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: _handleSearch, // Simplified this
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              elevation: 8,
              shadowColor: Colors.grey[300],
            ),
            child: const Text(
              'Ask Question',
              style: TextStyle(
                color: Color(0xFF333333),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}