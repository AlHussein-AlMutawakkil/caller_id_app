import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart' as ov;
import 'database_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  int _totalRecords = 0;
  int _currentIndex = 0; // 0: سجل الأرقام, 1: البحث بالاسم
  String _selectedCompany = "الكل";
  final List<String> _companies = ["الكل", "يمن موبايل", "سبأفون", "يو", "واي", "ثابت"];
  final Map<String, String> _companyPrefixes = {
    "يمن موبايل": "77",
    "سبأفون": "71",
    "يو": "73",
    "واي": "70",
    "ثابت": "0",
  };

  @override
  void initState() {
    super.initState();
    _updateDatabaseCounter();
  }

  Future<void> _updateDatabaseCounter() async {
    int count = await DatabaseHelper.instance.getTotalRecordsCount();
    if (mounted) {
      setState(() => _totalRecords = count);
    }
  }

  void _search() async {
    String query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isLoading = true);
    List<Map<String, dynamic>> results = [];

    if (_currentIndex == 0) {
      results = await DatabaseHelper.instance.searchByNumber(query);
    } else {
      String? prefix = _selectedCompany == "الكل" ? null : _companyPrefixes[_selectedCompany];
      results = await DatabaseHelper.instance.searchByName(query, companyPrefix: prefix);
    }

    setState(() {
      _results = results;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: _buildDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E232C),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "دليل اليمن",
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: Column(
        children: [
          // قسم العداد المطابق للفيديو
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 0.5)),
            ),
            child: Column(
              children: [
                const Text("يوجد حالياً", style: TextStyle(fontSize: 14, color: Colors.black54)),
                const SizedBox(height: 5),
                Text(
                  _totalRecords.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},'),
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1E232C)),
                ),
                const SizedBox(height: 5),
                const Text("رقم", style: TextStyle(fontSize: 14, color: Colors.black54)),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                child: Column(
                  children: [
                    if (_currentIndex == 1) ...[
                      DropdownButtonFormField<String>(
                        value: _selectedCompany,
                        decoration: const InputDecoration(
                          labelText: "إختر شركة الإتصالات",
                          labelStyle: TextStyle(color: Colors.grey),
                          border: UnderlineInputBorder(),
                        ),
                        items: _companies.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value, textDirection: TextDirection.rtl),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() => _selectedCompany = newValue!);
                        },
                      ),
                      const SizedBox(height: 15),
                    ],
                    TextField(
                      controller: _searchController,
                      textAlign: TextAlign.center,
                      keyboardType: _currentIndex == 0 ? TextInputType.phone : TextInputType.text,
                      decoration: InputDecoration(
                        hintText: _currentIndex == 0 ? "أدخل الرقم هنا" : "أدخل الاسم هنا",
                        hintStyle: const TextStyle(color: Colors.grey),
                        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF1E232C))),
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _search,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E232C),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                        child: const Text("بحث", style: TextStyle(color: Colors.white, fontSize: 20)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_isLoading)
                      const CircularProgressIndicator(color: Color(0xFF1E232C))
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _results.length,
                        separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[300]),
                        itemBuilder: (context, index) {
                          final item = _results[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              item['names'],
                              style: const TextStyle(color: Color(0xFF1E232C), fontWeight: FontWeight.bold, fontSize: 18),
                              textDirection: TextDirection.rtl,
                            ),
                            subtitle: Text(
                              item['phone'],
                              style: const TextStyle(color: Colors.blue, fontSize: 16),
                              textDirection: TextDirection.rtl,
                            ),
                            onTap: () {
                              if (_currentIndex == 1) {
                                _showDetailsDialog(item['phone']);
                              }
                            },
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: const Color(0xFF1E232C),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey[400],
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            _results = [];
            _searchController.clear();
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.phone_android), label: "سجل الأرقام"),
          BottomNavigationBarItem(icon: Icon(Icons.person_search), label: "البحث بالاسم"),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF1E232C)),
            child: Center(
              child: Text(
                "دليل اليمن",
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text("إعادة تحميل قاعدة البيانات"),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.update),
            title: const Text("تحديث قاعدة البيانات"),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.visibility),
            title: const Text("عرض اسم المتصل"),
            trailing: Switch(value: true, onChanged: (v) {}),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text("حول"),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showDetailsDialog(String phone) async {
    setState(() => _isLoading = true);
    final relatedNames = await DatabaseHelper.instance.searchByNumber(phone);
    setState(() => _isLoading = false);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("الأسماء المتعلقة بـ $phone", textDirection: TextDirection.rtl, style: const TextStyle(color: Color(0xFF1E232C))),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: relatedNames.length,
            itemBuilder: (context, index) => ListTile(
              title: Text(relatedNames[index]['names'], textDirection: TextDirection.rtl),
              leading: const Icon(Icons.person, color: Colors.grey),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("إغلاق", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
