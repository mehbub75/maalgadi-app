import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/product_service.dart';
import '../../models/product.dart';
import '../../models/stock_movement.dart';
import '../products/add_product_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ProductService _productService = ProductService();
  int _totalProducts = 0;
  int _lowStockCount = 0;
  int _stockIn = 0;
  int _stockOut = 0;
  List<Product> _lowStockProducts = [];
  List<StockMovement> _recentMovements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load statistics
      final totalProducts = await _productService.getProductsCount();
      final lowStockCount = await _productService.getLowStockCount();
      final todayMovements = await _productService.getTodayStockMovements();
      final lowStockProducts = await _productService.getLowStockProducts();

      setState(() {
        _totalProducts = totalProducts;
        _lowStockCount = lowStockCount;
        _stockIn = todayMovements['stockIn'] ?? 0;
        _stockOut = todayMovements['stockOut'] ?? 0;
        _lowStockProducts = lowStockProducts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MaalGadi',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Welcome, ${user?.displayName?.split(' ').first ?? 'User'}!',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
        actions: [
          if (_lowStockCount > 0)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    _showLowStockAlert(context);
                  },
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_lowStockCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            )
          else
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No notifications'),
                    backgroundColor: Color(0xFF4CAF50),
                  ),
                );
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Statistics Cards
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: 'Total Products',
                        value: '$_totalProducts',
                        icon: Icons.inventory_2,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        title: 'Low Stock',
                        value: '$_lowStockCount',
                        icon: Icons.warning,
                        color: _lowStockCount > 0 ? Colors.red : Colors.orange,
                        onTap: _lowStockCount > 0 ? () => _showLowStockAlert(context) : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: 'Stock In (Today)',
                        value: '$_stockIn',
                        icon: Icons.arrow_downward,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        title: 'Stock Out (Today)',
                        value: '$_stockOut',
                        icon: Icons.arrow_upward,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              
              // Quick Actions
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              
              // Add Product Button
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddProductScreen(),
                      ),
                    );
                    
                    if (result == true) {
                      // Refresh dashboard data if product was added
                      _loadDashboardData();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add),
                      SizedBox(width: 8),
                      Text(
                        'Add New Product',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Quick Action Buttons
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionButton(
                      title: 'View Products',
                      icon: Icons.list,
                      onTap: () {
                        // TODO: Navigate to products screen
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickActionButton(
                      title: 'Stock History',
                      icon: Icons.history,
                      onTap: () {
                        // TODO: Navigate to stock history screen
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Recent Activity Section
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              
              // Recent Stock Movements
              StreamBuilder<List<StockMovement>>(
                stream: _productService.getRecentStockMovements(limit: 5),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No recent activity',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Start by adding your first product',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return Column(
                    children: snapshot.data!.map((movement) => 
                      _buildActivityItem(movement)
                    ).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: const Color(0xFF4CAF50),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(StockMovement movement) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: movement.type == MovementType.inward 
                  ? Colors.green.shade50 
                  : Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              movement.type == MovementType.inward 
                  ? Icons.arrow_downward 
                  : Icons.arrow_upward,
              color: movement.type == MovementType.inward 
                  ? Colors.green 
                  : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movement.productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${movement.typeString}: ${movement.quantity} units',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            movement.formattedDate,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showLowStockAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Low Stock Alert'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You have $_lowStockCount products running low on stock:'),
            const SizedBox(height: 12),
            ..._lowStockProducts.take(5).map((product) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• ${product.name} (${product.quantity} left)',
                style: const TextStyle(fontSize: 14),
              ),
            )),
            if (_lowStockProducts.length > 5)
              Text(
                'and ${_lowStockProducts.length - 5} more...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

