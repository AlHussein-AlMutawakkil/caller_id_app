import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'core/theme/app_colors.dart';

class CallerOverlayWindow extends StatefulWidget {
  const CallerOverlayWindow({super.key});

  @override
  State<CallerOverlayWindow> createState() => _CallerOverlayWindowState();
}

class _CallerOverlayWindowState extends State<CallerOverlayWindow> {
  String _phone = "";
  List<String> _namesList = [];
  bool _isExpanded = false; // تبدأ مغلقة افتراضياً عند ورود المكالمة كما طلب المستخدم

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

  // دالة موحدة لمعالجة وتفكيك البيانات مع دعم الفواصل العربية والإنجليزية
  void _processData(Map data) {
    if (!mounted) return;
    setState(() {
      _phone = data['phone']?.toString().trim() ?? "";
      String rawNames = data['name']?.toString().trim() ?? "";
      _namesList = rawNames
          .split(RegExp(r'[,،|]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    });
  }

  // إضافة الرقم والاسم مباشرة إلى جهات الاتصال في نظام أندرويد
  Future<void> _addToContacts({required String name, required String phone}) async {
    final cleanName = (name.isEmpty || name == "رقم غير مسجل") ? "" : name;
    try {
      final intent = AndroidIntent(
        action: 'android.intent.action.INSERT',
        data: 'content://contacts/people',
        arguments: <String, dynamic>{
          'name': cleanName,
          'phone': phone,
        },
        flags: const <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      await intent.launch();
    } catch (e) {
      // نسخ الرقم كحل احتياطي في حال تعذر فتح شاشة إضافة جهات الاتصال
      await Clipboard.setData(ClipboardData(text: phone));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تعذر فتح جهات الاتصال مباشرة. تم نسخ الرقم: $phone',
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // نسخ الرقم إلى الحافظة
  void _copyPhone(BuildContext context, String phone) {
    if (phone.isEmpty) return;
    Clipboard.setData(ClipboardData(text: phone));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم نسخ الرقم: $phone',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOut,
            child: _isExpanded ? _buildExpandedView() : _buildCollapsedView(),
          ),
        ),
      ),
    );
  }

  // 1. التصميم المصغر (يعرض الرقم فقط كما طلب المستخدم بدون أي أسماء أثناء الطي)
  Widget _buildCollapsedView() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => setState(() => _isExpanded = true),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // أيقونة الهاتف الدائرية
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withOpacity(0.08),
                  child: const Icon(
                    Icons.phone_in_talk_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // عرض الرقم فقط كما طلب المستخدم بدقة تامة
                Expanded(
                  child: Text(
                    _phone.isEmpty ? "جاري البحث..." : _phone,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontFamily: 'Cairo',
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // سهم التوسيع الأنيق
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.scaffoldBackground,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.cardBorder, width: 1),
                  ),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),

                // زر إغلاق النافذة العائمة
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'إغلاق',
                  onPressed: () async => await FlutterOverlayWindow.closeOverlay(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 2. التصميم الموسع (مع حماية تامة من تجاوز المساحة RenderFlex Overflow)
  Widget _buildExpandedView() {
    final bool isUnregistered = _namesList.isEmpty ||
        (_namesList.length == 1 && _namesList.first == "رقم غير مسجل");
    final double availableHeight = MediaQuery.of(context).size.height;
    final double maxContainerHeight = availableHeight > 150 ? (availableHeight - 20) : 380;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      constraints: BoxConstraints(maxHeight: maxContainerHeight),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // شريط الرأس: يعرض الرقم فقط مع أزرار التحكم
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.phone_outlined,
                    size: 18,
                    color: Color(0xFF1E88E5),
                  ),
                  const SizedBox(width: 8),
                  // عرض الرقم فقط كما طلب المستخدم بدقة
                  Text(
                    _phone.isEmpty ? "كاشف الأرقام" : _phone,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  // عرض عدد الأسماء الموجودة في دائرة بجانب الرقم/العنوان
                  if (_namesList.length > 1) ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${_namesList.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  // زر تصغير النافذة
                  IconButton(
                    icon: const Icon(
                      Icons.keyboard_arrow_up_rounded,
                      color: AppColors.textSecondary,
                      size: 24,
                    ),
                    tooltip: 'تصغير',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => setState(() => _isExpanded = false),
                  ),
                  // زر إغلاق النافذة
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textSecondary,
                      size: 22,
                    ),
                    tooltip: 'إغلاق',
                    visualDensity: VisualDensity.compact,
                    onPressed: () async => await FlutterOverlayWindow.closeOverlay(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 0.8, color: AppColors.divider),

            // محتوى البطاقة: حالة التحميل أو النتائج أو رقم غير مسجل
            if (_phone.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2.8,
                      ),
                      SizedBox(height: 12),
                      Text(
                        "جاري فحص الرقم...",
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (isUnregistered)
              _buildUnregisteredTile()
            else
              Flexible(child: _buildNamesList()),
          ],
        ),
      ),
    );
  }

  // أزرار إجراءات نظيفة ومدمجة بدون أي حلقات أو إطارات دائرية
  Widget _buildCompactActionButton({
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    required String tooltip,
    double iconSize = 20,
  }) {
    return IconButton(
      icon: Icon(icon, size: iconSize, color: iconColor),
      tooltip: tooltip,
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }

  // عنصر عرض "رقم غير مسجل"
  Widget _buildUnregisteredTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.disabled.withOpacity(0.18),
            child: const Icon(
              Icons.person_off_rounded,
              color: AppColors.textSecondary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "رقم غير مسجل",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.phone_outlined,
                      size: 13,
                      color: Color(0xFF1E88E5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _phone,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E88E5),
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // زر الإضافة لجهات الاتصال المدمج
          _buildCompactActionButton(
            icon: Icons.person_add_alt_1_rounded,
            iconColor: AppColors.primary,
            tooltip: 'إضافة لجهات الاتصال',
            onTap: () => _addToContacts(name: "", phone: _phone),
          ),
          const SizedBox(width: 4),
          // زر نسخ الرقم المدمج
          _buildCompactActionButton(
            icon: Icons.copy_rounded,
            iconColor: AppColors.textSecondary,
            tooltip: 'نسخ الرقم',
            onTap: () => _copyPhone(context, _phone),
          ),
        ],
      ),
    );
  }

  // قائمة الأسماء المعتمدة: عرض عدد الأسماء في دائرة بجانب الاسم وإزالة الحلقات
  Widget _buildNamesList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      itemCount: _namesList.length,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        thickness: 0.8,
        color: AppColors.divider,
      ),
      itemBuilder: (context, index) {
        final String name = _namesList[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // أفاتار الشخص الدائري المعتمد
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withOpacity(0.07),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // الاسم والرقم: عرض الاسم وبجانبه عدد الأسماء في دائرة
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              fontFamily: 'Cairo',
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // عرض عدد الأسماء الموجودة في دائرة بجانب الاسم
                        if (_namesList.length > 1 && index == 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${_namesList.length}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.phone_outlined,
                          size: 13,
                          color: Color(0xFF1E88E5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _phone,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E88E5),
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // زر إضافة إلى جهات الاتصال المفعل المدمج (بدون حلقة)
              _buildCompactActionButton(
                icon: Icons.person_add_alt_1_rounded,
                iconColor: AppColors.primary,
                tooltip: 'إضافة لجهات الاتصال',
                onTap: () => _addToContacts(name: name, phone: _phone),
              ),
              const SizedBox(width: 4),

              // زر نسخ الرقم المدمج (بدون حلقة)
              _buildCompactActionButton(
                icon: Icons.copy_rounded,
                iconColor: AppColors.textSecondary,
                tooltip: 'نسخ الرقم',
                onTap: () => _copyPhone(context, _phone),
              ),
            ],
          ),
        );
      },
    );
  }
}