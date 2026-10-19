import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import '../../core/constants/app_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/settings_card.dart';
import '../../core/widgets/settings_tile.dart';
import '../../database/database_helper.dart';

class DatabaseView extends StatefulWidget {
  const DatabaseView({super.key});

  @override
  State<DatabaseView> createState() => _DatabaseViewState();
}

class _DatabaseViewState extends State<DatabaseView> {
  int _totalRecords = 0;
  String _fileSize = '0 MB';
  String _dbPath = '';
  bool _dbExists = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDatabaseInfo();
  }

  Future<void> _loadDatabaseInfo() async {
    setState(() => _isLoading = true);

    try {
      final dbDir = await DatabaseHelper.instance.getDatabasesDirectoryPath();
      final filePath = p.join(dbDir, 'contactsdb.db');
      final file = File(filePath);

      int count = 0;
      String sizeStr = '0 MB';
      bool exists = await file.exists();

      if (exists) {
        final length = await file.length();
        if (length > 1024 * 1024 * 1024) {
          sizeStr = '${(length / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
        } else {
          sizeStr = '${(length / (1024 * 1024)).toStringAsFixed(1)} MB';
        }
        count = await DatabaseHelper.instance.getTotalRecordsCount();
      }

      if (mounted) {
        setState(() {
          _totalRecords = count;
          _fileSize = sizeStr;
          _dbPath = filePath;
          _dbExists = exists;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  Future<void> _deleteDatabase() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'حذف قاعدة البيانات',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error),
          ),
          content: const Text(
            'هل أنت متأكد من رغبتك في حذف قاعدة البيانات؟ سيتم مسح جميع جهات الاتصال والأرقام المحلية من الجهاز.',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'حذف نهائي',
                style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await DatabaseHelper.instance.deleteDbFile();
      await _loadDatabaseInfo();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف قاعدة البيانات بنجاح', textAlign: TextAlign.center),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  Future<void> _scanAndImportDatabase() async {
    if (!await Permission.manageExternalStorage.isGranted) {
      await Permission.manageExternalStorage.request();
    }
    if (!await Permission.storage.isGranted) {
      await Permission.storage.request();
    }

    List<File> foundFiles = [];

    void safeScan(Directory dir) {
      try {
        var entities = dir.listSync(recursive: false);
        for (var entity in entities) {
          if (entity is File) {
            if (entity.path.toLowerCase().endsWith('.db') ||
                entity.path.toLowerCase().contains('contactsdb')) {
              foundFiles.add(entity);
            }
          }
        }
      } catch (_) {}
    }

    safeScan(Directory('/storage/emulated/0/Download'));
    safeScan(Directory('/storage/emulated/0/الكاشف'));

    if (!mounted) return;

    if (foundFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'لم يتم العثور على ملفات قاعدة بيانات (.db) في مجلد Download',
            textAlign: TextAlign.center,
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'اختر ملف قاعدة البيانات',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 250,
            child: ListView.builder(
              itemCount: foundFiles.length,
              itemBuilder: (context, index) {
                final file = foundFiles[index];
                final length = file.lengthSync();
                final sizeStr = length > 1024 * 1024 * 1024
                    ? '${(length / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB'
                    : '${(length / (1024 * 1024)).toStringAsFixed(1)} MB';

                return ListTile(
                  leading: const Icon(AppIcons.database, color: AppColors.primary),
                  title: Text(
                    file.path.split('/').last,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text('الحجم: $sizeStr'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('يمكنك إتمام الاستيراد الكامل من الشاشة الرئيسية'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: AppBar(
          backgroundColor: AppColors.scaffoldBackground,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(AppIcons.back, color: AppColors.textPrimary, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'قاعدة البيانات',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          centerTitle: false,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  // 1. كارد معلومات وحالة قاعدة البيانات (مطابق لتصميم الكروت)
                  SettingsCard(
                    children: [
                      SettingsTile(
                        leading: const Icon(AppIcons.database, color: AppColors.textPrimary, size: 22),
                        title: 'حالة القاعدة',
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _dbExists ? 'نشطة وجاهزة' : 'غير متوفرة',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _dbExists ? AppColors.success : AppColors.error,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              _dbExists ? AppIcons.checked : AppIcons.cancel,
                              color: _dbExists ? AppColors.success : AppColors.disabled,
                              size: 18,
                            ),
                          ],
                        ),
                        showDivider: true,
                      ),
                      SettingsTile(
                        leading: const Icon(Icons.pin_outlined, color: AppColors.textPrimary, size: 22),
                        title: 'إجمالي الأرقام المسجلة',
                        trailing: Text(
                          '${_formatNumber(_totalRecords)} رقم',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        showDivider: true,
                      ),
                      SettingsTile(
                        leading: const Icon(Icons.storage_outlined, color: AppColors.textPrimary, size: 22),
                        title: 'حجم ملف القاعدة',
                        trailing: Text(
                          _fileSize,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        showDivider: true,
                      ),
                      SettingsTile(
                        leading: const Icon(Icons.folder_outlined, color: AppColors.textPrimary, size: 22),
                        title: 'مسار التخزين',
                        subtitle: _dbPath.isEmpty ? 'غير محدد' : _dbPath,
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // 2. كارد الإجراءات وإدارة القاعدة
                  SettingsCard(
                    children: [
                      SettingsTile(
                        leading: const Icon(AppIcons.importDb, color: AppColors.textPrimary, size: 22),
                        title: 'استيراد قاعدة بيانات',
                        subtitle: 'البحث عن ملفات (.db) واستيرادها',
                        trailing: const Icon(AppIcons.chevronRight, size: 20, color: AppColors.textSecondary),
                        showDivider: true,
                        onTap: _scanAndImportDatabase,
                      ),
                      SettingsTile(
                        leading: const Icon(AppIcons.refresh, color: AppColors.textPrimary, size: 22),
                        title: 'تحديث وقراءة العداد',
                        subtitle: 'إعادة فحص وتحديث عدد السجلات',
                        showDivider: true,
                        onTap: () async {
                          await _loadDatabaseInfo();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم تحديث بيانات القاعدة بنجاح', textAlign: TextAlign.center),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                      ),
                      SettingsTile(
                        leading: const Icon(AppIcons.deleteDb, color: AppColors.error, size: 22),
                        title: 'حذف قاعدة البيانات',
                        textColor: AppColors.error,
                        subtitle: 'مسح جميع السجلات المحلية من الجهاز',
                        onTap: _deleteDatabase,
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
