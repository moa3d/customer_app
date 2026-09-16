class UserModel {
  final String id;
  final String name;
  final String phone;
  final String? imgUrl;
  final String gender;
  final String country;
  final bool isBanned;
  final String? createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.phone,
    this.imgUrl,
    required this.gender,
    required this.country,
    this.isBanned = false,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    String? extractedImgUrl;
    if (json['img'] != null && json['img'] is Map) {
      extractedImgUrl = json['img']['url'];
    }

    return UserModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      imgUrl: extractedImgUrl,
      gender: json['gender'] ?? '',
      country: json['country'] ?? 'SY',
      isBanned: json['isBanned'] ?? false,
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'phone': phone,
      'gender': gender,
      'country': country,
      'isBanned': isBanned,
      'img': imgUrl != null ? {'url': imgUrl} : null,
      'createdAt': createdAt,
    };
  }
}
