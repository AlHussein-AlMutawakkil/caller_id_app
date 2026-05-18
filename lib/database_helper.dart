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
      onUpgrade: (db, oldVersion, newVersion) async {},
      onDowngrade: (db, oldVersion, newVersion) async {},
    );
  }

  Future<void> closeDb() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      _mainTableName = null;
    }
  }

  Future<void> deleteDbFile() async {
    await closeDb();
    String path = join(await getDatabasesPath(), _databaseName);
    await databaseFactory.deleteDatabase(path);

    final fileWal = File('$path-wal');
    final fileShm = File('$path-shm');
    if (await fileWal.exists()) await fileWal.delete();
    if (await fileShm.exists()) await fileShm.delete();
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
      final result = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name != 'android_metadata'");
      if (result.isNotEmpty) {
        for (var row in result) {
          String tName = row['name'].toString().toLowerCase();
          if (tName.contains('contact') || tName.contains('number') || tName.contains('data') || tName.contains('thabeet')) {
            _mainTableName = row['name'] as String;
            return _mainTableName!;
          }
        }
        _mainTableName = result.first['name'] as String;
        return _mainTableName!;
      }
    } catch (e) {
      debugPrint("Error detecting table: $e");
    }
    return 'nambers_thabeet';
  }

  Future<int> getTotalRecordsCount() async {
    try {
      final db = await instance.database;
      String tableName = await getMainTableName();
      try {
        final result = await db.rawQuery('SELECT MAX(rowid) FROM $tableName');
        int? count = Sqflite.firstIntValue(result);
        if (count != null && count > 0) return count;
      } catch (_) {}
      try {
        final result2 = await db.rawQuery('SELECT MAX(id) FROM $tableName');
        return Sqflite.firstIntValue(result2) ?? 0;
      } catch (_) {}
      return 0;
    } catch (e) {
      return 0;
    }
  }

  Future<Map<String, String>> _getColumnNames(Database db, String tableName) async {
    var columns = await db.rawQuery("PRAGMA table_info($tableName)");
    String phoneCol = 'phone';
    String nameCol = 'names';

    for (var c in columns) {
      String colName = c['name'].toString().toLowerCase();
      if (colName == 'phone' || colName == 'number' || colName == 'num') {
        phoneCol = c['name'].toString();
      }
      if (colName == 'name' || colName == 'names' || colName == 'fullname') {
        nameCol = c['name'].toString();
      }
    }
    return {'phone': phoneCol, 'name': nameCol};
  }

  Future<List<Map<String, dynamic>>> searchByNumber(String number) async {
    try {
      final db = await instance.database;
      String tableName = await getMainTableName();
      var cols = await _getColumnNames(db, tableName);

      final results = await db.query(
        tableName,
        where: '${cols['phone']} = ?',
        whereArgs: [number],
        limit: 15,
      );

      return results.map((row) => {
        'names': row[cols['name']]?.toString() ?? 'بدون اسم',
        'phone': row[cols['phone']]?.toString() ?? 'بدون رقم',
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> searchByName(String name, {String? companyPrefix}) async {
    try {
      final db = await instance.database;
      String tableName = await getMainTableName();
      var cols = await _getColumnNames(db, tableName);

      String whereClause = '${cols['name']} LIKE ?';
      List<dynamic> whereArgs = ['$name%'];

      if (companyPrefix != null && companyPrefix.isNotEmpty) {
        whereClause += ' AND ${cols['phone']} LIKE ?';
        whereArgs.add('$companyPrefix%');
      }

      final results = await db.query(
        tableName,
        where: whereClause,
        whereArgs: whereArgs,
        limit: 50,
      );

      return results.map((row) => {
        'names': row[cols['name']]?.toString() ?? 'بدون اسم',
        'phone': row[cols['phone']]?.toString() ?? 'بدون رقم',
      }).toList();
    } catch (e) {
      return [];
    }
  }
}
