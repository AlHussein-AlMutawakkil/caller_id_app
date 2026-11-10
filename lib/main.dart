import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:phone_state/phone_state.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart' as ov;
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'database/database_helper.dart';
import 'home_screen.dart';
import 'overlay_window.dart';
import 'core/theme/app_colors.dart';
import 'core/services/telecom_companies_service.dart';
import 'core/services/activation_service.dart';
import 'core/services/theme_service.dart';
import 'views/activation/activation_gate_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeService.instance.init();
  await initializeBackgroundService();
  await TelecomCompaniesService.instance.getCompanies();
  runApp(const MyApp());
}

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'caller_id_channel',
    'خدمة كاشف الأرقام',
    description: 'هذه القناة مطلوبة لإبقاء الكاشف نشطاً في الخلفية',
    importance: Importance.min,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'caller_id_channel',
      initialNotificationTitle: 'كاشف الإرقام المحلي',
      initialNotificationContent: 'كاشف الأرقام يعمل للحماية',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(autoStart: false),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  Map<String, dynamic>? lastCallData;

  // الاستماع لطلبات البيانات من النافذة العائمة فور جاهزيتها
  ov.FlutterOverlayWindow.overlayListener.listen((data) {
    if (data == 'request_data' && lastCallData != null) {
      ov.FlutterOverlayWindow.shareData(lastCallData!);
    }
  });

  PhoneState.stream.listen((event) async {
    if (event.status == PhoneStateStatus.CALL_INCOMING) {
      // 0. التحقق من تفعيل التطبيق أولاً قبل عرض النافذة
      final isActivated = await ActivationService.instance.isActivated();
      if (!isActivated) return;

      String? incomingNumber = event.number;

      if (incomingNumber != null && incomingNumber.isNotEmpty) {
        // تنظيف الرقم من المسافات والأقواس
        String cleanNumber = incomingNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
        if (cleanNumber.startsWith('+967')) {
          cleanNumber = cleanNumber.substring(4);
        } else if (cleanNumber.startsWith('00967')) {
          cleanNumber = cleanNumber.substring(5);
        }

        // 1. جلب البيانات من قاعدة البيانات
        var dbResults =
            await DatabaseHelper.instance.searchByNumber(cleanNumber);
        if (dbResults.isEmpty && cleanNumber != incomingNumber) {
          dbResults =
              await DatabaseHelper.instance.searchByNumber(incomingNumber);
        }

        String displayName = "رقم غير مسجل";
        if (dbResults.isNotEmpty) {
          final Set<String> distinctNames = {};
          for (final row in dbResults) {
            final raw = row['names']?.toString() ?? '';
            final parts = raw
                .split(RegExp(r'[,،|\n]'))
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty);
            distinctNames.addAll(parts);
          }
          if (distinctNames.isNotEmpty) {
            displayName = distinctNames.join(' ، ');
          }
        }

        lastCallData = {
          'name': displayName,
          'phone': incomingNumber,
        };

        // 2. إظهار النافذة إذا لم تكن نشطة
        if (!await ov.FlutterOverlayWindow.isActive()) {
          await ov.FlutterOverlayWindow.showOverlay(
            height: 1050,
            width: ov.WindowSize.matchParent,
            alignment: ov.OverlayAlignment.center,
            flag: ov.OverlayFlag.defaultFlag,
            enableDrag: false,
            positionGravity: ov.PositionGravity.auto,
          );
        }

        // 3. إرسال البيانات المجهزة للنافذة مع تكرار تأكيدي
        await Future.delayed(const Duration(milliseconds: 300));
        ov.FlutterOverlayWindow.shareData(lastCallData!);

        await Future.delayed(const Duration(milliseconds: 600));
        ov.FlutterOverlayWindow.shareData(lastCallData!);
      }
    }

    if (event.status == PhoneStateStatus.CALL_ENDED) {
      lastCallData = null;
      if (await ov.FlutterOverlayWindow.isActive()) {
        await ov.FlutterOverlayWindow.closeOverlay();
      }
    }
  });
}

@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      primaryColor: AppColors.primary,
      fontFamily: 'Cairo',
    ),
    home: const Directionality(
      textDirection: TextDirection.rtl,
      child: CallerOverlayWindow(),
    ),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isCheckingActivation = true;
  bool _isActivated = false;

  @override
  void initState() {
    super.initState();
    _checkActivation();
  }

  Future<void> _checkActivation() async {
    final activated = await ActivationService.instance.isActivated();
    if (mounted) {
      setState(() {
        _isActivated = activated;
        _isCheckingActivation = false;
      });
    }

    if (activated) {
      await _requestRequiredPermissions();
    }
  }

  Future<void> _requestRequiredPermissions() async {
    await [
      Permission.phone,
      Permission.contacts,
      Permission.notification,
    ].request();

    final isOverlayGranted = await ov.FlutterOverlayWindow.isPermissionGranted();
    if (!isOverlayGranted) {
      await ov.FlutterOverlayWindow.requestPermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'دليل اليمن',
          debugShowCheckedModeBanner: false,
          themeMode: ThemeService.instance.themeMode == 2
              ? ThemeMode.dark
              : ThemeService.instance.themeMode == 1
                  ? ThemeMode.light
                  : ThemeMode.system,
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: AppColors.primary,
            scaffoldBackgroundColor: AppColors.scaffoldBackground,
            fontFamily: 'Cairo',
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              surface: AppColors.cardBackground,
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: AppColors.primary,
            scaffoldBackgroundColor: AppColors.scaffoldBackground,
            fontFamily: 'Cairo',
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.cardBackground,
            ),
          ),
          home: _isCheckingActivation
              ? Scaffold(
                  backgroundColor: AppColors.scaffoldBackground,
                  body: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              : _isActivated
                  ? const HomeScreen()
                  : ActivationGateView(
                      onActivated: () {
                        setState(() {
                          _isActivated = true;
                        });
                        _requestRequiredPermissions();
                      },
                    ),
        );
      },
    );
  }
}
