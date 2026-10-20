import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/app_result_card.dart';

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

    FocusScope.of(context).unfocus();

    setState(() {
      _results = [];
      _isLoading = true;
    });

    List<Map<String, dynamic>> dbResults =
        await DatabaseHelper.instance.searchByNumber(query);

    List<Map<String, dynamic>> separatedResults = [];
    for (var row in dbResults) {
      String namesStr = row['names'] ?? '';
      List<String> splitNames = namesStr
          .split(RegExp(r'[,،|]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

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
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextFormField(
                controller: _searchController,
                keyboardType: TextInputType.phone,
                textAlign: TextAlign.left,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.Secondary,
                  prefixIcon:
                      const Icon(Icons.dialpad, color: AppColors.primary),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  hintText: "أدخل الرقم المراد البحث عنه",
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
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
                    Text("بحث بالرقم",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: _buildResultsArea()),
      ],
    );
  }

  Widget _buildResultsArea() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 12),
            Text("جاري فحص وبحث السجلات بدقة...",
                style: TextStyle(color: Colors.blueGrey, fontSize: 14)),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return const Center(
          child: Text("لا توجد نتائج لعرضها حالياً",
              style: TextStyle(fontSize: 15, color: Colors.blueGrey)));
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 20),
      child: AppResultListContainer(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          for (final item in _results)
            AppResultTile(
              name: item['names'] ?? 'بدون اسم',
              phone: item['phone'] ?? '',
            ),
        ],
      ),
    );
  }
}
