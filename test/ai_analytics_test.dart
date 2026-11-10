import 'package:flutter_test/flutter_test.dart';
import 'package:caller_id_app/core/services/ai_analytics_service.dart';

void main() {
  group('AiAnalytics Tests', () {
    test('PrefixDistribution percentage formatting', () {
      final prefix = PrefixDistribution(
        prefix: '77',
        count: 500,
        percentage: 50.0,
        label: 'يمن موبايل',
        colorValue: 0xFFB71C1C,
      );

      expect(prefix.prefix, '77');
      expect(prefix.count, 500);
      expect(prefix.percentage, 50.0);
      expect(prefix.label, 'يمن موبايل');
      expect(prefix.colorValue, 0xFFB71C1C);
    });

    test('AiAnalyticsResult creation and properties', () {
      final result = AiAnalyticsResult(
        totalRecords: 1000000,
        detectedCountry: 'اليمن',
        detectedCountryCode: '+967',
        trustScore: 99.2,
        benchmarkMs: 3,
        databaseSizeBytes: 1024 * 1024 * 500,
        pageSize: 4096,
        pageCount: 128000,
        journalMode: 'wal',
        personalRatio: 0.85,
        commercialRatio: 0.08,
        medicalRatio: 0.02,
        governmentRatio: 0.01,
        servicesRatio: 0.03,
        spamRiskRatio: 0.01,
        personalCount: 850000,
        commercialCount: 80000,
        medicalCount: 20000,
        governmentCount: 10000,
        servicesCount: 30000,
        spamRiskCount: 10000,
        prefixList: [
          PrefixDistribution(
              prefix: '77',
              count: 400000,
              percentage: 40.0,
              label: 'يمن موبايل',
              colorValue: 0xFFB71C1C),
          PrefixDistribution(
              prefix: '73',
              count: 300000,
              percentage: 30.0,
              label: 'يو (YOU)',
              colorValue: 0xFFF57F17),
        ],
        singleNameRatio: 0.88,
        multiNameRatio: 0.12,
        avgNamesPerNumber: 1.15,
      );

      expect(result.totalRecords, 1000000);
      expect(result.detectedCountry, 'اليمن');
      expect(result.detectedCountryCode, '+967');
      expect(result.trustScore, 99.2);
      expect(result.benchmarkMs, 3);
      expect(result.prefixList.length, 2);
      expect(result.singleNameRatio + result.multiNameRatio, 1.0);
    });
  });
}
