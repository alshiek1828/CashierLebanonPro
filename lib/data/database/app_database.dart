import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class AppDatabase {
  static Database? _database;
  
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }
  
  static Future<Database> initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'cashier_lebanon_pro.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }
  
  static Future<void> _onCreate(Database db, int version) async {
    // Products table
    await db.execute('''
      CREATE TABLE products(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price_usd REAL NOT NULL,
        price_lbp REAL NOT NULL,
        barcode TEXT,
        category TEXT DEFAULT 'عام',
        stock_quantity INTEGER DEFAULT 0,
        image_url TEXT,
        description TEXT,
        is_active INTEGER DEFAULT 1,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    
    // Invoices table
    await db.execute('''
      CREATE TABLE invoices(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_number TEXT NOT NULL,
        subtotal REAL DEFAULT 0,
        discount REAL DEFAULT 0,
        tax REAL DEFAULT 0,
        total_usd REAL DEFAULT 0,
        total_lbp REAL DEFAULT 0,
        currency TEXT DEFAULT 'USD',
        status TEXT DEFAULT 'pending',
        payment_method TEXT,
        customer_name TEXT,
        customer_phone TEXT,
        notes TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    
    // Invoice items table
    await db.execute('''
      CREATE TABLE invoice_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER NOT NULL,
        product_id INTEGER,
        product_name TEXT NOT NULL,
        price REAL NOT NULL,
        quantity REAL NOT NULL,
        total REAL NOT NULL,
        unit TEXT DEFAULT 'piece',
        FOREIGN KEY (invoice_id) REFERENCES invoices(id)
      )
    ''');
    
    // Settings table
    await db.execute('''
      CREATE TABLE app_settings(
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    
    // Stock movements table
    await db.execute('''
      CREATE TABLE stock_movements(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        previous_quantity INTEGER NOT NULL,
        new_quantity INTEGER NOT NULL,
        reason TEXT NOT NULL,
        type TEXT NOT NULL,
        reference TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    
    // Categories table
    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        color TEXT,
        is_active INTEGER DEFAULT 1
      )
    ''');
  }
  
  // ==================== PRODUCTS CRUD ====================
  
  static Future<List<Map<String, dynamic>>> getAllProducts() async {
    final db = await database;
    return await db.query('products', where: 'is_active = ?', whereArgs: [1]);
  }
  
  static Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    final db = await database;
    return await db.query(
      'products',
      where: '(name LIKE ? OR barcode LIKE ?) AND is_active = ?',
      whereArgs: ['%$query%', '%$$query%', 1],
      orderBy: 'name ASC'
    );
  }
  
  static Future<Map<String, dynamic>?> getProductById(int id) async {
    final db = await database;
    final results = await db.query('products', where: 'id = ?', whereArgs: [id], limit: 1);
    return results.isNotEmpty ? results.first : null;
  }
  
  static Future<Map<String, dynamic>?> getProductByBarcode(String barcode) async {
    final db = await database;
    final results = await db.query('products', where: 'barcode = ?', whereArgs: [barcode], limit: 1);
    return results.isNotEmpty ? results.first : null;
  }
  
  static Future<int> insertProduct(Map<String, dynamic> product) async {
    final db = await database;
    return await db.insert('products', product);
  }
  
  static Future<int> updateProduct(Map<String, dynamic> product) async {
    final db = await database;
    return await db.update('products', product, where: 'id = ?', whereArgs: [product['id']]);
  }
  
  static Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }
  
  // ==================== INVOICES CRUD ====================
  
  static Future<List<Map<String, dynamic>>> getAllInvoices() async {
    final db = await database;
    return await db.query('invoices', orderBy: 'created_at DESC');
  }
  
  static Future<Map<String, dynamic>?> getInvoiceById(int id) async {
    final db = await database;
    final results = await db.query('invoices', where: 'id = ?', whereArgs: [id], limit: 1);
    return results.isNotEmpty ? results.first : null;
  }
  
  static Future<int> insertInvoice(Map<String, dynamic> invoice) async {
    final db = await database;
    return await db.insert('invoices', invoice);
  }
  
  static Future<int> updateInvoice(Map<String, dynamic> invoice) async {
    final db = await database;
    return await db.update('invoices', invoice, where: 'id = ?', whereArgs: [invoice['id']]);
  }
  
  static Future<int> deleteInvoice(int id) async {
    final db = await database;
    await db.delete('invoice_items', where: 'invoice_id = ?', whereArgs: [id]);
    return await db.delete('invoices', where: 'id = ?', whereArgs: [id]);
  }
  
  static Future<List<Map<String, dynamic>>> getInvoiceItems(int invoiceId) async {
    final db = await database;
    return await db.query('invoice_items', where: 'invoice_id = ?', whereArgs: [invoiceId]);
  }
  
  static Future<int> insertInvoiceItem(Map<String, dynamic> item) async {
    final db = await database;
    return await db.insert('invoice_items', item);
  }
  
  static Future<String> generateInvoiceNumber() async {
    final now = DateTime.now();
    final prefix = 'INV-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    
    final db = await database;
    final result = await db.rawQuery(
      "SELECT invoice_number FROM invoices WHERE invoice_number LIKE '$prefix%' ORDER BY id DESC LIMIT 1"
    );
    
    if (result.isEmpty) return '$prefix-001';
    
    final lastNumber = result.first['invoice_number'] as String;
    final sequence = int.parse(lastNumber.split('-').last);
    return '$prefix-${(sequence + 1).toString().padLeft(3, '0')}';
  }
  
  // ==================== SETTINGS CRUD ====================
  
  static Future<String?> getSetting(String key) async {
    final db = await database;
    final result = await db.query('app_settings', where: 'key = ?', whereArgs: [key], limit: 1);
    return result.isNotEmpty ? result.first['value'] as String : null;
  }
  
  static Future<void> setSetting(String key, String value) async {
    final db = await database;
    final existing = await getSetting(key);
    if (existing != null) {
      await db.update('app_settings', {'value': value}, where: 'key = ?', whereArgs: [key]);
    } else {
      await db.insert('app_settings', {'key': key, 'value': value});
    }
  }
  
  static Future<Map<String, String>> getAllSettings() async {
    final db = await database;
    final results = await db.query('app_settings');
    return {for (var r in results) r['key'] as String: r['value'] as String};
  }
  
  // ==================== UTILITY METHODS ====================
  
  static Future<void> clearAllData() async {
    final db = await database;
    await db.delete('invoice_items');
    await db.delete('stock_movements');
    await db.delete('invoices');
    await db.delete('products');
    await db.delete('app_settings');
  }
  
  static Future<Map<String, dynamic>> exportDatabase() async {
    final db = await database;
    final products = await getAllProducts();
    final invoices = await getAllInvoices();
    final settings = await getAllSettings();
    
    return {
      'products': products,
      'invoices': invoices,
      'settings': settings,
      'exportDate': DateTime.now().toIso8601String(),
      'version': '1.0.0',
    };
  }
}
