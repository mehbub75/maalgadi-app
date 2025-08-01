import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product.dart';
import '../models/stock_movement.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

  // Get products collection reference
  CollectionReference get _productsCollection =>
      _firestore.collection('users').doc(_userId).collection('products');

  // Get stock movements collection reference
  CollectionReference get _stockMovementsCollection =>
      _firestore.collection('users').doc(_userId).collection('stock_movements');

  // Get all products stream
  Stream<List<Product>> getProductsStream() {
    return _productsCollection
        .orderBy('dateAdded', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Product.fromFirestore(doc))
            .toList());
  }

  // Get products count
  Future<int> getProductsCount() async {
    try {
      final snapshot = await _productsCollection.get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // Get low stock products count
  Future<int> getLowStockCount() async {
    try {
      final snapshot = await _productsCollection.get();
      final products = snapshot.docs
          .map((doc) => Product.fromFirestore(doc))
          .toList();
      return products.where((product) => product.isLowStock).length;
    } catch (e) {
      return 0;
    }
  }

  // Get low stock products
  Future<List<Product>> getLowStockProducts() async {
    try {
      final snapshot = await _productsCollection.get();
      final products = snapshot.docs
          .map((doc) => Product.fromFirestore(doc))
          .toList();
      return products.where((product) => product.isLowStock).toList();
    } catch (e) {
      return [];
    }
  }

  // Get stock movements for today
  Future<Map<String, int>> getTodayStockMovements() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

      final snapshot = await _stockMovementsCollection
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      int stockIn = 0;
      int stockOut = 0;

      for (var doc in snapshot.docs) {
        final movement = StockMovement.fromFirestore(doc);
        if (movement.type == MovementType.inward) {
          stockIn += movement.quantity;
        } else {
          stockOut += movement.quantity;
        }
      }

      return {'stockIn': stockIn, 'stockOut': stockOut};
    } catch (e) {
      return {'stockIn': 0, 'stockOut': 0};
    }
  }

  // Add new product
  Future<bool> addProduct(Product product) async {
    try {
      await _productsCollection.add(product.toFirestore());
      
      // Add stock movement for initial stock
      if (product.quantity > 0) {
        final movement = StockMovement(
          id: '',
          productId: '',
          productName: product.name,
          type: MovementType.inward,
          quantity: product.quantity,
          reason: 'Initial stock',
          date: DateTime.now(),
          userId: _userId,
          userName: _auth.currentUser?.displayName ?? 'User',
        );
        await _stockMovementsCollection.add(movement.toFirestore());
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Update product
  Future<bool> updateProduct(Product product) async {
    try {
      await _productsCollection.doc(product.id).update(product.toFirestore());
      return true;
    } catch (e) {
      return false;
    }
  }

  // Delete product
  Future<bool> deleteProduct(String productId) async {
    try {
      await _productsCollection.doc(productId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Update stock quantity
  Future<bool> updateStock(String productId, int newQuantity, String reason) async {
    try {
      final productDoc = await _productsCollection.doc(productId).get();
      if (!productDoc.exists) return false;

      final product = Product.fromFirestore(productDoc);
      final oldQuantity = product.quantity;
      final difference = newQuantity - oldQuantity;

      // Update product quantity
      await _productsCollection.doc(productId).update({'quantity': newQuantity});

      // Add stock movement record
      if (difference != 0) {
        final movement = StockMovement(
          id: '',
          productId: productId,
          productName: product.name,
          type: difference > 0 ? MovementType.inward : MovementType.outward,
          quantity: difference.abs(),
          reason: reason,
          date: DateTime.now(),
          userId: _userId,
          userName: _auth.currentUser?.displayName ?? 'User',
        );
        await _stockMovementsCollection.add(movement.toFirestore());
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // Get recent stock movements
  Stream<List<StockMovement>> getRecentStockMovements({int limit = 10}) {
    return _stockMovementsCollection
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StockMovement.fromFirestore(doc))
            .toList());
  }

  // Search products
  Future<List<Product>> searchProducts(String query) async {
    try {
      final snapshot = await _productsCollection.get();
      final products = snapshot.docs
          .map((doc) => Product.fromFirestore(doc))
          .toList();
      
      return products.where((product) =>
          product.name.toLowerCase().contains(query.toLowerCase()) ||
          product.category.toLowerCase().contains(query.toLowerCase())
      ).toList();
    } catch (e) {
      return [];
    }
  }

  // Get products by category
  Future<List<Product>> getProductsByCategory(String category) async {
    try {
      final snapshot = await _productsCollection
          .where('category', isEqualTo: category)
          .get();
      return snapshot.docs
          .map((doc) => Product.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Get all categories
  Future<List<String>> getCategories() async {
    try {
      final snapshot = await _productsCollection.get();
      final products = snapshot.docs
          .map((doc) => Product.fromFirestore(doc))
          .toList();
      
      final categories = products.map((product) => product.category).toSet().toList();
      categories.sort();
      return categories;
    } catch (e) {
      return [];
    }
  }
}

