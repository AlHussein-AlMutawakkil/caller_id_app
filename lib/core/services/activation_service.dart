import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// مدد التفعيل المتاحة في النظام
enum ActivationDuration {
  lifetime,
  oneYear,
  sixMonths,
  threeMonths,
  oneMonth,
  sevenDays;

  String get labelAr {
    switch (this) {
      case ActivationDuration.lifetime:
        return 'تفعيل دائم (أبدي)';
      case ActivationDuration.oneYear:
        return 'سنة كاملة (12 شهر)';
      case ActivationDuration.sixMonths:
        return '6 أشهر';
      case ActivationDuration.threeMonths:
        return '3 أشهر';
      case ActivationDuration.oneMonth:
        return 'شهر واحد';
      case ActivationDuration.sevenDays:
        return 'أسبوع تجريبي (7 أيام)';
    }
  }

  int get days {
    switch (this) {
      case ActivationDuration.lifetime:
        return 99999;
      case ActivationDuration.oneYear:
        return 365;
      case ActivationDuration.sixMonths:
        return 180;
      case ActivationDuration.threeMonths:
        return 90;
      case ActivationDuration.oneMonth:
        return 30;
      case ActivationDuration.sevenDays:
        return 7;
    }
  }
}

/// نتيجة فحص أو تفعيل الكود
class ActivationResult {
  final bool isValid;
  final bool isExpired;
  final bool isTimeTampered;
  final bool isLifetime;
  final DateTime? expiryDate;
  final int? remainingDays;
  final String message;

  const ActivationResult({
    required this.isValid,
    this.isExpired = false,
    this.isTimeTampered = false,
    this.isLifetime = false,
    this.expiryDate,
    this.remainingDays,
    required this.message,
  });
}

/// خدمة إدارة التفعيل بدون إنترنت 100%
/// مبنية على خوارزمية HMAC-SHA256 المشفرة والمربوطة ببصمة الجهاز وجلسة التثبيت
class ActivationService {
  ActivationService._();
  static final ActivationService instance = ActivationService._();

  // قناة الاتصال الأصلية للحصول على معرف الجهاز من أندرويد
  static const MethodChannel _deviceChannel =
      MethodChannel('com.example.caller_id_app/device_info');

  // المفتاح السري المشفر لتوقيع والتحقق من الأكواد أوفلاين
  static const String _kMasterSecret =
      'CallerIdApp_SecureOfflineMasterKey_2026_@#\$9876543210';

  // رمز مرور المشرف الافتراضي للدخول للوحة توليد الأكواد
  static const String _kAdminPin = '998877';

  // تاريخ الأساس لحساب الأيام
  static final DateTime _baseEpochDate = DateTime.utc(2025, 1, 1);

  // أسماء ملفات التخزين المحلي المحمية
  static const String _installSessionFile = '.app_install_id';
  static const String _licenseFile = '.license_data.json';

  String? _cachedRequestCode;
  ActivationResult? _cachedStatus;

  final ValueNotifier<bool> isActivatedNotifier = ValueNotifier<bool>(false);

  /// التحقق من رمز مرور المشرف
  bool verifyAdminPin(String pin) {
    return pin.trim() == _kAdminPin;
  }

  /// الحصول على معرف أندرويد من النظام
  Future<String> _getAndroidId() async {
    try {
      final String? id =
          await _deviceChannel.invokeMethod<String>('getAndroidId');
      if (id != null && id.trim().isNotEmpty && id != 'UNKNOWN_DEVICE') {
        return id.trim();
      }
    } catch (_) {}
    return 'STANDARD_ANDROID_DEVICE';
  }

