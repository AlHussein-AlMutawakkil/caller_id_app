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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
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
  WidgetsFlutterBinding.ensureInitialized();

  PhoneState.stream.listen((event) async {
    if (event.status == PhoneStateStatus.CALL_INCOMING) {
      String? incomingNumber = event.number;

      if (incomingNumber != null && incomingNumber.isNotEmpty) {
        // 1. جلب البيانات من قاعدة البيانات (مطابقة تامة)
        final dbResults = await DatabaseHelper.instance.searchByNumber(incomingNumber);

        String displayName = "رقم غير مسجل";
        if (dbResults.isNotEmpty) {
          displayName = dbResults.first['names'] ?? "رقم غير مسجل";
        }

        // 2. إظهار النافذة إذا لم تكن نشطة
        if (!await ov.FlutterOverlayWindow.isActive()) {
          await ov.FlutterOverlayWindow.showOverlay(
            height: 450,
            width: ov.WindowSize.matchParent,
            alignment: ov.OverlayAlignment.center,
            flag: ov.OverlayFlag.defaultFlag,
            enableDrag: false,
            positionGravity: ov.PositionGravity.auto,
          );
        }

        // 3. تأخير بسيط (300ms) لضمان أن النافذة جاهزة لاستقبال البيانات عبر overlayListener
        await Future.delayed(const Duration(milliseconds: 300));

        // 4. إرسال البيانات المجهزة للنافذة
        ov.FlutterOverlayWindow.shareData({
          'name': displayName,
          'phone': incomingNumber
        });
      }
    }

    if (event.status == PhoneStateStatus.CALL_ENDED) {
      if (await ov.FlutterOverlayWindow.isActive()) {
        await ov.FlutterOverlayWindow.closeOverlay();
      }
    }
  });
}

@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: CallerOverlayWindow(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _requestRequiredPermissions();
  }

  Future<void> _requestRequiredPermissions() async {
    await [
      Permission.phone,
      Permission.contacts,
      Permission.systemAlertWindow,
      Permission.notification,
    ].request();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'دليل اليمن',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        fontFamily: 'Cairo',
      ),
      home: const HomeScreen(),
    );
  }
}