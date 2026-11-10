import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../theme/app_colors.dart';

class ThemeService extends ChangeNotifier {
  ThemeService._();
  static final ThemeService instance = ThemeService._();

  static const String _fileName = '.app_theme_mode.json';

  // 0: النظام، 1: فاتح، 2: مظلم
  int _themeMode = 1;
  int get themeMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == 2) return true;
    if (_themeMode == 1) return false;
    return PlatformDispatcher.instance.platformBrightness == Brightness.dark;
  }

  Future<void> init() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, _fileName));
      if (await file.exists()) {
        final content = await file.readAsString();
        final Map<String, dynamic> data = jsonDecode(content);
        _themeMode = data['theme_mode'] ?? 1;
      }
    } catch (_) {}

    PlatformDispatcher.instance.onPlatformBrightnessChanged = () {
      if (_themeMode == 0) {
        _syncWithAppColors();
        notifyListeners();
      }
    };

    _syncWithAppColors();
    notifyListeners();
  }

  Future<void> setThemeMode(int index) async {
    _themeMode = index;
    _syncWithAppColors();
    notifyListeners();

    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, _fileName));
      await file.writeAsString(jsonEncode({'theme_mode': index}));
    } catch (_) {}
  }

  void _syncWithAppColors() {
    AppColors.isDarkMode = isDarkMode;
  }

  void onPlatformBrightnessChanged() {
    if (_themeMode == 0) {
      _syncWithAppColors();
      notifyListeners();
    }
  }
}
