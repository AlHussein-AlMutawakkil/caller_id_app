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
    return rawResults.map((map) => ContactModel.fromMap(map)).toList();
  }
}