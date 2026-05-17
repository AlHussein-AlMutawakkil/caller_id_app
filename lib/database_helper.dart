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
  String? _mainTableName; // لتخزين اسم الجدول الديناميكي

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

  // 1. الدالة السحرية لإغلاق الاتصال تماماً قبل استيراد الملف الجديد
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

  // 2. دالة ذكية لاكتشاف اسم الجدول الحقيقي داخل ملف الـ 7 جيجا لتجنب الخطأ صفر
  Future<String> getMainTableName() async {
    if (_mainTableName != null) return _mainTableName!;
    final db = await instance.database;
    try {
      final result = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name != 'android_metadata'");
      if (result.isNotEmpty) {
        _mainTableName = result.first['name'] as String;
        debugPrint("تم اكتشاف اسم الجدول الحقيقي: $_mainTableName");
        return _mainTableName!;
      }
    } catch(e) {
      debugPrint("خطأ في قراءة اسم الجدول: $e");
    }
    return 'nambers_thabeet'; // الافتراضي
  }

  // جلب العداد الكلي الفعلي باستخدام اسم الجدول الديناميكي
  Future<int> getTotalRecordsCount() async {
    try {
      final db = await instance.database;
      String tableName = await getMainTableName();
      final result = await db.rawQuery('SELECT COUNT(*) FROM $tableName');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      debugPrint("خطأ أثناء قراءة عداد السجلات: $e");
      return 0;
    }
  }

  // البحث عن طريق الرقم مع دعم الأسماء المتغيرة للأعمدة
  Future<List<Map<String, dynamic>>> searchByNumber(String number) async {
    try {
      final db = await instance.database;
      String tableName = await getMainTableName();

      // فحص اسم عمود الرقم واسم المشترك الحقيقي في القاعدة المستوردة
      var columns = await db.rawQuery("PRAGMA table_info($tableName)");
      String phoneCol = columns.any((c) => c['name'] == 'phone') ? 'phone' : 'number';
      String nameCol = columns.any((c) => c['name'] == 'names') ? 'names' : 'name';

      final results = await db.query(
        tableName,
        where: '$phoneCol LIKE ?',
        whereArgs: ['%$number%'],
        limit: 100,
      );

      // توحيد المخرجات للواجهة لتجنب الأخطاء
      return results.map((row) => {
        'names': row[nameCol]?.toString() ?? 'بدون اسم',
        'phone': row[phoneCol]?.toString() ?? 'بدون رقم',
      }).toList();

    } catch (e) {
      debugPrint("خطأ في البحث بالرقم: $e");
      return [];
    }
  }

  // البحث عن طريق الاسم مع الفلترة
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
      debugPrint("خطأ في البحث بالاسم: $e");
      return [];
    }
  }
}