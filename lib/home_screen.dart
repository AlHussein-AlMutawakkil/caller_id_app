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
    int count = await DatabaseHelper.instance.getTotalRecordsCount(forceRefresh: true);
    if (mounted) {
      setState(() {
        _totalRecords = count;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 60,
          backgroundColor: AppColors.appBarBackground,
          automaticallyImplyLeading: false,
          title: const Text(
            "كاشف الأرقام المحلي",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.blueGrey.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.storage_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  const Text(
                    "يوجد حالياً",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: _totalRecords.toDouble()),
                    duration: const Duration(milliseconds: 1500),
                    builder: (context, value, child) {
                      final rawValue = value.round().toString().replaceAllMapped(
                        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                        (Match m) => '${m[1]},',
                      );

                      return Text(
                        rawValue,
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    "رقم",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(AppIcons.menu, color: Colors.white),
              tooltip: 'الإعدادات',
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsView()),
                );
                _updateDatabaseCounter();
              },
            ),
          ],
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: const [
            NameSearchView(),
            NumberSearchView(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          backgroundColor: AppColors.appBarBackground,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          onTap: (index) {
            FocusScope.of(context).unfocus();
            setState(() => _currentIndex = index);
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.person_search),
              label: "بحث بالإسم",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.dialpad),
              label: "بحث بالرقم",
            ),
          ],
        ),
      ),
    );
  }
}
