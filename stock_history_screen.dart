import 'package:flutter/material.dart';
import '../../services/product_service.dart';
import '../../models/stock_movement.dart';

class StockHistoryScreen extends StatefulWidget {
  const StockHistoryScreen({super.key});

  @override
  State<StockHistoryScreen> createState() => _StockHistoryScreenState();
}

class _StockHistoryScreenState extends State<StockHistoryScreen> {
  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();
  
  List<StockMovement> _allMovements = [];
  List<StockMovement> _filteredMovements = [];
  MovementType? _selectedType;
  DateTime? _selectedDate;
  bool _isLoading = true;

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
      // Load data and set loading to false
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterMovements(List<StockMovement> movements) {
    List<StockMovement> filtered = movements;

    // Filter by search query
    if (_searchController.text.isNotEmpty) {
      filtered = filtered.where((movement) =>
          movement.productName.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          movement.reason.toLowerCase().contains(_searchController.text.toLowerCase())
      ).toList();
    }

    // Filter by movement type
    if (_selectedType != null) {
      filtered = filtered.where((movement) => movement.type == _selectedType).toList();
    }

    // Filter by date
    if (_selectedDate != null) {
      filtered = filtered.where((movement) {
        final movementDate = movement.date;
        return movementDate.year == _selectedDate!.year &&
               movementDate.month == _selectedDate!.month &&
               movementDate.day == _selectedDate!.day;
      }).toList();
    }

    setState(() {
      _filteredMovements = filtered;
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _filterMovements(_allMovements);
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedType = null;
      _selectedDate = null;
      _searchController.clear();
      _filteredMovements = _allMovements;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock History'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
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
                    hintText: 'Search by product or reason...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    if (_allMovements.isNotEmpty) {
                      _filterMovements(_allMovements);
                    }
                  },
                ),
                const SizedBox(height: 12),
                
                // Active Filters
                if (_selectedType != null || _selectedDate != null)
                  Container(
                    width: double.infinity,
                    child: Wrap(
                      spacing: 8,
                      children: [
                        if (_selectedType != null)
                          Chip(
                            label: Text(_selectedType == MovementType.inward ? 'Stock In' : 'Stock Out'),
                            onDeleted: () {
                              setState(() {
                                _selectedType = null;
                                _filterMovements(_allMovements);
                              });
                            },
                            backgroundColor: _selectedType == MovementType.inward 
                                ? Colors.green.shade50 
                                : Colors.red.shade50,
                          ),
                        if (_selectedDate != null)
                          Chip(
                            label: Text('${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'),
                            onDeleted: () {
                              setState(() {
                                _selectedDate = null;
                                _filterMovements(_allMovements);
                              });
                            },
                            backgroundColor: Colors.blue.shade50,
                          ),
                        TextButton(
                          onPressed: _clearFilters,
                          child: const Text('Clear All'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          // Stock Movements List
          Expanded(
            child: StreamBuilder<List<StockMovement>>(
              stream: _productService.getRecentStockMovements(limit: 100),
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
                          'Error loading stock history',
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
                          Icons.history,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No stock movements found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Stock movements will appear here when you add or update products',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                // Update movements and apply filters
                _allMovements = snapshot.data!;
                if (_filteredMovements.isEmpty && _searchController.text.isEmpty && _selectedType == null && _selectedDate == null) {
                  _filteredMovements = _allMovements;
                } else {
                  _filterMovements(_allMovements);
                }

                if (_filteredMovements.isEmpty) {
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
                          'No movements match your filters',
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
                    itemCount: _filteredMovements.length,
                    itemBuilder: (context, index) {
                      final movement = _filteredMovements[index];
                      return _buildMovementCard(movement);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovementCard(StockMovement movement) {
    final isInward = movement.type == MovementType.inward;
    final color = isInward ? Colors.green : Colors.red;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isInward ? Icons.arrow_downward : Icons.arrow_upward,
                    color: color,
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        movement.typeString,
                        style: TextStyle(
                          fontSize: 14,
                          color: color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isInward ? '+' : '-'}${movement.quantity}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      movement.formattedDate,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reason',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    movement.reason,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.person,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  'By ${movement.userName}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${movement.date.hour.toString().padLeft(2, '0')}:${movement.date.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Stock History'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Movement Type Filter
            const Text(
              'Movement Type',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilterChip(
                    label: const Text('Stock In'),
                    selected: _selectedType == MovementType.inward,
                    onSelected: (selected) {
                      setState(() {
                        _selectedType = selected ? MovementType.inward : null;
                      });
                    },
                    selectedColor: Colors.green.shade50,
                    checkmarkColor: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilterChip(
                    label: const Text('Stock Out'),
                    selected: _selectedType == MovementType.outward,
                    onSelected: (selected) {
                      setState(() {
                        _selectedType = selected ? MovementType.outward : null;
                      });
                    },
                    selectedColor: Colors.red.shade50,
                    checkmarkColor: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Date Filter
            const Text(
              'Date',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selectDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _selectedDate != null
                          ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                          : 'Select Date',
                    ),
                    const Spacer(),
                    if (_selectedDate != null)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDate = null;
                          });
                        },
                        child: const Icon(Icons.clear, size: 20),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _clearFilters();
              Navigator.pop(context);
            },
            child: const Text('Clear All'),
          ),
          ElevatedButton(
            onPressed: () {
              _filterMovements(_allMovements);
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}

