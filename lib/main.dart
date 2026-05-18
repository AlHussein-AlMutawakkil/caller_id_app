import 'package:flutter/material.dart';
import 'package:phone_state/phone_state.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'database_helper.dart';
import 'home_screen.dart';
import 'overlay_window.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
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
    _initCallSniffer();
  }

  Future<void> _requestRequiredPermissions() async {
    // تم إضافة كافة الصلاحيات المطلوبة ليعمل 100%
    await [
      Permission.phone,
      Permission.contacts,
      Permission.systemAlertWindow,
      Permission.manageExternalStorage,
      Permission.storage,
    ].request();
  }

  void _initCallSniffer() {
    PhoneState.stream.listen((event) async {
      if (event.status == PhoneStateStatus.CALL_INCOMING) {
        String? incomingNumber = event.number;

        if (incomingNumber != null && incomingNumber.isNotEmpty) {
          final dbResults = await DatabaseHelper.instance.searchByNumber(incomingNumber);

          String displayName = "رقم غير مسجل";
          if (dbResults.isNotEmpty) {
            displayName = dbResults.first['names'] ?? "رقم غير مسجل";
          }

          if (!await FlutterOverlayWindow.isActive()) {
            await FlutterOverlayWindow.showOverlay(
              height: 400,
              width: WindowSize.matchParent,

              alignment: OverlayAlignment.center,
              flag: OverlayFlag.defaultFlag,
              enableDrag: true,
              positionGravity: PositionGravity.auto,
            );
          }

          FlutterOverlayWindow.shareData({
            'name': displayName,
            'phone': incomingNumber
          });
        }
      }

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
      title: 'كاشف الأرقام',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primaryColor: const Color(0xFF1E232C)),
      home: const HomeScreen(),
    );
  }
}
