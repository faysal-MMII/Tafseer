import 'dart:convert';

class HadithNumber {
  final int book;
  final int hadith;

  HadithNumber({
    required this.book,
    required this.hadith,
  });

  @override
  String toString() => '$book:$hadith';

  factory HadithNumber.fromDynamic(dynamic value) {
    print('Creating HadithNumber from: (${value?.runtimeType}) $value');

    if (value == null) return HadithNumber(book: 0, hadith: 0);

    try {
      // Case 1: Map format
      if (value is Map) {
        final book = _parseIntSafely(value['book']);
        final hadith = _parseIntSafely(value['hadith']);
        return HadithNumber(
          book: book >= 0 ? book : 0,  // No negative numbers
          hadith: hadith >= 0 ? hadith : 0,
        );
      }

      // Case 2: String handling
      if (value is String) {
        String cleanValue = value.trim();
        
        if (cleanValue.isEmpty) {
          return HadithNumber(book: 0, hadith: 0);
        }

        // Try colon format first (e.g., "1:234")
        if (cleanValue.contains(':')) {
          final parts = cleanValue.split(':');
          if (parts.length == 2) {
            final book = _parseIntSafely(parts[0]);
            final hadith = _parseIntSafely(parts[1]);
            return HadithNumber(
              book: book >= 0 ? book : 0,
              hadith: hadith >= 0 ? hadith : 0,
            );
          }
        }

        // Try to extract numbers from text (e.g., "Book 1, Hadith 234")
        final numbers = RegExp(r'\d+').allMatches(cleanValue).map((m) => int.parse(m.group(0)!)).toList();
        if (numbers.length >= 2) {
          return HadithNumber(
            book: numbers[0] >= 0 ? numbers[0] : 0,
            hadith: numbers[1] >= 0 ? numbers[1] : 0,
          );
        } else if (numbers.length == 1) {
          return HadithNumber(
            book: 0,
            hadith: numbers[0] >= 0 ? numbers[0] : 0,
          );
        }

        // Try JSON format as last resort
        try {
          cleanValue = cleanValue.replaceAll("'", '"');
          Map<String, dynamic> map = json.decode(cleanValue);
          final book = _parseIntSafely(map['book']);
          final hadith = _parseIntSafely(map['hadith']);
          return HadithNumber(
            book: book >= 0 ? book : 0,
            hadith: hadith >= 0 ? hadith : 0,
          );
        } catch (e) {
          print('Error parsing hadith number as JSON: $e');
          print('Input value was: $value');
        }
      }

      // Case 3: Number format
      if (value is num) {
        final number = value.toInt();
        return HadithNumber(
          book: 0,
          hadith: number >= 0 ? number : 0,
        );
      }

      print('Could not parse value: $value');
      return HadithNumber(book: 0, hadith: 0);
      
    } catch (e) {
      print('Error in HadithNumber.fromDynamic: $e');
      return HadithNumber(book: 0, hadith: 0);
    }
  }

  static int _parseIntSafely(dynamic value) {
    try {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) {
        final cleanValue = value.replaceAll(RegExp(r'[^0-9-]'), '');
        final number = int.tryParse(cleanValue) ?? 0;
        return number >= 0 ? number : 0;  // No negative numbers
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'book': book,
      'hadith': hadith,
    };
  }

  String toJson() => json.encode(toMap());
}

class Hadith {
  final int id;
  final int collectionId;
  final int chapterId;
  final HadithNumber hadithNumber;
  final String text;
  final String? arabicText;
  final String? grade;
  final String? narrator;
  final String? keywords;

  Hadith({
    required this.id,
    required this.collectionId,
    required this.chapterId,
    required this.hadithNumber,
    required this.text,
    this.arabicText,
    this.grade,
    this.narrator,
    this.keywords,
  }) {
    print('\n--- DEBUG HADITH CREATION ---');
    print('Creating Hadith with hadithNumber: $hadithNumber');
    print('Type of hadithNumber: ${hadithNumber.runtimeType}');
    print('-------------------------\n');
  }

