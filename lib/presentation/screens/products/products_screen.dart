import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_strings.dart';
import '../../providers/providers.dart';
import '../../../data/database/app_database.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(
      _searchQuery.isEmpty ? activeProductsProvider : searchProductsProvider(_searchQuery)
    );
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.manageProducts),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: AppStrings.scanBarcodeBtn,
            onPressed: () => context.push('/barcode/scan'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppStrings.searchProducts,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _searchController.clear();
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),

          // Category Filter (if categories exist)
          categoriesAsync.when(
            data: (categories) {
              if (categories.length <= 1) return const SizedBox.shrink();
              return SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: categories.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildCategoryChip(context, AppStrings.allInvoices, null);
                    }
                    return _buildCategoryChip(context, categories[index - 1], categories[index - 1]);
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Products List
          Expanded(
            child: productsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return _buildEmptyState(context);
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return _ProductCard(product: products[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('خطأ: $error')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(context),
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.addProduct),
      ),
    );
  }

  Widget _buildCategoryChip(BuildContext context, String label, String? category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedCategory = selected ? category : null);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.noProducts,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.addFirstProduct,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddEditDialog(context),
            icon: const Icon(Icons.add),
            label: const Text(AppStrings.addProduct),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddEditDialog(BuildContext context, {Product? product}) async {
    await showDialog(
      context: context,
      builder: (context) => _AddEditProductDialog(product: product),
    );
    
    // Refresh the list
    ref.invalidate(activeProductsProvider);
    if (_searchQuery.isNotEmpty) {
      ref.invalidate(searchProductsProvider(_searchQuery));
    }
  }
}

// ==================== PRODUCT CARD WIDGET ====================

class _ProductCard extends ConsumerWidget {
  final Product product;
  
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showOptions(context, ref),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Product Image or Placeholder
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          product.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.image),
                        ),
                      )
                    : Icon(
                        Icons.shopping_bag_outlined,
                        color: Theme.of(context).colorScheme.primary,
                        size: 30,
                      ),
              ),
              
              const SizedBox(width: 12),
              
              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '\$${product.priceUsd.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.green[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${product.priceLbp.toStringAsFixed(0)} ل.ل',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                    if (product.barcode != null && product.barcode!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.qr_code, size: 14),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                product.barcode!,
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              
              // Stock Badge
              _StockBadge(quantity: product.stockQuantity),
            ],
          ),
        ),
      ),
    );
  }

  void _showOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text(AppStrings.editProduct),
              onTap: () {
                Navigator.pop(context);
                _showAddEditDialog(context, product: product, ref: ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code, color: Colors.blue),
              title: const Text(AppStrings.generateBarcode),
              onTap: () {
                Navigator.pop(context);
                _showBarcodeDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(AppStrings.deleteProduct),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddEditDialog(BuildContext context, {Product? product, required WidgetRef ref}) async {
    await showDialog(
      context: context,
      builder: (context) => _AddEditProductDialog(product: product),
    );
    ref.invalidate(activeProductsProvider);
  }

  Future<void> _showBarcodeDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.generateBarcode),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (product.barcode != null && product.barcode!.isNotEmpty)
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Text(
                      product.barcode!,
                      style: const TextStyle(
                        fontFamily: 'LibreBarcode39',
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            Text('اسم المنتج: ${product.name}'),
            Text('الباركود: ${product.barcode ?? "غير محدد"}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.confirmDelete),
        content: Text(AppStrings.deleteConfirmMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(productsRepositoryProvider).delete(product.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${AppStrings.deleteProduct}: ${product.name}')),
                  );
                }
                ref.invalidate(activeProductsProvider);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('خطأ: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text(AppStrings.deleteProduct),
          ),
        ],
      ),
    );
  }
}

// ==================== STOCK BADGE ====================

class _StockBadge extends StatelessWidget {
  final int quantity;
  
  const _StockBadge({required this.quantity});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;
    
