import 'package:flutter/material.dart';
import '../models/place.dart';
import '../models/filter_option.dart';

class PlaceMarker extends StatelessWidget {
  final Place place;
  final double distance;
  final FilterOption filterOption;
  final VoidCallback? onTap;

  PlaceMarker({
    Key? key,
    required this.place,
    required this.distance,
    required this.filterOption,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        // Removed fixed height constraint to let it adjust based on content
        padding: EdgeInsets.all(4),
        // Added constraints to prevent overflow
        constraints: BoxConstraints(maxWidth: 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Important: keep this
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              filterOption.icon,
              size: 16,
              color: filterOption.markerColor,
            ),
            Text(
              _formatDistance(distance),
              style: TextStyle(
                fontSize: 8,
                height: 1.0,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis, // Important: ensure text is cut off if too long
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatDistance(double distance) {
    if (distance < 0.1) {
      // Convert to meters if less than 100m
      return '${(distance * 1000).toStringAsFixed(0)}m';
    } else {
      return '${distance.toStringAsFixed(1)}km';
    }
  }
}

class CurrentLocationMarker extends StatelessWidget {
  const CurrentLocationMarker({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.7),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Icon(
        Icons.my_location,
        color: Colors.white,
        size: 12,
      ),
    );
  }
}