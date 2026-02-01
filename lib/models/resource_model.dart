class ResourceModel {
  final String id;
  final String name;
  final int quantity;
  final String imageUrl;
  final String unit;

  ResourceModel({
    required this.id,
    required this.name,
    required this.quantity,
    this.imageUrl = '',
    this.unit = 'kg',
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'imageUrl': imageUrl,
      'unit': unit,
    };
  }

  factory ResourceModel.fromMap(Map<String, dynamic> map, String id) {
    return ResourceModel(
      id: id,
      name: map['name'] ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      imageUrl: map['imageUrl'] ?? '',
      unit: map['unit'] ?? 'kg',
    );
  }
}
