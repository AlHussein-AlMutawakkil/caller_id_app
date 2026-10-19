import 'package:flutter/material.dart';
import '../../core/constants/app_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/settings_card.dart';

class AppearanceView extends StatefulWidget {
  const AppearanceView({super.key});

  @override
  State<AppearanceView> createState() => _AppearanceViewState();
}

class _AppearanceViewState extends State<AppearanceView> {
  // الوضع الافتراضي: فاتح
  int _selectedThemeIndex = 1;

  final List<String> _themes = [
    'النظام',
    'فاتح',
    'مظلم',
  ];

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
            'سمة الألوان',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          centerTitle: false,
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            SettingsCard(
              children: List.generate(_themes.length, (index) {
                final isSelected = _selectedThemeIndex == index;
                final isLast = index == _themes.length - 1;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          _selectedThemeIndex = index;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _themes[index],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                AppIcons.checked,
                                color: AppColors.textPrimary,
                                size: 22,
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (!isLast)
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.divider,
                        indent: 20,
                        endIndent: 20,
                      ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
