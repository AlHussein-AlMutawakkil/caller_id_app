import '../../../database/database_helper.dart';
import 'contact_model.dart';

class NumberSearchRepository {
  final DatabaseHelper _dbHelper;

  NumberSearchRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<ContactModel>> searchByNumber(String phoneQuery) async {
    final query = phoneQuery.trim();
    if (query.isEmpty) return [];

    final rawResults = await _dbHelper.searchByNumber(query);
    List<ContactModel> list = [];
    for (var map in rawResults) {
      String namesStr = (map['names'] ?? map['name'] ?? 'بدون اسم').toString();
      String phone = (map['phone'] ?? query).toString();
      List<String> splitNames = namesStr
          .split(RegExp(r'[,،|]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      if (splitNames.isEmpty) {
        list.add(ContactModel(name: namesStr, phone: phone));
      } else {
        for (var name in splitNames) {
          list.add(ContactModel(name: name, phone: phone));
        }
      }
    }
    return list;
  }
}