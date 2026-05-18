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
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      // تجاهل أخطاء اختلاف الإصدارات في القواعد المسربة
      onUpgrade: (db, oldVersion, newVersion) async {},
      onDowngrade: (db, oldVersion, newVersion) async {},
      // تم حذف onOpen بالكامل لتجنب مشاكل هواتف سامسونج
    );
  }

  Future<void> closeDb() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      _mainTableName = null;
    }
  }

  // تدمير القاعدة القديمة من القرص والذاكرة العشوائية لتجنب أخطاء النقل
  Future<void> deleteDbFile() async {
    await closeDb();
    String path = join(await getDatabasesPath(), _databaseName);
    await databaseFactory.deleteDatabase(path);

    // حذف ملفات WAL و SHM يدوياً لضمان عدم التلف
    final fileWal = File('$path-wal');
    final fileShm = File('$path-shm');
    if (await fileWal.exists()) await fileWal.delete();
    if (await fileShm.exists()) await fileShm.delete();
  }

  Future _onCreate(Database db, int version) async {
    // إضافة IF NOT EXISTS لمنع التصادم مع الجداول الموجودة مسبقاً في القاعدة المسربة
    await db.execute('''
          CREATE TABLE IF NOT EXISTS nambers_thabeet (
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

  // ذكاء اصطناعي لاكتشاف اسم الجدول الحقيقي الذي يحتوي على البيانات المسربة
  Future<String> getMainTableName() async {
    if (_mainTableName != null) return _mainTableName!;
    final db = await instance.database;
    try {
      final result = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name != 'android_metadata'");
      if (result.isNotEmpty) {
        // محاولة إيجاد جدول يحتوي على كلمات تدل على الأرقام
        for (var row in result) {
          String tName = row['name'].toString().toLowerCase();
          if (tName.contains('contact') || tName.contains('number') || tName.contains('data') || tName.contains('thabeet')) {
            _mainTableName = row['name'] as String;
            return _mainTableName!;
          }
        }
        // إذا لم يجد اسماً مألوفاً، يختار أول جدول في القاعدة
        _mainTableName = result.first['name'] as String;
        return _mainTableName!;
      }
    } catch (e) {
      debugPrint("خطأ في اكتشاف الجدول: $e");
    }
    return 'nambers_thabeet';
  }

  // جلب عدد السجلات السريع
  Future<int> getTotalRecordsCount() async {
    try {
      final db = await instance.database;
      String tableName = await getMainTableName();

      // المحاولة الأولى: العد السريع جداً باستخدام MAX(rowid)
      try {
        final result = await db.rawQuery('SELECT MAX(rowid) FROM $tableName');
        int? count = Sqflite.firstIntValue(result);
        if (count != null && count > 0) return count;
      } catch (_) {}

      // المحاولة الثانية: العد السريع باستخدام MAX(id)
      try {
        final result2 = await db.rawQuery('SELECT MAX(id) FROM $tableName');
        return Sqflite.firstIntValue(result2) ?? 0;
      } catch (_) {}

      return 0;
    } catch (e) {
      return 0;
    }
  }

  // دالة مساعدة لاكتشاف أسماء الأعمدة الصحيحة (تتجاهل حالة الأحرف)
  Future<Map<String, String>> _getColumnNames(Database db, String tableName) async {
    var columns = await db.rawQuery("PRAGMA table_info($tableName)");
    String phoneCol = 'phone';
    String nameCol = 'names';

    for (var c in columns) {
      String colName = c['name'].toString().toLowerCase();
      if (colName == 'phone' || colName == 'number' || colName == 'num') {
        phoneCol = c['name'].toString(); // نأخذ الاسم الأصلي من القاعدة
      }
      if (colName == 'name' || colName == 'names' || colName == 'fullname') {
        nameCol = c['name'].toString();
      }
    }
    return {'phone': phoneCol, 'name': nameCol};
  }

  // البحث بالرقم (باستخدام الحيلة الثالثة: التطابق الدقيق للسرعة القصوى)
  Future<List<Map<String, dynamic>>> searchByNumber(String number) async {
    try {
      final db = await instance.database;
      String tableName = await getMainTableName();
      var cols = await _getColumnNames(db, tableName);

      final results = await db.query(
        tableName,
        where: '${cols['phone']} = ?', // استخدام = بدلاً من LIKE
        whereArgs: [number],
        limit: 15, // الإيقاف المبكر
      );

      return results.map((row) => {
        'names': row[cols['name']]?.toString() ?? 'بدون اسم',
        'phone': row[cols['phone']]?.toString() ?? 'بدون رقم',
      }).toList();
    } catch (e) {
      debugPrint("خطأ في البحث بالرقم: $e");
      return [];
    }
  }

  // البحث بالاسم (باستخدام الحيلة الثالثة: البحث من بداية الكلمة فقط)
  Future<List<Map<String, dynamic>>> searchByName(String name, String company) async {
    try {
      final db = await instance.database;
      String tableName = await getMainTableName();
      var cols = await _getColumnNames(db, tableName);

      final results = await db.query(
        tableName,
        where: '${cols['name']} LIKE ?',
        whereArgs: ['$name%'], // إزالة % من البداية
        limit: 15, // الإيقاف المبكر
      );

      return results.map((row) => {
        'names': row[cols['name']]?.toString() ?? 'بدون اسم',
        'phone': row[cols['phone']]?.toString() ?? 'بدون رقم',
      }).toList();
    } catch (e) {
      debugPrint("خطأ في البحث بالاسم: $e");
      return [];
    }
  }
}
