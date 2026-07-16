import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../providers/providers.dart';
import '../../../data/database/database_provider.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final double totalAmount;
  final String? invoiceId;

  const PaymentScreen({
    super.key,
    required this.totalAmount,
    this.invoiceId,
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  String _selectedCurrency = 'USD';
  double _amountPaid = 0.0;
  double _exchangeRate = 89500.0; // Default LBP rate
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  
  // Controllers
  final _amountController = TextEditingController();
  final _rateController = TextEditingController();
  final _customerNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.totalAmount.toStringAsFixed(2);
    _amountPaid = widget.totalAmount;
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = ref.read(settingsRepositoryProvider);
    final currency = await settings.getDefaultCurrency();
    final rate = await settings.getExchangeRate();
    
    setState(() {
      _selectedCurrency = currency;
      _exchangeRate = rate;
      _rateController.text = rate.toStringAsFixed(0);
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _rateController.dispose();
    _customerNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amountInLBP = _amountPaid * _exchangeRate;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.paymentTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Due Card
            _buildAmountDueCard(context),
            const SizedBox(height: 24),
            
            // Currency Selection
            _buildCurrencySection(context),
            const SizedBox(height: 24),
            
            // Payment Method
            _buildPaymentMethodSection(context),
            const SizedBox(height: 24),
            
            // Customer Name (Optional)
            _buildCustomerSection(context),
            const SizedBox(height: 24),
            
            // Exchange Rate (when showing LBP)
            if (_selectedCurrency == 'LBP') ...[
              _buildExchangeRateSection(context),
              const SizedBox(height: 24),
            ],
            
            // Summary
            _buildPaymentSummary(context, amountInLBP),
            const SizedBox(height: 24),
            
            // Action Buttons
            _buildActionButtons(context, amountInLBP),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountDueCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            AppStrings.amountDue,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${widget.totalAmount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '≈ ${(widget.totalAmount * _exchangeRate).toStringAsFixed(0)} ل.ل',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.selectCurrency,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildCurrencyOption(
                context,
                title: 'USD',
                subtitle: '\$ دولار أمريكي',
                isSelected: _selectedCurrency == 'USD',
                onTap: () => setState(() => _selectedCurrency = 'USD'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCurrencyOption(
                context,
                title: 'LBP',
                subtitle: 'ل.ل ليرة لبنانية',
                isSelected: _selectedCurrency == 'LBP',
                onTap: () => setState(() => _selectedCurrency = 'LBP'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCurrencyOption(BuildContext context, {
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).colorScheme.primary 
                : Theme.of(context).colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? Theme.of(context).colorScheme.primary : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Theme.of(context).colorScheme.primary : null,
                )),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'طريقة الدفع',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: PaymentMethod.values.map((method) {
            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getPaymentIcon(method), size: 18),
                  const SizedBox(width: 6),
                  Text(_getPaymentLabel(method)),
                ],
              ),
              selected: _paymentMethod == method,
              onSelected: (_) => setState(() => _paymentMethod = method),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCustomerSection(BuildContext context) {
    return TextField(
      controller: _customerNameController,
      decoration: InputDecoration(
        labelText: 'اسم العميل (اختياري)',
        prefixIcon: const Icon(Icons.person_outline),
      ),
    );
  }

  Widget _buildExchangeRateSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.exchangeRate,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _rateController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: '${AppStrings.currentRate} (1 USD = ? LBP)',
            prefixIcon: const Icon(Icons.currency_exchange),
            suffixText: 'ل.ل',
          ),
          onChanged: (v) {
            final rate = double.tryParse(v);
            if (rate != null && rate > 0) {
              setState(() => _exchangeRate = rate);
            }
          },
        ),
        const SizedBox(height: 8),
        Text(
          'ملاحظة: سعر الصرف يتغير يومياً. يرجى التحديث.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.orange[700],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSummary(BuildContext context, double amountInLBP) {
    final change = _amountPaid - widget.totalAmount;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppStrings.amountDue),
              Text('\$${widget.totalAmount.toStringAsFixed(2)}'),
            ],
          ),
          if (_selectedCurrency == 'LBP') ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('المبلغ بالليرة'),
                Text('${(widget.totalAmount * _exchangeRate).toStringAsFixed(0)} ل.ل'),
              ],
            ),
          ],
          const Divider(),
          if (change >= 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppStrings.change, style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold)),
                Text(
                  '\$${change.toStringAsFixed(2)}',
                  style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold),
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('المتبقي', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                Text(
                  '\$${change.abs().toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, double amountInLBP) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            onPressed: _processPayment,
            icon: const Icon(Icons.check_circle_outline),
            label: Text(
              AppStrings.completePayment,
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.print_outlined),
          label: Text(AppStrings.printInvoice),
        ),
      ],
    );
  }

  IconData _getPaymentIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Icons.money;
      case PaymentMethod.card:
        return Icons.credit_card;
      case PaymentMethod.mixed:
        return Icons.merge_type;
    }
  }

  String _getPaymentLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return AppStrings.cashPayment;
      case PaymentMethod.card:
        return AppStrings.cardPayment;
      case PaymentMethod.mixed:
        return AppStrings.mixedPayment;
    }
  }

  Future<void> _processPayment() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final invoicesRepo = ref.read(invoicesRepositoryProvider);
      final cartState = ref.read(cartProvider);
      
      // Generate invoice number
      final invoiceNumber = await invoicesRepo.generateNumber();
      
      // Create invoice
      final invoiceId = await invoicesRepo.create(InvoicesCompanion(
        invoiceNumber: Value(invoiceNumber),
        subtotal: Value(cartState.subtotal),
        discount: Value(cartState.discount),
        tax: Value(cartState.taxAmount),
        totalUsd: Value(widget.totalAmount),
        totalLbp: Value(widget.totalAmount * _exchangeRate),
        currency: Value(_selectedCurrency),
        status: Value('paid'),
        paymentMethod: Value(_paymentMethod.name),
        customerName: Value(_customerNameController.text.isEmpty ? null : _customerNameController.text),
      ));
      
      // Add invoice items
      for (final item in cartState.items) {
        await invoicesRepo.addItem(InvoiceItemsCompanion(
          invoiceId: Value(invoiceId),
          productId: Value(item.productId ?? 0),
          productName: Value(item.name),
          price: Value(item.price),
          quantity: Value(item.quantity.toDouble()),
          total: Value(item.total),
        ));
        
        // Update stock if product exists
        if (item.productId != null) {
          final productsRepo = ref.read(productsRepositoryProvider);
          final product = await productsRepo.getById(item.productId!);
          if (product != null) {
            final newStock = product.stockQuantity - item.quantity;
            await productsRepo.update(product.copyWith(stockQuantity: Value(newStock)));
          }
        }
      }
      
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      // Show success dialog
      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 64),
            title: const Text(AppStrings.paymentSuccess),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('رقم الفاتورة: $invoiceNumber'),
                Text('المبلغ: \$${widget.totalAmount.toStringAsFixed(2)}'),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context, true); // Return to invoice screen with success
                  },
                  child: const Text(AppStrings.backToHome),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في معالجة الدفع: $e')),
        );
      }
    }
  }
}

enum PaymentMethod { cash, card, mixed }
