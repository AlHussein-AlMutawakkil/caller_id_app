import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../../core/constants/app_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/settings_card.dart';

class PermissionsView extends StatefulWidget {
  const PermissionsView({super.key});

  @override
  State<PermissionsView> createState() => _PermissionsViewState();
}

class _PermissionsViewState extends State<PermissionsView> {
  bool _phoneGranted = false;
  bool _overlayGranted = false;
  bool _storageGranted = false;
  bool _notificationGranted = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final phone = await Permission.phone.isGranted;
    final overlay = await FlutterOverlayWindow.isPermissionGranted();
    final storage = await Permission.manageExternalStorage.isGranted ||
        await Permission.storage.isGranted;
    final notification = await Permission.notification.isGranted;

    if (mounted) {
      setState(() {
        _phoneGranted = phone;
        _overlayGranted = overlay;
        _storageGranted = storage;
        _notificationGranted = notification;
        _isLoading = false;
      });
    }
  }

  Future<void> _requestPhone() async {
    final status = await Permission.phone.request();
    if (status.isGranted) {
      setState(() => _phoneGranted = true);
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  Future<void> _requestOverlay() async {
    final bool? res = await FlutterOverlayWindow.requestPermission();
    if (res == true) {
      setState(() => _overlayGranted = true);
    }
    _checkPermissions();
  }

  Future<void> _requestStorage() async {
    var status = await Permission.manageExternalStorage.request();
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }
    if (status.isGranted) {
      setState(() => _storageGranted = true);
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  Future<void> _requestNotification() async {
    final status = await Permission.notification.request();
    if (status.isGranted) {
      setState(() => _notificationGranted = true);
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final permissionsList = [
      _PermissionItem(
        title: 'حالة الهاتف والمكالمات',
        icon: AppIcons.phone,
        isGranted: _phoneGranted,
        onTap: _requestPhone,
      ),
      _PermissionItem(
        title: 'الظهور فوق التطبيقات (النافذة العائمة)',
        icon: AppIcons.overlay,
        isGranted: _overlayGranted,
        onTap: _requestOverlay,
      ),
      _PermissionItem(
        title: 'الوصول لملفات قاعدة البيانات (التخزين)',
        icon: AppIcons.storage,
        isGranted: _storageGranted,
        onTap: _requestStorage,
      ),
      _PermissionItem(
        title: 'الإشعارات والعمل في الخلفية',
        icon: AppIcons.notifications,
        isGranted: _notificationGranted,
        onTap: _requestNotification,
      ),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: AppBar(
          backgroundColor: AppColors.scaffoldBackground,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(AppIcons.back, color: AppColors.textPrimary, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'الأذونات',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          centerTitle: false,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  SettingsCard(
                    children: List.generate(permissionsList.length, (index) {
                      final item = permissionsList[index];
                      final isLast = index == permissionsList.length - 1;

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: item.isGranted ? null : item.onTap,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 16),
                              child: Row(
                                children: [
                                  // أيقونة الإذن
                                  Icon(
                                    item.icon,
                                    size: 22,
                                    color: AppColors.textPrimary,
                                  ),
                                  const SizedBox(width: 14),
                                  // اسم الإذن
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  // أيقونة حالة الإذن مطابقة للصورة 4
                                  Icon(
                                    item.isGranted
                                        ? AppIcons.checked
                                        : AppIcons.cancel,
                                    color: item.isGranted
                                        ? AppColors.success
                                        : AppColors.disabled,
                                    size: 22,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (!isLast)
                            const Divider(
                              height: 1,
                              thickness: 1,
                              color: AppColors.divider,
                              indent: 20,
                              endIndent: 20,
                            ),
                        ],
                      );
                    }),
                  ),
                ],
              ),
      ),
    );
  }
}

class _PermissionItem {
  final String title;
  final IconData icon;
  final bool isGranted;
  final VoidCallback onTap;

  _PermissionItem({
    required this.title,
    required this.icon,
    required this.isGranted,
    required this.onTap,
  });
}
