import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_database.dart';

// Database Provider
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

// Products Repository Provider
final productsRepositoryProvider = Provider<ProductsRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ProductsRepository(db);
});

// Invoices Repository Provider
final invoicesRepositoryProvider = Provider<InvoicesRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return InvoicesRepository(db);
});

// Settings Repository Provider
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return SettingsRepository(db);
});

// ==================== PRODUCTS REPOSITORY ====================

class ProductsRepository {
  final AppDatabase _db;
  
  ProductsRepository(this._db);

  Future<List<Product>> getAll() => _db.getAllProducts();
  
  Future<List<Product>> getActive() => _db.getActiveProducts();
  
  Future<Product?> getById(int id) => _db.getProductById(id);
  
  Future<Product?> getByBarcode(String barcode) => _db.getProductByBarcode(barcode);
  
  Future<List<Product>> search(String query) => _db.searchProducts(query);
  
  Future<int> create(ProductsCompanion product) => _db.insertProduct(product);
  
  Future<bool> update(ProductsCompanion product) => _db.updateProduct(product);
  
  Future<bool> delete(int id) async {
    // Also delete related stock movements
    await _db.customSelect(
      'DELETE FROM stock_movements WHERE product_id = ?',
      variables: [Variable.withInt(id)],
    ).go();
    return (await _db.deleteProduct(id)) > 0;
  }
  
  Future<List<String>> getCategories() => _db.getAllCategories();
  
  Future<List<Product>> getByCategory(String category) => _db.getProductsByCategory(category);
}

// ==================== INVOICES REPOSITORY ====================

class InvoicesRepository {
  final AppDatabase _db;
  
  InvoicesRepository(this._db);

  Future<List<Invoice>> getAll() => _db.getAllInvoices();
  
  Future<Invoice?> getById(int id) => _db.getInvoiceById(id);
  
  Future<Invoice?> getByNumber(String number) => _db.getInvoiceByNumber(number);
  
  Future<int> create(InvoicesCompanion invoice) => _db.insertInvoice(invoice);
  
  Future<bool> update(InvoicesCompanion invoice) => _db.updateInvoice(invoice);
  
  Future<bool> delete(int id) async {
    await _db.deleteInvoiceItemsByInvoiceId(id);
    return (await _db.deleteInvoice(id)) > 0;
  }
  
  Future<List<InvoiceItem>> getItems(int invoiceId) => _db.getInvoiceItems(invoiceId);
  
  Future<int> addItem(InvoiceItemsCompanion item) => _db.insertInvoiceItem(item);
  
  Future<bool> updateItem(InvoiceItemsCompanion item) => _db.updateInvoiceItem(item);
  
  Future<void> removeItem(int id) => _db.deleteInvoiceItem(id);
  
  Future<void> clearItems(int invoiceId) => _db.deleteInvoiceItemsByInvoiceId(invoiceId);
  
  Future<String> generateNumber() => _db.generateInvoiceNumber();
  
  Future<double> getTotalSales(DateTime start, DateTime end) => 
      _db.getTotalSales(start, end);
      
  Future<int> getCount(DateTime start, DateTime end) => 
      _db.getInvoicesCount(start, end);
}

// ==================== SETTINGS REPOSITORY ====================

class SettingsRepository {
  final AppDatabase _db;
  
  SettingsRepository(this._db);

  Future<String?> get(String key) => _db.getSetting(key);
  
  Future<void> set(String key, String value) => _db.setSetting(key, value);
  
  Future<Map<String, String>> getAll() => _db.getAllSettings();
  
  // Convenience methods for common settings
  Future<String> getStoreName() async => await get('store_name') ?? 'متجري';
  Future<void> setStoreName(String name) => set('store_name', name);
  
  Future<String> getPhone() async => await get('phone') ?? '';
  Future<void> setPhone(String phone) => set('phone', phone);
  
  Future<String> getAddress() async => await get('address') ?? '';
  Future<void> setAddress(String address) => set('address', address);
  
  Future<double> getExchangeRate() async {
    final rate = await get('exchange_rate');
    return rate != null ? double.tryParse(rate) ?? 89500.0 : 89500.0; // Default LBP rate
  }
  Future<void> setExchangeRate(double rate) => set('exchange_rate', rate.toString());
  
  Future<String> getDefaultCurrency() async => await get('default_currency') ?? 'USD';
  Future<void> setDefaultCurrency(String currency) => set('default_currency', currency);
  
  Future<double> getTaxRate() async {
    final tax = await get('tax_rate');
    return tax != null ? double.tryParse(tax) ?? 0.0 : 0.0;
  }
  Future<void> setTaxRate(double rate) => set('tax_rate', rate.toString());
  
  Future<bool> isAutoBackupEnabled() async {
    final enabled = await get('auto_backup');
    return enabled == 'true';
  }
  Future<void> setAutoBackup(bool enabled) => set('auto_backup', enabled.toString());
  
  Future<bool> isDarkMode() async {
    final dark = await get('dark_mode');
    return dark == 'true';
  }
  Future<void> setDarkMode(bool enabled) => set('dark_mode', enabled.toString());
}
