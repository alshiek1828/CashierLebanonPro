import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/database_provider.dart';

// ==================== PRODUCTS PROVIDERS ====================

// All Products Provider
final allProductsProvider = FutureProvider<List<Product>>((ref) {
  final repository = ref.watch(productsRepositoryProvider);
  return repository.getAll();
});

// Active Products Provider
final activeProductsProvider = FutureProvider<List<Product>>((ref) {
  final repository = ref.watch(productsRepositoryProvider);
  return repository.getActive();
});

// Product by ID Provider
final productByIdProvider = FutureProvider.family<Product?, int>((ref, id) {
  final repository = ref.watch(productsRepositoryProvider);
  return repository.getById(id);
});

// Product by Barcode Provider
final productByBarcodeProvider = FutureProvider.family<Product?, String>((ref, barcode) {
  final repository = ref.watch(productsRepositoryProvider);
  return repository.getByBarcode(barcode);
});

// Search Products Provider
final searchProductsProvider = FutureProvider.family<List<Product>, String>((ref, query) {
  final repository = ref.watch(productsRepositoryProvider);
  if (query.isEmpty) return repository.getActive();
  return repository.search(query);
});

// Categories Provider
final categoriesProvider = FutureProvider<List<String>>((ref) {
  final repository = ref.watch(productsRepositoryProvider);
  return repository.getCategories();
});

// ==================== INVOICE PROVIDERS ====================

// All Invoices Provider
final allInvoicesProvider = FutureProvider<List<Invoice>>((ref) {
  final repository = ref.watch(invoicesRepositoryProvider);
  return repository.getAll();
});

// Invoice by ID Provider
final invoiceByIdProvider = FutureProvider.family<Invoice?, int>((ref, id) {
  final repository = ref.watch(invoicesRepositoryProvider);
  return repository.getById(id);
});

// Invoice Items Provider
final invoiceItemsProvider = FutureProvider.family<List<InvoiceItem>, int>((ref, invoiceId) {
  final repository = ref.watch(invoicesRepositoryProvider);
  return repository.getItems(invoiceId);
});

// ==================== CART PROVIDER ====================

class CartItem {
  final int? productId;
  final String name;
  double price;
  int quantity;
  final String unit;
  
  CartItem({
    this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    this.unit = 'piece',
  });
  
  double get total => price * quantity;
  
  CartItem copyWith({
    int? productId,
    String? name,
    double? price,
    int? quantity,
    String? unit,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
    );
  }
}

class CartState {
  final List<CartItem> items;
  final double discount;
  final double taxRate;
  final String customerName;
  final String notes;
  
  const CartState({
    this.items = const [],
    this.discount = 0.0,
    this.taxRate = 0.0,
    this.customerName = '',
    this.notes = '',
  });
  
  double get subtotal => items.fold(0.0, (sum, item) => sum + item.total);
  
  double get taxAmount => (subtotal - discount) * (taxRate / 100);
  
  double get total => (subtotal - discount) + taxAmount;
  
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  
  bool get isEmpty => items.isEmpty;
  
  CartState copyWith({
    List<CartItem>? items,
    double? discount,
    double? taxRate,
    String? customerName,
    String? notes,
  }) {
    return CartState(
      items: items ?? this.items,
      discount: discount ?? this.discount,
      taxRate: taxRate ?? this.taxRate,
      customerName: customerName ?? this.customerName,
      notes: notes ?? this.notes,
    );
  }
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());
  
  void addItem(CartItem item) {
    // Check if item already exists
    final existingIndex = state.items.indexWhere(
      (i) => i.productId == item.productId && i.name == item.name
    );
    
    if (existingIndex >= 0) {
      // Update quantity
      final existingItems = List<CartItem>.from(state.items);
      existingItems[existingIndex] = existingItems[existingIndex].copyWith(
        quantity: existingItems[existingIndex].quantity + item.quantity,
      );
      state = state.copyWith(items: existingItems);
    } else {
      state = state.copyWith(items: [...state.items, item]);
    }
  }
  
  void removeItem(int index) {
    final newItems = List<CartItem>.from(state.items)..removeAt(index);
    state = state.copyWith(items: newItems);
  }
  
  void updateQuantity(int index, int quantity) {
    if (quantity <= 0) {
      removeItem(index);
      return;
    }
    final newItems = List<CartItem>.from(state.items);
    newItems[index] = newItems[index].copyWith(quantity: quantity);
    state = state.copyWith(items: newItems);
  }
  
  void updatePrice(int index, double price) {
    final newItems = List<CartItem>.from(state.items);
    newItems[index] = newItems[index].copyWith(price: price);
    state = state.copyWith(items: newItems);
  }
  
  void setDiscount(double discount) {
    state = state.copyWith(discount: discount.clamp(0.0, state.subtotal));
  }
  
  void setTaxRate(double rate) {
    state = state.copyWith(taxRate: rate);
  }
  
  void setCustomerName(String name) {
    state = state.copyWith(customerName: name);
  }
  
  void setNotes(String notes) {
    state = state.copyWith(notes: notes);
  }
  
  void clearCart() {
    state = const CartState();
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});

// ==================== SETTINGS PROVIDERS ====================

// Store Name Provider
final storeNameProvider = FutureProvider<String>((ref) async {
  final repository = ref.watch(settingsRepositoryProvider);
  return await repository.getStoreName();
});

// Exchange Rate Provider
final exchangeRateProvider = FutureProvider<double>((ref) async {
  final repository = ref.watch(settingsRepositoryProvider);
  return await repository.getExchangeRate();
});

// Default Currency Provider
final defaultCurrencyProvider = FutureProvider<String>((ref) async {
  final repository = ref.watch(settingsRepositoryProvider);
  return await repository.getDefaultCurrency();
});

// Tax Rate Provider
final taxRateProvider = FutureProvider<double>((ref) async {
  final repository = ref.watch(settingsRepositoryProvider);
  return await repository.getTaxRate();
});

// Dark Mode Provider
final darkModeSettingsProvider = FutureProvider<bool>((ref) async {
  final repository = ref.watch(settingsRepositoryProvider);
  return await repository.isDarkMode();
});