    if (quantity <= 0) {
      color = Colors.red;
      text = AppStrings.outOfStock;
    } else if (quantity <= 10) {
      color = Colors.orange;
      text = '$quantity ${AppStrings.lowStock}';
    } else {
      color = Colors.green;
      text = '$quantity ${AppStrings.inStock}';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ==================== ADD/EDIT PRODUCT DIALOG ====================

class _AddEditProductDialog extends ConsumerStatefulWidget {
  final Product? product;
  
  const _AddEditProductDialog({this.product});

  @override
  ConsumerState<_AddEditProductDialog> createState() => _AddEditProductDialogState();
}

class _AddEditProductDialogState extends ConsumerState<_AddEditProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceUsdController;
  late final TextEditingController _priceLbpController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _stockController;
  late final TextEditingController _categoryController;
  
  String? _imagePath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _priceUsdController = TextEditingController(text: p?.priceUsd.toString() ?? '');
    _priceLbpController = TextEditingController(text: p?.priceLbp.toString() ?? '');
    _barcodeController = TextEditingController(text: p?.barcode ?? '');
    _stockController = TextEditingController(text: p?.stockQuantity.toString() ?? '0');
    _categoryController = TextEditingController(text: p?.category ?? 'عام');
    _imagePath = p?.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceUsdController.dispose();
    _priceLbpController.dispose();
    _barcodeController.dispose();
    _stockController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.product == null ? AppStrings.addProduct : AppStrings.editProduct,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: AppStrings.productName,
                  prefixIcon: const Icon(Icons.label_outline),
                ),
                validator: (v) => v?.isEmpty == true ? AppStrings.requiredField : null,
              ),
              const SizedBox(height: 12),

              // Price Fields Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceUsdController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: '${AppStrings.productPrice} (\$)',
                        prefixIcon: const Icon(Icons.attach_money),
                      ),
                      validator: (v) {
                        if (v?.isEmpty == true) return AppStrings.requiredField;
                        if (double.tryParse(v!) == null) return AppStrings.invalidPrice;
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _priceLbpController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: '${AppStrings.productPrice} (ل.ل)',
                        prefixIcon: const Icon(Icons.money),
                      ),
                      validator: (v) {
                        if (v?.isEmpty == true) return AppStrings.requiredField;
                        if (double.tryParse(v!) == null) return AppStrings.invalidPrice;
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Barcode Field with Scan Button
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _barcodeController,
                      decoration: InputDecoration(
                        labelText: AppStrings.productBarcode,
                        prefixIcon: const Icon(Icons.qr_code),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () async {
                      final result = await context.push<String>('/barcode/scan');
                      if (result != null) {
                        _barcodeController.text = result;
                      }
                    },
                    icon: const Icon(Icons.qr_code_scanner),
                    tooltip: AppStrings.scanBarcodeBtn,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Category & Stock Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _categoryController,
                      decoration: InputDecoration(
                        labelText: AppStrings.productCategory,
                        prefixIcon: const Icon(Icons.category_outline),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _stockController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: AppStrings.productStock,
                        prefixIcon: const Icon(Icons.inventory_2_outlined),
                      ),
                      validator: (v) {
                        if (int.tryParse(v ?? '') == null) return AppStrings.invalidQuantity;
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Image Picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 100,
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.outline),
                    borderRadius: BorderRadius.circular(10),
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  child: _imagePath != null
                      ? Stack(
                          alignment: Alignment.topRight,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(9),
                              child: Image.file(
                                File(_imagePath!),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(Icons.broken_image),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => setState(() => _imagePath = null),
                            ),
                          ],
                        )
                      : const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image_outlined, size: 32),
                              Text(AppStrings.productImage),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _isLoading ? null : _saveProduct,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.product == null ? AppStrings.addProduct : AppStrings.save),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _imagePath = image.path);
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final repository = ref.read(productsRepositoryProvider);
      
      final companion = ProductsCompanion(
        name: Value(_nameController.text.trim()),
        priceUsd: Value(double.parse(_priceUsdController.text)),
        priceLbp: Value(double.parse(_priceLbpController.text)),
        barcode: Value(_barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim()),
        category: Value(_categoryController.text.trim().isEmpty ? 'عام' : _categoryController.text.trim()),
        stockQuantity: Value(int.parse(_stockController.text)),
        imageUrl: Value(_imagePath),
        updatedAt: Value(DateTime.now()),
      );

      if (widget.product == null) {
        await repository.create(companion);
      } else {
        await repository.update(companion.copyWith(id: Value(widget.product!.id)));
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.product == null ? AppStrings.success : AppStrings.save)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppStrings.failed}: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
