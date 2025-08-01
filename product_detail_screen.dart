import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import 'add_product_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ProductService _productService = ProductService();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  
  late Product _product;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _updateStock() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Stock'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current stock: ${_product.quantity}'),
            const SizedBox(height: 16),
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'New Quantity',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
                hintText: 'e.g., Stock adjustment, Sale, Purchase',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _quantityController.clear();
              _reasonController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_quantityController.text.isNotEmpty && _reasonController.text.isNotEmpty) {
                final newQuantity = int.parse(_quantityController.text);
                final reason = _reasonController.text.trim();
                
                Navigator.pop(context);
                
                setState(() {
                  _isLoading = true;
                });

                final success = await _productService.updateStock(_product.id, newQuantity, reason);
                
                if (success && mounted) {
                  setState(() {
                    _product = _product.copyWith(quantity: newQuantity);
                    _isLoading = false;
                  });
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Stock updated successfully'),
                      backgroundColor: Color(0xFF4CAF50),
                    ),
                  );
                } else if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to update stock'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                
                _quantityController.clear();
                _reasonController.clear();
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _editProduct() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddProductScreen(product: _product),
      ),
    );

    if (result == true) {
      // Product was updated, go back to refresh the list
      Navigator.pop(context, true);
    }
  }

  Future<void> _deleteProduct() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${_product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      final success = await _productService.deleteProduct(_product.id);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product deleted successfully'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
        Navigator.pop(context, true); // Go back and refresh
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete product'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_product.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                _editProduct();
              } else if (value == 'delete') {
                _deleteProduct();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Header
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _product.name,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _product.category,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_product.isLowStock)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.red.shade200),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.warning, size: 16, color: Colors.red.shade600),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Low Stock',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.red.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Added on ${_product.dateAdded.day}/${_product.dateAdded.month}/${_product.dateAdded.year}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stock Information
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Stock Information',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: _updateStock,
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text('Update Stock'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoCard(
                                  'Current Stock',
                                  '${_product.quantity}',
                                  Icons.inventory,
                                  _product.isLowStock ? Colors.red : Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildInfoCard(
                                  'Low Stock Alert',
                                  '${_product.lowStockThreshold}',
                                  Icons.warning,
                                  Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Pricing Information
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pricing Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoCard(
                                  'Cost Price',
                                  '₹${_product.costPrice.toStringAsFixed(2)}',
                                  Icons.attach_money,
                                  Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildInfoCard(
                                  'Sell Price',
                                  '₹${_product.sellPrice.toStringAsFixed(2)}',
                                  Icons.sell,
                                  Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Profit per Unit',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  '₹${(_product.sellPrice - _product.costPrice).toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: (_product.sellPrice - _product.costPrice) >= 0 
                                        ? Colors.green 
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

