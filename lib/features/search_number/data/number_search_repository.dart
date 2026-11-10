import '../../../database/database_helper.dart';
import 'contact_model.dart';

class NumberSearchRepository {
  final DatabaseHelper _dbHelper;

  NumberSearchRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<ContactModel>> searchByNumber(String phoneQuery) async {
    final query = phoneQuery.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (query.isEmpty) return [];

    String cleanNumber = query;
    if (cleanNumber.startsWith('+967')) {
      cleanNumber = cleanNumber.substring(4);
    } else if (cleanNumber.startsWith('00967')) {
      cleanNumber = cleanNumber.substring(5);
    } else if (cleanNumber.startsWith('967') && cleanNumber.length > 7) {
      cleanNumber = cleanNumber.substring(3);
    }

    // استعلام قاعدة البيانات لجميع صيغ الرقم (مع وبدون الصفر، وكود الدولة) دفعة واحدة
    final rawResults = await _dbHelper.searchByNumber(cleanNumber);

    final Set<String> distinctNames = {};

    // تنسيق رقم العرض ليكون قياسياً وأنيقاً للمستخدم (مثال: 01209302 أو 0771234567)
    String displayPhone = cleanNumber;
    if (!displayPhone.startsWith('0') &&
        (displayPhone.length == 7 || displayPhone.length == 8 || displayPhone.length == 9)) {
      displayPhone = '0$displayPhone';
    }

    for (var map in rawResults) {
      String namesStr = (map['names'] ?? map['name'] ?? 'بدون اسم').toString();
      List<String> splitNames = namesStr
          .split(RegExp(r'[,،|\n]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      distinctNames.addAll(splitNames);
    }

    return distinctNames
        .map((name) => ContactModel(name: name, phone: displayPhone))
        .toList();
  }
}