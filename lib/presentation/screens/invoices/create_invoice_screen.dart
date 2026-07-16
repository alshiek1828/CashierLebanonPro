import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../providers/providers.dart';

class CreateInvoiceScreen extends ConsumerStatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  ConsumerState<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends ConsumerState<CreateInvoiceScreen> {
  final _searchController = TextEditingController();
  final _discountController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.createNewInvoice),
        actions: [
          if (!cartState.isEmpty)
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('تفريغ السلة'),
                    content: const Text('هل أنت متأكد من تفريغ السلة؟'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(AppStrings.cancel),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(cartProvider.notifier).clearCart();
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text(AppStrings.clearCart),
                      ),
                    ],
                  ),
                );
              },
              child: const Text(AppStrings.clearCart, style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: AppStrings.productNameHint,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() => _searchQuery = '');
                                _searchController.clear();
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: () async {
                    final result = await context.push<String>('/barcode/scan');
                    if (result != null) {
                      _addProductByBarcode(result);
                    }
                  },
                  icon: const Icon(Icons.qr_code_scanner),
                  tooltip: AppStrings.scanBarcodeBtn,
                ),
              ],
            ),
          ),

          // Cart Items or Product Search
          Expanded(
            child: cartState.isEmpty && _searchQuery.isEmpty
                ? _buildEmptyCart(context)
                : cartState.isEmpty
                    ? _buildProductSearch()
                    : _buildCartItems(context, cartState),
          ),

          // Summary & Checkout
          if (!cartState.isEmpty) _buildSummarySection(context, cartState),
        ],
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.cartIsEmpty,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.addProductsToCart,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _searchController.requestFocus(),
            icon: const Icon(Icons.search),
            label: const Text(AppStrings.searchAddProducts),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSearch() {
    final productsAsync = ref.watch(searchProductsProvider(_searchQuery));
    
    return productsAsync.when(
      data: (products) {
        if (products.isEmpty) {
          return Center(child: Text(AppStrings.noResults));
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(product.name[0]),
              ),
              title: Text(product.name),
              subtitle: Text('\$${product.priceUsd.toStringAsFixed(2)}'),
              trailing: const Icon(Icons.add_circle_outline, color: Colors.green),
              onTap: () => _addToCart(product),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('خطأ: $error')),
    );
  }

  Widget _buildCartItems(BuildContext context, CartState cartState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'عناصر السلة (${cartState.itemCount})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _searchQuery = ''),
                child: const Text('+ إضافة المزيد'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: cartState.items.length,
            itemBuilder: (context, index) {
              final item = cartState.items[index];
              return _CartItemTile(item: item, index: index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummarySection(BuildContext context, CartState cartState) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Discount Input
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _discountController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: AppStrings.discount,
                      prefixIcon: const Icon(Icons.percent),
                      suffixText: '\$',
                    ),
                    onChanged: (v) {
                      final discount = double.tryParse(v) ?? 0;
                      ref.read(cartProvider.notifier).setDiscount(discount);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 100,
                  child: FilledButton.tonal(
                    onPressed: () {},
                    child: Text('${AppStrings.tax}: ${cartState.taxRate.toStringAsFixed(0)}%'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Totals
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppStrings.subtotal),
                Text('\$${cartState.subtotal.toStringAsFixed(2)}'),
              ],
            ),
            if (cartState.discount > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AppStrings.discount, style: const TextStyle(color: Colors.red)),
                  Text('-\$${cartState.discount.toStringAsFixed(2)}', 
                       style: const TextStyle(color: Colors.red)),
                ],
              ),
            if (cartState.taxRate > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AppStrings.tax),
                  Text('\$${cartState.taxAmount.toStringAsFixed(2)}'),
                ],
              ),
            
            const Divider(height: 24),
            
            // Grand Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.grandTotal,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '\$${cartState.total.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Checkout Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: () => _proceedToPayment(context, cartState.total),
                icon: const Icon(Icons.payment),
                label: Text(
                  AppStrings.proceedToPayment,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addToCart(Product product) {
    ref.read(cartProvider.notifier).addItem(CartItem(
      productId: product.id,
      name: product.name,
      price: product.priceUsd,
      quantity: 1,
    ));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تمت إضافة ${product.name} للسلة'),
        duration: const Duration(seconds: 1),
        action: SnackBarAction(
          label: 'تراجع',
          textColor: Colors.white,
          onPressed: () {
            // Could implement undo here
          },
        ),
      ),
    );
    
    setState(() => _searchQuery = '');
    _searchController.clear();
  }

  void _addProductByBarcode(String barcode) async {
    final repository = ref.read(productsRepositoryProvider);
    final product = await repository.getByBarcode(barcode);
    
    if (product != null) {
      _addToCart(product);
    } else {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text(AppStrings.productNotFound),
            content: Text('الباركود: $barcode\n\nهل تريد إضافة هذا كمنتج جديد؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(AppStrings.cancel),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to add product with barcode pre-filled
                  // This would require passing data through router
                },
                child: const Text(AppStrings.addNewProduct),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _proceedToPayment(BuildContext context, double total) async {
    final result = await context.push<bool>(
      '/payment',
      extra: {'totalAmount': total},
    );
    
    if (result == true) {
      // Payment successful, clear cart and show success
      ref.read(cartProvider.notifier).clearCart();
      _discountController.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.paymentSuccess)),
        );
      }
    }
  }
}

// ==================== CART ITEM TILE ====================

class _CartItemTile extends ConsumerWidget {
  final CartItem item;
  final int index;
  
  const _CartItemTile({required this.item, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Item Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '\$${item.price.toStringAsFixed(2)} لكل وحدة',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            
            // Quantity Controls
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).colorScheme.outline),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, size: 18),
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    onPressed: () {
                      ref.read(cartProvider.notifier).updateQuantity(index, item.quantity - 1);
                    },
                  ),
                  Text(
                    '${item.quantity}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 18),
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    onPressed: () {
                      ref.read(cartProvider.notifier).updateQuantity(index, item.quantity + 1);
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Total & Delete
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${item.total.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    ref.read(cartProvider.notifier).removeItem(index);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
