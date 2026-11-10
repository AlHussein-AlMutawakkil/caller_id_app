import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  // اسم ملف قاعدة البيانات الداخلي الثابت
  static const _databaseName = "contactsdb.db";
  static const _databaseVersion = 1;

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  static int? _cachedRecordsCount;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String databasesPath = await getDatabasesPath();
    String path = join(databasesPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onOpen: (db) async {
        // 🚀 حقن منشطات السرعة القصوى لربط الـ 7.8 جيجابايت بالذاكرة العشوائية RAM فوراً
        try {
          await db.rawQuery('PRAGMA journal_mode=WAL;');
          await db.rawQuery('PRAGMA synchronous=OFF;');
          await db.rawQuery('PRAGMA temp_store=MEMORY;');
          await db.rawQuery('PRAGMA cache_size=-200000;'); // كاش 200 ميجابايت فوري
          await db.rawQuery('PRAGMA mmap_size=30000000000;'); // خرائط الذاكرة لقفز المعالج
        } catch (e) {
          debugPrint("تنبيه أثناء تهيئة المحرك: $e");
        }
      },
    );
  }

  Future<void> closeDb() async {
    _cachedRecordsCount = null;
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<void> deleteDbFile() async {
    _cachedRecordsCount = 0;
    await closeDb();
    String databasesPath = await getDatabasesPath();
    String path = join(databasesPath, _databaseName);
    await databaseFactory.deleteDatabase(path);
  }

  /// التحقق من أن الملف هو ملف SQLite سليم بقراءة الـ Header السحري
  Future<bool> isValidSqliteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return false;
      final raf = await file.open(mode: FileMode.read);
      final header = await raf.read(16);
      await raf.close();
      if (header.length < 16) return false;
      final magic = String.fromCharCodes(header);
      return magic.startsWith('SQLite format 3');
    } catch (_) {
      return false;
    }
  }

  /// استيراد قاعدة بيانات جديدة من المسار المحدد مع بث التقدم الحقيقي (0% -> 100%) دون استهلاك كاش
  Future<bool> importDatabaseWithProgress(
    String sourcePath, {
    void Function(double progress, int copiedBytes, int totalBytes)? onProgress,
  }) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        throw Exception("الملف المحدد غير موجود على الجهاز");
      }

      // 1. التحقق من أن الملف هو قاعدة بيانات SQLite صالحة
      final isValid = await isValidSqliteFile(sourcePath);
      if (!isValid) {
        throw Exception("الملف المختار ليس ملف قاعدة بيانات SQLite صالح (.db)");
      }

      // 2. إغلاق أي اتصال مفتوح بالقاعدة الحالية
      await closeDb();

      // 3. تحديد المسار الداخلي للقاعدة
      String databasesPath = await getDatabasesPath();
      String destinationPath = join(databasesPath, _databaseName);

      final dbDir = Directory(databasesPath);
      if (!await dbDir.exists()) {
        await dbDir.create(recursive: true);
      }

      // 4. حذف ملفات القاعدة القديمة ومخلفات الـ WAL لضمان عدم تلف الملف الجديد
      try {
        await databaseFactory.deleteDatabase(destinationPath);
      } catch (_) {}

      for (final ext in ['-wal', '-shm', '-journal']) {
        final aux = File('$destinationPath$ext');
        if (await aux.exists()) {
          try {
            await aux.delete();
          } catch (_) {}
        }
      }

      // 5. نسخ الملف عبر التدفق (Stream) مباشرة من مجلد التنزيلات لحساب النسبة المئوية وتفادي الكاش
      final totalBytes = await sourceFile.length();
      int copiedBytes = 0;
      final destinationFile = File(destinationPath);

      final readStream = sourceFile.openRead();
      final writeSink = destinationFile.openWrite();

      int lastReportedPercent = -1;

      await for (final chunk in readStream) {
        writeSink.add(chunk);
        copiedBytes += chunk.length;

        if (onProgress != null && totalBytes > 0) {
          final progress = (copiedBytes / totalBytes).clamp(0.0, 1.0);
          final intPercent = (progress * 100).toInt();

          // إرسال التحديث عند كل تغير في النسبة لتفادي بطء الواجهة
          if (intPercent != lastReportedPercent || copiedBytes >= totalBytes) {
            lastReportedPercent = intPercent;
            onProgress(progress, copiedBytes, totalBytes);
          }
        }
      }

      await writeSink.flush();
      await writeSink.close();

      if (onProgress != null) {
        onProgress(1.0, totalBytes, totalBytes);
      }

      // 6. فتح وتهيئة قاعدة البيانات الجديدة للتأكد من سلامتها
      _database = await _initDatabase();
      _cachedRecordsCount = null;

      return true;
    } catch (e) {
      debugPrint("خطأ أثناء استيراد قاعدة البيانات: $e");
      try {
        _database = await _initDatabase();
      } catch (_) {}
      rethrow;
    }
  }

  /// دالة الاستيراد الافتراضية
  Future<bool> importDatabase(String sourcePath) async {
    return await importDatabaseWithProgress(sourcePath);
  }

  Future _onCreate(Database db, int version) async {
    try {
      await db.execute('''
          CREATE TABLE IF NOT EXISTS nambers_thabeet (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            phone TEXT,
            names TEXT,
            company TEXT
          )
          ''');
    } catch (e) {
      debugPrint("خطأ في إنشاء الجدول الافتراضي: $e");
    }
  }

  Future<String> getDatabasesDirectoryPath() async {
    return await getDatabasesPath();
  }

  // ⚡ قراءة إجمالي عدد السجلات الفعلي الحقيقي بدقة تامة وبدون استخدام rowid المغلوط
  Future<int> getTotalRecordsCount({bool forceRefresh = false}) async {
    if (_cachedRecordsCount != null && !forceRefresh) {
      return _cachedRecordsCount!;
    }

    try {
      final db = await database;

      // 1. استكشاف الجداول المتاحة في قاعدة البيانات
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name != 'android_metadata' AND name NOT LIKE 'sqlite_%'",
      );
      if (tables.isEmpty) return 0;

      // 2. تحديد اسم الجدول (الأولوية لـ nambers_thabeet أو أول جدول فعلي)
      String tableName = 'nambers_thabeet';
      final hasThabeet = tables.any((t) => t['name'] == 'nambers_thabeet');
      if (!hasThabeet) {
        tableName = tables.first['name'] as String;
      }

      // 3. قراءة العدد الفعلي الحقيقي لجميع الصفوف عبر COUNT(*)
      final countResult = await db.rawQuery('SELECT COUNT(*) FROM $tableName');
      int? count = Sqflite.firstIntValue(countResult);

      if (count != null && count > 0) {
        _cachedRecordsCount = count;
        return count;
      }

      return 0;
    } catch (e) {
      debugPrint("خطأ في قراءة العداد: $e");
      return 0;
    }
  }

  // استخراج كافة الصيغ المحتملة للرقم اليمني (مع وبدون الصفر، وبالرمز الدولي 967 و 00967)
  static List<String> getPhoneVariants(String rawNumber) {
    String clean = rawNumber.trim().replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
    if (clean.isEmpty) return [];

    // استخلاص الرقم المحلي بدون المفتاح الدولي
    String local = clean;
    if (local.startsWith('00967')) {
      local = local.substring(5);
    } else if (local.startsWith('967') && local.length > 7) {
      local = local.substring(3);
    }

    final Set<String> variants = {
      rawNumber.trim(),
      clean,
      local,
    };

    if (local.startsWith('0')) {
      final withoutZero = local.substring(1);
      variants.add(withoutZero);
      variants.add('967$local');
      variants.add('967$withoutZero');
      variants.add('00967$local');
      variants.add('00967$withoutZero');
      variants.add('+967$local');
      variants.add('+967$withoutZero');
    } else {
      final withZero = '0$local';
      variants.add(withZero);
      variants.add('967$local');
      variants.add('967$withZero');
      variants.add('00967$local');
      variants.add('00967$withZero');
      variants.add('+967$local');
      variants.add('+967$withZero');
    }

    return variants.where((v) => v.isNotEmpty).toSet().toList();
  }

  // ⚡ استعلام الرقم الصاروخي الفوري المباشر مع دعم التوافق التلقائي للأعمدة وكافة صيغ الأرقام
  Future<List<Map<String, dynamic>>> searchByNumber(String number) async {
    try {
      final db = await database;

      var tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name != 'android_metadata' AND name NOT LIKE 'sqlite_%'");
      if (tables.isEmpty) return [];

      String tableName = 'nambers_thabeet';
      if (!tables.any((t) => t['name'] == 'nambers_thabeet')) {
        tableName = tables.first['name'] as String;
      }

      var columns = await db.rawQuery("PRAGMA table_info($tableName)");
      String phoneCol = columns.any((c) => c['name'] == 'phone')
          ? 'phone'
          : (columns.any((c) => c['name'] == 'number') ? 'number' : (columns.isNotEmpty ? columns.first['name'] as String : 'phone'));
      String nameCol = columns.any((c) => c['name'] == 'names')
          ? 'names'
          : (columns.any((c) => c['name'] == 'name') ? 'name' : (columns.length > 1 ? columns[1]['name'] as String : 'names'));

      final variants = getPhoneVariants(number);
      if (variants.isEmpty) return [];

      final placeholders = List.filled(variants.length, '?').join(',');

      final results = await db.query(
        tableName,
        columns: [nameCol, phoneCol],
        where: '$phoneCol IN ($placeholders)',
        whereArgs: variants,
        limit: 100,
      );

      return results.map((row) => {
        'names': row[nameCol]?.toString().trim() ?? 'بدون اسم',
        'phone': row[phoneCol]?.toString().trim() ?? 'بدون رقم',
      }).toList();
    } catch (e) {
      debugPrint("خطأ أثناء البحث بالرقم: $e");
      return [];
    }
  }

  // ⚡ استعلام الاسم الصاروخي الفوري المباشر
  Future<List<Map<String, dynamic>>> searchByName(String name, {String? companyPrefix}) async {
    try {
      final db = await database;

      var tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name != 'android_metadata' AND name NOT LIKE 'sqlite_%'");
      if (tables.isEmpty) return [];

      String tableName = 'nambers_thabeet';
      if (!tables.any((t) => t['name'] == 'nambers_thabeet')) {
        tableName = tables.first['name'] as String;
      }

      var columns = await db.rawQuery("PRAGMA table_info($tableName)");
      String nameCol = columns.any((c) => c['name'] == 'names')
          ? 'names'
          : (columns.any((c) => c['name'] == 'name') ? 'name' : (columns.length > 1 ? columns[1]['name'] as String : 'names'));
      String phoneCol = columns.any((c) => c['name'] == 'phone')
          ? 'phone'
          : (columns.any((c) => c['name'] == 'number') ? 'number' : (columns.isNotEmpty ? columns.first['name'] as String : 'phone'));

      String whereClause = '$nameCol LIKE ?';
      List<dynamic> whereArgs = ['$name%']; // بادئة الاسم لقفز الذاكرة العشوائية فوراً

      if (companyPrefix != null && companyPrefix.isNotEmpty) {
        whereClause += ' AND $phoneCol LIKE ?';
        whereArgs.add('$companyPrefix%');
      }

      final results = await db.query(
        tableName,
        where: whereClause,
        whereArgs: whereArgs,
        limit: 100,
      );

      return results.map((row) => {
        'names': row[nameCol]?.toString().trim() ?? 'بدون اسم',
        'phone': row[phoneCol]?.toString().trim() ?? 'بدون رقم',
      }).toList();
    } catch (e) {
      debugPrint("خطأ أثناء البحث بالاسم: $e");
      return [];
    }
  }

  /// فحص فائق السرعة لنتائج البحث وتحديد ما إذا كان لكل رقم أسماء مرتبطة متعددة في قاعدة البيانات بدقة تامة
  Future<List<Map<String, dynamic>>> enrichResultsWithMultipleNames(
    List<Map<String, dynamic>> rawResults,
  ) async {
    if (rawResults.isEmpty) return [];

    try {
      final db = await database;
      var tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name != 'android_metadata' AND name NOT LIKE 'sqlite_%'");
      if (tables.isEmpty) return rawResults;

      String tableName = 'nambers_thabeet';
      if (!tables.any((t) => t['name'] == 'nambers_thabeet')) {
        tableName = tables.first['name'] as String;
      }

      var columns = await db.rawQuery("PRAGMA table_info($tableName)");
      String phoneCol = columns.any((c) => c['name'] == 'phone')
          ? 'phone'
          : (columns.any((c) => c['name'] == 'number')
              ? 'number'
              : (columns.isNotEmpty
                  ? columns.first['name'] as String
                  : 'phone'));
      String nameCol = columns.any((c) => c['name'] == 'names')
          ? 'names'
          : (columns.any((c) => c['name'] == 'name')
              ? 'name'
              : (columns.length > 1
                  ? columns[1]['name'] as String
                  : 'names'));

      // تجميع كل الصيغ المحتملة لكل الأرقام في النتائج
      final Map<String, Set<String>> phoneToVariants = {};
      final Set<String> allVariantsSet = {};

      for (var row in rawResults) {
        String phone = (row[phoneCol] ?? row['phone'] ?? '').toString().trim();
        if (phone.isNotEmpty && !phoneToVariants.containsKey(phone)) {
          final variants = getPhoneVariants(phone);
          phoneToVariants[phone] = variants.toSet();
          allVariantsSet.addAll(variants);
        }
      }

      if (allVariantsSet.isEmpty) return rawResults;

      final allVariantsList = allVariantsSet.toList();
      final placeholders = List.filled(allVariantsList.length, '?').join(',');
      final queryResults = await db.query(
        tableName,
        columns: [phoneCol, nameCol],
        where: '$phoneCol IN ($placeholders)',
        whereArgs: allVariantsList,
      );

      final Map<String, List<String>> dbPhoneToNames = {};
      for (var r in queryResults) {
        String p = r[phoneCol]?.toString().trim() ?? '';
        String n = r[nameCol]?.toString().trim() ?? '';
        if (p.isNotEmpty && n.isNotEmpty) {
          dbPhoneToNames.putIfAbsent(p, () => []).add(n);
        }
      }

      return rawResults.map((row) {
        String phone = (row[phoneCol] ?? row['phone'] ?? '').toString().trim();
        String initialNames =
            (row[nameCol] ?? row['names'] ?? '').toString().trim();

        final Set<String> distinctNames = {};

        if (initialNames.isNotEmpty) {
          distinctNames.addAll(
            initialNames
                .split(RegExp(r'[,،|\n]'))
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty),
          );
        }

        final variants = phoneToVariants[phone] ?? {};
        for (var v in variants) {
          final matchedNames = dbPhoneToNames[v];
          if (matchedNames != null) {
            for (var nameStr in matchedNames) {
              distinctNames.addAll(
                nameStr
                    .split(RegExp(r'[,،|\n]'))
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty),
              );
            }
          }
        }

        final bool hasMultiple = distinctNames.length > 1;

        return {
          ...row,
          'hasMultipleNames': hasMultiple,
          'namesCount': distinctNames.length,
          'allAssociatedNames': distinctNames.toList(),
        };
      }).toList();
    } catch (e) {
      debugPrint("خطأ أثناء إثراء نتائج البحث: $e");
      return rawResults;
    }
  }
}
