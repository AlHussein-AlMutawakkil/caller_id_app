import 'package:flutter/material.dart';
import 'database/database_helper.dart';
import 'core/theme/app_colors.dart';
import 'features/search_number/presentation/number_search_view.dart';
import 'views/name_search_view.dart';
import 'views/settings/settings_view.dart';
import 'core/constants/app_icons.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _totalRecords = 0;
  int _currentIndex = 1; // التبويب الافتراضي (البحث بالرقم)

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 60, // الارتفاع الافتراضي للعنوان
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
        title: const Text("كاشف الأرقام المحلي", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        // استخدام bottom لإضافة العداد بشكل منفصل ومنظم
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.blueGrey.withOpacity(0.08), // خلفية بيضاء شفافة لتبرز فوق لون الـ AppBar
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white),
            ),
            child: // هذا هو الكود الصحيح الذي يضمن ثبات الترتيب (النص - الرقم - النص - الأيقونة)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: _totalRecords.toDouble()),
                  duration: const Duration(milliseconds: 1500),
                  builder: (context, value, child) {
                    // 1. تنسيق الرقم بالفواصل
                    String rawValue = value.round().toString().replaceAllMapped(
                        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},'
                    );

                    // 2. "العزل": إضافة رمز Unicode يمنع قلب الأرقام نهائياً
                    String formattedValue = "\u200E" + rawValue;

                    return Text(
                      "يوجد حالياً $formattedValue رقم",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 10),
                const Icon(Icons.storage_rounded, color: Colors.white, size: 22),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(AppIcons.menu, color: Colors.white),
            tooltip: 'الإعدادات',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsView()),
              );
            },
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: IndexedStack(
          index: _currentIndex,
          children: const [
            NameSearchView(),
            NumberSearchView(),
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