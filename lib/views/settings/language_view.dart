import 'package:flutter/material.dart';
import '../../core/constants/app_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/settings_card.dart';

class LanguageView extends StatefulWidget {
  const LanguageView({super.key});

  @override
  State<LanguageView> createState() => _LanguageViewState();
}

class _LanguageViewState extends State<LanguageView> {
  // اللغة العربية هي المفعلة حالياً
  final int _selectedLanguageIndex = 1;

  final List<String> _languages = [
    'English (US)',
    'Arabic (Arabic)',
    'German (Deutsch)',
    'Spanish (Español)',
    'French (France)',
    'Italian (Italiano)',
    'Japanese (日本語)',
    'Korean (Korean)',
    'Portuguese (Portugal)',
    'Portuguese (Brasil)',
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
            'اللغة',
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
              children: List.generate(_languages.length, (index) {
                final isSelected = _selectedLanguageIndex == index;
                final isLast = index == _languages.length - 1;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () {
                        if (index != 1) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'اللغة العربية هي المتوفرة حالياً في التطبيق',
                                textAlign: TextAlign.center,
                              ),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _languages[index],
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
