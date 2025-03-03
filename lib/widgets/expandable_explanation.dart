import 'package:flutter/material.dart';

class ExpandableExplanation extends StatefulWidget {
  final String text;
  final TextStyle? style; // Add style parameter
  
  const ExpandableExplanation({
    Key? key, 
    required this.text,
    this.style, // Make it optional
  }) : super(key: key);

  @override
  _ExpandableExplanationState createState() => _ExpandableExplanationState();
}

class _ExpandableExplanationState extends State<ExpandableExplanation> {
  bool _expanded = false;
  
  @override
  Widget build(BuildContext context) {
    // If text is short, just display it
    if (widget.text.length < 300) {
      return Text(
        widget.text,
        style: widget.style ?? TextStyle(fontSize: 16), // Use provided style
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show either full or truncated text
        Text(
          _expanded ? widget.text : _getExcerpt(widget.text, 300),
          style: widget.style ?? TextStyle(fontSize: 16), // Use provided style
        ),
        
        // Show Read more/less button
        TextButton(
          onPressed: () {
            setState(() {
              _expanded = !_expanded;
            });
          },
          child: Text(_expanded ? 'Read less' : 'Read more'),
        ),
      ],
    );
  }
  
  // Get a clean excerpt of text
  String _getExcerpt(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    
    // Find a good breaking point
    int endPos = maxLength;
    while (endPos > maxLength - 20 && endPos > 0 && text[endPos] != ' ' && text[endPos] != '.') {
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