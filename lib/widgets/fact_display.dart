import 'package:flutter/material.dart';
import '../models/islamic_fact.dart';
import '../theme/text_styles.dart';

class FactDisplay extends StatelessWidget {
  final IslamicFact fact;
  final String subtitle;

  const FactDisplay({
    Key? key,
    required this.fact,
    required this.subtitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.2),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Text('💡', style: TextStyle(fontSize: 24)),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fact.title,
                style: AppTextStyles.titleText.copyWith(
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8),
              Text(
                fact.description,
                style: AppTextStyles.englishText.copyWith(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTextStyles.englishText.copyWith(
                  fontSize: 12,
                  color: Colors.black38,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
