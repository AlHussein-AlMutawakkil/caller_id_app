import 'dart:io';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'database/database_helper.dart';
import 'core/theme/app_colors.dart';
import 'views/number_search_view.dart';
import 'views/name_search_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _totalRecords = 0;
  int _currentIndex = 1; // التبويب الافتراضي (البحث بالرقم)

  // متغيرات الاستيراد الذكي
  bool _isImporting = false;
  bool _isLoadingScan = false;
  double _importProgress = 0.0;
  String _progressText = "";

  @override
  void initState() {
    super.initState();
    _updateDatabaseCounter();
  }

  // تحديث عداد السجلات
  Future<void> _updateDatabaseCounter() async {
    int count = await DatabaseHelper.instance.getTotalRecordsCount();
    if (mounted) {
      setState(() {
        _totalRecords = count;
      });
    }
  }

  // مستكشف الملفات الآمن من أندرويد
  Future<void> _scanAndSelectDatabase() async {
    if (!await Permission.manageExternalStorage.isGranted) {
      await Permission.manageExternalStorage.request();
    }
    if (!await Permission.storage.isGranted) {
      await Permission.storage.request();
    }

    setState(() => _isLoadingScan = true);
    List<File> foundFiles = [];

    void safeScan(Directory dir) {
      try {
        var entities = dir.listSync(recursive: false);
        for (var entity in entities) {
          if (entity is File) {
            if (entity.lengthSync() > 50000000 &&
                (entity.path.toLowerCase().endsWith('.db') ||
                    entity.path.toLowerCase().contains('contactsdb'))) {
              foundFiles.add(entity);
            }
          } else if (entity is Directory) {
            String dirName = entity.path.split('/').last;
            if (!dirName.startsWith('.') && dirName != 'Android') {
              safeScan(entity);
            }
          }
        }
      } catch (e) {}
    }

    safeScan(Directory('/storage/emulated/0/Download'));
    safeScan(Directory('/storage/emulated/0/الكاشف'));

    setState(() => _isLoadingScan = false);

    if (foundFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("لم نجد ملف قاعدة البيانات (.db)! يرجى وضعه في مجلد Download.", textDirection: TextDirection.rtl),
        backgroundColor: Colors.red,
      ));
      return;
    }

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("اختر قاعدة البيانات للاستيراد", textDirection: TextDirection.rtl, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
        content: SizedBox(
          width: double.maxFinite, height: 300,
          child: ListView.builder(
            itemCount: foundFiles.length,
            itemBuilder: (context, index) {
              final file = foundFiles[index];
              final sizeGB = (file.lengthSync() / (1024 * 1024 * 1024)).toStringAsFixed(2);
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.storage, color: AppColors.primary, size: 30),
                  title: Text(file.path.split('/').last, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("الحجم: $sizeGB جيجا\nالمسار: ${file.path.replaceAll('/storage/emulated/0/', '')}", textDirection: TextDirection.ltr),
                  onTap: () {
                    Navigator.pop(context);
                    _startBackgroundIsolateImport(file);
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  Future<void> _startBackgroundIsolateImport(File sourceFile) async {
    try {
      await DatabaseHelper.instance.deleteDbFile();
      String dbDir = await DatabaseHelper.instance.getDatabasesDirectoryPath();
      String targetPath = '$dbDir/contactsdb.db';

      setState(() {
        _isImporting = true;
        _importProgress = 0.0;
        _progressText = "جاري تحضير المحرك الخلفي...";
      });

      final receivePort = ReceivePort();
      await Isolate.spawn(_copyFileIsolate, [sourceFile.path, targetPath, receivePort.sendPort]);

      await for (var message in receivePort) {
        if (message is Map) {
          if (message['status'] == 'progress') {
            setState(() {
              _importProgress = message['progress'];
              _progressText = message['text'];
            });
          } else if (message['status'] == 'done') {
            receivePort.close();
            break;
          } else if (message['status'] == 'error') {
            receivePort.close();
            throw Exception(message['error']);
          }
        }
      }

      setState(() {
        _importProgress = 1.0;
        _progressText = "تم النقل بنجاح! جاري تهيئة العداد...";
      });

      await Future.delayed(const Duration(milliseconds: 500));
      await _updateDatabaseCounter();

      setState(() => _isImporting = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم استيراد قاعدة البيانات بنجاح!", textDirection: TextDirection.rtl), backgroundColor: Colors.green));

    } catch (e) {
      setState(() => _isImporting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("حدث خطأ: $e", textDirection: TextDirection.rtl), backgroundColor: Colors.red));
    }
  }

  static void _copyFileIsolate(List<dynamic> args) {
    String source = args[0];
    String dest = args[1];
    SendPort sendPort = args[2];

    try {
      File sourceFile = File(source);
      File destFile = File(dest);
      int totalBytes = sourceFile.lengthSync();
      int copiedBytes = 0;

      var rafIn = sourceFile.openSync(mode: FileMode.read);
      var rafOut = destFile.openSync(mode: FileMode.write);

      int chunkSize = 1024 * 1024 * 5;
      int lastUpdate = DateTime.now().millisecondsSinceEpoch;

      while (copiedBytes < totalBytes) {
        int remaining = totalBytes - copiedBytes;
        int currentChunk = remaining < chunkSize ? remaining : chunkSize;

        var buffer = rafIn.readSync(currentChunk);
        rafOut.writeFromSync(buffer);
        copiedBytes += currentChunk;

        int now = DateTime.now().millisecondsSinceEpoch;
        if (now - lastUpdate > 250 || copiedBytes == totalBytes) {
          lastUpdate = now;
          double progress = copiedBytes / totalBytes;
          double copiedGB = copiedBytes / (1024 * 1024 * 1024);
          double totalGB = totalBytes / (1024 * 1024 * 1024);

          sendPort.send({
            'status': 'progress',
            'progress': progress,
            'text': 'تم نقل ${copiedGB.toStringAsFixed(2)} جيجا من ${totalGB.toStringAsFixed(2)} جيجا'
          });
        }
      }
      rafIn.closeSync();
      rafOut.closeSync();
      sendPort.send({'status': 'done'});
    } catch (e) {
      sendPort.send({'status': 'error', 'error': e.toString()});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text("كاشف الأرقام اليمني", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: _isLoadingScan
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.drive_folder_upload, color: Colors.white),
            onPressed: _isImporting ? null : _scanAndSelectDatabase,
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(
          children: [
            Column(
              children: [
                // تصميم عداد السجلات المضبوط الاتجاه والصياغة
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.blueGrey.withOpacity(0.15)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.storage_rounded, color: AppColors.primary, size: 22),
                      const SizedBox(width: 10),
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: _totalRecords.toDouble()),
                        duration: const Duration(milliseconds: 1500),
                        builder: (context, value, child) {
                          int roundedValue = value.round();
                          String formattedValue = roundedValue.toString().replaceAllMapped(
                              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},'
                          );
                          return Text(
                            "يوجد حالياً $formattedValue سجل في الدليل",
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: const [
                      NameSearchView(),
                      NumberSearchView(),
                    ],
                  ),
                ),
              ],
            ),

            if (_isImporting)
              Container(
                color: Colors.black.withOpacity(0.85),
                child: Center(
                  child: Card(
                    margin: const EdgeInsets.all(24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text("استيراد قاعدة البيانات", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          const SizedBox(height: 20),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 100, height: 100,
                                child: CircularProgressIndicator(value: _importProgress, strokeWidth: 8, color: AppColors.primary),
                              ),
                              Text("${(_importProgress * 100).toStringAsFixed(0)}%", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 25),
                          LinearProgressIndicator(value: _importProgress, color: Colors.blue),
                          const SizedBox(height: 15),
                          Text(_progressText, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.blueGrey), textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: AppColors.primary,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person_search), label: "بحث بالإسم"),
          BottomNavigationBarItem(icon: Icon(Icons.dialpad), label: "بحث بالرقم"),
        ],
      ),
    );
  }
}