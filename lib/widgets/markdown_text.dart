import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MarkdownText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Color? color;
  final double? fontSize;
  final FontWeight? fontWeight;

  const MarkdownText({
    Key? key,
    required this.text,
    this.style,
    this.color,
    this.fontSize,
    this.fontWeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: _parseMarkdownText(text, style),
    );
  }

  TextSpan _parseMarkdownText(String text, TextStyle? baseStyle) {
    final List<TextSpan> spans = [];
    final RegExp boldRegex = RegExp(r'\*\*(.*?)\*\*');
    
    int lastEnd = 0;
    
    for (final Match match in boldRegex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: baseStyle ?? GoogleFonts.poppins(
            color: color,
            fontSize: fontSize,
            fontWeight: fontWeight,
          ),
        ));
      }
      
      spans.add(TextSpan(
        text: match.group(1),
        style: (baseStyle ?? GoogleFonts.poppins(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        )).copyWith(fontWeight: FontWeight.bold),
      ));
      
      lastEnd = match.end;
    }
    
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: baseStyle ?? GoogleFonts.poppins(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ));
    }
    
    if (spans.isEmpty) {
      spans.add(TextSpan(
        text: text,
        style: baseStyle ?? GoogleFonts.poppins(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ));
    }
    
    return TextSpan(children: spans);
  }
}