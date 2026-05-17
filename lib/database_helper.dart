import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const _databaseName = "contactsdb.db";
  static const _databaseVersion = 1;

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  String? _mainTableName;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onOpen: (db) async {
          // تسريع القراءة الخارقة للملفات الضخمة
          await db.execute('PRAGMA journal_mode=WAL;');
        }
    );
  }

  // إغلاق القاعدة بأمان
  Future<void> closeDb() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      _mainTableName = null;
    }
  }

  // 🔥 الدالة الحاسمة: تدمير القاعدة القديمة من الذاكرة العشوائية تماماً قبل الاستيراد
  Future<void> deleteDbFile() async {
    await closeDb();
    String path = join(await getDatabasesPath(), _databaseName);
    await databaseFactory.deleteDatabase(path);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE nambers_thabeet (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            phone TEXT,
            names TEXT,
            company TEXT
          )
          ''');
  }

  Future<String> getDatabasesDirectoryPath() async {
    return await getDatabasesPath();
  }

  // اكتشاف اسم الجدول الحقيقي تلقائياً
  Future<String> getMainTableName() async {
    if (_mainTableName != null) return _mainTableName!;
    final db = await instance.database;
    try {
      final result = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name != 'android_metadata'");
      if (result.isNotEmpty) {
        _mainTableName = result.first['name'] as String;
        return _mainTableName!;
      }
    } catch(e) {
      debugPrint("خطأ في قراءة اسم الجدول: $e");
    }
    return 'nambers_thabeet';
  }

  // 🔥 جلب الملايين في جزء من الثانية باستخدام MAX(rowid)
  Future<int> getTotalRecordsCount() async {
    try {
      final db = await instance.database;
      String tableName = await getMainTableName();
      final result = await db.rawQuery('SELECT MAX(rowid) FROM $tableName');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // البحث عن طريق الرقم مع الفحص الذكي للأعمدة
  Future<List<Map<String, dynamic>>> searchByNumber(String number) async {
    try {
      final db = await instance.database;
      String tableName = await getMainTableName();

      var columns = await db.rawQuery("PRAGMA table_info($tableName)");
      String phoneCol = columns.any((c) => c['name'] == 'phone') ? 'phone' : 'number';
      String nameCol = columns.any((c) => c['name'] == 'names') ? 'names' : 'name';

      final results = await db.query(
        tableName,
        where: '$phoneCol LIKE ?',
        whereArgs: ['%$number%'],
        limit: 50,
      );

      return results.map((row) => {
        'names': row[nameCol]?.toString() ?? 'بدون اسم',
        'phone': row[phoneCol]?.toString() ?? 'بدون رقم',
      }).toList();

    } catch (e) {
      return [];
    }
  }

  // البحث عن طريق الاسم
  Future<List<Map<String, dynamic>>> searchByName(String name, String company) async {
    try {
      final db = await instance.database;
      String tableName = await getMainTableName();

      var columns = await db.rawQuery("PRAGMA table_info($tableName)");
      String nameCol = columns.any((c) => c['name'] == 'names') ? 'names' : 'name';
      String phoneCol = columns.any((c) => c['name'] == 'phone') ? 'phone' : 'number';

      final results = await db.query(
        tableName,
        where: '$nameCol LIKE ?',
        whereArgs: ['%$name%'],
        limit: 50,
      );

      return results.map((row) => {
        'names': row[nameCol]?.toString() ?? 'بدون اسم',
        'phone': row[phoneCol]?.toString() ?? 'بدون رقم',
      }).toList();

    } catch(e) {
      return [];
    }
  }
}