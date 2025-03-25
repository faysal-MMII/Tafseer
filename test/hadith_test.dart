// test/hadith_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:tafseer/models/hadith.dart';

void main() {
  group('HadithNumber Parsing Tests', () {
    test('Parses Map format correctly', () {
      final result = HadithNumber.fromDynamic({
        'book': 1,
        'hadith': 234
      });
      expect(result.book, equals(1));
      expect(result.hadith, equals(234));
    });

    test('Parses String colon format correctly', () {
      final result = HadithNumber.fromDynamic('1:234');
      expect(result.book, equals(1));
      expect(result.hadith, equals(234));
    });

    test('Parses single number as hadith number', () {
      final result = HadithNumber.fromDynamic('234');
      expect(result.book, equals(0));
      expect(result.hadith, equals(234));
    });

    test('Handles empty string gracefully', () {
      final result = HadithNumber.fromDynamic('');
      expect(result.book, equals(0));
      expect(result.hadith, equals(0));
    });

    test('Handles null input gracefully', () {
      final result = HadithNumber.fromDynamic(null);
      expect(result.book, equals(0));
      expect(result.hadith, equals(0));
    });

    test('Handles malformed JSON string gracefully', () {
      final result = HadithNumber.fromDynamic('{"bad":json"}');
      expect(result.book, equals(0));
      expect(result.hadith, equals(0));
    });

    test('Handles numeric input', () {
      final result = HadithNumber.fromDynamic(234);
      expect(result.book, equals(0));
      expect(result.hadith, equals(234));
    });

    test('Parses JSON string format correctly', () {
      final result = HadithNumber.fromDynamic('{"book":1,"hadith":234}');
      expect(result.book, equals(1));
      expect(result.hadith, equals(234));
    });

    test('Handles mixed string formats', () {
      final result = HadithNumber.fromDynamic('Book 1, Hadith 234');
      expect(result.book, equals(1));
      expect(result.hadith, equals(234));
    });
  });

  group('HadithNumber toString Tests', () {
    test('Formats toString correctly', () {
      final hadith = HadithNumber(book: 1, hadith: 234);
      expect(hadith.toString(), equals('1:234'));
    });
  });

  group('Edge Cases', () {
    test('Handles negative numbers', () {
      final result = HadithNumber.fromDynamic('-1:-234');
      expect(result.book, equals(0));
      expect(result.hadith, equals(0));
    });

    test('Handles floating point numbers', () {
      final result = HadithNumber.fromDynamic({'book': 1.5, 'hadith': 234.7});
      expect(result.book, equals(1));
      expect(result.hadith, equals(234));
    });

    test('Handles extremely large numbers', () {
      final result = HadithNumber.fromDynamic('999999999999:999999999999');
      expect(result.book, equals(999999999999));
      expect(result.hadith, equals(999999999999));
    });
  });
}
