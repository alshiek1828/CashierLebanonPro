import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../providers/providers.dart';
import '../../../data/database/app_database.dart';

class InvoiceDetailScreen extends ConsumerStatefulWidget {
  final String invoiceId;
  
  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  ConsumerState<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends ConsumerState<InvoiceDetailScreen> {
  
  @override
  Widget build(BuildContext context) {
    final invoiceId = int.tryParse(widget.invoiceId) ?? 0;
    final invoiceAsync = ref.watch(invoiceByIdProvider(invoiceId));
    final itemsAsync = ref.watch(invoiceItemsProvider(invoiceId));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الفاتورة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: AppStrings.reprint,
            onPressed: () => _printInvoice(context),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: AppStrings.shareInvoice,
            onPressed: () => _shareInvoice(context),
          ),
        ],
      ),
      body: invoiceAsync.when(
        data: (invoice) {
          if (invoice == null) {
            return Center(child: Text(AppStrings.noData));
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Invoice Header Card
                _buildHeaderCard(context, invoice),
                
                const SizedBox(height: 16),
                
                // Status & Payment Info
                _buildStatusCard(context, invoice),
                
                const SizedBox(height: 16),
                
                // Items List
                itemsAsync.when(
                  data: (items) => _buildItemsSection(context, items),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Text('خطأ في تحميل العناصر'),
                ),
                
                const SizedBox(height: 16),
                
                // Totals Summary
                _buildTotalsCard(context, invoice),
                
                const SizedBox(height: 24),
                
                // Action Buttons
                _buildActionButtons(context, invoice),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('خطأ: $error')),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, Invoice invoice) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.invoiceNumber,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                    Text(
                      invoice.invoiceNumber,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getStatusIcon(invoice.status), size: 16, color: _getStatusColor(invoice.status)),
                      const SizedBox(width: 4),
                      Text(
                        _getStatusText(invoice.status),
                        style: TextStyle(fontWeight: FontWeight.w600, color: _getStatusColor(invoice.status)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const Divider(height: 24),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _InfoItem(icon: Icons.calendar_today, label: AppStrings.date, value: _formatDate(invoice.createdAt)),
                if (invoice.customerName != null && invoice.customerName!.isNotEmpty)
                  _InfoItem(icon: Icons.person_outline, label: AppStrings.customer, value: invoice.customerName!),
                if (invoice.paymentMethod != null)
                  _InfoItem(icon: Icons.payment, label: 'طريقة الدفع', value: _getPaymentMethodLabel(invoice.paymentMethod!)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, Invoice invoice) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getStatusColor(invoice.status).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(_getStatusIcon(invoice.status), color: _getStatusColor(invoice.status)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'حالة الفاتورة',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    _getStatusText(invoice.status),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(invoice.status),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '\$${invoice.totalUsd.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsSection(BuildContext context, List<InvoiceItem> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'عناصر الفاتورة (${items.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            // Table Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Expanded(flex: 3, child: Text('المنتج', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(child: Text(AppStrings.price, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(child: Text(AppStrings.quantity, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text(AppStrings.total, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Items
            ...items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  Expanded(child: Text('\$${item.price.toStringAsFixed(2)}', textAlign: TextAlign.center)),
                  Expanded(child: Text('${item.quantity.toInt()}', textAlign: TextAlign.center)),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '\$${item.total.toStringAsFixed(2)}',
                      textAlign: TextAlign.end,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalsCard(BuildContext context, Invoice invoice) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _TotalRow(label: AppStrings.subtotal, value: invoice.subtotal),
            if (invoice.discount > 0)
              _TotalRow(label: AppStrings.discount, value: -invoice.discount, isNegative: true),
            if (invoice.tax > 0)
              _TotalRow(label: AppStrings.tax, value: invoice.tax),
            const Divider(),
            _TotalRow(
              label: AppStrings.grandTotal,
              value: invoice.totalUsd,
              isBold: true,
              labelStyle: Theme.of(context).textTheme.titleMedium,
              valueStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            if (invoice.totalLbp > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '≈ ${invoice.totalLbp.toStringAsFixed(0)} ل.ل',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, Invoice invoice) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            onPressed: () => _printInvoice(context),
            icon: const Icon(Icons.print),
            label: const Text(AppStrings.reprint),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _shareInvoice(context),
          icon: const Icon(Icons.share_outlined),
          label: const Text(AppStrings.shareInvoice),
          style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
        ),
        if (invoice.status == 'pending') ...[
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: () {},
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.1),
              foregroundColor: Colors.red,
            ),
            child: const Text(AppStrings.cancelInvoice),
          ),
        ],
      ],
    );
  }

  Widget _TotalRow({
    required String label,
    required double value,
    bool isNegative = false,
    bool isBold = false,
    TextStyle? labelStyle,
    TextStyle? valueStyle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: labelStyle ?? (isBold ? const TextStyle(fontWeight: FontWeight.bold) : null)),
          Text(
            '${isNegative ? '-' : ''}\$${value.abs().toStringAsFixed(2)}',
            style: valueStyle ?? TextStyle(
              color: isNegative ? Colors.red : null,
              fontWeight: isBold ? FontWeight.bold : null,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'paid': return Icons.check_circle;
      case 'pending': return Icons.pending;
      case 'cancelled': return Icons.cancel;
      default: return Icons.help_outline;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'paid': return Colors.green;
      case 'pending': return Colors.orange;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'paid': return AppStrings.paid;
      case 'pending': return AppStrings.pending;
      case 'cancelled': return AppStrings.cancelled;
      default: return status;
    }
  }

  String _getPaymentMethodLabel(String method) {
    switch (method) {
      case 'cash': return AppStrings.cashPayment;
      case 'card': return AppStrings.cardPayment;
      case 'mixed': return AppStrings.mixedPayment;
      default: return method;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _printInvoice(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: text: 'جاري تحضير الطباعة...'),
    );
  }

  void _shareInvoice(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: text: 'جاري تحضير المشاركة...'),
    );
  }
}

// ==================== INFO ITEM ====================

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  
  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10)),
      ],
    );
  }
}
