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

  Future<Database> _initDatabase() async {
    String databasesPath = await getDatabasesPath();
    String path = join(databasesPath, _databaseName);

    // 1. التحقق مما إذا كانت قاعدة البيانات موجودة بالفعل في المجلد الخاص بالتطبيق
    bool exists = await databaseExists(path);

    if (!exists) {
      // 2. إذا كان تثبيت جديد وقاعدة البيانات غير موجودة، نقوم باستيرادها
      debugPrint("تثبيت جديد: قاعدة البيانات الداخلية غير موجودة. جاري البحث عنها في الذاكرة الخارجية...");

      // المسار المتوقع للملف الخارجي (مثلاً وضع الملف في مجلد الداونلود للهاتف)
      String externalPath = "/storage/emulated/0/Download/contactsdb.db";
      File externalFile = File(externalPath);

      if (await externalFile.exists()) {
        try {
          // إنشاء المجلد الداخلي للتطبيق في حال لم يكن موجوداً بعد
          await Directory(databasesPath).create(recursive: true);

          debugPrint("تم العثور على الملف الخارجي، جاري النسخ والاستيراد... قد يستغرق هذا دقيقة بناءً على الحجم.");

          // نسخ ملف قاعدة البيانات بالكامل إلى المسار الداخلي للتطبيق
          await externalFile.copy(path);

          debugPrint("مبروك! تم استيراد قاعدة البيانات بنجاح إلى النظام الداخلي.");
        } catch (e) {
          debugPrint("خطأ حرج أثناء نسخ قاعدة البيانات: $e");
        }
      } else {
        debugPrint("تنبيه حرج: لم يتم العثور على ملف contactsdb.db في مجلد Download الخارجي!");
        // هنا يمكنك ترك التطبيق ينشئ قاعدة بيانات فارغة كاحتياط عبر الـ onCreate التقليدي
      }
    } else {
      debugPrint("قاعدة البيانات موجودة مسبقاً وجاهزة للاستخدام مباشرة.");
    }

    // 3. فتح قاعدة البيانات المستوردة والمستقرة الآن
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE IF NOT EXISTS nambers_thabeet (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            phone TEXT,
            names TEXT,
            company TEXT
          )
          ''');
  }

  Future<String> getMainTableName() async {
    if (_mainTableName != null) return _mainTableName!;
    final db = await instance.database;
    try {
      final result = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'");
      if (result.isNotEmpty) {
        for (var row in result) {
          String tName = row['name'].toString().toLowerCase();
          if (tName.contains('contact') || tName.contains('number') || tName.contains('thabeet')) {
            _mainTableName = row['name'] as String;
            return _mainTableName!;
          }
        }
        _mainTableName = result.first['name'] as String;
        return _mainTableName!;
      }
    } catch (_) {}
    return 'nambers_thabeet';
  }

  // دالة البحث بالرقم - تجلب السطر كما هو ليتم تفكيكه في الواجهة
  Future<List<Map<String, dynamic>>> searchByNumber(String number) async {
    try {
      final db = await instance.database;
      String tableName = await getMainTableName();

      final results = await db.rawQuery('''
        SELECT phone, names 
        FROM $tableName 
        WHERE phone = ?
        LIMIT 1
      ''', [number]);

      return results;
    } catch (e) {
      debugPrint("Search Error: $e");
      return [];
    }
  }

  // دالة البحث بالاسم - تجلب السجلات المتطابقة مباشرة
  Future<List<Map<String, dynamic>>> searchByName(String name, {String? companyPrefix}) async {
    try {
      final db = await instance.database;
      String tableName = await getMainTableName();

      String whereClause = "names LIKE ?";
      List<dynamic> whereArgs = ["%$name%"];

      if (companyPrefix != null && companyPrefix.isNotEmpty) {
        whereClause += " AND phone LIKE ?";
        whereArgs.add("$companyPrefix%");
      }

      final results = await db.rawQuery('''
        SELECT phone, names 
        FROM $tableName 
        WHERE $whereClause 
        LIMIT 50
      ''', whereArgs);

      return results;
    } catch (e) {
      debugPrint("Search Name Error: $e");
      return [];
    }
  }

  Future<int> getTotalRecordsCount() async {
    try {
      final db = await instance.database;
      String tableName = await getMainTableName();
      final result = await db.rawQuery('SELECT MAX(rowid) FROM $tableName');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (_) {
      return 0;
    }
  }
}