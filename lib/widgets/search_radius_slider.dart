import 'package:flutter/material.dart';

class SearchRadiusSlider extends StatelessWidget {
  final double radius;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;
  final double minRadius;
  final double maxRadius;
  final int divisions;

  const SearchRadiusSlider({
    Key? key,
    required this.radius,
    required this.onChanged,
    required this.onChangeEnd,
    this.minRadius = 0.5,
    this.maxRadius = 5.0,
    this.divisions = 9,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 8.0 : 16.0,
        vertical: 4.0,
      ),
      child: Row(
        children: [
          Text(
            'Radius: ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text('${radius.toStringAsFixed(1)} km'),
          Expanded(
            child: Slider(
              value: radius,
              min: minRadius,
              max: maxRadius,
              divisions: divisions,
              label: '${radius.toStringAsFixed(1)} km',
              onChanged: onChanged,
              onChangeEnd: onChangeEnd,
            ),
          ),
        ],
      ),
    );
  }
}

class CompactSearchRadiusControl extends StatelessWidget {
  final double radius;
  final ValueChanged<double> onChanged;
  final double minRadius;
  final double maxRadius;

  const CompactSearchRadiusControl({
    Key? key,
    required this.radius,
    required this.onChanged,
    this.minRadius = 0.5,
    this.maxRadius = 5.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Radius: ${radius.toStringAsFixed(1)} km',
          style: TextStyle(fontSize: 12),
        ),
        IconButton(
          icon: Icon(Icons.remove_circle_outline, size: 18),
          padding: EdgeInsets.all(4),
          constraints: BoxConstraints(),
          onPressed: radius > minRadius
              ? () => onChanged(radius - 0.5)
              : null,
        ),
        IconButton(
          icon: Icon(Icons.add_circle_outline, size: 18),
          padding: EdgeInsets.all(4),
          constraints: BoxConstraints(),
          onPressed: radius < maxRadius
              ? () => onChanged(radius + 0.5)
              : null,
        ),
      ],
    );
  }
}
