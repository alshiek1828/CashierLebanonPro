import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../providers/providers.dart';
import '../../../data/database/app_database.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  String _filter = 'all'; // all, low, out

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(activeProductsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.inventoryTitle),
      ),
      body: Column(
        children: [
          // Filter Chips
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(child: _buildFilterChip('all', 'الكل')),
                const SizedBox(width: 8),
                Expanded(child: _buildFilterChip('low', AppStrings.lowStock, color: Colors.orange)),
                const SizedBox(width: 8),
                Expanded(child: _buildFilterChip('out', AppStrings.outOfStock, color: Colors.red)),
              ],
            ),
          ),
          
          // Products List
          Expanded(
            child: productsAsync.when(
              data: (products) {
                var filteredProducts = products;
                
                if (_filter == 'low') {
                  filteredProducts = products.where((p) => p.stockQuantity > 0 && p.stockQuantity <= 10).toList();
                } else if (_filter == 'out') {
                  filteredProducts = products.where((p) => p.stockQuantity <= 0).toList();
                }
                
                if (filteredProducts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(AppStrings.noData, style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    return _InventoryCard(product: filteredProducts[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('خطأ: $error')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, {Color? color}) {
    final isSelected = _filter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _filter = value),
      selectedColor: (color ?? Theme.of(context).colorScheme.primary).withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? (color ?? Theme.of(context).colorScheme.primary) : null,
        fontWeight: isSelected ? FontWeight.bold : null,
      ),
    );
  }
}

// ==================== INVENTORY CARD ====================

class _InventoryCard extends ConsumerWidget {
  final Product product;
  
  const _InventoryCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    if (product.stockQuantity <= 0) {
      statusColor = Colors.red;
      statusText = AppStrings.outOfStock;
      statusIcon = Icons.cancel;
    } else if (product.stockQuantity <= 10) {
      statusColor = Colors.orange;
      statusText = '${AppStrings.lowStock} (${product.stockQuantity})';
      statusIcon = Icons.warning_amber;
    } else {
      statusColor = Colors.green;
      statusText = '${AppStrings.inStock} (${product.stockQuantity})';
      statusIcon = Icons.check_circle;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    product.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ActionButton(
                  icon: Icons.add,
                  label: AppStrings.addStock,
                  color: Colors.green,
                  onTap: () => _adjustStock(context, ref, product, true),
                ),
                _ActionButton(
                  icon: Icons.remove,
                  label: AppStrings.removeStock,
                  color: Colors.red,
                  onTap: () => _adjustStock(context, ref, product, false),
                ),
                _ActionButton(
                  icon: Icons.edit,
                  label: AppStrings.setQuantity,
                  color: Colors.blue,
                  onTap: () => _setExactQuantity(context, ref, product),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _adjustStock(BuildContext context, WidgetRef ref, Product product, bool isAddition) async {
    final controller = TextEditingController(text: '1');
    
    final quantity = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isAddition ? AppStrings.addStock : AppStrings.removeStock),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'الكمية',
            suffixText: isAddition ? '+' : '-',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text(AppStrings.cancel)),
          FilledButton(
            onPressed: () {
              final q = int.tryParse(controller.text);
              if (q != null && q > 0) Navigator.pop(context, q);
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
    
    if (quantity != null) {
      final newQty = isAddition 
          ? product.stockQuantity + quantity 
          : (product.stockQuantity - quantity).clamp(0, double.max).toInt();
      
      await _updateStock(context, ref, product, newQty, 
        isAddition ? 'إضافة مخزون' : 'سحب من المخزون'
      );
    }
  }

  Future<void> _setExactQuantity(BuildContext context, WidgetRef ref, Product product) async {
    final controller = TextEditingController(text: product.stockQuantity.toString());
    
    final newQuantity = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.setQuantity),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: AppStrings.quantity,
            suffixText: 'وحدة',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text(AppStrings.cancel)),
          FilledButton(
            onPressed: () {
              final q = int.tryParse(controller.text);
              if (q != null && q >= 0) Navigator.pop(context, q);
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
    
    if (newQuantity != null) {
      await _updateStock(context, ref, product, newQuantity, 'تعديل يدوي');
    }
  }

  Future<void> _updateStock(BuildContext context, WidgetRef ref, Product product, int newQuantity, String reason) async {
    try {
      final repo = ref.read(productsRepositoryProvider);
      await repo.update(product.copyWith(stockQuantity: Value(newQuantity)));
      
      ref.invalidate(activeProductsProvider);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم تحديث كمية ${product.name} إلى $newQuantity')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    }
  }
}

// ==================== ACTION BUTTON ====================

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, color: color)),
          ],
        ),
      ),
    );
  }
}
