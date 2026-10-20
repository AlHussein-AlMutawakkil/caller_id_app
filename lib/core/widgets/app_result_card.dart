import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

/// وعاء قائمة النتائج والبطاقات المشتركة (مطابق لتصميم الصورة 2)
/// يعرض بطاقة بيضاء موحدة بحواف دائرية وظل ناعم، تفصل بين عناصرها خطوط أفقية دقيقة.
class AppResultListContainer extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? margin;

  const AppResultListContainer({
    super.key,
    required this.children,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < children.length; i++) ...[
              if (i > 0)
                const Divider(
                  height: 1,
                  thickness: 0.8,
                  color: AppColors.divider,
                ),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// عنصر صف النتيجة الفردي (مخصص لنتائج البحث بالاسم والرقم)
class AppResultTile extends StatelessWidget {
  final String name;
  final String phone;
  final VoidCallback? onTap;
  final bool hasMultipleNames;
  final int? namesCount;
  final VoidCallback? onMoreNamesPressed;
  final bool showCopyButton;

  const AppResultTile({
    super.key,
    required this.name,
    required this.phone,
    this.onTap,
    this.hasMultipleNames = false,
    this.namesCount,
    this.onMoreNamesPressed,
    this.showCopyButton = true,
  });

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: phone));
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? (hasMultipleNames ? onMoreNamesPressed : null),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // أيقونة الأفاتار الرمزية
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withOpacity(0.07),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),

              // الاسم والرقم
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.phone_outlined,
                          size: 14,
                          color: Color(0xFF1E88E5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          phone,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E88E5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // زر نسخ الرقم
              if (showCopyButton)
                IconButton(
                  icon: const Icon(
                    Icons.copy_rounded,
                    size: 19,
                    color: AppColors.textSecondary,
                  ),
                  tooltip: 'نسخ الرقم',
                  onPressed: () => _copyToClipboard(context),
                ),

              // شارة / سهم الأسماء المتعددة إن وجدت
              if (hasMultipleNames)
                IconButton(
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textSecondary,
                    size: 24,
                  ),
                  tooltip: 'عرض الأسماء المرتبطة',
                  onPressed: onMoreNamesPressed,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
