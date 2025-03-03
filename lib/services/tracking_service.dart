import 'package:shared_preferences/shared_preferences.dart';

class UserInteractionTracker {
  static const String kFilterCountKey = 'filter_counts';
  static const String kSearchHistoryKey = 'search_history';
  static const String kPlaceClicksKey = 'place_clicks';

  // Track filter usage
  Future<void> trackFilterUsage(String filter) async {
    final prefs = await SharedPreferences.getInstance();
    final counts = prefs.getStringList(kFilterCountKey) ?? [];

    // Store as "filter:count" pairs
    Map<String, int> filterCounts = {};
    for (String pair in counts) {
      final parts = pair.split(':');
      if (parts.length == 2) {
        filterCounts[parts[0]] = int.parse(parts[1]);
      }
    }

    filterCounts[filter] = (filterCounts[filter] ?? 0) + 1;

    // Convert back to list for storage
    final updatedCounts = filterCounts.entries
        .map((e) => '${e.key}:${e.value}')
        .toList();

    await prefs.setStringList(kFilterCountKey, updatedCounts);
  }

  // Track search history
  Future<void> trackSearch(String searchTerm) async {
    if (searchTerm.trim().isEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    final searches = prefs.getStringList(kSearchHistoryKey) ?? [];

    // Remove if already exists to avoid duplicates
    searches.remove(searchTerm);
    
    // Keep only last 20 searches
    if (searches.length >= 20) {
      searches.removeLast();
    }
    searches.insert(0, searchTerm);

    await prefs.setStringList(kSearchHistoryKey, searches);
  }

  // Track place clicks
  Future<void> trackPlaceClick(String placeType) async {
    final prefs = await SharedPreferences.getInstance();
    final clicks = prefs.getStringList(kPlaceClicksKey) ?? [];

    // Keep last 50 interactions
    if (clicks.length >= 50) {
      clicks.removeLast();
    }
    clicks.insert(0, placeType);

    await prefs.setStringList(kPlaceClicksKey, clicks);
  }

  // Get most used filter
  Future<String?> getMostUsedFilter() async {
    final prefs = await SharedPreferences.getInstance();
    final counts = prefs.getStringList(kFilterCountKey) ?? [];

    if (counts.isEmpty) return null;

    Map<String, int> filterCounts = {};
    for (String pair in counts) {
      final parts = pair.split(':');
      if (parts.length == 2) {
        filterCounts[parts[0]] = int.parse(parts[1]);
      }
    }

    // Find highest count
    String? mostUsed;
    int maxCount = 0;
    filterCounts.forEach((filter, count) {
      if (count > maxCount) {
        maxCount = count;
        mostUsed = filter;
      }
    });

    return mostUsed;
  }

  // Get recent searches
  Future<List<String>> getRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(kSearchHistoryKey) ?? [];
  }

  // Get recent interactions
  static Future<List<String>> getRecentInteractions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(kPlaceClicksKey) ?? [];
  }

  // Get interaction summary
  Future<Map<String, dynamic>> getInteractionSummary() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'mostUsedFilter': await getMostUsedFilter(),
      'recentSearches': prefs.getStringList(kSearchHistoryKey) ?? [],
      'recentClicks': prefs.getStringList(kPlaceClicksKey) ?? []
    };
  }
  
  // Clear tracking data
  Future<void> clearTrackingData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(kFilterCountKey);
    await prefs.remove(kSearchHistoryKey);
    await prefs.remove(kPlaceClicksKey);
  }
}