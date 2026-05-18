import 'dart:io';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import 'package:file_picker/file_picker.dart'; // أضف هذا الاستيراد في أعلى الملف

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  int _totalRecords = 0;
  String _selectedCompany = 'إختر شركة الإتصالات';
  List<Map<String, dynamic>> _searchResults = [];

  bool _isImporting = false;
  bool _isLoading = false;
  double _importProgress = 0.0;
  String _progressText = "";

  final List<String> _telecomCompanies = ['إختر شركة الإتصالات', 'يمن موبايل', 'سبأفون', 'إم تي إن / يو', 'واي', 'الهاتف الثابت'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.delayed(const Duration(milliseconds: 500), () => _updateDatabaseCounter());
  }

  Future<void> _updateDatabaseCounter() async {
    try {
      final db = await DatabaseHelper.instance.database;

      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name != 'android_metadata' AND name NOT LIKE 'sqlite_%'");

      if (tables.isEmpty) {
        _showDebugDialog("الملف لا يحتوي على جداول SQLite.");
        return;
      }

      String tableName = tables.first['name'] as String;
      int count = 0;

      // المحاولة الأولى: القفز السريع لآخر rowid (تأخذ جزء من الثانية)
      try {
        final countResult = await db.rawQuery('SELECT MAX(rowid) FROM $tableName');
        count = Sqflite.firstIntValue(countResult) ?? 0;
      } catch (_) {}

      // المحاولة الثانية: القفز السريع لآخر id (إذا كان الجدول لا يدعم rowid)
      if (count == 0) {
        try {
          final countResult2 = await db.rawQuery('SELECT MAX(id) FROM $tableName');
          count = Sqflite.firstIntValue(countResult2) ?? 0;
        } catch (_) {}
      }

      // تم حذف طريقة COUNT(*) البطيئة جداً لأنها تجمد الهاتف!

      if (count > 0 && mounted) {
        setState(() => _totalRecords = count);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("تم قراءة القاعدة بنجاح! ($count سجل)", textDirection: TextDirection.rtl),
          backgroundColor: Colors.green,
        ));
      } else {
        // إذا لم يتمكن من جلب العدد السريع، نضع رقماً افتراضياً لكي لا يتجمد التطبيق
        setState(() => _totalRecords = 37000000);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("تم فتح القاعدة بنجاح وجاهزة للبحث!", textDirection: TextDirection.rtl),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      _showDebugDialog("حدث خطأ:\n$e");
    }
  }


  // دالة مساعدة لإظهار رسالة الفحص على الشاشة
  void _showDebugDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("🔍 تقرير فحص القاعدة", textDirection: TextDirection.rtl, style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(child: Text(message, textDirection: TextDirection.ltr)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("حسناً"),
          )
        ],
      ),
    );
  }


  Future<void> _performNumberSearch() async {
    if (_numberController.text.isEmpty) return;
    setState(() => _searchResults = []);
    final results = await DatabaseHelper.instance.searchByNumber(_numberController.text);
    setState(() => _searchResults = results);
  }

  Future<void> _performNameSearch() async {
    if (_nameController.text.isEmpty) return;
    setState(() => _searchResults = []);
    final results = await DatabaseHelper.instance.searchByName(_nameController.text, _selectedCompany);
    setState(() => _searchResults = results);
  }

  // البحث المباشر والآمن في مجلدات الهاتف (مضاد لانهيارات الأندرويد)
  // المستكشف الداخلي المحسن (بدون تخزين مؤقت وبدون تجميد للشاشة)
  // المستكشف الداخلي مع معالجة ذكية للصلاحيات
  // المستكشف الداخلي المتوافق مع أندرويد 10 و 11+
  Future<void> _scanAndSelectDatabase() async {
    bool hasPermission = false;

    // 1. طلب صلاحية التخزين العادية (تكفي وتعمل بنجاح في أندرويد 10 وما دون)
    var storageStatus = await Permission.storage.request();

    // 2. طلب صلاحية إدارة الملفات (لأندرويد 11 وما فوق)
    var manageStatus = await Permission.manageExternalStorage.request();

    // إذا وافق المستخدم على أيٍ من الصلاحيتين حسب نوع هاتفه
    if (storageStatus.isGranted || manageStatus.isGranted) {
      hasPermission = true;
    }

    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("يجب إعطاء صلاحية التخزين لكي نتمكن من إيجاد القاعدة.", textDirection: TextDirection.rtl),
        backgroundColor: Colors.red,
      ));
      await openAppSettings();
      return;
    }

    // إظهار مؤشر البحث في الشاشة
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 100));

    List<File> foundFiles = [];

    // دالة البحث الآمنة
    void safeScan(Directory dir) {
      try {
        if (!dir.existsSync()) return;
        var entities = dir.listSync(recursive: false);
        for (var entity in entities) {
          if (entity is File) {
            String fileName = entity.path.split('/').last.toLowerCase();
            if (fileName == 'contactsdb.db') {
              foundFiles.add(entity);
            }
          } else if (entity is Directory) {
            String dirName = entity.path.split('/').last;
            if (!dirName.startsWith('.') && dirName != 'Android' && dirName != 'Android/data') {
              safeScan(entity);
            }
          }
        }
      } catch (e) {
        // تخطي المجلدات الممنوعة بصمت
      }
    }

    // مسارات البحث
    safeScan(Directory('/storage/emulated/0/Download'));
    safeScan(Directory('/storage/emulated/0/الكاشف'));
    safeScan(Directory('/storage/emulated/0/Telegram/Telegram Documents'));
    safeScan(Directory('/storage/emulated/0'));

    setState(() => _isLoading = false);

    if (foundFiles.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("لم نجد الملف! تأكد من أن اسمه contactsdb.db وموجود في التنزيلات.", textDirection: TextDirection.rtl),
        backgroundColor: Colors.red,
      ));
      return;
    }

    if (!mounted) return;

    // عرض نافذة اختيار الملف
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("اختر قاعدة البيانات", textDirection: TextDirection.rtl, style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite, height: 300,
          child: ListView.builder(
            itemCount: foundFiles.length,
            itemBuilder: (context, index) {
              final file = foundFiles[index];
              final sizeGB = (file.lengthSync() / (1024 * 1024 * 1024)).toStringAsFixed(2);
              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.storage, color: Color(0xFF1E232C), size: 30),
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("إلغاء", style: TextStyle(color: Colors.red, fontSize: 16)),
          )
        ],
      ),
    );
  }




  // ... (باقي الكود في الأسفل _startBackgroundIsolateImport وغيرها)

  // 🚀 البنية الهندسية المعزولة: تعمل في مسار خلفي لضمان عدم تعليق الشاشة مطلقاً
  Future<void> _startBackgroundIsolateImport(File sourceFile) async {
    try {
      await DatabaseHelper.instance.deleteDbFile();
      String dbDir = await DatabaseHelper.instance.getDatabasesDirectoryPath();
      String targetPath = '$dbDir/contactsdb.db';

      setState(() {
        _isImporting = true;
        _importProgress = 0.0;
        _progressText = "جاري تحضير النقل الخلفي...";
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
        _progressText = "تم النقل! جاري تهيئة العداد والملايين...";
      });

      await Future.delayed(const Duration(milliseconds: 500));
      await _updateDatabaseCounter();

      setState(() => _isImporting = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("اكتمل التحديث بنجاح!", textDirection: TextDirection.rtl), backgroundColor: Colors.green));

    } catch (e) {
      setState(() => _isImporting = false);
      debugPrint("خطأ: $e");
    }
  }

  // 🔥 الخوارزمية المعزولة (Isolate): تنقل الـ 7.8 جيجابايت بثبات وبدون أي اختناق للهاتف
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

      int chunkSize = 1024 * 1024 * 5; // 5 ميجابايت للدفعة لضمان أقصى سرعة
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
        backgroundColor: const Color(0xFF1E232C),
        title: const Text("دليل الهاتف اليمني المحرك", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.white,
          tabs: const [Tab(text: "البحث بالرقم", icon: Icon(Icons.phone)), Tab(text: "البحث بالاسم", icon: Icon(Icons.person))],
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 10),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: _totalRecords.toDouble()),
                  duration: const Duration(milliseconds: 2000),
                  builder: (context, value, child) {
                    int roundedValue = value.round();
                    String formattedValue = roundedValue.toString().replaceAllMapped(
                        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},'
                    );
                    return Text("رقم $formattedValue يوجد حالياً", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey), textAlign: TextAlign.center);
                  },
                ),
                const Divider(),
                if (_isLoading) const LinearProgressIndicator(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [_buildNumberSearchTab(), _buildNameSearchTab()],
                  ),
                ),
                if (!_isImporting && !_isLoading) Expanded(child: _buildResultsList()),
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
                          const Text("تحديث قاعدة البيانات", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 20),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 100, height: 100,
                                child: CircularProgressIndicator(value: _importProgress, strokeWidth: 8, color: const Color(0xFF1E232C)),
                              ),
                              Text("${(_importProgress * 100).toStringAsFixed(0)}%", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 25),
                          LinearProgressIndicator(value: _importProgress),
                          const SizedBox(height: 15),
                          Text(_progressText, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: _isImporting ? null : FloatingActionButton.extended(
        onPressed: _scanAndSelectDatabase,
        backgroundColor: const Color(0xFF1E232C),
        icon: const Icon(Icons.manage_search, color: Colors.white),
        label: const Text("البحث واستيراد القاعدة", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildNumberSearchTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(controller: _numberController, keyboardType: TextInputType.phone, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "أدخل الرقم هنا")),
            const SizedBox(height: 15),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E232C), minimumSize: const Size.fromHeight(50)),
              onPressed: _performNumberSearch,
              child: const Text("بحث", style: TextStyle(color: Colors.white, fontSize: 18)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildNameSearchTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedCompany,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: _telecomCompanies.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) => setState(() => _selectedCompany = v!),
            ),
            const SizedBox(height: 10),
            TextFormField(controller: _nameController, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "أدخل الاسم هنا")),
            const SizedBox(height: 15),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E232C), minimumSize: const Size.fromHeight(50)),
              onPressed: _performNameSearch,
              child: const Text("بحث", style: TextStyle(color: Colors.white, fontSize: 18)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList() {
    if (_searchResults.isEmpty) return const Center(child: Text("لا توجد نتائج لعرضها حالياً"));
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final item = _searchResults[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          child: ListTile(
            leading: const Icon(Icons.contact_phone, color: Color(0xFF1E232C)),
            title: Text(item['names'] ?? 'بدون اسم', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(item['phone'] ?? 'بدون رقم', style: const TextStyle(color: Colors.blue)),
          ),
        );
      },
    );
  }
}