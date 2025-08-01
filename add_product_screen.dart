import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/product_service.dart';
import '../../models/product.dart';

class AddProductScreen extends StatefulWidget {
  final Product? product; // For editing existing product
  
  const AddProductScreen({super.key, this.product});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _quantityController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _sellPriceController = TextEditingController();
  final _lowStockThresholdController = TextEditingController();
  
  final ProductService _productService = ProductService();
  bool _isLoading = false;
  List<String> _categories = [];
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    
    // If editing, populate fields
    if (widget.product != null) {
      final product = widget.product!;
      _nameController.text = product.name;
      _categoryController.text = product.category;
      _selectedCategory = product.category;
      _quantityController.text = product.quantity.toString();
      _costPriceController.text = product.costPrice.toString();
      _sellPriceController.text = product.sellPrice.toString();
      _lowStockThresholdController.text = product.lowStockThreshold.toString();
    } else {
      _lowStockThresholdController.text = '10'; // Default value
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _quantityController.dispose();
    _costPriceController.dispose();
    _sellPriceController.dispose();
    _lowStockThresholdController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final categories = await _productService.getCategories();
    setState(() {
      _categories = categories;
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final product = Product(
        id: widget.product?.id ?? '',
        name: _nameController.text.trim(),
        category: _selectedCategory ?? _categoryController.text.trim(),
        quantity: int.parse(_quantityController.text),
        costPrice: double.parse(_costPriceController.text),
        sellPrice: double.parse(_sellPriceController.text),
        dateAdded: widget.product?.dateAdded ?? DateTime.now(),
        lowStockThreshold: int.parse(_lowStockThresholdController.text),
      );

      bool success;
      if (widget.product != null) {
        // Update existing product
        success = await _productService.updateProduct(product);
      } else {
        // Add new product
        success = await _productService.addProduct(product);
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.product != null 
                ? 'Product updated successfully!' 
                : 'Product added successfully!'),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save product. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product != null ? 'Edit Product' : 'Add Product'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveProduct,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Product Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Product Name *',
                  prefixIcon: const Icon(Icons.inventory_2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF4CAF50)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter product name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_categories.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Category *',
                        prefixIcon: const Icon(Icons.category),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF4CAF50)),
                        ),
                      ),
                      items: [
                        ..._categories.map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        )),
                        const DropdownMenuItem(
                          value: 'new',
                          child: Text('+ Add New Category'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          if (value == 'new') {
                            _selectedCategory = null;
                          } else {
                            _selectedCategory = value;
                            _categoryController.text = value ?? '';
                          }
                        });
                      },
                      validator: (value) {
                        if (_selectedCategory == null && _categoryController.text.trim().isEmpty) {
                          return 'Please select or enter a category';
                        }
                        return null;
                      },
                    ),
                    if (_selectedCategory == null) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _categoryController,
                        decoration: InputDecoration(
                          labelText: 'New Category *',
                          prefixIcon: const Icon(Icons.add),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF4CAF50)),
                          ),
                        ),
                        validator: (value) {
                          if (_selectedCategory == null && (value == null || value.trim().isEmpty)) {
                            return 'Please enter category name';
                          }
                          return null;
                        },
                      ),
                    ],
                  ] else
                    TextFormField(
                      controller: _categoryController,
                      decoration: InputDecoration(
                        labelText: 'Category *',
                        prefixIcon: const Icon(Icons.category),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF4CAF50)),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter category';
                        }
                        return null;
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Quantity
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Quantity *',
                  prefixIcon: const Icon(Icons.numbers),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF4CAF50)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter quantity';
                  }
                  if (int.tryParse(value) == null || int.parse(value) < 0) {
                    return 'Please enter a valid quantity';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Cost Price
              TextFormField(
                controller: _costPriceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  labelText: 'Cost Price *',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF4CAF50)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter cost price';
                  }
                  if (double.tryParse(value) == null || double.parse(value) < 0) {
                    return 'Please enter a valid cost price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Sell Price
              TextFormField(
                controller: _sellPriceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  labelText: 'Sell Price *',
                  prefixIcon: const Icon(Icons.sell),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF4CAF50)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter sell price';
                  }
                  if (double.tryParse(value) == null || double.parse(value) < 0) {
                    return 'Please enter a valid sell price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Low Stock Threshold
              TextFormField(
                controller: _lowStockThresholdController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Low Stock Threshold',
                  prefixIcon: const Icon(Icons.warning),
                  helperText: 'Alert when stock falls below this number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF4CAF50)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter low stock threshold';
                  }
                  if (int.tryParse(value) == null || int.parse(value) < 0) {
                    return 'Please enter a valid threshold';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProduct,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        widget.product != null ? 'Update Product' : 'Add Product',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

