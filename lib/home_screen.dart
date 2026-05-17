import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart'; // عدنا لاستخدام المتصفح بذكاء
import 'package:permission_handler/permission_handler.dart';
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
      setState(() {
        _totalRecords = count;
      });
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

  // 🔥 الدالة الاحترافية: استيراد ديناميكي مباشر بـ البث الحي (بدون مسارات ثابتة وبدون تعليق)
  Future<void> _pickAndImportDynamic() async {
    try {
      // 1. طلب الصلاحيات
      if (await Permission.manageExternalStorage.isDenied) {
        await Permission.manageExternalStorage.request();
      }
      if (await Permission.storage.isDenied) {
        await Permission.storage.request();
      }

      // 2. فتح المتصفح مع خاصية البث الحي لمنع الكارثة (Out of Memory & Caching)
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withReadStream: true, // 🌟 هذه الخاصية هي السر لمنع تعليق المتصفح مع الملفات العملاقة
      );

      // إذا اختار المستخدم ملفاً
      if (result != null && result.files.isNotEmpty) {
        PlatformFile pickedFile = result.files.first;

        // التحقق من امتداد الملف للتأكد من أنه قاعدة بيانات
        if (!pickedFile.name.endsWith('.db') && !pickedFile.name.endsWith('.txt') && !pickedFile.name.contains('contactsdb')) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("يرجى اختيار ملف قاعدة بيانات صحيح", textDirection: TextDirection.rtl), backgroundColor: Colors.orange)
          );
          return;
        }

        // 3. إغلاق القاعدة القديمة وتنظيف الكاش الخاص بها لكسر قفل النظام
        await DatabaseHelper.instance.closeDb();
        String dbDirectoryPath = await DatabaseHelper.instance.getDatabasesDirectoryPath();
        String targetPath = '$dbDirectoryPath/contactsdb.db';
        final targetFile = File(targetPath);

        if (await targetFile.exists()) await targetFile.delete();
        File walFile = File('$targetPath-wal');
        File shmFile = File('$targetPath-shm');
        if (await walFile.exists()) await walFile.delete();
        if (await shmFile.exists()) await shmFile.delete();

        // 4. تفعيل الواجهة التفاعلية فوراً
        setState(() {
          _isImporting = true;
          _importProgress = 0.0;
          _progressText = "جاري الاتصال المباشر بالملف...";
        });

        // 5. استقبال البث الحي من الملف المختار (أينما كان موقعه في الهاتف)
        final sourceStream = pickedFile.readStream;
        if (sourceStream == null) {
          throw Exception("فشل في إنشاء قناة البث للملف المختار.");
        }

        final targetSink = targetFile.openWrite(mode: FileMode.write);
        int bytesCopied = 0;
        int totalBytes = pickedFile.size; // قراءة الحجم الحقيقي للملف

        // سحب البيانات كباقات (Chunks) وعرضها على واجهة التحميل مباشرة
        await for (List<int> chunk in sourceStream) {
          targetSink.add(chunk);
          bytesCopied += chunk.length;

          double progress = totalBytes > 0 ? (bytesCopied / totalBytes) : 0.0;
          double copiedGB = bytesCopied / (1024 * 1024 * 1024);
          double totalGB = totalBytes > 0 ? (totalBytes / (1024 * 1024 * 1024)) : 0.0;

          setState(() {
            _importProgress = progress;
            if (totalBytes > 0) {
              _progressText = "تم نقل ${copiedGB.toStringAsFixed(2)} جيجا من أصل ${totalGB.toStringAsFixed(2)} جيجا";
            } else {
              _progressText = "جاري نقل البيانات: ${copiedGB.toStringAsFixed(2)} جيجا";
            }
          });
        }

        // حفظ البيانات النهائية وإغلاق القناة
        await targetSink.flush();
        await targetSink.close();

        setState(() {
          _progressText = "جاري قراءة السجلات المليونية وتهيئة العداد... لحظات";
        });

        // 6. تشغيل العداد الحي الديناميكي
        await _updateDatabaseCounter();

        setState(() { _isImporting = false; });

        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("اكتمل التحديث بنجاح! قاعدة البيانات جاهزة.", textDirection: TextDirection.rtl), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      setState(() { _isImporting = false; });
      debugPrint("حدث خطأ أثناء الاستيراد الديناميكي: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("حدث خطأ: $e", textDirection: TextDirection.rtl), backgroundColor: Colors.red)
      );
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
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildNumberSearchTab(),
                      _buildNameSearchTab(),
                    ],
                  ),
                ),
                Expanded(child: _buildResultsList()),
              ],
            ),

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
        onPressed: _pickAndImportDynamic, // ربط الزر بالدالة الديناميكية الخالية من المسارات
        backgroundColor: const Color(0xFF1E232C),
        icon: const Icon(Icons.flash_on, color: Colors.white),
        label: const Text("استيراد مباشر من الهاتف (.db)", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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