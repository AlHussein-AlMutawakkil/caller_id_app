import 'package:flutter/material.dart';
import 'package:phone_state/phone_state.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart' as ov;
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

          if (!await ov.FlutterOverlayWindow.isActive()) {
            await ov.FlutterOverlayWindow.showOverlay(
              height: 450,
              width: ov.WindowSize.matchParent,
              alignment: ov.OverlayAlignment.center,
              flag: ov.OverlayFlag.defaultFlag,
              enableDrag: true,
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'دليل اليمن',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF1E232C),
        fontFamily: 'Cairo', // يفضل إضافة خط عربي مثل Cairo في pubspec.yaml
      ),
      home: const HomeScreen(),
    );
  }
}
