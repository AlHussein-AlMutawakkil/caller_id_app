import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static const _databaseName = "contactsdb.db";
  static const _databaseVersion = 1;

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  String? _mainTableName; // متغير ذكي لتخزين اسم الجدول الحقيقي

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
    );
  }

  // 1. الدالة السحرية لكسر حماية القاعدة القديمة وإغلاقها قبل النقل
  Future<void> closeDb() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      _mainTableName = null;
    }
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

  // 2. الدالة الخارقة للبحث عن الجدول المليوني الحقيقي وتجاهل الجداول الفارغة
  Future<String> getMainTableName() async {
    if (_mainTableName != null) return _mainTableName!;
    final db = await instance.database;
    try {
      final result = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name != 'android_metadata'");

      for (var row in result) {
        String tName = row['name'] as String;
        // فحص عدد السجلات في كل جدول لاكتشاف الكنز الحقيقي!
        var countResult = await db.rawQuery('SELECT COUNT(*) FROM $tName');
        int count = Sqflite.firstIntValue(countResult) ?? 0;
        if (count > 1000) {
          _mainTableName = tName;
          debugPrint("تم العثور على الجدول الحقيقي: $tName بعدد $count سجل");
          return tName;
        }
      }
      if (result.isNotEmpty) {
        _mainTableName = result.first['name'] as String;
        return _mainTableName!;
      }
    } catch(e) {
      debugPrint("خطأ في قراءة اسم الجدول: $e");
    }
    return 'nambers_thabeet';
  }

  // جلب العداد الكلي بناءً على الجدول الحقيقي
  Future<int> getTotalRecordsCount() async {
    try {
      final db = await instance.database;
      String tableName = await getMainTableName();
      final result = await db.rawQuery('SELECT COUNT(*) FROM $tableName');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // البحث الذكي مهما كانت أسماء الأعمدة في القاعدة المسربة
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
        limit: 100,
      );

      return results.map((row) => {
        'names': row[nameCol]?.toString() ?? 'بدون اسم',
        'phone': row[phoneCol]?.toString() ?? 'بدون رقم',
      }).toList();

    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> searchByName(String name, String company) async {
    try {
      final db = await instance.database;
      String tableName = await getMainTableName();

      var columns = await db.rawQuery("PRAGMA table_info($tableName)");
      String nameCol = columns.any((c) => c['name'] == 'names') ? 'names' : 'name';
      String phoneCol = columns.any((c) => c['name'] == 'phone') ? 'phone' : 'number';
      bool hasCompanyCol = columns.any((c) => c['name'] == 'company');

      List<Map<String, Object?>> results;

      if (company == 'إختر شركة الإتصالات' || !hasCompanyCol) {
        results = await db.query(
          tableName,
          where: '$nameCol LIKE ?',
          whereArgs: ['%$name%'],
          limit: 100,
        );
      } else {
        results = await db.query(
          tableName,
          where: '$nameCol LIKE ? AND company = ?',
          whereArgs: ['%$name%', company],
          limit: 100,
        );
      }

      return results.map((row) => {
        'names': row[nameCol]?.toString() ?? 'بدون اسم',
        'phone': row[phoneCol]?.toString() ?? 'بدون رقم',
      }).toList();

    } catch(e) {
      return [];
    }
  }
}