  factory Hadith.fromMap(Map<String, dynamic> map) {
    print('Creating Hadith from map. hadith_number: (${map['hadith_number'].runtimeType}) ${map['hadith_number']}');

    return Hadith(
      id: map['id'] ?? 0,
      collectionId: map['collection_id'] ?? 0,
      chapterId: map['chapter_id'] ?? 0,
      hadithNumber: HadithNumber.fromDynamic(map['hadith_number']),
      text: map['text'] ?? '',
      arabicText: map['arabic_text'],
      grade: map['grade'],
      narrator: map['narrator'],
      keywords: map['keywords'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'collection_id': collectionId,
      'chapter_id': chapterId,
      'hadith_number': hadithNumber.toMap(),
      'text': text,
      'arabic_text': arabicText,
      'grade': grade,
      'narrator': narrator,
      'keywords': keywords,
    };
  }

  dynamic operator [](String key) {
    switch (key) {
      case 'id':
        return id;
      case 'collectionId':
      case 'collection':
        return collectionId;
      case 'chapterId':
      case 'chapter':
        return chapterId;
      case 'hadithNumber':
      case 'hadith_number':
      case 'number':
        return hadithNumber.toJson();
      case 'text':
        return text;
      case 'arabicText':
      case 'arabic':
        return arabicText;
      case 'grade':
        return grade;
      case 'narrator':
        return narrator;
      case 'keywords':
        return keywords;
      default:
        throw ArgumentError('Invalid key: $key');
    }
  }
}

class HadithResponse {
  final String answer;
  final List<Hadith> hadiths;

  HadithResponse({
    required this.answer,
    required this.hadiths,
  });

  factory HadithResponse.fromMap(Map<String, dynamic> map) {
    print('\n=== DEBUG: HADITH RESPONSE ===');
    print('Response type: ${map.runtimeType}');

    // Handle answer field
    String answerText = '';
    if (map['answer'] != null) {
      answerText = map['answer'].toString();
    }

    // Handle hadiths list
    List<Hadith> hadithsList = [];
    if (map['hadiths'] != null) {
      print('Hadiths type: ${map['hadiths'].runtimeType}');

      if (map['hadiths'] is List) {
        try {
          hadithsList = (map['hadiths'] as List).map((hadith) {
            print('First hadith type: ${hadith.runtimeType}');

            if (hadith is Map<String, dynamic>) {
              // Ensure hadith_number is properly formatted
              if (hadith['hadith_number'] != null) {
                var hadithNumber = hadith['hadith_number'];
                // If it's already a string, use it as is
                if (hadithNumber is! String) {
                  // Convert Map to JSON string if necessary
                  hadith = Map<String, dynamic>.from(hadith);
                  hadith['hadith_number'] = json.encode(hadithNumber);
                }
              }
              return Hadith.fromMap(hadith);
            }

            // Fallback for non-map hadiths
            return Hadith(
              id: 0,
              collectionId: 0,
              chapterId: 0,
              hadithNumber: HadithNumber(book: 0, hadith: 0),
              text: hadith.toString(),
            );
          }).toList();
        } catch (e) {
          print('Error parsing hadiths list: $e');
          // Return empty list on error
          hadithsList = [];
        }
      }
    }

    return HadithResponse(
      answer: answerText,
      hadiths: hadithsList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'answer': answer,
      'hadiths': hadiths.map((hadith) => hadith.toMap()).toList(),
    };
  }
}

// Helper function to debug hadith processing
void debugHadithProcessing(dynamic hadithData, String stage) {
  print('\n==== DEBUG HADITH PROCESSING ($stage) ====');
  if (hadithData is Map) {
    print('Type: Map');
    hadithData.forEach((key, value) {
      print('$key: (${value.runtimeType}) $value');
    });

    // Special check for hadith_number
    if (hadithData.containsKey('hadith_number')) {
      print('HADITH_NUMBER FOCUS: ${hadithData['hadith_number']} (${hadithData['hadith_number'].runtimeType})');
    }
  } else if (hadithData is List) {
    print('Type: List with ${hadithData.length} items');
    if (hadithData.isNotEmpty) {
      print('First item type: ${hadithData.first.runtimeType}');
    }
  } else {
    print('Type: ${hadithData.runtimeType}');
    print('Value: $hadithData');
  }
  print('=============================\n');
}