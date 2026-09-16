// موديل تصنيف أصناف مطعم — يقابل GET /api/user/categories/:id بالباك إند
class FoodCategory {
  final String id;
  final String name;

  FoodCategory({required this.id, required this.name});

  factory FoodCategory.fromJson(Map<String, dynamic> json) {
    return FoodCategory(
      id: (json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
    );
  }
}
