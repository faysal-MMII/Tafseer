import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/hadith.dart';

class HadithCollectorService {
  static final HadithCollectorService _instance = HadithCollectorService._internal();
  
  static final Map<String, List<String>> topicMappings = {
    'marriage': ['wife', 'wives', 'marry', 'divorce', 'divorced', 'marriage', 'spouse', 'wedding'],
    'pregnancy': ['pregnant', 'birth', 'child', 'baby', 'womb', 'deliver'],
    'divorce': ['divorce', 'separated', 'talaq', 'separation', 'marital'],
    'prayer': ['salah', 'salat', 'pray', 'worship', 'mosque', 'masjid', 'prostration', 'ruku', 'sujud'],
    'fasting': ['fast', 'sawm', 'ramadan', 'iftar', 'suhoor', 'suhur', 'taraweeh'],
    'zakat': ['charity', 'sadaqah', 'sadaqa', 'alms', 'giving', 'wealth', 'poor', 'needy'],
    'purification': ['wudu', 'ghusl', 'tayammum', 'clean', 'pure', 'ablution', 'water'],
    'faith': ['iman', 'belief', 'allah', 'prophet', 'quran', 'islam', 'muslim'],
    'charity': ['donation', 'help', 'support', 'aid', 'philanthropy'],
    'community': ['ummah', 'brotherhood', 'sisterhood', 'society', 'collective'],
    'knowledge': ['ilm', 'learning', 'education', 'study', 'scholarship'],
    'patience': ['sabr', 'endurance', 'perseverance', 'tolerance'],
    'forgiveness': ['maghfirah', 'pardon', 'mercy', 'clemency'],
    'justice': ['adl', 'fairness', 'equity', 'law', 'rights'],
    'humility': ['tawadu', 'modesty', 'humbleness', 'selflessness'],
    'gratitude': ['shukr', 'thankfulness', 'appreciation', 'recognition'],
    'trust': ['tawakkul', 'faith', 'confidence', 'reliance'],
    'sincerity': ['ikhlas', 'genuineness', 'honesty', 'purity'],
    'service': ['khidmah', 'helping', 'assistance', 'support'],
    // Add more mappings as needed
  };

  final List<String> urls = [
    "https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/eng-bukhari.json",
    "https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/eng-muslim.json"
  ];

  Map<String, dynamic>? _cachedData;
  final _cache = <String, List<Map<String, dynamic>>>{};

  factory HadithCollectorService() => _instance;

  HadithCollectorService._internal();

  Future<Map<String, dynamic>> loadHadithData() async {
    if (_cachedData != null) return _cachedData!;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/hadith_data.json');

      if (await file.exists()) {
        print("Loading cached hadith data...");
        final jsonString = await file.readAsString();
        _cachedData = json.decode(jsonString);
        return _cachedData!;
      }

      print("Downloading hadith collections...");
      Map<String, dynamic> combinedData = {};

      for (String url in urls) {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final collectionName = url.contains('bukhari') ? 'bukhari' : 'muslim';
          combinedData[collectionName] = data['hadiths'];
        }
      }

      // Cache the data
      await file.writeAsString(json.encode(combinedData));
      _cachedData = combinedData;
      return combinedData;
    } catch (e) {
      print("Error loading hadith data: $e");
      return {};
    }
  }

  Set<String> expandSearchTerms(String query) {
    Set<String> searchTerms = {};
    List<String> queryWords = query.toLowerCase().split(' ');

    // Add original query and words
    searchTerms.add(query.toLowerCase());
    searchTerms.addAll(queryWords);

    // Add related terms from mappings
    for (String word in queryWords) {
      topicMappings.forEach((topic, relatedTerms) {
        if (word == topic || relatedTerms.contains(word)) {
          searchTerms.addAll(relatedTerms);
          searchTerms.add(topic);
        }
      });
    }

    return searchTerms;
  }

  Future<List<Map<String, dynamic>>> getHadiths(String query) async {
    print('=== COLLECTOR: getHadiths START ===');
    print('Processing query: $query');

    // Check cache first
    if (_cache.containsKey(query)) {
      print('Returning cached results for: $query');
      return _cache[query]!;
    }

    final searchTerms = expandSearchTerms(query);
    print("Searching for terms: $searchTerms");

    List<Map<String, dynamic>> results = [];
    final collections = await loadHadithData();

    collections.forEach((collectionName, hadiths) {
      for (var hadith in hadiths) {
        String hadithText = hadith['text'].toString().toLowerCase();
        int score = 0;

        for (String term in searchTerms) {
          if (hadithText.contains(term)) {
            // Base score for term presence
            int baseScore = hadithText.split(term).length - 1;
            score += baseScore * 2;

            // Position bonus
            int firstPos = hadithText.indexOf(term);
            if (firstPos < hadithText.length ~/ 4) {
              score += 3;  // Bonus for terms appearing in the first quarter
            } else if (firstPos < hadithText.length ~/ 2) {
              score += 1;  // Bonus for terms appearing in the first half
            }

            // Exact phrase bonus
            if (hadithText.contains(query.toLowerCase())) {
              score += 4;
            }
          }
        }

        if (score > 0) {
          results.add({
            'score': score,
            'collection': collectionName[0].toUpperCase() + collectionName.substring(1),
            'number': hadith['reference'] ?? hadith['number'] ?? 'N/A',
            'text': hadith['text'],
            'arabic': hadith['arabic'] ?? '',
            'chapter': hadith['chapter'] ?? ''
          });
        }
      }
    });

    // Sort by score and take top 5
    results.sort((a, b) => b['score'].compareTo(a['score']));
    final topResults = results.take(5).toList();

    // Cache results
    _cache[query] = topResults;

    // Limit cache size
    if (_cache.length > 50) {
      _cache.remove(_cache.keys.first);
    }

    print('Found ${topResults.length} results');
    print('=== COLLECTOR: getHadiths END ===');
    return topResults;
  }

  Future<List<Map<String, dynamic>>> getHadithsWithRelevance(String query) async {
    final results = await getHadiths(query);
    
    // Sort by relevance
    results.sort((a, b) {
      final scoreA = a['score'] ?? 0;
      final scoreB = b['score'] ?? 0;
      return scoreB.compareTo(scoreA);
    });

    // Only return relevant results (score > 0)
    return results.where((hadith) => (hadith['score'] ?? 0) > 0).take(3).toList();
  }
}