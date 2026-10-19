import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'core/theme/app_colors.dart';

class CallerOverlayWindow extends StatefulWidget {
  const CallerOverlayWindow({super.key});

  @override
  State<CallerOverlayWindow> createState() => _CallerOverlayWindowState();
}

class _CallerOverlayWindowState extends State<CallerOverlayWindow> {
  String _phone = "";
  List<String> _namesList = [];
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();

    // الاستماع المباشر للبيانات القادمة من الخدمة الخلفية
    FlutterOverlayWindow.overlayListener.listen((data) {
      if (data != null && data is Map) {
        _processData(data);
      }
    });
  }

  // دالة موحدة لمعالجة البيانات
  void _processData(Map data) {
    if (!mounted) return;
    setState(() {
      _phone = data['phone']?.toString() ?? "";
      String rawNames = data['name']?.toString() ?? "";
      _namesList = rawNames
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _isExpanded ? _buildExpandedView() : _buildCollapsedView(),
        ),
      ),
    );
  }

  // 1. التصميم المصغر
  Widget _buildCollapsedView() {
    return GestureDetector(
      onTap: () => setState(() => _isExpanded = true),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.close, color: Colors.black, size: 22),
              onPressed: () async => await FlutterOverlayWindow.closeOverlay(),
            ),
            const Icon(Icons.search, color: AppColors.textDark, size: 24),
            const SizedBox(width: 10),
            Text(
              _phone.isEmpty ? "جاري البحث..." : _phone,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
            const SizedBox(width: 15),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFF0A5C66),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.security, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  // 2. التصميم الموسع
  Widget _buildExpandedView() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () async => await FlutterOverlayWindow.closeOverlay(),
              ),
              Text(
                _phone,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_up, color: Colors.grey),
                onPressed: () => setState(() => _isExpanded = false),
              ),
            ],
          ),
          const Divider(color: Colors.grey),

          // عرض حالة التحميل أو النتائج
          if (_phone.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(),
            )
          else if (_namesList.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text("لا توجد بيانات", style: TextStyle(fontSize: 18, color: Colors.grey)),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _namesList.length,
                itemBuilder: (context, index) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[100]!, width: 1))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.person_add_alt_1, color: AppColors.textDark),
                          onPressed: () {},
                        ),
                        Expanded(
                          child: Text(
                            _namesList[index],
                            style: const TextStyle(fontSize: 18, color: AppColors.primary, fontWeight: FontWeight.w400),
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}