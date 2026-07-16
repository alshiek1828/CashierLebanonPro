import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

part 'app_database.g.dart';

// Products Table
class Products extends Table {
  IntColumn get id => integer().autoincrement()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  RealColumn get priceUsd => real()();
  RealColumn get priceLbp => real()();
  TextColumn get barcode => text().nullable()();
  TextColumn get category => text().withDefault(const Value('عام'))();
  IntegerColumn get stockQuantity => integer().withDefault(const Constant(0))();
  TextColumn get imageUrl => text().nullable()();
  TextColumn get description => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withCurrentTimestamp()();
  DateTimeColumn get updatedAt => dateTime().withCurrentTimestamp()();
}

// Invoices Table
class Invoices extends Table {
  IntColumn get id => integer().autoincrement()();
  TextColumn get invoiceNumber => text()();
  RealColumn get subtotal => real().withDefault(const Constant(0))();
  RealColumn get discount => real().withDefault(const Constant(0))();
  RealColumn get tax => real().withDefault(const Constant(0))();
  RealColumn get totalUsd => real().withDefault(const Constant(0))();
  RealColumn get totalLbp => real().withDefault(const Constant(0))();
  TextColumn get currency => text().withDefault(const Constant('USD'))();
  TextColumn get status => text().withDefault(const Constant('pending'))(); // pending, paid, cancelled
  TextColumn get paymentMethod => text().nullable()(); // cash, card, mixed
  TextColumn get customerName => text().nullable()();
  TextColumn get customerPhone => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withCurrentTimestamp()();
  DateTimeColumn get updatedAt => dateTime().withCurrentTimestamp()();
}

