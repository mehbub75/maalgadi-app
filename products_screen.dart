import 'package:flutter/material.dart';
import '../../services/product_service.dart';
import '../../models/product.dart';
import 'add_product_screen.dart';
import 'product_detail_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  List<String> _categories = [];
  String? _selectedCategory;
  bool _isLoading = true;
  bool _showLowStockOnly = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final categories = await _productService.getCategories();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterProducts(List<Product> products) {
    List<Product> filtered = products;

    // Filter by search query
    if (_searchController.text.isNotEmpty) {
      filtered = filtered.where((product) =>
          product.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          product.category.toLowerCase().contains(_searchController.text.toLowerCase())
      ).toList();
    }

    // Filter by category
    if (_selectedCategory != null && _selectedCategory != 'All') {
      filtered = filtered.where((product) => product.category == _selectedCategory).toList();
    }

    // Filter by low stock
    if (_showLowStockOnly) {
      filtered = filtered.where((product) => product.isLowStock).toList();
    }

    setState(() {
      _filteredProducts = filtered;
    });
  }

  Future<void> _navigateToAddProduct([Product? product]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddProductScreen(product: product),
      ),
    );

    if (result == true) {
      // Refresh the data if a product was added/updated
      _loadData();
    }
  }

  Future<void> _deleteProduct(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
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
      final success = await _productService.deleteProduct(product.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product deleted successfully'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete product'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportToCSV() async {
    try {
      if (_allProducts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No products to export'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Create CSV content
      String csvContent = 'Name,Category,Quantity,Cost Price,Sell Price,Profit,Date Added,Low Stock Threshold,Status\n';
      
      for (final product in _allProducts) {
        final profit = product.sellPrice - product.costPrice;
        final status = product.isLowStock ? 'Low Stock' : 'In Stock';
        final dateAdded = '${product.dateAdded.day}/${product.dateAdded.month}/${product.dateAdded.year}';
        
        csvContent += '"${product.name}","${product.category}",${product.quantity},${product.costPrice},${product.sellPrice},${profit.toStringAsFixed(2)},"$dateAdded",${product.lowStockThreshold},"$status"\n';
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported ${_allProducts.length} products to CSV'),
          backgroundColor: const Color(0xFF4CAF50),
          action: SnackBarAction(
            label: 'View',
            textColor: Colors.white,
            onPressed: () {
              // Show CSV content in a dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('CSV Export'),
                  content: SingleChildScrollView(
                    child: Text(
                      csvContent,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to export CSV'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(
              _showLowStockOnly ? Icons.warning : Icons.warning_outlined,
              color: _showLowStockOnly ? Colors.red : Colors.white,
            ),
            onPressed: () {
              setState(() {
                _showLowStockOnly = !_showLowStockOnly;
              });
            },
            tooltip: 'Show low stock only',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'export') {
                _exportToCSV();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download, size: 20),
                    SizedBox(width: 8),
                    Text('Export to CSV'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade50,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    // Trigger filter when search text changes
                    if (_allProducts.isNotEmpty) {
                      _filterProducts(_allProducts);
                    }
                  },
                ),
                const SizedBox(height: 12),
                
                // Category Filter
                if (_categories.isNotEmpty)
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildCategoryChip('All'),
                        ..._categories.map((category) => _buildCategoryChip(category)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          // Products List
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: _productService.getProductsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading products',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No products found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add your first product to get started',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _navigateToAddProduct(),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Product'),
                        ),
                      ],
                    ),
                  );
                }

                // Update products and apply filters
                _allProducts = snapshot.data!;
                if (_filteredProducts.isEmpty && _searchController.text.isEmpty && _selectedCategory == null && !_showLowStockOnly) {
                  _filteredProducts = _allProducts;
                } else {
                  _filterProducts(_allProducts);
                }

                if (_filteredProducts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No products match your filters',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your search or filters',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = _filteredProducts[index];
                      return _buildProductCard(product);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddProduct(),
        backgroundColor: const Color(0xFF4CAF50),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = _selectedCategory == category || 
                     (category == 'All' && _selectedCategory == null);
    
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(category),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = category == 'All' ? null : category;
            _filterProducts(_allProducts);
          });
        },
        selectedColor: const Color(0xFF4CAF50).withOpacity(0.2),
        checkmarkColor: const Color(0xFF4CAF50),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(product: product),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product.category,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _navigateToAddProduct(product);
                      } else if (value == 'delete') {
                        _deleteProduct(product);
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
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoChip(
                      'Quantity',
                      '${product.quantity}',
                      product.isLowStock ? Colors.red : Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoChip(
                      'Cost',
                      '₹${product.costPrice.toStringAsFixed(2)}',
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoChip(
                      'Sell',
                      '₹${product.sellPrice.toStringAsFixed(2)}',
                      Colors.green,
                    ),
                  ),
                ],
              ),
              if (product.isLowStock) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(6),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

