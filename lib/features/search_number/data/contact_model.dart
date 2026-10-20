class ContactModel {
  final int? id;
  final String name;
  final String phone;

  const ContactModel({
    this.id,
    required this.name,
    required this.phone,
  });

  factory ContactModel.fromMap(Map<String, dynamic> map) {
    return ContactModel(
      id: map['id'] as int?,
      name: (map['names'] ?? map['name'] ?? 'بدون اسم').toString(),
      phone: (map['phone'] ?? '').toString(),
    );
  }
}