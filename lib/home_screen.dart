import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        extendBody: true,
        body: IndexedStack(
          index: _currentIndex,
          children: const [
            NameSearchView(),
            NumberSearchView(),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFloatingBottomNavBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // شريط التبويب العائم المطابق للتصميم الكبسولي في الصورة المرفقة
  Widget _buildFloatingBottomNavBar() {
    final bool isDark = AppColors.isDarkMode;
    final Color outerBg = isDark ? AppColors.cardBackground : Colors.white;
    final Color outerBorder =
        isDark ? AppColors.cardBorder : Colors.black.withOpacity(0.06);
    final Color activePillBg =
        isDark ? const Color(0xFF2563EB) : const Color(0xFF0F2643);
    final Color inactiveIconColor =
        isDark ? Colors.white70 : const Color(0xFF0F2643);

    return Container(
      decoration: BoxDecoration(
        color: outerBg,
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: outerBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 5),
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.all(5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildNavItem(
            index: 0,
            label: "بحث بالإسم",
            icon: Icons.person_search_rounded,
            isSelected: _currentIndex == 0,
            activePillBg: activePillBg,
            inactiveIconColor: inactiveIconColor,
          ),
          const SizedBox(width: 4),
          _buildNavItem(
            index: 1,
            label: "بحث بالرقم",
            icon: Icons.dialpad_rounded,
            isSelected: _currentIndex == 1,
            activePillBg: activePillBg,
            inactiveIconColor: inactiveIconColor,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color activePillBg,
    required Color inactiveIconColor,
  }) {
    return InkWell(
      onTap: () {
        if (_currentIndex != index) {
          HapticFeedback.lightImpact();
          FocusScope.of(context).unfocus();
          setState(() => _currentIndex = index);
        }
      },
      borderRadius: BorderRadius.circular(28),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOutCubic,
        padding: isSelected
            ? const EdgeInsets.symmetric(horizontal: 18, vertical: 10)
            : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? activePillBg : Colors.transparent,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : inactiveIconColor,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