  /// الحصول على رقم جلسة التثبيت (الخيار الثاني: يتغير تلقائياً عند حذف التطبيق)
  Future<String> _getInstallSessionId() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, _installSessionFile));

      if (await file.exists()) {
        final content = (await file.readAsString()).trim();
        if (content.isNotEmpty) {
          return content;
        }
      }

      // توليد رقم تثبيت عشوائي جديد وتخزينه في مسار التطبيق
      final random = Random.secure();
      final values = List<int>.generate(16, (i) => random.nextInt(256));
      final newInstallId =
          values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

      await file.writeAsString(newInstallId);
      return newInstallId;
    } catch (_) {
      return 'DEFAULT_SESSION_SALT';
    }
  }

  /// كود طلب التفعيل الخاص بهذا الهاتف (12 خانة: XXXX-XXXX-XXXX)
  /// مربوط ببصمة الهاتف + جلسة التثبيت الحالية
  Future<String> getDeviceRequestCode() async {
    if (_cachedRequestCode != null) return _cachedRequestCode!;

    final androidId = await _getAndroidId();
    final installId = await _getInstallSessionId();

    final rawPayload = '$androidId:$installId:caller_id_offline_salt_v2';
    final digest = sha256.convert(utf8.encode(rawPayload)).toString().toUpperCase();

    // نأخذ 12 خانة ونفصلها بشرطات
    final p1 = digest.substring(0, 4);
    final p2 = digest.substring(4, 8);
    final p3 = digest.substring(8, 12);

    _cachedRequestCode = '$p1-$p2-$p3';
    return _cachedRequestCode!;
  }

  /// [خاص بالمشرف]: توليد كود تفعيل صالح بناءً على كود طلب المستخدم والمدة
  String generateActivationCode({
    required String requestCode,
    required ActivationDuration duration,
  }) {
    final cleanRequest = requestCode
        .replaceAll('-', '')
        .replaceAll(' ', '')
        .trim()
        .toUpperCase();

    if (cleanRequest.length != 12) {
      throw ArgumentError('كود طلب التفعيل غير صحيح (يجب أن يكون 12 خانة)');
    }

    // 1. تحديد ترويسة الانتهاء (4 خانات بنظام سداسي عشر)
    String expiryHex;
    if (duration == ActivationDuration.lifetime) {
      expiryHex = 'FFFF';
    } else {
      final expiryDate =
          DateTime.now().toUtc().add(Duration(days: duration.days));
      final days = expiryDate.difference(_baseEpochDate).inDays;
      expiryHex = days.toRadixString(16).padLeft(4, '0').toUpperCase();
    }

    // 2. حساب التوقيع الرقمي HMAC-SHA256
    final hmac = Hmac(sha256, utf8.encode(_kMasterSecret));
    final payload = '$cleanRequest:$expiryHex';
    final digest =
        hmac.convert(utf8.encode(payload)).toString().toUpperCase();

    // نأخذ 12 خانة من التوقيع
    final sig = digest.substring(0, 12);

    // 3. تركيب كود التفعيل النهائي: [المدة]-[التوقيع1]-[التوقيع2]-[التوقيع3]
    return '$expiryHex-${sig.substring(0, 4)}-${sig.substring(4, 8)}-${sig.substring(8, 12)}';
  }

  /// التحقق الرياضي من صحة كود التفعيل ومطابقته للجهاز
  ActivationResult verifyCode({
    required String activationCode,
    required String requestCode,
    DateTime? lastRecordedDate,
  }) {
    final cleanCode = activationCode
        .replaceAll('-', '')
        .replaceAll(' ', '')
        .trim()
        .toUpperCase();

    final cleanRequest = requestCode
        .replaceAll('-', '')
        .replaceAll(' ', '')
        .trim()
        .toUpperCase();

    if (cleanCode.length != 16) {
      return const ActivationResult(
        isValid: false,
        message: 'كود التفعيل غير صالح (تأكد من كتابة 16 حرفاً ورقماً)',
      );
    }

    if (cleanRequest.length != 12) {
      return const ActivationResult(
        isValid: false,
        message: 'كود طلب الجهاز غير صالح',
      );
    }

    final expiryHex = cleanCode.substring(0, 4);
    final providedSig = cleanCode.substring(4, 16);

    // حساب التوقيع المتوقع
    final hmac = Hmac(sha256, utf8.encode(_kMasterSecret));
    final payload = '$cleanRequest:$expiryHex';
    final expectedDigest =
        hmac.convert(utf8.encode(payload)).toString().toUpperCase();
    final expectedSig = expectedDigest.substring(0, 12);

    if (providedSig != expectedSig) {
      return const ActivationResult(
        isValid: false,
        message: 'كود التفعيل غير مطابق لهذا الجهاز أو غير صالح',
      );
    }

    // الكود سليم رياضياً! الآن نفحص المدة وصلاحية التاريخ
    if (expiryHex == 'FFFF') {
      return const ActivationResult(
        isValid: true,
        isLifetime: true,
        message: 'تفعيل دائم (أبدي) بنجاح',
      );
    }

    // كود محدد بمدة
    final int? days = int.tryParse(expiryHex, radix: 16);
    if (days == null) {
      return const ActivationResult(
        isValid: false,
        message: 'بيانات تاريخ الكود غير صالحة',
      );
    }

    final expiryDate = _baseEpochDate.add(Duration(days: days));
    final now = DateTime.now().toUtc();

    // فحص حماية التلاعب بالساعة (Anti-Clock Tampering)
    if (lastRecordedDate != null) {
      if (now.isBefore(lastRecordedDate.subtract(const Duration(hours: 2)))) {
        return ActivationResult(
          isValid: false,
          isTimeTampered: true,
          expiryDate: expiryDate,
          message: 'تم رصد تلاعب بساعة الجهاز! يرجى ضبط الوقت الحقيقي للمتابعة',
        );
      }
    }

    // فحص الانتهاء
    if (now.isAfter(expiryDate)) {
      return ActivationResult(
        isValid: false,
        isExpired: true,
        expiryDate: expiryDate,
        message: 'انتهت مدة تفعيل هذا الكود، يرجى تجديد التفعيل',
      );
    }

    final remaining = expiryDate.difference(now).inDays;

    return ActivationResult(
      isValid: true,
      expiryDate: expiryDate,
      remainingDays: remaining,
      message: 'تم التفعيل بنجاح (متبقي $remaining يوماً)',
    );
  }

  /// تفعيل التطبيق بالكود المدخل
  Future<ActivationResult> activateWithCode(String code) async {
    final currentReqCode = await getDeviceRequestCode();
    final result = verifyCode(
      activationCode: code,
      requestCode: currentReqCode,
    );

    if (!result.isValid) {
      return result;
    }

    // حفظ بيانات التفعيل محلياً
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, _licenseFile));

      final data = {
        'activation_code': code.trim(),
        'request_code': currentReqCode,
        'is_lifetime': result.isLifetime,
        'expiry_date': result.expiryDate?.toIso8601String(),
        'activated_at': DateTime.now().toUtc().toIso8601String(),
        'last_opened_at': DateTime.now().toUtc().toIso8601String(),
      };

      await file.writeAsString(jsonEncode(data));
      _cachedStatus = result;
      isActivatedNotifier.value = true;
      return result;
    } catch (e) {
      return ActivationResult(
        isValid: false,
        message: 'حدث خطأ أثناء حفظ ملف التفعيل: $e',
      );
    }
  }

  /// فحص حالة التفعيل الحالية عند فتح التطبيق
  Future<ActivationResult> checkCurrentStatus() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, _licenseFile));

      if (!await file.exists()) {
        _cachedStatus = const ActivationResult(
          isValid: false,
          message: 'التطبيق غير مفعل، يرجى إدخال كود التفعيل',
        );
        isActivatedNotifier.value = false;
        return _cachedStatus!;
      }

      final content = await file.readAsString();
      final Map<String, dynamic> data = jsonDecode(content);

      final String activationCode = data['activation_code'] ?? '';
      final String lastOpenedStr = data['last_opened_at'] ?? '';
      final DateTime? lastOpened = DateTime.tryParse(lastOpenedStr);

      final currentReqCode = await getDeviceRequestCode();

      final result = verifyCode(
        activationCode: activationCode,
        requestCode: currentReqCode,
        lastRecordedDate: lastOpened,
      );

      if (result.isValid) {
        // تحديث آخر وقت فتح لحماية الساعة
        data['last_opened_at'] = DateTime.now().toUtc().toIso8601String();
        await file.writeAsString(jsonEncode(data));
        _cachedStatus = result;
        isActivatedNotifier.value = true;
      } else {
        _cachedStatus = result;
        isActivatedNotifier.value = false;
      }

      return result;
    } catch (_) {
      _cachedStatus = const ActivationResult(
        isValid: false,
        message: 'التطبيق غير مفعل',
      );
      isActivatedNotifier.value = false;
      return _cachedStatus!;
    }
  }

  /// هل التطبيق مفعل حالياً؟ (استدعاء سريع)
  Future<bool> isActivated() async {
    if (_cachedStatus != null && _cachedStatus!.isValid) {
      return true;
    }
    final status = await checkCurrentStatus();
    return status.isValid;
  }

  /// [خاص بالاختبار أو إعادة الضبط]: إلغاء التفعيل
  Future<void> deactivate() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, _licenseFile));
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
    _cachedStatus = null;
    isActivatedNotifier.value = false;
  }
}

