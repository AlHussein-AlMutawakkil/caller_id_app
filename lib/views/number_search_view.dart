import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../core/theme/app_colors.dart';

class NumberSearchView extends StatefulWidget {
  const NumberSearchView({super.key});

  @override
  State<NumberSearchView> createState() => _NumberSearchViewState();
}

class _NumberSearchViewState extends State<NumberSearchView> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;

  void _search() async {
    String query = _searchController.text.trim();
    if (query.isEmpty) return;

    // السحر هنا: إغلاق لوحة المفاتيح وسحب مؤشر الكتابة فوراً عند الضغط على بحث
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    List<Map<String, dynamic>> dbResults = await DatabaseHelper.instance.searchByNumber(query);

    List<Map<String, dynamic>> separatedResults = [];
    for (var row in dbResults) {
      String namesStr = row['names'] ?? '';
      List<String> splitNames = namesStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

      for (var name in splitNames) {
        separatedResults.add({
          'names': name,
          'phone': row['phone'] ?? query,
        });
      }
    }

    setState(() {
      _results = separatedResults;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      // ميزة ذكية: إخفاء لوحة المفاتيح تلقائياً بمجرد لمس الشاشة والتمرير لأسفل
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Column(
              children: [
                const Text(
                  "البحث بالرقم",
                  style: TextStyle(fontSize: 24, color: AppColors.primary, fontWeight: FontWeight.w400),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _searchController,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, letterSpacing: 1.0),
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: "أدخل الرقم هنا",
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _search,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    child: const Text("بحث", style: TextStyle(color: Colors.white, fontSize: 18)),
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
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey[200]!, width: 0.8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item['names'],
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