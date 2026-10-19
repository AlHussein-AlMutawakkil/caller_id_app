import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppModalDialog extends StatelessWidget {
  final String? title;
  final Widget child;
  final String? actionButtonText;
  final VoidCallback? onActionButtonPressed;
  final Color? actionButtonColor;
  final Color? actionButtonTextColor;
  final bool showCloseButton;
  final VoidCallback? onClose;

  const AppModalDialog({
    super.key,
    this.title,
    required this.child,
    this.actionButtonText,
    this.onActionButtonPressed,
    this.actionButtonColor,
    this.actionButtonTextColor,
    this.showCloseButton = true,
    this.onClose,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    required Widget child,
    String? actionButtonText,
    VoidCallback? onActionButtonPressed,
    Color? actionButtonColor,
    Color? actionButtonTextColor,
    bool showCloseButton = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AppModalDialog(
          title: title,
          actionButtonText: actionButtonText,
          onActionButtonPressed: onActionButtonPressed,
          actionButtonColor: actionButtonColor,
          actionButtonTextColor: actionButtonTextColor,
          showCloseButton: showCloseButton,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      elevation: 0,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // شريط علوي يحتوي على زر الإغلاق X والعنوان إن وجد
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (showCloseButton)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary, size: 24),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onClose ?? () => Navigator.of(context).pop(),
                  )
                else
                  const SizedBox(width: 24),
                if (title != null)
                  Expanded(
                    child: Text(
                      title!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  )
                else
                  const Spacer(),
                const SizedBox(width: 24), // توازن مع زر الإغلاق
              ],
            ),
            const SizedBox(height: 14),

            // محتوى النافذة المنبثقة
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: child,
              ),
            ),

            // الزر السفلي (يظهر فقط عند تمرير actionButtonText)
            if (actionButtonText != null) ...[
              const SizedBox(height: 18),
              SizedBox(
                height: 50,
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: actionButtonColor ?? AppColors.primary,
                    foregroundColor: actionButtonTextColor ?? Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: onActionButtonPressed,
                  child: Text(
                    actionButtonText!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
