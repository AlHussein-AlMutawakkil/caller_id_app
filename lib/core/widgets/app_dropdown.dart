import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// مكون القائمة المنسدلة المشترك (مطابق لتصميم الصورة المرفقة)
/// يتميز ببطاقة عائمة بيضاء بحواف دائرية، خطوط فاصلة دقيقة،
/// وأيقونة اختيار دائرية سوداء للعنصر المحدد.
class AppDropdown<T> extends StatelessWidget {
  final T? value;
  final List<T> items;
  final String Function(T item)? itemLabel;
  final ValueChanged<T> onChanged;
  final String? hintText;
  final IconData? prefixIcon;
  final bool isExpanded;
  final double height;

  const AppDropdown({
    super.key,
    required this.value,
    required this.items,
    this.itemLabel,
    required this.onChanged,
    this.hintText,
    this.prefixIcon,
    this.isExpanded = true,
    this.height = 52.0,
  });

  /// دالة لإظهار قائمة الاختيار المنسدلة من أي مكان في التطبيق
  static Future<T?> show<T>({
    required BuildContext context,
    required List<T> items,
    T? selectedItem,
    String Function(T item)? itemLabel,
    String? title,
  }) async {
    return showDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (ctx) {
        return Directionality(
          textDirection: Directionality.of(context),
          child: _AppDropdownMenuDialog<T>(
            items: items,
            selectedItem: selectedItem,
            itemLabel: itemLabel,
            title: title,
          ),
        );
      },
    );
  }

  void _openSelectionMenu(BuildContext context) async {
    final selected = await show<T>(
      context: context,
      items: items,
      selectedItem: value,
      itemLabel: itemLabel,
      title: hintText,
    );

    if (selected != null) {
      onChanged(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayText = value != null
        ? (itemLabel != null ? itemLabel!(value as T) : value.toString())
        : (hintText ?? '');

    final isSelected = value != null;

    return InkWell(
      onTap: () => _openSelectionMenu(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.Secondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.transparent),
        ),
        child: Row(
          children: [
            if (prefixIcon != null) ...[
              Icon(prefixIcon, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                displayText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

/// البطاقة المنبثقة للاختيار (مطابقة للتصميم تماماً)
class _AppDropdownMenuDialog<T> extends StatelessWidget {
  final List<T> items;
  final T? selectedItem;
  final String Function(T item)? itemLabel;
  final String? title;

  const _AppDropdownMenuDialog({
    super.key,
    required this.items,
    this.selectedItem,
    this.itemLabel,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.70,
          maxWidth: 380,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.cardBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 6),
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              thickness: 0.8,
              color: AppColors.divider,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              final isCurrentSelected =
                  selectedItem != null && item == selectedItem;
              final label =
                  itemLabel != null ? itemLabel!(item) : item.toString();

              return InkWell(
                onTap: () => Navigator.of(context).pop(item),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: Row(
                    children: [
                      // أيقونة الاختيار الدائرية السوداء (مطابقة للصورة 1)
                      if (isCurrentSelected)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primary,
                          size: 22,
                        )
                      else
                        const SizedBox(width: 22),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isCurrentSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