// Invoice Items Table
class InvoiceItems extends Table {
  IntColumn get id => integer().autoincrement()();
  IntColumn get invoiceId => integer().references(Invoices, #id)();
  IntColumn get productId => integer().references(Products, #id).nullable()();
  TextColumn get productName => text()();
  RealColumn get price => real()();
  RealColumn get quantity => real()();
  RealColumn get total => real()();
  TextColumn get unit => text().withDefault(const Value('piece'))();
}

// Settings Table
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  
  @override
  Set<Column> get primaryKey => {key};
}

// Stock Movements Table
class StockMovements extends Table {
  IntColumn get id => integer().autoincrement()();
  IntColumn get productId => integer().references(Products, #id)();
  IntegerColumn get previousQuantity => integer()();
  IntegerColumn get newQuantity => integer()();
  TextColumn get reason => text()();
  TextColumn get type => text()(); // sale, purchase, adjustment, return
  TextColumn get reference => text().nullable()(); // invoice number or adjustment id
  DateTimeColumn get createdAt => dateTime().withCurrentTimestamp()();
}

// Categories Table (optional for future use)
class Categories extends Table {
  IntColumn get id => integer().autoincrement()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get color => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}

@DriftDatabase(tables: [
  Products,
  Invoices,
  InvoiceItems,
  AppSettings,
  StockMovements,
  Categories,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // Migration methods can be added here for future schema changes
  // @override
  // MigrationStrategy get migration {
  //   return MigrationStrategy(
  //     onCreate: (Migrator m) async {
  //       await m.createAll();
  //     },
  //     onUpgrade: (Migrator m, int from, int to) async {
  //       // Handle migrations here
  //     },
  //   );
  // }

  // ==================== PRODUCTS CRUD ====================
  
  Future<List<Product>> getAllProducts() => select(products).get();
  
  Future<List<Product>> getActiveProducts() =>
      (select(products)..where((t) => t.isActive.equals(true))).get();
  
  Future<Product?> getProductById(int id) =>
      (select(products)..where((t) => t.id.equals(id))).getSingleOrNull();
  
  Future<Product?> getProductByBarcode(String barcode) =>
      (select(products)..where((t) => t.barcode.equals(barcode))).getSingleOrNull();
  
  Future<List<Product>> searchProducts(String query) {
    final searchPattern = '%$query%';
    return (select(products)
      ..where((t) => t.name.like(searchPattern) | t.barcode.like(searchPattern))
      ..orderBy([(t) => OrderingTerm.asc(t.name)])
    ).get();
  }
  
  Future<int> insertProduct(ProductsCompanion product) => into(products).insert(product);
  
  Future<bool> updateProduct(ProductsCompanion product) => update(products).replace(product);
  
  Future<int> deleteProduct(int id) => (delete(products)..where((t) => t.id.equals(id))).go();
  
  Future<List<Product>> getProductsByCategory(String category) =>
      (select(products)..where((t) => t.category.equals(category))).get();
  
  Future<List<String>> getAllCategories() =>
      customSelect('SELECT DISTINCT category FROM products WHERE is_active = 1 ORDER BY category')
          .map((row) => row.read<String>('category'))
          .get();

  // ==================== INVOICES CRUD ====================
  
  Future<List<Invoice>> getAllInvoices() =>
      (select(invoices)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
  
  Future<List<Invoice>> getInvoicesByStatus(String status) =>
      (select(invoices)..where((t) => t.status.equals(status))).get();
  
  Future<Invoice?> getInvoiceById(int id) =>
      (select(invoices)..where((t) => t.id.equals(id))).getSingleOrNull();
  
  Future<Invoice?> getInvoiceByNumber(String number) =>
      (select(invoices)..where((t) => t.invoiceNumber.equals(number))).getSingleOrNull();
  
  Future<int> insertInvoice(InvoicesCompanion invoice) => into(invoices).insert(invoice);
  
  Future<bool> updateInvoice(InvoicesCompanion invoice) => update(invoices).replace(invoice);
  
  Future<int> deleteInvoice(int id) => (delete(invoices)..where((t) => t.id.equals(id))).go();
  
  Future<List<Invoice>> getInvoicesByDateRange(DateTime start, DateTime end) {
    return (select(invoices)
      ..where((t) => t.createdAt.isBetweenValues(start, end))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
    ).get();
  }
  
  Future<double> getTotalSales(DateTime start, DateTime end) async {
    final result = customSelect(
      'SELECT COALESCE(SUM(total_usd), 0) as total FROM invoices WHERE status = ? AND created_at BETWEEN ? AND ?',
      variables: [
        Variable.withString('paid'),
        Variable.withDateTime(start),
        Variable.withDateTime(end),
      ],
    ).getSingle();
    return result.read<double>('total');
  }
  
  Future<int> getInvoicesCount(DateTime start, DateTime end) async {
    final result = customSelect(
      'SELECT COUNT(*) as count FROM invoices WHERE status = ? AND created_at BETWEEN ? AND ?',
      variables: [
        Variable.withString('paid'),
        Variable.withDateTime(start),
        Variable.withDateTime(end),
      ],
    ).getSingle();
    return result.read<int>('count');
  }

  // ==================== INVOICE ITEMS CRUD ====================
  
  Future<List<InvoiceItem>> getInvoiceItems(int invoiceId) =>
      (select(invoiceItems)..where((t) => t.invoiceId.equals(invoiceId))).get();
  
  Future<int> insertInvoiceItem(InvoiceItemsCompanion item) => into(invoiceItems).insert(item);
  
  Future<bool> updateInvoiceItem(InvoiceItemsCompanion item) => update(invoiceItems).replace(item);
  
  Future<int> deleteInvoiceItem(int id) => (delete(invoiceItems)..where((t) => t.id.equals(id))).go();
  
  Future<int> deleteInvoiceItemsByInvoiceId(int invoiceId) =>
      (delete(invoiceItems)..where((t) => t.invoiceId.equals(invoiceId))).go();

  // ==================== SETTINGS CRUD ====================
  
  Future<String?> getSetting(String key) async {
    final result = (select(appSettings)..where((t) => t.key.equals(key))).getSingleOrNull();
    return result?.value;
  }
  
  Future<void> setSetting(String key, String value) async {
    final existing = await getSetting(key);
    if (existing != null) {
      (update(appSettings)..where((t) => t.key.equals(key)))
          .write(AppSettingsCompanion(value: Value(value)));
    } else {
      into(appSettings).insert(AppSettingsCompanion(key: Value(key), value: Value(value)));
    }
  }
  
  Future<Map<String, String>> getAllSettings() async {
    final settings = await select(appSettings).get();
    return {for (var s in settings) s.key: s.value};
  }

  // ==================== STOCK MOVEMENTS ====================
  
  Future<void> recordStockMovement({
    required int productId,
    required int previousQuantity,
    required int newQuantity,
    required String reason,
    required String type,
    String? reference,
  }) {
    return into(stockMovements).insert(StockMovementsCompanion(
      productId: Value(productId),
      previousQuantity: Value(previousQuantity),
      newQuantity: Value(newQuantity),
      reason: Value(reason),
      type: Value(type),
      reference: Value(reference),
    ));
  }
  
  Future<List<StockMovement>> getProductStockHistory(int productId) =>
      (select(stockMovements)
        ..where((t) => t.productId.equals(productId))
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ).get();

  // ==================== UTILITY METHODS ====================
  
  Future<String> generateInvoiceNumber() async {
    final date = DateTime.now();
    final prefix = 'INV-${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
    
    final lastInvoice = await customSelect(
      "SELECT invoice_number FROM invoices WHERE invoice_number LIKE '$prefix%' ORDER BY id DESC LIMIT 1",
    ).getSingleOrNull();
    
    if (lastInvoice == null) {
      return '$prefix-001';
    }
    
    final lastNumber = lastInvoice.read<String>('invoice_number');
    final sequence = int.parse(lastNumber.split('-').last);
    return '$prefix-${(sequence + 1).toString().padLeft(3, '0')}';
  }
  
  Future<void> clearAllData() async {
    await customSelect('DELETE FROM invoice_items').go();
    await customSelect('DELETE FROM stock_movements').go();
    await customSelect('DELETE FROM invoices').go();
    await customSelect('DELETE FROM products').go();
    await customSelect('DELETE FROM app_settings').go();
  }
  
  Future<Map<String, dynamic>> exportDatabase() async {
    final productsList = await getAllProducts();
    final invoicesList = await getAllInvoices();
    final settings = await getAllSettings();
    
    return {
      'products': productsList.map((p) => p.toJson()).toList(),
      'invoices': invoicesList.map((i) => i.toJson()).toList(),
      'settings': settings,
      'exportDate': DateTime.now().toIso8601String(),
      'version': '1.0.0',
    };
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'cashier_lebanon_pro.sqlite'));
    
    if (Platform.isAndroid || Platform.isIOS) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }
    
    return NativeDatabase.createInBackground(file);
  });
}
