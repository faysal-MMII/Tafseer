import 'package:flutter/material.dart';
import '../models/hadith.dart';

class HadithCard extends StatefulWidget {
  final dynamic hadith;
  final bool showExpandButton;
  
  const HadithCard({
    Key? key, 
    required this.hadith,
    this.showExpandButton = true,
  }) : super(key: key);

  @override
  _HadithCardState createState() => _HadithCardState();
}

class _HadithCardState extends State<HadithCard> {
  bool _expanded = false;
  
  @override
  Widget build(BuildContext context) {
    // Handle both Hadith object and Map (from API)
    String text = '';
    String collection = '';
    String number = '';
    
    if (widget.hadith is Hadith) {
      text = widget.hadith.text;
      // Adapt as needed based on your Hadith model
      collection = "Hadith"; 
      number = widget.hadith.hadithNumber.toString();
    } else if (widget.hadith is Map) {
      text = widget.hadith['text'] ?? '';
      collection = widget.hadith['collection'] ?? '';
      number = widget.hadith['number']?.toString() ?? '';
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Reference
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Reference: $collection $number',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (widget.showExpandButton)
                  IconButton(
                    icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                    onPressed: () {
                      setState(() {
                        _expanded = !_expanded;
                      });
                    },
                  ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Hadith Text
            if (_expanded || !widget.showExpandButton || text.length < 300)
              // Full text
              Text(
                text,
                style: TextStyle(fontSize: 15),
              )
            else
              // Truncated text with "Read more"
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getExcerpt(text, 300),
                    style: TextStyle(fontSize: 15),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _expanded = true;
                      });
                    },
                    child: Text('Read more'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
  
  // Get a clean excerpt of text
  String _getExcerpt(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    }
    
    // Find a good breaking point
    int endPos = maxLength;
    while (endPos > maxLength - 20 && text[endPos] != ' ' && text[endPos] != '.') {
      if (endPos <= 0) break;
      endPos--;
    }
    
    // If we found a period, break there
    if (endPos > 0 && text[endPos] == '.') {
      return text.substring(0, endPos + 1);
    }
    
    // Otherwise break at a space
    return text.substring(0, endPos) + "...";
  }
}