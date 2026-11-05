import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:android_intent_plus/android_intent.dart';
import '../../core/services/activation_service.dart';
import '../../core/theme/app_colors.dart';
import 'admin_activation_view.dart';

class ActivationGateView extends StatefulWidget {
  final VoidCallback onActivated;

  const ActivationGateView({super.key, required this.onActivated});

  @override
  State<ActivationGateView> createState() => _ActivationGateViewState();
}

class _ActivationGateViewState extends State<ActivationGateView> {
  final TextEditingController _activationCodeController = TextEditingController();
  String? _requestCode;
  bool _isLoading = true;
  bool _isActivating = false;
  String? _errorMessage;
  int _secretTapCount = 0;

  @override
  void initState() {
    super.initState();
    _loadDeviceRequestCode();
  }

  @override
  void dispose() {
    _activationCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadDeviceRequestCode() async {
    setState(() => _isLoading = true);
    final code = await ActivationService.instance.getDeviceRequestCode();
    if (mounted) {
      setState(() {
        _requestCode = code;
        _isLoading = false;
      });
    }
  }

  void _copyRequestCode() {
    if (_requestCode == null) return;
    Clipboard.setData(ClipboardData(text: _requestCode!));
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
    if (_requestCode == null) return;
    final message =
        'مرحباً، أود تفعيل تطبيق كاشف الأرقام.\nكود جهازي هو:\n$_requestCode';

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
          content: Text('تم نسخ رسالة الطلب إلى الحافظة'),
        ),
      );
    }
  }

  void _pasteActivationCode() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      setState(() {
        _activationCodeController.text = data.text!.trim();
        _errorMessage = null;
      });
    }
  }

  Future<void> _submitActivation() async {
    final code = _activationCodeController.text.trim();
    if (code.isEmpty) {
      setState(() => _errorMessage = 'يرجى إدخال كود التفعيل');
      return;
    }

    setState(() {
      _isActivating = true;
      _errorMessage = null;
    });

    FocusScope.of(context).unfocus();

    final result = await ActivationService.instance.activateWithCode(code);

    if (!mounted) return;

    if (result.isValid) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Color(0xFF4CAF50), size: 26),
                SizedBox(width: 8),
                Text('تم التفعيل بنجاح',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
              ],
            ),
            content: Text(
              result.isLifetime
                  ? 'تفعيل دائم (أبدي)'
                  : 'صالح حتى: ${result.expiryDate?.toLocal().toString().split(' ')[0]} (${result.remainingDays} يوم متبقي)',
              style: const TextStyle(fontSize: 14, fontFamily: 'Cairo'),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  widget.onActivated();
                },
                child: const Text('دخول',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
              ),
            ],
          ),
        ),
      );
    } else {
      setState(() {
        _isActivating = false;
        _errorMessage = result.message;
      });
    }
  }

  void _handleSecretTap() {
    _secretTapCount++;
    if (_secretTapCount >= 10) {
      _secretTapCount = 0;
      _openAdminPinDialog();
    }
  }

  void _openAdminPinDialog() {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'رمز المرور',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
          ),
          content: TextField(
            controller: pinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 6),
            decoration: InputDecoration(
              hintText: '••••••',
              filled: true,
              fillColor: AppColors.scaffoldBackground,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.cardBorder),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('إلغاء', style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Cairo')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                final enteredPin = pinController.text.trim();
                if (ActivationService.instance.verifyAdminPin(enteredPin)) {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AdminActivationView(initialRequestCode: _requestCode),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('رمز المرور غير صحيح', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Cairo')),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
              child: const Text('دخول', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: SafeArea(
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: AppColors.primary))
              : Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // أيقونة وشعار التطبيق (الضغط 10 مرات متتالية يفتح لوحة المشرف)
                        GestureDetector(
                          onTap: _handleSecretTap,
                          behavior: HitTestBehavior.opaque,
                          child: Column(
                            children: [
                              Container(
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.asset(
                                    'assets/icon/icon_2.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'تفعيل كاشف الأرقام',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'أدخل كود التفعيل للمتابعة',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // البطاقة الأولى: كود الجهاز
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
                              Text(
                                'كود الجهاز:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                              const SizedBox(height: 10),

                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.scaffoldBackground,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.cardBorder),
                                ),
                                child: SelectableText(
                                  _requestCode ?? '—',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                    color: AppColors.primary,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.copy_rounded, size: 16),
                                      label: const Text('نسخ', style: TextStyle(fontFamily: 'Cairo')),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.textPrimary,
                                        side: BorderSide(color: AppColors.cardBorder),
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onPressed: _copyRequestCode,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 16),
                                      label: const Text('طلب التفعيل',
                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
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
                        const SizedBox(height: 16),

                        // البطاقة الثانية: إدخال كود التفعيل
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
                              Text(
                                'كود التفعيل:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                              const SizedBox(height: 10),

                              TextField(
                                controller: _activationCodeController,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                  fontFamily: 'Cairo',
                                ),
                                decoration: InputDecoration(
                                  hintText: 'XXXX-XXXX-XXXX-XXXX',
                                  hintStyle: TextStyle(
                                    color: AppColors.textSecondary.withOpacity(0.4),
                                    letterSpacing: 1,
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
                                    borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(Icons.paste_rounded, color: AppColors.primary, size: 20),
                                    tooltip: 'لصق',
                                    onPressed: _pasteActivationCode,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),

                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    elevation: 0.5,
                                  ),
                                  onPressed: _isActivating ? null : _submitActivation,
                                  child: _isActivating
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                        )
                                      : const Text(
                                          'تفعيل التطبيق',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            fontFamily: 'Cairo',
                                          ),
                                        ),
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
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}