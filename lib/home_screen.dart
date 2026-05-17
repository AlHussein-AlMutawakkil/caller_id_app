import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

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

  final List<String> _telecomCompanies = [
    'إختر شركة الإتصالات',
    'يمن موبايل',
    'سبأفون',
    'إم تي إن / يو',
    'واي',
    'الهاتف الثابت'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // تشغيل العداد بانسيابية فور الفتح
    Future.delayed(const Duration(milliseconds: 500), () {
      _updateDatabaseCounter();
    });
  }

  Future<void> _updateDatabaseCounter() async {
    int count = await DatabaseHelper.instance.getTotalRecordsCount();
    if (count > 0) {
      setState(() { _totalRecords = count; });
    }
  }

  Future<void> _performNumberSearch() async {
    if (_numberController.text.isEmpty) return;
    setState(() { _searchResults = []; });
    final results = await DatabaseHelper.instance.searchByNumber(_numberController.text);
    setState(() { _searchResults = results; });
  }

  Future<void> _performNameSearch() async {
    if (_nameController.text.isEmpty) return;
    setState(() { _searchResults = []; });
    final results = await DatabaseHelper.instance.searchByName(_nameController.text, _selectedCompany);
    setState(() { _searchResults = results; });
  }

  // 🔥 الدالة الخارقة: مستكشف الملفات الداخلي (لتجاوز تجميد الأندرويد)
  Future<void> _scanAndSelectDatabase() async {
    try {
      // 1. طلب الصلاحيات الأساسية لقراءة الذاكرة
      if (await Permission.manageExternalStorage.isDenied) {
        await Permission.manageExternalStorage.request();
      }
      if (await Permission.storage.isDenied) {
        await Permission.storage.request();
      }

      setState(() { _isLoading = true; });

      List<File> foundFiles = [];

      // 2. البحث الذكي في المجلدات التي يحفظ فيها المستخدمون بياناتهم
      List<Directory> dirsToSearch = [
        Directory('/storage/emulated/0/Download'),
        Directory('/storage/emulated/0/الكاشف'),
        Directory('/storage/emulated/0/Documents'),
      ];

      for (var dir in dirsToSearch) {
        if (dir.existsSync()) {
          try {
            var entities = dir.listSync(recursive: true, followLinks: false);
            for (var entity in entities) {
              // جلب الملفات الضخمة فقط (أكبر من نصف جيجا) لفلترة البحث
              if (entity is File && entity.lengthSync() > 500000000) {
                String name = entity.path.toLowerCase();
                if (name.endsWith('.db') || name.endsWith('.txt') || name.contains('contactsdb')) {
                  foundFiles.add(entity);
                }
              }
            }
          } catch(e) {}
        }
      }

      // البحث في المسار الجذري للهاتف
      try {
        var entities = Directory('/storage/emulated/0/').listSync(recursive: false);
        for(var entity in entities) {
          if (entity is File && entity.lengthSync() > 500000000) {
            if(!foundFiles.any((f) => f.path == entity.path)) foundFiles.add(entity);
          }
        }
      } catch(e) {}

      setState(() { _isLoading = false; });

      if (foundFiles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("لم نجد ملفات ضخمة! تأكد من وجود القاعدة في التنزيلات", textDirection: TextDirection.rtl),
              backgroundColor: Colors.red,
            )
        );
        return;
      }

      // 3. عرض نافذة الاختيار الديناميكية والمباشرة
      if (!mounted) return;
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("اختر ملف قاعدة البيانات", textDirection: TextDirection.rtl, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              content: SizedBox(
                width: double.maxFinite,
                height: 300,
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
                        subtitle: Text("الحجم: $sizeGB جيجابايت\nالمسار: ${file.path.replaceAll('/storage/emulated/0/', '')}", textDirection: TextDirection.ltr),
                        onTap: () {
                          Navigator.pop(context); // إغلاق النافذة
                          _startDirectImport(file); // بدء النقل التفاعلي المباشر!
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
            );
          }
      );
    } catch (e) {
      setState(() { _isLoading = false; });
      debugPrint("خطأ أثناء البحث عن الملفات: $e");
    }
  }

  // 🔥 الدالة التفاعلية الخالصة: تبدأ البث الحي فوراً بدون أي تجميد
  Future<void> _startDirectImport(File sourceFile) async {
    try {
      // إغلاق القاعدة القديمة ومسح أقفال الـ Cache الخاصة بالنظام
      await DatabaseHelper.instance.closeDb();
      String dbDirectoryPath = await DatabaseHelper.instance.getDatabasesDirectoryPath();
      String targetPath = '$dbDirectoryPath/contactsdb.db';
      // 🔥 تدمير قاعدة البيانات القديمة من جذورها رسمياً باستخدام Sqflite
      await databaseFactory.deleteDatabase(targetPath);
      final targetFile = File(targetPath);

      if (targetFile.existsSync()) targetFile.deleteSync();
      File walFile = File('$targetPath-wal');
      File shmFile = File('$targetPath-shm');
      if (walFile.existsSync()) walFile.deleteSync();
      if (shmFile.existsSync()) shmFile.deleteSync();

      // تفعيل واجهة التحميل السوداء في نفس الجزء من الثانية!
      setState(() {
        _isImporting = true;
        _importProgress = 0.0;
        _progressText = "جاري الاتصال والنسخ المباشر...";
      });

      // إعطاء المعالج فرصة 150 ملي ثانية ليرسم الشاشة السوداء قبل الضغط
      await Future.delayed(const Duration(milliseconds: 150));

      final sourceStream = sourceFile.openRead();
      final targetSink = targetFile.openWrite(mode: FileMode.write);
      int bytesCopied = 0;
      int totalBytes = sourceFile.lengthSync();

      // خانق التحديث (Throttle) لمنع اختناق الشاشة
      int lastUiUpdateTime = DateTime.now().millisecondsSinceEpoch;

      await for (List<int> chunk in sourceStream) {
        targetSink.add(chunk);
        bytesCopied += chunk.length;

        int currentTime = DateTime.now().millisecondsSinceEpoch;

        // تحديث النسبة المئوية كل ربع ثانية لتعمل بسلاسة وانسيابية
        if (currentTime - lastUiUpdateTime > 250) {
          lastUiUpdateTime = currentTime;

          double progress = totalBytes > 0 ? (bytesCopied / totalBytes) : 0.0;
          double copiedGB = bytesCopied / (1024 * 1024 * 1024);
          double totalGB = totalBytes > 0 ? (totalBytes / (1024 * 1024 * 1024)) : 0.0;

          setState(() {
            _importProgress = progress;
            _progressText = "تم نقل ${copiedGB.toStringAsFixed(2)} جيجا من أصل ${totalGB.toStringAsFixed(2)} جيجا";
          });
        }
      }

      await targetSink.flush();
      await targetSink.close();

      setState(() {
        _importProgress = 1.0;
        _progressText = "جاري قراءة السجلات المليونية وتهيئة العداد... لحظات";
      });
      await Future.delayed(const Duration(milliseconds: 300));

      // تشغيل العداد ليقفز حياً إلى الملايين!
      await _updateDatabaseCounter();

      setState(() { _isImporting = false; });

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("اكتمل التحديث بنجاح! قاعدة البيانات جاهزة.", textDirection: TextDirection.rtl), backgroundColor: Colors.green)
      );
    } catch (e) {
      setState(() { _isImporting = false; });
      debugPrint("حدث خطأ أثناء النقل: $e");
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
          tabs: const [
            Tab(text: "البحث بالرقم", icon: Icon(Icons.phone)),
            Tab(text: "البحث بالاسم", icon: Icon(Icons.person)),
          ],
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
                    return Text(
                      "رقم $formattedValue يوجد حالياً",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                      textAlign: TextAlign.center,
                    );
                  },
                ),
                const Divider(),
                if (_isLoading) const LinearProgressIndicator(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildNumberSearchTab(),
                      _buildNameSearchTab(),
                    ],
                  ),
                ),
                if (!_isImporting && !_isLoading) Expanded(child: _buildResultsList()),
              ],
            ),

            // 🔥 الواجهة التفاعلية الفخمة والمنقذة!
            if (_isImporting)
              Container(
                color: Colors.black.withOpacity(0.85),
                child: Center(
                  child: Card(
                    margin: const EdgeInsets.all(24),
                    color: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "تحديث قاعدة البيانات الكبرى",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E232C)),
                          ),
                          const SizedBox(height: 20),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 100,
                                height: 100,
                                child: CircularProgressIndicator(
                                  value: _importProgress,
                                  strokeWidth: 8,
                                  backgroundColor: Colors.grey.shade200,
                                  color: const Color(0xFF1E232C),
                                ),
                              ),
                              Text(
                                "${(_importProgress * 100).toStringAsFixed(0)}%",
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 25),
                          LinearProgressIndicator(
                            value: _importProgress,
                            backgroundColor: Colors.grey.shade200,
                            color: Colors.blue,
                          ),
                          const SizedBox(height: 15),
                          Text(
                            _progressText,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.blueGrey),
                            textAlign: TextAlign.center,
                          ),
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
        onPressed: _scanAndSelectDatabase, // تشغيل المستكشف الداخلي الديناميكي
        backgroundColor: const Color(0xFF1E232C),
        icon: const Icon(Icons.manage_search, color: Colors.white),
        label: const Text("البحث واستيراد القاعدة", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildNumberSearchTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text("البحث بالرقم", style: TextStyle(fontSize: 20)),
            const SizedBox(height: 10),
            TextFormField(
              controller: _numberController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "أدخل الرقم هنا"),
            ),
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
            const Text("البحث بالاسم", style: TextStyle(fontSize: 20)),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedCompany,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: _telecomCompanies.map((String value) {
                return DropdownMenuItem<String>(value: value, child: Text(value));
              }).toList(),
              onChanged: (newValue) { setState(() { _selectedCompany = newValue!; }); },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "أدخل الاسم هنا"),
            ),
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
    if (_searchResults.isEmpty) { return const Center(child: Text("لا توجد نتائج لعرضها حالياً")); }
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