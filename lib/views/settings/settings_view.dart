import 'package:flutter/material.dart';
import '../../core/constants/app_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/settings_card.dart';
import '../../core/widgets/settings_tile.dart';
import 'appearance_view.dart';
import 'language_view.dart';
import 'permissions_view.dart';
import 'about_view.dart';
import 'database_view.dart';
import 'telecom_companies_view.dart';
import '../../database/database_helper.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  int _totalRecords = 0;

  @override
  void initState() {
    super.initState();
    _updateRecords();
  }

  Future<void> _updateRecords() async {
    final count = await DatabaseHelper.instance.getTotalRecordsCount();
    if (mounted) {
      setState(() {
        _totalRecords = count;
      });
    }
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
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
            'الإعدادات',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          centerTitle: false,
        ),
        body: ListView(
          padding: const EdgeInsets.only(top: 8, bottom: 28),
          children: [
            // 1. بطاقة الملف الشخصي (مطابقة للصورة 3)
            SettingsCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              children: [
                Row(
                  children: [
                    // الصورة الرمزية في دائرة داكنة
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        AppIcons.profileAvatar,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 14),
                    // الاسم وتعديل الملف الشخصي
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'الحسين علي المتوكل',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'تعديل الملف الشخصي',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // 2. بطاقة الحساب (مطابقة للصورة 3)
            SettingsCard(
              children: [
                SettingsTile(
                  leading: const Icon(AppIcons.account, color: AppColors.textPrimary, size: 22),
                  title: 'الحساب',
                  trailing: const Text(
                    '...alhossenail776472265',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  onTap: () {},
                ),
              ],
            ),

            // 3. بطاقة شركات الاتصالات وقاعدة البيانات
            SettingsCard(
              children: [
                SettingsTile(
                  leading: const Icon(AppIcons.telecom, color: AppColors.textPrimary, size: 22),
                  title: 'شركات الاتصالات',
                  trailing: const Icon(AppIcons.chevronRight, size: 20, color: AppColors.textSecondary),
                  showDivider: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TelecomCompaniesView()),
                    );
                  },
                ),
                SettingsTile(
                  leading: const Icon(AppIcons.database, color: AppColors.textPrimary, size: 22),
                  title: 'قاعدة البيانات',
                  trailing: Text(
                    _totalRecords > 0 ? '${_formatNumber(_totalRecords)} رقم' : 'غير متوفرة',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DatabaseView()),
                    );
                    _updateRecords();
                  },
                ),
              ],
            ),

            // 4. بطاقة المظهر واللغة (مطابقة للصورة 3)
            SettingsCard(
              children: [
                SettingsTile(
                  leading: const Icon(AppIcons.appearance, color: AppColors.textPrimary, size: 22),
                  title: 'المظهر',
                  trailing: const Text(
                    'فاتح',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  showDivider: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AppearanceView()),
                    );
                  },
                ),
                SettingsTile(
                  leading: const Icon(AppIcons.language, color: AppColors.textPrimary, size: 22),
                  title: 'لغة التطبيق',
                  trailing: const Text(
                    'العربية (Arabic)',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LanguageView()),
                    );
                  },
                ),
              ],
            ),

            // 5. بطاقة إدارة الأذونات وحول التطبيق (مطابقة للصورة 3)
            SettingsCard(
              children: [
                SettingsTile(
                  leading: const Icon(AppIcons.permissions, color: AppColors.textPrimary, size: 22),
                  title: 'إدارة الأذونات',
                  showDivider: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PermissionsView()),
                    );
                  },
                ),
                SettingsTile(
                  leading: const Icon(AppIcons.about, color: AppColors.textPrimary, size: 22),
                  title: 'حول التطبيق',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AboutView()),
                    );
                  },
                ),
              ],
            ),

            // 6. بطاقة تسجيل الخروج (مطابقة للصورة 3 باللون الأحمر)
            SettingsCard(
              children: [
                SettingsTile(
                  title: 'تسجيل الخروج',
                  textColor: AppColors.error,
                  trailing: const Icon(
                    AppIcons.logout,
                    color: AppColors.error,
                    size: 22,
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => Directionality(
                        textDirection: TextDirection.rtl,
                        child: AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: const Text('تسجيل الخروج'),
                          content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('إلغاء'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                              },
                              child: const Text(
                                'تأكيد',
                                style: TextStyle(color: AppColors.error),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
