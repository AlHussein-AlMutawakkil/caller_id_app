import 'package:flutter/material.dart';
import 'package:phone_state/phone_state.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart' as ov;
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // استدعاء مكتبة الإشعارات

import 'database/database_helper.dart';
import 'home_screen.dart';
import 'overlay_window.dart';
import 'core/theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تشغيل الخدمة الخلفية بأمان
  await initializeBackgroundService();

  runApp(const MyApp());
}

// =========================================================
// 1. إعداد الخدمة الخلفية وإنشاء قناة الإشعارات (هنا الحل!)
// =========================================================
Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  // السحر هنا: إنشاء قناة إشعارات صريحة يرضى عنها نظام أندرويد لمنع الـ Crash
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'caller_id_channel', // معرف القناة (يجب أن يتطابق مع الموجود في الأسفل)
    'خدمة كاشف الأرقام', // اسم القناة للمستخدم
    description: 'هذه القناة مطلوبة لإبقاء الكاشف نشطاً في الخلفية',
    importance: Importance.low, // Low لكي لا يصدر صوتاً مزعجاً بشكل مستمر
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
      notificationChannelId: 'caller_id_channel', // تم ربطها بالقناة التي أنشأناها بنجاح
      initialNotificationTitle: 'دليل اليمن',
      initialNotificationContent: 'كاشف الأرقام يعمل للحماية',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(autoStart: false),
  );
}

// =========================================================
// 2. دالة تشغيل مراقب المكالمات في الخلفية
// =========================================================
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();

  PhoneState.stream.listen((event) async {
    if (event.status == PhoneStateStatus.CALL_INCOMING) {
      String? incomingNumber = event.number;

      if (incomingNumber != null && incomingNumber.isNotEmpty) {
        final dbResults = await DatabaseHelper.instance.searchByNumber(incomingNumber);

        String displayName = "رقم غير مسجل";
        if (dbResults.isNotEmpty) {
          displayName = dbResults.first['names'] ?? "رقم غير مسجل";
        }

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

// =========================================================
// 3. نقطة انطلاق النافذة العائمة (Overlay)
// =========================================================
@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(

    debugShowCheckedModeBanner: false,
    home: CallerOverlayWindow(),
  ));
}

// =========================================================
// 4. التطبيق الرئيسي
// =========================================================
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