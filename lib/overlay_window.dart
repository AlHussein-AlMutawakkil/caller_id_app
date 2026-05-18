import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart' as ov;

class CallerOverlayWindow extends StatefulWidget {
  const CallerOverlayWindow({super.key});

  @override
  State<CallerOverlayWindow> createState() => _CallerOverlayWindowState();
}

class _CallerOverlayWindowState extends State<CallerOverlayWindow> {
  String callerName = "جاري البحث...";
  String callerPhone = "";

  @override
  void initState() {
    super.initState();
    ov.FlutterOverlayWindow.overlayListener.listen((data) {
      if (data is Map) {
        setState(() {
          callerName = data['name'] ?? "رقم غير مسجل";
          callerPhone = data['phone'] ?? "";
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 25),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, spreadRadius: 5),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("مكالمة واردة", style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 15),
              Text(
                callerName,
                style: const TextStyle(color: Colors.blue, fontSize: 26, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "المنزل $callerPhone",
                style: const TextStyle(color: Colors.black87, fontSize: 18),
              ),
              const Text("اليمن", style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(Icons.call, Colors.green, "رد"),
                  _buildActionButton(Icons.message, Colors.blue, "رسالة"),
                  _buildActionButton(Icons.call_end, Colors.red, "رفض"),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 15),
                child: Divider(height: 1, color: Colors.grey),
              ),
              const Text("الأسماء الأخرى المقترحة", style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  callerName,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF1E232C)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
