import 'package:cloud_firestore/cloud_firestore.dart';

enum MovementType { inward, outward }

class StockMovement {
  final String id;
  final String productId;
  final String productName;
  final MovementType type;
  final int quantity;
  final String reason;
  final DateTime date;
  final String userId;
  final String userName;

  StockMovement({
    required this.id,
    required this.productId,
    required this.productName,
    required this.type,
    required this.quantity,
    required this.reason,
    required this.date,
    required this.userId,
    required this.userName,
  });

  factory StockMovement.fromMap(Map<String, dynamic> data, String id) {
    return StockMovement(
      id: id,
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      type: data['type'] == 'inward' ? MovementType.inward : MovementType.outward,
      quantity: data['quantity'] ?? 0,
      reason: data['reason'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
    );
  }

  factory StockMovement.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return StockMovement.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'type': type == MovementType.inward ? 'inward' : 'outward',
      'quantity': quantity,
      'reason': reason,
      'date': Timestamp.fromDate(date),
      'userId': userId,
      'userName': userName,
    };
  }

  Map<String, dynamic> toFirestore() {
    return toMap();
  }

  String get typeString {
    return type == MovementType.inward ? 'Stock In' : 'Stock Out';
  }

  String get formattedDate {
    return '${date.day}/${date.month}/${date.year}';
  }
}

