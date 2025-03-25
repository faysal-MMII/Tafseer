import 'package:flutter/material.dart';
import '../models/filter_option.dart';
import '../models/place.dart'; 

class FilterChipsRow extends StatelessWidget {
  final String activeFilter;
  final Function(String) onFilterSelected;
  final Map<String, FilterOption> filterOptions;

  const FilterChipsRow({
    Key? key,
    required this.activeFilter,
    required this.onFilterSelected,
    required this.filterOptions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Container(
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 5 : 10,
          vertical: 5
        ),
        children: filterOptions.entries.map((filter) {
          bool isActive = activeFilter == filter.key;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 5),
            child: FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    filter.value.icon,
                    size: 20,
                    color: isActive ? Colors.white : Colors.black
                  ),
                  SizedBox(width: 5),
                  Text(
                    _capitalizeText(filter.value.displayName), // Use helper method instead
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.black
                    ),
                  ),
                ],
              ),
              selected: isActive,
              onSelected: (bool selected) {
                if (selected) {
                  onFilterSelected(filter.key);
                }
              },
              backgroundColor: Colors.grey[200],
              selectedColor: Theme.of(context).primaryColor,
            ),
          );
        }).toList(),
      ),
    );
  }
  
  // Define a helper method to capitalize text directly in this class
  String _capitalizeText(String text) {
    if (text.isEmpty) return text;
    return "${text[0].toUpperCase()}${text.substring(1)}";
  }
}

// A smaller version of the filter chips for specific layouts
class CompactFilterChips extends StatelessWidget {
  final String activeFilter;
  final Function(String) onFilterSelected;
  final Map<String, FilterOption> filterOptions;

  const CompactFilterChips({
    Key? key,
    required this.activeFilter,
    required this.onFilterSelected,
    required this.filterOptions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: filterOptions.entries.map<Widget>((filter) { // Added <Widget> type
        bool isActive = activeFilter == filter.key;
        return ActionChip(
          avatar: Icon(
            filter.value.icon,
            size: 16,
            color: isActive ? Colors.white : Colors.black,
          ),
          label: Text(
            _capitalizeText(filter.value.displayName), // Use helper method instead
            style: TextStyle(
              fontSize: 12,
              color: isActive ? Colors.white : Colors.black,
            ),
          ),
          backgroundColor: isActive
              ? Theme.of(context).primaryColor
              : Colors.grey[200],
          onPressed: () {
            onFilterSelected(filter.key);
          },
        );
      }).toList(),
    );
  }
  
  // Define a helper method to capitalize text directly in this class
  String _capitalizeText(String text) {
    if (text.isEmpty) return text;
    return "${text[0].toUpperCase()}${text.substring(1)}";
  }
}