import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/settings_card.dart';
import '../../core/widgets/settings_tile.dart';
import '../../core/widgets/app_modal_dialog.dart';
import 'appearance_view.dart';
import 'language_view.dart';
import 'permissions_view.dart';
import 'about_view.dart';
import 'database_view.dart';
import 'telecom_companies_view.dart';
import '../../database/database_helper.dart';
import 'license_view.dart';

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
    final count = await DatabaseHelper.instance.getTotalRecordsCount(forceRefresh: true);
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
            icon: Icon(AppIcons.back, color: AppColors.textPrimary, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
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
            // 1. بطاقة الترخيص
            SettingsCard(
              children: [
                SettingsTile(
                  leading: Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 22),
                  title: 'الترخيص',
                  trailing: Icon(AppIcons.chevronRight, size: 20, color: AppColors.textSecondary),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LicenseView()),
                    );
                  },
                ),
              ],
            ),

            // 3. بطاقة شركات الاتصالات وقاعدة البيانات
            SettingsCard(
              children: [
                SettingsTile(
                  leading: Icon(AppIcons.telecom, color: AppColors.textPrimary, size: 22),
                  title: 'شركات الاتصالات',
                  trailing: Icon(AppIcons.chevronRight, size: 20, color: AppColors.textSecondary),
                  showDivider: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TelecomCompaniesView()),
                    );
                  },
                ),
                SettingsTile(
                  leading: Icon(AppIcons.database, color: AppColors.textPrimary, size: 22),
                  title: 'قاعدة البيانات',
                  trailing: _totalRecords > 0
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatNumber(_totalRecords),
                              textDirection: TextDirection.ltr,
                              style: TextStyle(
                                fontSize: 13,
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
                        )
                      : Text(
                          'غير متوفرة',
                          style: TextStyle(
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
                  leading: Icon(AppIcons.appearance, color: AppColors.textPrimary, size: 22),
                  title: 'المظهر',
                  trailing: Text(
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
                  leading: Icon(AppIcons.language, color: AppColors.textPrimary, size: 22),
                  title: 'لغة التطبيق',
                  trailing: Text(
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
                  leading: Icon(AppIcons.permissions, color: AppColors.textPrimary, size: 22),
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
                  leading: Icon(AppIcons.about, color: AppColors.textPrimary, size: 22),
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

            // 5. بطاقة الخروج من التطبيق
            SettingsCard(
              children: [
                SettingsTile(
                  title: 'الخروج من التطبيق',
                  textColor: AppColors.error,
                  trailing: const Icon(
                    AppIcons.logout,
                    color: AppColors.error,
                    size: 22,
                  ),
                  onTap: () {
                    AppModalDialog.show(
                      context: context,
                      title: 'الخروج من التطبيق',
                      actionButtonText: 'تأكيد الخروج',
                      actionButtonColor: AppColors.error,
                      onActionButtonPressed: () {
                        SystemNavigator.pop();
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text(
                          'هل أنت متأكد من رغبتك في إغلاق والخروج من التطبيق؟',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: AppColors.textPrimary,
                          ),
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