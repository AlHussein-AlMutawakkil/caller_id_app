import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class CallerOverlayWindow extends StatefulWidget {
  const CallerOverlayWindow({super.key});

  @override
  State<CallerOverlayWindow> createState() => _CallerOverlayWindowState();
}

class _CallerOverlayWindowState extends State<CallerOverlayWindow> {
  String callerName = "جاري البحث...";
  String callerPhone = "...";

  @override
  void initState() {
    super.initState();
    // التقاط البيانات المرسلة من الـ Stream الخلفي عبر الـ main
    FlutterOverlayWindow.overlayListener.listen((data) {
      if (data != null && data is Map) {
        setState(() {
          callerName = data['name'] ?? "رقم غير مسجل";
          callerPhone = data['phone'] ?? "";
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // جعل الخلفية شفافة للرسم فوق واجهة الاتصال الأصلية
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))
              ]
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFF1E232C),
                child: Icon(Icons.phone_callback, color: Colors.white),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  textDirection: TextDirection.rtl,
                  children: [
                    const Text("كاشف الأرقام المحلي", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text(callerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(callerPhone, style: const TextStyle(color: Colors.blue, fontSize: 14)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () async {
                  await FlutterOverlayWindow.closeOverlay();
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}