import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_strings.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/products/products_screen.dart';
import '../../presentation/screens/invoices/create_invoice_screen.dart';
import '../../presentation/screens/inventory/inventory_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/backup/backup_screen.dart';
import '../../presentation/screens/about/about_screen.dart';
import '../../presentation/screens/barcode/barcode_scan_screen.dart';
import '../../presentation/screens/payment/payment_screen.dart';
import '../../presentation/screens/invoice_history/invoice_history_screen.dart';
import '../../presentation/screens/invoice_history/invoice_detail_screen.dart';

// Router Provider
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    routes: [
      // Home Route
      GoRoute(
        path: '/',
        name: AppStrings.home,
        builder: (context, state) => const HomeScreen(),
      ),
      
      // Products Route
      GoRoute(
        path: '/products',
        name: AppStrings.products,
        builder: (context, state) => const ProductsScreen(),
      ),
      
      // Create Invoice Route
      GoRoute(
        path: '/invoice/create',
        name: AppStrings.createInvoice,
        builder: (context, state) => const CreateInvoiceScreen(),
      ),
      
      // Inventory Route
      GoRoute(
        path: '/inventory',
        name: AppStrings.inventory,
        builder: (context, state) => const InventoryScreen(),
      ),
      
      // Settings Route
      GoRoute(
        path: '/settings',
        name: AppStrings.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      
      // Backup Route
      GoRoute(
        path: '/backup',
        name: AppStrings.backup,
        builder: (context, state) => const BackupScreen(),
      ),
      
      // About Route
      GoRoute(
        path: '/about',
        name: AppStrings.about,
        builder: (context, state) => const AboutScreen(),
      ),
      
      // Barcode Scan Route
      GoRoute(
        path: '/barcode/scan',
        name: AppStrings.scanBarcode,
        builder: (context, state) => const BarcodeScanScreen(),
      ),
      
      // Payment Route
      GoRoute(
        path: '/payment',
        name: AppStrings.payment,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return PaymentScreen(
            totalAmount: extra?['totalAmount'] ?? 0.0,
            invoiceId: extra?['invoiceId'],
          );
        },
      ),
      
      // Invoice History Route
      GoRoute(
        path: '/invoices/history',
        name: AppStrings.invoiceHistory,
        builder: (context, state) => const InvoiceHistoryScreen(),
      ),
      
      // Invoice Detail Route
      GoRoute(
        path: '/invoices/:id',
        name: AppStrings.invoiceDetail,
        builder: (context, state) {
          final invoiceId = state.pathParameters['id'];
          return InvoiceDetailScreen(invoiceId: invoiceId!);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text(AppStrings.error)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              '${AppStrings.pageNotFound}: ${state.uri.path}',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text(AppStrings.goBack),
            ),
          ],
        ),
      ),
    ),
  );
});
