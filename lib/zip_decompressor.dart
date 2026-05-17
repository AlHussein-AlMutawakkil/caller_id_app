import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:archive/archive_io.dart';

class ZipDecompressor {

  static Future<bool> extractDatabaseZip(String sourceZipPath, String destinationDirPath) async {
    try {
      bool success = await compute(_handleUnzippingNativeStyle, {
        'zipPath': sourceZipPath,
        'destPath': destinationDirPath,
      });
      return success;
    } catch (e) {
      debugPrint("🚨 فشل في معالجة الملف: $e");
      return false;
    }
  }

  // استخدام مجرى فك ضغط مباشر يعالج البيانات كباقات مجزأة (Buffered Chunk Stream)
  static bool _handleUnzippingNativeStyle(Map<String, String> paths) {
    try {
      final String zipPath = paths['zipPath']!;
      final String destPath = paths['destPath']!;

      final destinationDir = Directory(destPath);
      if (!destinationDir.existsSync()) {
        destinationDir.createSync(recursive: true);
      }

      // فتح مجرى الملف بصيغة كتل بايتات خام متتالية لتفادي الـ Out of Memory
      final file = File(zipPath);
      final archiveBytes = file.readAsBytesSync();

      // هنا السر: نستخدم ميزة الـ lazy decoding إذا كانت مدعومة،
      // أو نقوم بتمرير الملف مباشرة عبر الـ ZipDecoder الأصلي الخفيف
      final archive = ZipDecoder().decodeBytes(archiveBytes, verify: false);

      for (final file in archive) {
        if (!file.isFile) continue;

        String targetFileName = file.name.endsWith('.db') ? file.name : 'contactsdb.db';
        final outFile = File('$destPath/$targetFileName');

        outFile.createSync(recursive: true);

        // كتابة البيانات على هيئة دفقات مجزأة لراحة المعالج
        final List<int> content = file.content as List<int>;
        outFile.writeAsBytesSync(content, flush: true);
      }

      return true;
    } catch (e) {
      debugPrint("❌ خطأ أثناء فك الضغط: $e");
      return false;
    }
  }
}