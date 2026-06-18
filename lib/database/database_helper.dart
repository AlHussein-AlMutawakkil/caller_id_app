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
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<void> deleteDbFile() async {
    await closeDb();
    String databasesPath = await getDatabasesPath();
    String path = join(databasesPath, _databaseName);
    await databaseFactory.deleteDatabase(path);
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
    } catch(e) {}
  }

  Future<String> getDatabasesDirectoryPath() async {
    return await getDatabasesPath();
  }

  // ⚡ قراءة عداد الـ 37 مليون سجل في لمح البصر دون تجميد
  Future<int> getTotalRecordsCount() async {
    try {
      final db = await database;
      // الاتجاه المباشر للجدول الأساسي المليوني نكاية في جداول النظام الفارغة
      final result = await db.rawQuery('SELECT MAX(rowid) FROM nambers_thabeet');
      int? count = Sqflite.firstIntValue(result);

      // إذا كان جدول الملف المستورد يحمل اسماً آخر احتياطياً
      if (count == null || count == 0) {
        final altResult = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name != 'android_metadata' AND name NOT LIKE 'sqlite_%'");
        if (altResult.isNotEmpty) {
          String altTable = altResult.first['name'] as String;
          final res = await db.rawQuery('SELECT MAX(rowid) FROM $altTable');
          return Sqflite.firstIntValue(res) ?? 0;
        }
      }
      return count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // ⚡ استعلام الرقم الصاروخي الفوري المباشر
  Future<List<Map<String, dynamic>>> searchByNumber(String number) async {
    try {
      final db = await database;

      // الكشف الديناميكي عن اسم العمود الداخلي (هل هو phone أم number) لمنع الانهيار
      var columns = await db.rawQuery("PRAGMA table_info(nambers_thabeet)");
      if (columns.isEmpty) {
        // محاولة جلب الجدول البديل إذا اختلف الاسم
        final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name != 'android_metadata' AND name NOT LIKE 'sqlite_%'");
        if (tables.isNotEmpty) {
          columns = await db.rawQuery("PRAGMA table_info(${tables.first['name']})");
        }
      }

      String phoneCol = columns.any((c) => c['name'] == 'phone') ? 'phone' : 'number';
      String nameCol = columns.any((c) => c['name'] == 'names') ? 'names' : 'name';
      String tableName = columns.isNotEmpty ? (columns.first['table']?.toString() ?? 'nambers_thabeet') : 'nambers_thabeet';
      if(_database != null && tableName == 'nambers_thabeet') {
        final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name != 'android_metadata' AND name NOT LIKE 'sqlite_%'");
        if(tables.isNotEmpty) tableName = tables.first['name'] as String;
      }

      final results = await db.query(
        tableName,
        where: '$phoneCol LIKE ?',
        whereArgs: ['$number%'], // الفهرسة المباشرة بالبادئة لمنع البطء والـ Lock
        limit: 100,
      );

      return results.map((row) => {
        'names': row[nameCol]?.toString().trim() ?? 'بدون اسم',
        'phone': row[phoneCol]?.toString().trim() ?? 'بدون رقم',
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // ⚡ استعلام الاسم الصاروخي الفوري المباشر
  Future<List<Map<String, dynamic>>> searchByName(String name, {String? companyPrefix}) async {
    try {
      final db = await database;

      var tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name != 'android_metadata' AND name NOT LIKE 'sqlite_%'");
      String tableName = tables.isNotEmpty ? tables.first['name'] as String : 'nambers_thabeet';

      var columns = await db.rawQuery("PRAGMA table_info($tableName)");
      String nameCol = columns.any((c) => c['name'] == 'names') ? 'names' : 'name';
      String phoneCol = columns.any((c) => c['name'] == 'phone') ? 'phone' : 'number';

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
      return [];
    }
  }
}