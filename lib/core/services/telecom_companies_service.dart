import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../constants/app_constants.dart';

class TelecomCompanyModel {
  final String name;
  final String prefix;

  TelecomCompanyModel({required this.name, required this.prefix});

  Map<String, dynamic> toJson() => {'name': name, 'prefix': prefix};

  factory TelecomCompanyModel.fromJson(Map<String, dynamic> json) {
    return TelecomCompanyModel(
      name: json['name'] as String,
      prefix: json['prefix'] as String,
    );
  }
}

class TelecomCompaniesService {
  TelecomCompaniesService._();
  static final TelecomCompaniesService instance = TelecomCompaniesService._();

  static const String _fileName = 'telecom_companies.json';

  Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, _fileName));
  }

  Future<List<TelecomCompanyModel>> getCompanies() async {
    try {
      final file = await _getFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> data = jsonDecode(content);
        final list = data.map((e) => TelecomCompanyModel.fromJson(e as Map<String, dynamic>)).toList();
        _syncWithAppConstants(list);
        return list;
      }
    } catch (_) {}

    // القائمة الافتراضية
    final defaultList = [
      TelecomCompanyModel(name: 'يمن موبايل', prefix: '77'),
      TelecomCompanyModel(name: 'سبأفون', prefix: '71'),
      TelecomCompanyModel(name: 'يو', prefix: '73'),
      TelecomCompanyModel(name: 'واي', prefix: '70'),
      TelecomCompanyModel(name: 'ثابت', prefix: '0'),
    ];
    _syncWithAppConstants(defaultList);
    return defaultList;
  }

  void _syncWithAppConstants(List<TelecomCompanyModel> list) {
    AppConstants.companies = ['الكل', ...list.map((c) => c.name)];
    AppConstants.companyPrefixes = {
      for (var c in list) c.name: c.prefix,
    };
  }

  Future<void> saveCompanies(List<TelecomCompanyModel> list) async {
    try {
      final file = await _getFile();
      final jsonStr = jsonEncode(list.map((c) => c.toJson()).toList());
      await file.writeAsString(jsonStr);
      _syncWithAppConstants(list);
    } catch (_) {}
  }

  Future<void> addCompany(String name, String prefix) async {
    final list = await getCompanies();
    list.add(TelecomCompanyModel(name: name.trim(), prefix: prefix.trim()));
    await saveCompanies(list);
  }

  Future<void> updateCompany(int index, String newName, String newPrefix) async {
    final list = await getCompanies();
    if (index >= 0 && index < list.length) {
      list[index] = TelecomCompanyModel(name: newName.trim(), prefix: newPrefix.trim());
      await saveCompanies(list);
    }
  }

  Future<void> deleteCompany(int index) async {
    final list = await getCompanies();
    if (index >= 0 && index < list.length) {
      list.removeAt(index);
      await saveCompanies(list);
    }
  }
}
