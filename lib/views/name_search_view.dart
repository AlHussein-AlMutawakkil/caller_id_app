import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../core/theme/app_colors.dart';
import '../core/constants/app_constants.dart';

class NameSearchView extends StatefulWidget {
  const NameSearchView({super.key});

  @override
  State<NameSearchView> createState() => _NameSearchViewState();
}

class _NameSearchViewState extends State<NameSearchView> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  String _selectedCompany = "الكل";

  void _search() async {
    String query = _searchController.text.trim();
    if (query.isEmpty) return;

    // السحر هنا: إغلاق لوحة المفاتيح وسحب مؤشر الكتابة فوراً عند الضغط على بحث
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    String? prefix = _selectedCompany == "الكل" ? null : AppConstants.companyPrefixes[_selectedCompany];
    List<Map<String, dynamic>> dbResults = await DatabaseHelper.instance.searchByName(query, companyPrefix: prefix);

    setState(() {
      _results = dbResults;
      _isLoading = false;
    });
  }

  String _extractMatchingName(String allNames, String searchQuery) {
    List<String> list = allNames.split(',').map((e) => e.trim()).toList();
    String match = list.firstWhere(
          (name) => name.toLowerCase().contains(searchQuery.toLowerCase()),
      orElse: () => list.first,
    );
    return match;
  }

  void _showNamesDialog(BuildContext context, String phone, String allNames) {
    List<String> namesList = allNames.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          backgroundColor: Colors.white,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "الأسماء المتعلقة بـ  $phone",
                  style: const TextStyle(color: AppColors.textDark, fontSize: 20),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 15),
                const Divider(height: 1, color: Colors.grey),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: namesList.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          namesList[index],
                          style: const TextStyle(color: AppColors.primary, fontSize: 18),
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String currentQuery = _searchController.text.trim();

    return CustomScrollView(
      // ميزة ذكية: إخفاء لوحة المفاتيح تلقائياً بمجرد لمس الشاشة والتمرير لأسفل
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Column(
              children: [
                // const Text(
                //   "البحث بالإسم",
                //   style: TextStyle(fontSize: 24, color: AppColors.primary, fontWeight: FontWeight.w400),
                // ),
                // const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedCompany,
                  decoration: const InputDecoration(labelText: "إختر شركة الإتصالات", border: UnderlineInputBorder()),
                  items: AppConstants.companies.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setState(() => _selectedCompany = v!),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _searchController,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18),
                  keyboardType: TextInputType.text,
                  decoration:  InputDecoration(
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    prefixIcon: const Icon(Icons.person_search, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),

                    hintText: "أدخل الاسم هنا",
                    // focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
                    // enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _search,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search, color: Colors.white),
                        SizedBox(width: 8),
                        Text("بحث بالإسم", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        if (_isLoading)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            ),
          ),

        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final item = _results[index];
                String rawNames = item['names'] ?? '';
                bool hasMultipleNames = rawNames.contains(',');
                String matchedName = _extractMatchingName(rawNames, currentQuery);

                return InkWell(
                  onTap: hasMultipleNames ? () => _showNamesDialog(context, item['phone'], rawNames) : null,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey[200]!, width: 0.8),
                    ),
                    child: Row(
                      children: [
                        if (hasMultipleNames)
                          const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 24)
                        else
                          const SizedBox(width: 24),

                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                matchedName,
                                style: const TextStyle(
                                  color: AppColors.textDark,
                                  fontWeight: FontWeight.normal,
                                  fontSize: 22,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item['phone'],
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.underline,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                      ],
                    ),
                  ),
                );
              },
              childCount: _results.length,
            ),
          ),
        ),
      ],
    );
  }
}

