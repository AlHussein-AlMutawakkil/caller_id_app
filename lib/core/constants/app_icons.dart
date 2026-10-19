import 'package:flutter/material.dart';

class AppIcons {
  AppIcons._();

  // أيقونات التنقل والـ AppBar
  static const IconData menu = Icons.menu_rounded;
  static const IconData back = Icons.arrow_forward_ios_rounded; // RTL back arrow
  static const IconData chevronRight = Icons.chevron_left_rounded; // RTL chevron

  // أيقونات الملف الشخصي والحساب
  static const IconData profileAvatar = Icons.face_rounded;
  static const IconData account = Icons.person_outline_rounded;

  // أيقونات الميزات والتطوير
  static const IconData categories = Icons.category_outlined;
  static const IconData units = Icons.grid_view_rounded;

  // أيقونات الإعدادات العامة
  static const IconData database = Icons.storage_rounded;
  static const IconData refresh = Icons.refresh_rounded;
  static const IconData importDb = Icons.drive_folder_upload_rounded;
  static const IconData deleteDb = Icons.delete_outline_rounded;
  static const IconData appearance = Icons.wb_sunny_outlined;
  static const IconData language = Icons.language_rounded;
  static const IconData permissions = Icons.shield_outlined;
  static const IconData about = Icons.info_outline_rounded;
  static const IconData logout = Icons.logout_rounded;

  // أيقونات الأذونات
  static const IconData phone = Icons.phone_android_rounded;
  static const IconData overlay = Icons.layers_outlined;
  static const IconData storage = Icons.folder_open_rounded;
  static const IconData notifications = Icons.notifications_none_rounded;

  // أيقونات الحالة
  static const IconData checked = Icons.check_circle_rounded;
  static const IconData unchecked = Icons.radio_button_unchecked_rounded;
  static const IconData cancel = Icons.cancel_rounded;
}
