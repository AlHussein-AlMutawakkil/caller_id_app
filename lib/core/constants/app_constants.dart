class AppConstants {
  AppConstants._();

  // قائمة شركات الاتصالات لـ Dropdown
  static const List<String> companies = [
    "الكل",
    "يمن موبايل",
    "سبأفون",
    "يو",
    "واي",
    "ثابت"
  ];

  // خريطة مقدمات الأرقام الخاصة بكل شركة لفلترة البحث بالاسم
  static const Map<String, String> companyPrefixes = {
    "يمن موبايل": "77",
    "سبأفون": "71",
    "يو": "73",
    "واي": "70",
    "ثابت": "0",
  };
}