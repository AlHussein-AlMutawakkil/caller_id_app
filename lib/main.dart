import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';
import 'package:phone_state/phone_state.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'database_helper.dart';
import 'home_screen.dart';
import 'overlay_window.dart';

// 1. نقطة الدخول الرئيسية للتطبيق الرسومي
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

// 2. نقطة الدخول الخاصة بالنافذة العائمة (تستدعيها الخدمة الخلفية للأندرويد تلقائياً)
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
    _initCallSniffer();
  }

  // طلب الصلاحيات اللازمة للعمل بكل كفاءة
  Future<void> _requestRequiredPermissions() async {
    await [
      Permission.phone,
      Permission.systemAlertWindow,
    ].request();
  }

  // مراقبة ورصد المكالمات الواردة
  void _initCallSniffer() {
    PhoneState.stream.listen((PhoneState event) async {
      if (event.status == PhoneStateStatus.CALL_INCOMING) {
        String incomingNumber = event.number ?? "";
        if (incomingNumber.isNotEmpty) {
          // استعلام فوري من قاعدة البيانات المحلية المسطحة
          final dbResults = await DatabaseHelper.instance.searchByNumber(incomingNumber);

          String displayName = "رقم غير مسجل";
          if (dbResults.isNotEmpty) {
            displayName = dbResults.first['names'] ?? "رقم غير مسجل";
          }

          // تفعيل وفتح النافذة العائمة وتمرير البيانات إليها
          if (!await FlutterOverlayWindow.isActive()) {
            await FlutterOverlayWindow.showOverlay(
              height: 500,
              width: 400,
              alignment: OverlayAlignment.center,
              flag: OverlayFlag.defaultFlag,
              enableDrag: true,
              positionGravity: PositionGravity.auto,
              overlayTitle: "مكالمة واردة",
              overlayContent: "الاسم: $displayName\nالرقم: $incomingNumber",
            );
          }
        }
      }

      // إغلاق الكاشف فوراً عند إنهاء أو الرد على المكالمة
      if (event.status == PhoneStateStatus.CALL_ENDED) {
        if (await FlutterOverlayWindow.isActive()) {
          await FlutterOverlayWindow.closeOverlay();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'كاشف الأرقام المحترف',
      theme: ThemeData(
        primaryColor: const Color(0xFF1E232C),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}