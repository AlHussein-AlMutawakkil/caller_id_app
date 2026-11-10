import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import '../../core/constants/app_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/settings_card.dart';
import '../../core/widgets/settings_tile.dart';
import '../../core/widgets/app_modal_dialog.dart';
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
        sizeStr = _formatFileSize(length);
        count = await DatabaseHelper.instance.getTotalRecordsCount(forceRefresh: true);
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

  String _formatFileSize(int length) {
    if (length > 1024 * 1024 * 1024) {
      return '${(length / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    } else {
      return '${(length / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  Future<void> _deleteDatabase() async {
    final confirmed = await AppModalDialog.show<bool>(
      context: context,
      title: 'حذف قاعدة البيانات',
      actionButtonText: 'حذف نهائي',
      actionButtonColor: AppColors.error,
      onActionButtonPressed: () {
        Navigator.of(context).pop(true);
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Text(
          'هل أنت متأكد من رغبتك في حذف قاعدة البيانات؟ سيتم مسح جميع جهات الاتصال والأرقام المحلية من الجهاز.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            height: 1.5,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );

    if (confirmed == true) {
      await DatabaseHelper.instance.deleteDbFile();
      await _loadDatabaseInfo();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حذف قاعدة البيانات بنجاح', textAlign: TextAlign.center),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  /// فحص مجلد التنزيلات وعرض ملفات قاعدة البيانات المتوفرة مباشرة بدون أي كاش
  Future<void> _scanAndImportDatabaseFromDownloads() async {
    if (!await Permission.manageExternalStorage.isGranted) {
      await Permission.manageExternalStorage.request();
    }
    if (!await Permission.storage.isGranted) {
      await Permission.storage.request();
    }

    List<File> foundFiles = [];
    final scanDirs = [
      Directory('/storage/emulated/0/Download'),
      Directory('/storage/emulated/0/Downloads'),
      Directory('/storage/emulated/0/الكاشف'),
    ];

    for (var dir in scanDirs) {
      try {
        if (dir.existsSync()) {
          var entities = dir.listSync(recursive: false);
          for (var entity in entities) {
            if (entity is File) {
              final path = entity.path.toLowerCase();
              if (path.endsWith('.db') ||
                  path.endsWith('.sqlite') ||
                  path.endsWith('.sqlite3') ||
                  path.contains('contactsdb')) {
                if (!foundFiles.any((f) => f.path == entity.path)) {
                  foundFiles.add(entity);
                }
              }
            }
          }
        }
      } catch (_) {}
    }

    if (!mounted) return;

    if (foundFiles.isEmpty) {
      _showSnackBar(
        'لم يتم العثور على أي ملفات قاعدة بيانات (.db) في مجلد التنزيلات (Download)',
        isError: true,
      );
      return;
    }

    AppModalDialog.show(
      context: context,
      title: 'اختر قاعدة بيانات من التنزيلات',
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: foundFiles.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.divider),
        itemBuilder: (context, index) {
          final file = foundFiles[index];
          final length = file.lengthSync();
          final sizeStr = _formatFileSize(length);

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.scaffoldBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(AppIcons.database, color: AppColors.primary, size: 22),
            ),
            title: Text(
              p.basename(file.path),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text('الحجم: $sizeStr', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            trailing: Icon(AppIcons.chevronRight, size: 18, color: AppColors.textSecondary),
            onTap: () {
              Navigator.of(context).pop();
              _confirmAndImport(file);
            },
          );
        },
      ),
    );
  }

  /// نافذة التأكيد قبل البدء في عملية الاستيراد والاستبدال
  Future<void> _confirmAndImport(File file) async {
    // 1. التحقق من سلامة وصلاحية ملف الـ SQLite
    final isValid = await DatabaseHelper.instance.isValidSqliteFile(file.path);
    if (!isValid) {
      _showSnackBar('الملف المختار ليس ملف قاعدة بيانات SQLite صالح (.db)', isError: true);
      return;
    }

    final length = await file.length();
    final sizeStr = _formatFileSize(length);
    final fileName = p.basename(file.path);

    if (!mounted) return;

    final confirmed = await AppModalDialog.show<bool>(
      context: context,
      title: 'تأكيد استيراد قاعدة البيانات',
      actionButtonText: 'بدء الاستيراد',
      actionButtonColor: AppColors.primary,
      onActionButtonPressed: () {
        Navigator.of(context).pop(true);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.scaffoldBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(AppIcons.database, color: AppColors.primary, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          fileName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.storage_outlined, color: AppColors.textSecondary, size: 18),
                      const SizedBox(width: 8),
                      Text('الحجم: $sizeStr', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.folder_outlined, color: AppColors.textSecondary, size: 18),
                      SizedBox(width: 8),
                      Text('المصدر: مجلد التنزيلات (مباشر بدون كاش)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'تنبيه: سيتم استبدال قاعدة البيانات الحالية بهذه القاعدة ونقلها مباشرة دون استهلاك مساحة الكاش.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      _executeImportWithProgress(file);
    }
  }

  /// تنفيذ عملية الاستيراد مع عرض شريط تقدم حي والنسبة المئوية (0% - 100%)
  void _executeImportWithProgress(File file) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => _ImportProgressDialog(
        file: file,
        onFinished: () async {
          Navigator.of(dialogCtx).pop();
          await _loadDatabaseInfo();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'تم استيراد قاعدة البيانات بنجاح! الإجمالي: \u200E${_formatNumber(_totalRecords)}\u200E رقم',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                backgroundColor: AppColors.success,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        },
        onError: (errorMsg) {
          Navigator.of(dialogCtx).pop();
          _showSnackBar('فشل الاستيراد: $errorMsg', isError: true);
        },
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
        duration: Duration(seconds: isError ? 4 : 2),
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
            icon: Icon(AppIcons.back, color: AppColors.textPrimary, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
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
                  // 1. كارد معلومات وحالة قاعدة البيانات
                  SettingsCard(
                    children: [
                      SettingsTile(
                        leading: Icon(AppIcons.database, color: AppColors.textPrimary, size: 22),
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
                        leading: Icon(Icons.pin_outlined, color: AppColors.textPrimary, size: 22),
                        title: 'إجمالي الأرقام المسجلة',
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatNumber(_totalRecords),
                              textDirection: TextDirection.ltr,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'رقم',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        showDivider: true,
                      ),
                      SettingsTile(
                        leading: Icon(Icons.storage_outlined, color: AppColors.textPrimary, size: 22),
                        title: 'حجم ملف القاعدة',
                        trailing: Text(
                          _fileSize,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        showDivider: true,
                      ),
                      SettingsTile(
                        leading: Icon(Icons.folder_outlined, color: AppColors.textPrimary, size: 22),
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
                        leading: Icon(AppIcons.importDb, color: AppColors.textPrimary, size: 22),
                        title: 'استيراد قاعدة بيانات',
                        subtitle: 'البحث عن ملفات (.db) في مجلد التنزيلات واستيرادها',
                        trailing: Icon(AppIcons.chevronRight, size: 20, color: AppColors.textSecondary),
                        showDivider: true,
                        onTap: _scanAndImportDatabaseFromDownloads,
                      ),
                      SettingsTile(
                        leading: Icon(AppIcons.refresh, color: AppColors.textPrimary, size: 22),
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

/// نافذة مخصصة لعرض التقدم المئوي للاستيراد لحظة بلحظة مع شريط تقدم تفاعلي
class _ImportProgressDialog extends StatefulWidget {
  final File file;
  final VoidCallback onFinished;
  final ValueChanged<String> onError;

  const _ImportProgressDialog({
    required this.file,
    required this.onFinished,
    required this.onError,
  });

  @override
  State<_ImportProgressDialog> createState() => _ImportProgressDialogState();
}

class _ImportProgressDialogState extends State<_ImportProgressDialog> {
  double _progress = 0.0;
  int _copiedBytes = 0;
  int _totalBytes = 0;

  @override
  void initState() {
    super.initState();
    _totalBytes = widget.file.lengthSync();
    _startImport();
  }

  Future<void> _startImport() async {
    try {
      await DatabaseHelper.instance.importDatabaseWithProgress(
        widget.file.path,
        onProgress: (progress, copied, total) {
          if (mounted) {
            setState(() {
              _progress = progress;
              _copiedBytes = copied;
              _totalBytes = total;
            });
          }
        },
      );
      if (mounted) {
        widget.onFinished();
      }
    } catch (e) {
      if (mounted) {
        widget.onError(e.toString());
      }
    }
  }

  String _formatFileSize(int length) {
    if (length > 1024 * 1024 * 1024) {
      return '${(length / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    } else {
      return '${(length / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  @override
  Widget build(BuildContext context) {
    final percent = (_progress * 100).toInt();

    return PopScope(
      canPop: false,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.cardBorder, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(AppColors.isDarkMode ? 0.3 : 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // أيقونة الحوار
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(AppIcons.database, color: AppColors.primary, size: 36),
                ),
                const SizedBox(height: 16),
                Text(
                  'جاري استيراد قاعدة البيانات',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'يتم النقل المباشر من التنزيلات دون استهلاك كاش',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // النسبة المئوية
                Text(
                  '$percent%',
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),

                // شريط التقدم الفعلي
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 12,
                    backgroundColor: AppColors.cardBorder,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 14),

                // حجم البيانات المنسوخة
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatFileSize(_copiedBytes),
                      textDirection: TextDirection.ltr,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    Text(
                      _formatFileSize(_totalBytes),
                      textDirection: TextDirection.ltr,
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // تنبيه
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.scaffoldBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_clock_rounded, size: 16, color: AppColors.textSecondary),
                      SizedBox(width: 6),
                      Text(
                        'يرجى عدم إغلاق التطبيق حتى تكتمل العملية',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}