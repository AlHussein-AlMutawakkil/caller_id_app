import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/database_helper.dart';
import '../core/theme/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/app_icons.dart';
import '../core/widgets/app_modal_dialog.dart';
import '../core/widgets/app_dropdown.dart';
import '../core/widgets/app_result_card.dart';

class NameSearchView extends StatefulWidget {
  const NameSearchView({super.key});

  @override
  State<NameSearchView> createState() => _NameSearchViewState();
}

class _NameSearchViewState extends State<NameSearchView>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String _selectedCompany = "الكل";

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _search() async {
    String query = _searchController.text.trim();
    if (query.isEmpty) return;

    // إغلاق لوحة المفاتيح وسحب التركيز فوراً
    _searchFocusNode.unfocus();
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    String? prefix = _selectedCompany == "الكل"
        ? null
        : AppConstants.companyPrefixes[_selectedCompany];
    List<Map<String, dynamic>> dbResults = await DatabaseHelper.instance
        .searchByName(query, companyPrefix: prefix);

    final enrichedResults = await DatabaseHelper.instance
        .enrichResultsWithMultipleNames(dbResults);

    if (mounted) {
      setState(() {
        _results = enrichedResults;
        _isLoading = false;
      });
    }
  }

  String _extractMatchingName(String allNames, String searchQuery) {
    List<String> list = allNames
        .split(RegExp(r'[,،|\n]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (list.isEmpty) return allNames;
    String match = list.firstWhere(
      (name) => name.toLowerCase().contains(searchQuery.toLowerCase()),
      orElse: () => list.first,
    );
    return match;
  }

  Future<void> _showNamesDialog(
      BuildContext context, String phone, String allNames,
      {List<String>? preloadedNames}) async {
    // سحب التركيز تماماً قبل فتح الحوار
    _searchFocusNode.unfocus();
    FocusScope.of(context).unfocus();

    final Set<String> distinctNames = {};

    void addNamesFromString(String str) {
      final parts = str
          .split(RegExp(r'[,،|\n]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty);
      distinctNames.addAll(parts);
    }

    if (preloadedNames != null && preloadedNames.isNotEmpty) {
      distinctNames.addAll(preloadedNames);
    } else {
      addNamesFromString(allNames);

      // استعلام فوري لقاعدة البيانات برقم الهاتف لجلب كافة الأسماء المسجلة لهذا الرقم عبر جميع الصفوف
      try {
        final dbResults = await DatabaseHelper.instance.searchByNumber(phone);
        for (final row in dbResults) {
          final namesStr = row['names']?.toString() ?? '';
          addNamesFromString(namesStr);
        }
      } catch (e) {
        debugPrint("خطأ أثناء جلب كافة الأسماء المرتبطة بالرقم: $e");
      }
    }

    final List<String> namesList = distinctNames.toList();
    if (!context.mounted) return;

    await AppModalDialog.show(
      context: context,
      title: "الأسماء المرتبطة بالرقم",
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // شارة رقم الهاتف مع زر النسخ بجانب الرقم العلوي
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.scaffoldBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.phone_android_rounded,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  phone,
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: phone));
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'تم نسخ الرقم: $phone',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: AppColors.primary,
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.copy_rounded,
                      size: 17,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: AppColors.divider),
          // قائمة الأسماء المرتبطة
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: namesList.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: AppColors.divider,
              indent: 10,
              endIndent: 10,
            ),
            itemBuilder: (context, index) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.scaffoldBackground,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        namesList[index],
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          height: 1.35,
                        ),
                        softWrap: true,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );

    // بعد إغلاق الحوار (بالـ X أو النقر بالخارج): نسحب التركيز فوراً للحفاظ على موضع التمرير
    _searchFocusNode.unfocus();
    if (context.mounted) {
      FocusScope.of(context).unfocus();
    }
  }

  Widget _buildResultsCountHeader(int count) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(AppColors.isDarkMode ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.format_list_bulleted_rounded,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                "نتائج البحث",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: count > 0
                  ? AppColors.primary.withOpacity(AppColors.isDarkMode ? 0.2 : 0.08)
                  : AppColors.error.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "$count ${count == 1 ? 'نتيجة' : (count == 2 ? 'نتيجتان' : 'نتائج')}",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: count > 0 ? AppColors.primary : AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyResultsIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 46,
            color: AppColors.textSecondary.withOpacity(0.6),
          ),
          const SizedBox(height: 12),
          Text(
            "لم يتم العثور على أي نتائج (0)",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "تأكد من صحة الاسم المدخل أو اختر 'الكل' في شركة الاتصالات",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    String currentQuery = _searchController.text.trim();

    return CustomScrollView(
      controller: _scrollController,
      key: const PageStorageKey<String>('name_search_scroll_view'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Column(
              children: [
                AppDropdown<String>(
                  value: _selectedCompany,
                  hintText: "إختر شركة الإتصالات",
                  prefixIcon: AppIcons.telecom,
                  items: AppConstants.companies,
                  itemLabel: (s) => s,
                  onChanged: (v) {
                    _searchFocusNode.unfocus();
                    FocusScope.of(context).unfocus();
                    setState(() => _selectedCompany = v);
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  autofocus: false,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: AppColors.textPrimary),
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.Secondary,
                    prefixIcon: Icon(Icons.person_search,
                        color: AppColors.primary),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    hintText: "أدخل الاسم هنا",
                    hintStyle: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonBackground,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _search,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search, color: Colors.white),
                        SizedBox(width: 8),
                        Text("بحث بالإسم",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_hasSearched && !_isLoading)
          SliverToBoxAdapter(
            child: _buildResultsCountHeader(_results.length),
          ),
        if (_isLoading)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary)),
            ),
          ),
        if (_hasSearched && !_isLoading && _results.isEmpty)
          SliverToBoxAdapter(
            child: _buildEmptyResultsIndicator(),
          ),
        if (_results.isNotEmpty)
          SliverToBoxAdapter(
            child: AppResultListContainer(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                for (int index = 0; index < _results.length; index++) ...[
                  () {
                    final item = _results[index];
                    String rawNames = item['names'] ?? '';
                    bool hasMultipleNames = item['hasMultipleNames'] ?? false;
                    List<String> associatedNames =
                        (item['allAssociatedNames'] as List<dynamic>?)
                                ?.map((e) => e.toString())
                                .toList() ??
                            [];
                    String matchedName =
                        _extractMatchingName(rawNames, currentQuery);

                    return AppResultTile(
                      name: matchedName,
                      phone: item['phone'] ?? '',
                      hasMultipleNames: hasMultipleNames,
                      showCopyButton: false, // إخفاء أيقونة النسخ نهائياً من نتائج البحث بالاسم
                      onTap: hasMultipleNames
                          ? () => _showNamesDialog(
                                context,
                                item['phone'],
                                rawNames,
                                preloadedNames: associatedNames,
                              )
                          : null,
                      onMoreNamesPressed: hasMultipleNames
                          ? () => _showNamesDialog(
                                context,
                                item['phone'],
                                rawNames,
                                preloadedNames: associatedNames,
                              )
                          : null,
                    );
                  }(),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
