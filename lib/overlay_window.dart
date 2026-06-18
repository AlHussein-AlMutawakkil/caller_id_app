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

  // السحر هنا: هذا المتغير يحدد هل النافذة مصغرة أم موسعة
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    FlutterOverlayWindow.overlayListener.listen((data) {
      if (data != null && data is Map) {
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        // AnimatedSize يعطي حركة تمدد ناعمة جداً واحترافية
        child: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _isExpanded ? _buildExpandedView() : _buildCollapsedView(),
        ),
      ),
    );
  }

  // ==========================================
  // 1. التصميم المصغر (الشريط الصغير الأنيق)
  // ==========================================
  Widget _buildCollapsedView() {
    return GestureDetector(
      // عند الضغط على الشريط الصغير، تتوسع النافذة
      onTap: () => setState(() => _isExpanded = true),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30), // حواف دائرية مثل الكبسولة
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min, // يأخذ مساحة المحتوى فقط
          children: [
            // زر الإغلاق النهائي
            IconButton(
              icon: const Icon(Icons.close, color: Colors.black, size: 22),
              onPressed: () async {
                await FlutterOverlayWindow.closeOverlay();
              },
            ),
            const Icon(Icons.search, color: AppColors.textDark, size: 24),
            const SizedBox(width: 10),
            Text(
              _phone,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
            const SizedBox(width: 15),
            // الشعار (الدرع الأخضر)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFF0A5C66), // لون مقارب للأخضر/النيلي
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.security, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 2. التصميم الموسع (قائمة الأسماء الثابتة)
  // ==========================================
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
          // الشريط العلوي للنافذة الموسعة
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // زر الإغلاق النهائي
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () async {
                  await FlutterOverlayWindow.closeOverlay();
                },
              ),
              Text(
                _phone,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              // زر تصغير النافذة (العودة للشريط الصغير)
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_up, color: Colors.grey),
                onPressed: () => setState(() => _isExpanded = false),
              ),
            ],
          ),
          const Divider(color: Colors.grey),

          // قائمة الأسماء المفتتة (ثابتة بدون Overflow)
          if (_namesList.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text("جاري جلب البيانات...", style: TextStyle(fontSize: 18, color: Colors.grey)),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _namesList.length,
                itemBuilder: (context, index) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey[100]!, width: 1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.person_add_alt_1, color: AppColors.textDark),
                          onPressed: () {
                            // منطق حفظ جهة الاتصال
                          },
                        ),
                        Expanded(
                          child: Text(
                            _namesList[index],
                            style: const TextStyle(
                              fontSize: 18,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w400,
                            ),
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