import 'package:flutter/material.dart';
import '../../core/constants/app_icons.dart';
import '../../core/services/telecom_companies_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/settings_card.dart';

class TelecomCompaniesView extends StatefulWidget {
  const TelecomCompaniesView({super.key});

  @override
  State<TelecomCompaniesView> createState() => _TelecomCompaniesViewState();
}

class _TelecomCompaniesViewState extends State<TelecomCompaniesView> {
  List<TelecomCompanyModel> _companies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  Future<void> _loadCompanies() async {
    final list = await TelecomCompaniesService.instance.getCompanies();
    if (mounted) {
      setState(() {
        _companies = list;
        _isLoading = false;
      });
    }
  }

  void _showAddOrEditDialog({TelecomCompanyModel? company, int? index}) {
    final isEditing = company != null && index != null;
    final nameController = TextEditingController(text: isEditing ? company.name : '');
    final prefixController = TextEditingController(text: isEditing ? company.prefix : '');

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            isEditing ? 'تعديل شركة الاتصالات' : 'إضافة شركة اتصالات جديدة',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'اسم الشركة',
                  hintText: 'مثال: يمن موبايل',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: prefixController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'مقدمة الرقم (الفلتر)',
                  hintText: 'مثال: 77 أو 71',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final name = nameController.text.trim();
                final prefix = prefixController.text.trim();

                if (name.isEmpty || prefix.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('يرجى ملء جميع الحقول المطلوبة', textAlign: TextAlign.center),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                Navigator.pop(ctx);

                if (isEditing) {
                  await TelecomCompaniesService.instance.updateCompany(index, name, prefix);
                } else {
                  await TelecomCompaniesService.instance.addCompany(name, prefix);
                }
                _loadCompanies();
              },
              child: Text(isEditing ? 'حفظ' : 'إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteCompany(int index, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'حذف شركة الاتصالات',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error),
          ),
          content: Text('هل أنت متأكد من حذف فلتر "$name"؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'حذف',
                style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await TelecomCompaniesService.instance.deleteCompany(index);
      _loadCompanies();
    }
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
            'شركات الاتصالات',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          centerTitle: false,
          actions: [
            IconButton(
              icon: const Icon(AppIcons.add, color: AppColors.textPrimary, size: 26),
              tooltip: 'إضافة شركة جديدة',
              onPressed: () => _showAddOrEditDialog(),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  SettingsCard(
                    children: List.generate(_companies.length, (index) {
                      final company = _companies[index];
                      final isLast = index == _companies.length - 1;

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            child: Row(
                              children: [
                                // اسم الشركة وتفاصيل مقدمة الرقم
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        company.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'مقدمة الرقم: ${company.prefix}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // زر الثلاث نقاط مع القائمة المنسدلة للتعديل والحذف
                                PopupMenuButton<String>(
                                  icon: const Icon(
                                    AppIcons.more,
                                    color: AppColors.textSecondary,
                                    size: 20,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _showAddOrEditDialog(company: company, index: index);
                                    } else if (value == 'delete') {
                                      _deleteCompany(index, company.name);
                                    }
                                  },
                                  itemBuilder: (ctx) => [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Directionality(
                                        textDirection: TextDirection.rtl,
                                        child: Row(
                                          children: const [
                                            Icon(AppIcons.edit, size: 18, color: AppColors.textPrimary),
                                            SizedBox(width: 10),
                                            Text('تعديل', style: TextStyle(fontSize: 14)),
                                          ],
                                        ),
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Directionality(
                                        textDirection: TextDirection.rtl,
                                        child: Row(
                                          children: const [
                                            Icon(AppIcons.deleteDb, size: 18, color: AppColors.error),
                                            SizedBox(width: 10),
                                            Text('حذف', style: TextStyle(fontSize: 14, color: AppColors.error)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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
