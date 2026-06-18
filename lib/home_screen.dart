import 'package:flutter/material.dart';
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
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _updateDatabaseCounter();
  }

  // تحديث عداد السجلات من قاعدة البيانات
  Future<void> _updateDatabaseCounter() async {
    int count = await DatabaseHelper.instance.getTotalRecordsCount();
    if (mounted) {
      setState(() {
        _totalRecords = count;
      });
    }
  }

  // دالة بدء استيراد ونسخ قاعدة البيانات من مجلد Download
  Future<void> _handleDatabaseImport() async {
    setState(() => _isImporting = true);

    // إظهار رسالة للمستخدم بأن العملية بدأت
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("جاري فحص واستيراد قاعدة البيانات من مجلد Download...", textAlign: TextAlign.right),
        duration: Duration(seconds: 3),
      ),
    );

    try {
      // استدعاء قاعدة البيانات يطلق دالة الفحص والنسخ تلقائياً بداخل DatabaseHelper
      final db = await DatabaseHelper.instance.database;
      await _updateDatabaseCounter(); // تحديث العداد بعد الاستيراد الناجح

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("مبروك! تم استيراد قاعدة البيانات بنجاح وتحديث النظام.", textAlign: TextAlign.right),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("خطأ أثناء الاستيراد: $e", textAlign: TextAlign.right),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        title: const Text(
            "دليل اليمن",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
        ),
        // زر الاستيراد يظهر هنا مباشرة في الأعلى لضمان عدم اختفائه
        actions: [
          _isImporting
              ? const Padding(
            padding: EdgeInsets.all(12.0),
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            ),
          )
              : IconButton(
            icon: const Icon(Icons.storage_rounded, color: Colors.white, size: 28),
            tooltip: "استيراد قاعدة البيانات",
            onPressed: _handleDatabaseImport,
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط عرض عدد السجلات الحالية
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: Colors.grey[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("رقم  ", style: TextStyle(fontSize: 14, color: Colors.black54)),
                Text(
                  _totalRecords.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},'),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const Text("  مسجل حالياً", style: TextStyle(fontSize: 14, color: Colors.black54)),
              ],
            ),
          ),

          // واجهات البحث (بالاسم وبالرقم)
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: const [
                NameSearchView(),   // index 0
                NumberSearchView(), // index 1
              ],
            ),
          ),
        ],
      ),

      // أزرار التنقل السفلية بين البحث بالرقم والاسم
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: AppColors.primary,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person_search), label: "بحث بالإسم"),
          BottomNavigationBarItem(icon: Icon(Icons.phone), label: "بحث بالرقم"),
        ],
      ),
    );
  }
}