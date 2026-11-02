import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:android_intent_plus/android_intent.dart';
import '../../core/services/activation_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_dropdown.dart';

class AdminActivationView extends StatefulWidget {
  final String? initialRequestCode;

  const AdminActivationView({super.key, this.initialRequestCode});

  @override
  State<AdminActivationView> createState() => _AdminActivationViewState();
}

class _AdminActivationViewState extends State<AdminActivationView> {
  final TextEditingController _requestCodeController = TextEditingController();
  ActivationDuration _selectedDuration = ActivationDuration.lifetime;
  String? _generatedCode;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialRequestCode != null && widget.initialRequestCode!.isNotEmpty) {
      _requestCodeController.text = widget.initialRequestCode!;
    }
  }

  @override
  void dispose() {
    _requestCodeController.dispose();
    super.dispose();
  }

  void _pasteRequestCode() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      setState(() {
        _requestCodeController.text = data.text!.trim();
        _errorMessage = null;
      });
    }
  }

  void _generateCode() {
    final reqCode = _requestCodeController.text.trim();
    final cleanReq = reqCode.replaceAll('-', '').replaceAll(' ', '');

    if (cleanReq.length != 12) {
      setState(() {
        _errorMessage = 'كود غير صحيح (يجب أن يكون 12 خانة)';
        _generatedCode = null;
      });
      return;
    }

    try {
      final code = ActivationService.instance.generateActivationCode(
        requestCode: reqCode,
        duration: _selectedDuration,
      );

      setState(() {
        _generatedCode = code;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'خطأ أثناء التوليد: $e';
        _generatedCode = null;
      });
    }
  }

  void _copyGeneratedCode() {
    if (_generatedCode == null) return;
    Clipboard.setData(ClipboardData(text: _generatedCode!));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'تم النسخ بنجاح',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _shareViaWhatsApp() async {
    if (_generatedCode == null) return;
    final message =
        'كود تفعيل تطبيق كاشف الأرقام الخاص بك:\n\n$_generatedCode\n\nالمدة: ${_selectedDuration.labelAr}';

    try {
      final intent = AndroidIntent(
        action: 'android.intent.action.SEND',
        type: 'text/plain',
        arguments: {'android.intent.extra.TEXT': message},
      );
      await intent.launch();
    } catch (_) {
      Clipboard.setData(ClipboardData(text: message));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم نسخ الرسالة للحافظة'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: AppBar(
          backgroundColor: AppColors.scaffoldBackground,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textPrimary, size: 19),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'توليد كود التفعيل',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: 'Cairo',
            ),
          ),
          centerTitle: false,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // بطاقة الإدخال
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'كود الجهاز:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _requestCodeController,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        fontFamily: 'Cairo',
                      ),
                      decoration: InputDecoration(
                        hintText: 'XXXX-XXXX-XXXX',
                        hintStyle: TextStyle(
                          color: AppColors.textSecondary.withOpacity(0.4),
                          letterSpacing: 1.5,
                        ),
                        filled: true,
                        fillColor: AppColors.scaffoldBackground,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppColors.cardBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppColors.cardBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.paste_rounded, color: AppColors.primary, size: 20),
                          tooltip: 'لصق',
                          onPressed: _pasteRequestCode,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'مدة التفعيل:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 8),

                    AppDropdown<ActivationDuration>(
                      value: _selectedDuration,
                      items: ActivationDuration.values,
                      itemLabel: (d) => d.labelAr,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedDuration = val;
                            _generatedCode = null;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.vpn_key_rounded, color: Colors.white, size: 20),
                        label: const Text(
                          'توليد الكود',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0.5,
                        ),
                        onPressed: _generateCode,
                      ),
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // بطاقة النتيجة
              if (_generatedCode != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.5)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.scaffoldBackground,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: SelectableText(
                          _generatedCode!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: AppColors.primary,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _selectedDuration.labelAr,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.copy_rounded, size: 16),
                              label: const Text('نسخ', style: TextStyle(fontFamily: 'Cairo')),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.primary),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: _copyGeneratedCode,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.share_rounded, color: Colors.white, size: 16),
                              label: const Text('إرسال لواتساب',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Cairo')),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: _shareViaWhatsApp,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
