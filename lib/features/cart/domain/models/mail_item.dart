import 'package:equatable/equatable.dart';

class MailItem extends Equatable {
  final String id;
  final String foodId;
  final String restaurantId;
  final String title;
  final double price;
  /// السعر الأصلي قبل حسم العرض، أو null إذا لم يكن على الوجبة عرض
  final double? originalPrice;
  final String? size;
  final double? sizePrice;
  final int quantity;
  final String imagePath;
  final List<Map<String, dynamic>> extras;
  final String notes;

  const MailItem({
    required this.id,
    required this.foodId,
    required this.restaurantId,
    required this.title,
    required this.price,
    this.originalPrice,
    this.size,
    this.sizePrice,
    required this.quantity,
    required this.imagePath,
    this.extras = const [],
    this.notes = "",
  });

  Map<String, dynamic> toJson() {
    return {
      "foodId": foodId,
      "quantity": quantity,
      // إذا كان الحجم فارغاً أو غير موجود نرسل null للسيرفر ليعتبره حجماً قياسياً
      "size": (size == null || size == "" || size == "standard")
          ? null
          : {"name": size, "price": sizePrice ?? 0.0},
      "extras": extras,
      "notes": notes,
    };
  }

  @override
  List<Object?> get props =>
      [
        id,
        foodId,
        restaurantId,
        title,
        price,
        originalPrice,
        size,
        sizePrice,
        quantity,
        imagePath,
        extras,
        notes
      ];
}