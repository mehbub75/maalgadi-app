import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String category;
  final int quantity;
  final double costPrice;
  final double sellPrice;
  final DateTime dateAdded;
  final int lowStockThreshold;
  final String? imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.costPrice,
    required this.sellPrice,
    required this.dateAdded,
    this.lowStockThreshold = 10,
    this.imageUrl,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      quantity: data['quantity'] ?? 0,
      costPrice: (data['costPrice'] ?? 0).toDouble(),
      sellPrice: (data['sellPrice'] ?? 0).toDouble(),
      dateAdded: (data['dateAdded'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lowStockThreshold: data['lowStockThreshold'] ?? 10,
      imageUrl: data['imageUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'category': category,
      'quantity': quantity,
      'costPrice': costPrice,
      'sellPrice': sellPrice,
      'dateAdded': Timestamp.fromDate(dateAdded),
      'lowStockThreshold': lowStockThreshold,
      'imageUrl': imageUrl,
    };
  }

  // Helper method to check if stock is low
  bool get isLowStock => quantity <= lowStockThreshold;

  // Copy with method for updating product instances
  Product copyWith({
    String? id,
    String? name,
    String? category,
    int? quantity,
    double? costPrice,
    double? sellPrice,
    DateTime? dateAdded,
    int? lowStockThreshold,
    String? imageUrl,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      costPrice: costPrice ?? this.costPrice,
      sellPrice: sellPrice ?? this.sellPrice,
      dateAdded: dateAdded ?? this.dateAdded,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

