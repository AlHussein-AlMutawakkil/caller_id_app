import 'package:flutter_test/flutter_test.dart';
import 'package:caller_id_app/database/database_helper.dart';

void main() {
  group('Phone Variants Tests', () {
    test('Landline with leading zero (e.g. 01209302)', () {
      final variants = DatabaseHelper.getPhoneVariants('01209302');
      expect(variants, contains('01209302'));
      expect(variants, contains('1209302'));
      expect(variants, contains('96701209302'));
      expect(variants, contains('9671209302'));
      expect(variants, contains('0096701209302'));
      expect(variants, contains('009671209302'));
    });

    test('Landline without leading zero (e.g. 1209302)', () {
      final variants = DatabaseHelper.getPhoneVariants('1209302');
      expect(variants, contains('1209302'));
      expect(variants, contains('01209302'));
      expect(variants, contains('9671209302'));
      expect(variants, contains('96701209302'));
      expect(variants, contains('009671209302'));
      expect(variants, contains('0096701209302'));
    });

    test('Landline with Yemen international code (+967 1 209302)', () {
      final variants = DatabaseHelper.getPhoneVariants('+967 1 209302');
      expect(variants, contains('1209302'));
      expect(variants, contains('01209302'));
    });

    test('Mobile number with 0 (e.g. 0771234567)', () {
      final variants = DatabaseHelper.getPhoneVariants('0771234567');
      expect(variants, contains('0771234567'));
      expect(variants, contains('771234567'));
      expect(variants, contains('967771234567'));
      expect(variants, contains('00967771234567'));
    });

    test('Mobile number without 0 (e.g. 771234567)', () {
      final variants = DatabaseHelper.getPhoneVariants('771234567');
      expect(variants, contains('771234567'));
      expect(variants, contains('0771234567'));
      expect(variants, contains('967771234567'));
      expect(variants, contains('00967771234567'));
    });
  });
}

