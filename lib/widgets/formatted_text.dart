import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../theme/text_styles.dart';

class FormattedText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final TextAlign? textAlign;

  // Constructor with positional parameter for the text
  const FormattedText(
    this.text, {
    Key? key,
    required this.style,
    this.textAlign,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: textAlign == TextAlign.center 
          ? Alignment.center 
          : textAlign == TextAlign.end
              ? Alignment.centerRight
              : Alignment.centerLeft,
      child: MarkdownBody(
        data: text,
        styleSheet: MarkdownStyleSheet(
          p: style,
          strong: style.copyWith(fontWeight: FontWeight.bold),
          em: style.copyWith(fontStyle: FontStyle.italic),
          listBullet: style,
        ),
        softLineBreak: true,
        shrinkWrap: true,
      ),
    );
  }
}