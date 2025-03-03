import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/hadith.dart';

class HadithCollectorService {
  static final HadithCollectorService _instance = HadithCollectorService._internal();
  
  // Keep your existing topic mappings
  static final Map<String, List<String>> topicMappings = {
    // Your existing mappings
  };
  
  // Add intent classification mapping - this helps understand the user's intent
  static final Map<String, List<String>> intentMappings = {
    'howto': ['how', 'steps', 'procedure', 'method', 'guide', 'instructions', 'perform'],
    'definition': ['what is', 'define', 'meaning', 'definition', 'explain', 'concept'],
    'importance': ['why', 'importance', 'benefit', 'significance', 'reason', 'purpose'],
    'rules': ['rules', 'conditions', 'requirements', 'obligatory', 'mandatory', 'forbidden', 'allowed'],
    'history': ['origin', 'history', 'start', 'began', 'first', 'during', 'prophet']
  };
  
  // Add procedural term mappings for different topics
  static final Map<String, List<String>> proceduralMappings = {
    'prayer': [
      'stand', 'standing', 'ruku', 'prostration', 'sujud', 'recite', 
      'recitation', 'tashahhud', 'tasleem', 'salam', 'takbir', 
      'raise hands', 'bow', 'perform', 'step', 'direction', 'face', 
      'mecca', 'qibla', 'fatiha', 'position', 'movement', 'sequence',
      'begin', 'end', 'start', 'finish', 'iqamah', 'allahu akbar'
    ],
    'wudu': [
      'wash', 'hands', 'face', 'arms', 'feet', 'head', 'wiping', 'water',
      'ablution', 'clean', 'rinse', 'mouth', 'nose', 'ears', 'sequence'
    ],
    'fasting': [
      'start', 'break', 'iftar', 'suhoor', 'dawn', 'sunset', 'refrain',
      'eat', 'drink', 'abstain', 'intention', 'niyyah', 'during'
    ]
    // Add more procedural mappings for other topics
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
    String lowercaseQuery = query.toLowerCase();
    List<String> queryWords = lowercaseQuery.split(' ');

    // Add original query and words
    searchTerms.add(lowercaseQuery);
    searchTerms.addAll(queryWords);

    // Detect query intent (how-to, what is, why, etc.)
    String detectedIntent = 'general';
    for (var intent in intentMappings.keys) {
      for (var term in intentMappings[intent]!) {
        if (lowercaseQuery.contains(term)) {
          detectedIntent = intent;
          break;
        }
      }
      if (detectedIntent != 'general') break;
    }
    
    print("Detected query intent: $detectedIntent");

    // Identify primary topics in the query
    Set<String> primaryTopics = {};
    for (String topic in topicMappings.keys) {
      if (lowercaseQuery.contains(topic)) {
        primaryTopics.add(topic);
      } else {
        // Check if query contains any related terms
        for (String term in topicMappings[topic]!) {
          if (queryWords.contains(term)) {
            primaryTopics.add(topic);
            break;
          }
        }
      }
    }
    
    print("Identified primary topics: $primaryTopics");

    // Add related terms for identified topics
    for (String topic in primaryTopics) {
      searchTerms.addAll(topicMappings[topic] ?? []);
      
      // For how-to queries, add procedural terms
      if (detectedIntent == 'howto' && proceduralMappings.containsKey(topic)) {
        searchTerms.addAll(proceduralMappings[topic] ?? []);
        print("Added procedural terms for $topic");
      }
    }

    // Add multi-word combinations for better phrase matching
    if (queryWords.length > 1) {
      for (int i = 0; i < queryWords.length - 1; i++) {
        searchTerms.add("${queryWords[i]} ${queryWords[i + 1]}");
      }
    }

    // Remove very common words
    searchTerms.removeWhere((term) => 
      term.length < 3 || 
      ['the', 'and', 'for', 'was', 'that', 'with', 'this', 'his', 'her', 'they'].contains(term)
    );

    print("Expanded search terms: $searchTerms");
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

    // Detect intent and topics for contextual search
    String lowercaseQuery = query.toLowerCase();
    String detectedIntent = 'general';
    for (var intent in intentMappings.keys) {
      for (var term in intentMappings[intent]!) {
        if (lowercaseQuery.contains(term)) {
          detectedIntent = intent;
          break;
        }
      }
      if (detectedIntent != 'general') break;
    }
    
    Set<String> primaryTopics = {};
    for (String topic in topicMappings.keys) {
      if (lowercaseQuery.contains(topic)) {
        primaryTopics.add(topic);
      } else {
        // Check if query contains any related terms
        for (String term in topicMappings[topic]!) {
          if (lowercaseQuery.contains(term)) {
            primaryTopics.add(topic);
            break;
          }
        }
      }
    }
    
    final searchTerms = expandSearchTerms(query);
    print("Searching for terms: $searchTerms");

    List<Map<String, dynamic>> results = [];
    final collections = await loadHadithData();

    // Extract "core" terms for higher weighting
    List<String> coreTerms = query.toLowerCase().split(' ')
        .where((term) => term.length > 3 && !['the', 'and', 'for', 'was', 'that', 'with'].contains(term))
        .toList();

    collections.forEach((collectionName, hadiths) {
      for (var hadith in hadiths) {
        String hadithText = hadith['text'].toString().toLowerCase();
        int score = 0;
        
        // Check for exact phrase match first
        if (hadithText.contains(lowercaseQuery)) {
          score += 15;  // High bonus for exact match
        }
        
        // Score each core term
        for (String term in coreTerms) {
          if (hadithText.contains(term)) {
            // Base score for term presence
            int baseScore = hadithText.split(term).length - 1;
            score += baseScore * 2;
            
            // Position bonus
            int firstPos = hadithText.indexOf(term);
            if (firstPos < hadithText.length ~/ 4) {
              score += 3;  // Higher bonus for terms appearing early
            } else if (firstPos < hadithText.length ~/ 2) {
              score += 1;
            }
          }
        }
        
        // Score other search terms
        for (String term in searchTerms) {
          if (!coreTerms.contains(term) && hadithText.contains(term)) {
            // Base score for term presence
            int baseScore = hadithText.split(term).length - 1;
            score += baseScore;
            
            // Special handling for procedural terms in how-to queries
            if (detectedIntent == 'howto' && 
                primaryTopics.isNotEmpty && 
                primaryTopics.any((topic) => 
                  proceduralMappings.containsKey(topic) && 
                  proceduralMappings[topic]!.contains(term))) {
              score += 5;  // Big bonus for procedural terms in how-to queries
            }
          }
        }
        
        // Context-specific scoring based on query intent
        switch (detectedIntent) {
          case 'howto':
            // For how-to queries, boost hadiths with procedural language
            if (hadithText.contains('narrated') && 
                (hadithText.contains('perform') || 
                 hadithText.contains('said') || 
                 hadithText.contains('used to') || 
                 hadithText.contains('would'))) {
              score += 5;
            }
            
            // Check for sequential language (first, then, after)
            if (hadithText.contains('first') || 
                hadithText.contains('then') || 
                hadithText.contains('after') || 
                hadithText.contains('before') || 
                hadithText.contains('during')) {
              score += 5;
            }
            break;
            
          case 'definition':
            // For definition queries, boost hadiths with explanatory language
            if (hadithText.contains('means') || 
                hadithText.contains('defined') || 
                hadithText.contains('called') || 
                hadithText.contains('refers to')) {
              score += 5;
            }
            break;
            
          case 'importance':
            // For importance queries, boost hadiths with value statements
            if (hadithText.contains('importance') || 
                hadithText.contains('important') || 
                hadithText.contains('benefit') || 
                hadithText.contains('reward') || 
                hadithText.contains('virtue')) {
              score += 5;
            }
            break;
        }
        
        // Add results with any score, we'll filter later
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

    // Sort by score
    results.sort((a, b) => b['score'].compareTo(a['score']));
    
    // Get more results initially, then filter
    var topResults = results.take(10).toList();
    
    // If we have strong matches, take only those
    if (topResults.isNotEmpty && topResults[0]['score'] > 10) {
      // Find cutoff score (at least 40% of top score)
      int topScore = topResults[0]['score'];
      int cutoffScore = (topScore * 0.4).round();
      
      // Filter by cutoff
      topResults = topResults.where((r) => r['score'] >= cutoffScore).take(5).toList();
    } else {
      // Otherwise take top 5
      topResults = topResults.take(5).toList();
    }

    // Cache results
    _cache[query] = topResults;

    // Limit cache size
    if (_cache.length > 50) {
      _cache.remove(_cache.keys.first);
    }

    print('Found ${topResults.length} results with scores: ${topResults.map((r) => r['score']).toList()}');
    print('=== COLLECTOR: getHadiths END ===');
    return topResults;
  }

  Future<List<Map<String, dynamic>>> getHadithsWithRelevance(String query) async {
    final results = await getHadiths(query);
    
    // Already sorted by relevance
    return results.take(3).toList();
  }
}