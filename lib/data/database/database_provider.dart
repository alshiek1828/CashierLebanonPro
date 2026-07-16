import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_database.dart';

// Database Provider
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

// Products Repository Provider
final productsRepositoryProvider = Provider<ProductsRepository>((ref) {
  return ProductsRepository();
});

// Invoices Repository Provider
final invoicesRepositoryProvider = Provider<InvoicesRepository>((ref) {
  return InvoicesRepository();
});

// Settings Repository Provider
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

// ==================== PRODUCTS REPOSITORY ====================

class ProductsRepository {
  
  Future<List<Map<String, dynamic>>> getAll() => AppDatabase.getAllProducts();
  
  Future<List<Map<String, dynamic>>> search(String query) => AppDatabase.searchProducts(query);
  
  Future<Map<String, dynamic>?> getById(int id) => AppDatabase.getProductById(id);
  
  Future<Map<String, dynamic>?> getByBarcode(String barcode) => AppDatabase.getProductByBarcode(barcode);
  
  Future<int> create(Map<String, dynamic> product) => AppDatabase.insertProduct(product);
  
  Future<int> update(Map<String, dynamic> product) => AppDatabase.updateProduct(product);
  
  Future<bool> delete(int id) async {
    final result = await AppDatabase.deleteProduct(id);
    return result > 0;
  }
}

// ==================== INVOICES REPOSITORY ====================

class InvoicesRepository {
  
  Future<List<Map<String, dynamic>>> getAll() => AppDatabase.getAllInvoices();
  
  Future<Map<String, dynamic>?> getById(int id) => AppDatabase.getInvoiceById(id);
  
  Future<int> create(Map<String, dynamic> invoice) => AppDatabase.insertInvoice(invoice);
  
  Future<int> update(Map<String, dynamic> invoice) => AppDatabase.updateInvoice(invoice);
  
  Future<bool> delete(int id) async {
    final result = await AppDatabase.deleteInvoice(id);
    return result > 0;
  }
  
  Future<List<Map<String, dynamic>>> getItems(int invoiceId) => AppDatabase.getInvoiceItems(invoiceId);
  
  Future<int> addItem(Map<String, dynamic> item) => AppDatabase.insertInvoiceItem(item);
  
  Future<String> generateNumber() => AppDatabase.generateInvoiceNumber();
}

// ==================== SETTINGS REPOSITORY ====================

class SettingsRepository {
  
  Future<String?> get(String key) => AppDatabase.getSetting(key);
  
  Future<void> set(String key, String value) => AppDatabase.setSetting(key, value);
  
  Future<Map<String, String>> getAll() => AppDatabase.getAllSettings();
  
  // Convenience methods for common settings
  Future<String> getStoreName() async => await get('store_name') ?? 'متجري';
  Future<void> setStoreName(String name) => set('store_name', name);
  
  Future<String> getPhone() async => await get('phone') ?? '';
  Future<void> setPhone(String phone) => set('phone', phone);
  
  Future<String> getAddress() async => await get('address') ?? '';
  Future<void> setAddress(String address) => set('address', address);
  
  Future<double> getExchangeRate() async {
    final rate = await get('exchange_rate');
    return rate != null ? double.tryParse(rate) ?? 89500.0 : 89500.0;
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
