import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../providers/providers.dart';
import '../../../core/theme/app_theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _storeNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _taxRateController = TextEditingController();
  final _exchangeRateController = TextEditingController();

  bool _isLoading = true;
  bool _isDarkMode = false;
  bool _autoBackup = false;
  String _defaultCurrency = 'USD';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = ref.read(settingsRepositoryProvider);
    
    final storeName = await settings.getStoreName();
    final phone = await settings.getPhone();
    final address = await settings.getAddress();
    final taxRate = await settings.getTaxRate();
    final exchangeRate = await settings.getExchangeRate();
    final currency = await settings.getDefaultCurrency();
    final darkMode = await settings.isDarkMode();
    final autoBackup = await settings.isAutoBackupEnabled();
    
    setState(() {
      _storeNameController.text = storeName;
      _phoneController.text = phone;
      _addressController.text = address;
      _taxRateController.text = taxRate.toStringAsFixed(1);
      _exchangeRateController.text = exchangeRate.toStringAsFixed(0);
      _defaultCurrency = currency;
      _isDarkMode = darkMode;
      _autoBackup = autoBackup;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _taxRateController.dispose();
    _exchangeRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.settingsTitle),
        actions: [
          TextButton(
            onPressed: _saveAll,
            child: const Text(AppStrings.save, style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // General Settings Section
            _buildSectionHeader(context, AppStrings.generalSettings, Icons.store_outlined),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.store),
                    title: const Text(AppStrings.storeName),
                    subtitle: Text(_storeNameController.text.isEmpty ? AppStrings.storeNameHint : _storeNameController.text),
                    onTap: () => _editField(
                      context,
                      title: AppStrings.storeName,
                      controller: _storeNameController,
                      hint: AppStrings.storeNameHint,
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.phone_outlined),
                    title: const Text(AppStrings.phone),
                    subtitle: Text(_phoneController.text.isEmpty ? 'أدخل رقم الهاتف' : _phoneController.text),
                    onTap: () => _editField(
                      context,
                      title: AppStrings.phone,
                      controller: _phoneController,
                      hint: 'أدخل رقم الهاتف',
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.location_on_outlined),
                    title: const Text(AppStrings.address),
                    subtitle: Text(_addressController.text.isEmpty ? 'أدخل العنوان' : _addressController.text),
                    onTap: () => _editField(
                      context,
                      title: AppStrings.address,
                      controller: _addressController,
                      hint: 'أدخل عنوان المتجر',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Currency Settings Section
            _buildSectionHeader(context, AppStrings.currencySettings, Icons.attach_money),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.currency_exchange),
                    title: const Text(AppStrings.defaultCurrency),
                    trailing: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'USD', label: Text('USD \$')),
                        ButtonSegment(value: 'LBP', label: Text('LBP ل.ل')),
                      ],
                      selected: {_defaultCurrency},
                      onSelectionChanged: (v) => setState(() => _defaultCurrency = v.first),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.trending_up),
                    title: const Text(AppStrings.exchangeRate),
                    subtitle: Text('1 USD = ${_exchangeRateController.text} LBP'),
                    onTap: () => _editField(
                      context,
                      title: AppStrings.exchangeRate,
                      controller: _exchangeRateController,
                      hint: 'أدخل سعر الصرف',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.percent),
                    title: const Text(AppStrings.taxRate),
                    subtitle: Text('${_taxRateController.text}%'),
                    onTap: () => _editField(
                      context,
                      title: AppStrings.taxRate,
                      controller: _taxRateController,
                      hint: 'أدخل نسبة الضريبة',
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Appearance Settings Section
            _buildSectionHeader(context, AppStrings.appearanceSettings, Icons.palette_outlined),
            const SizedBox(height: 12),
            Card(
              child: SwitchListTile(
                secondary: Icon(_isDarkMode ? Icons.dark_mode : Icons.light_mode),
                title: const Text(AppStrings.darkMode),
                subtitle: Text(_isDarkMode ? 'الوضع الداكن مفعل' : 'الوضع الفاتح'),
                value: _isDarkMode,
                onChanged: (v) {
                  setState(() => _isDarkMode = v);
                  ref.read(themeModeProvider.notifier).state = v ? ThemeMode.dark : ThemeMode.light;
                },
              ),
            ),

            const SizedBox(height: 24),

            // Data Settings Section
            _buildSectionHeader(context, AppStrings.dataSettings, Icons.storage_outlined),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.backup_outlined),
                    title: const Text(AppStrings.autoBackup),
                    subtitle: const Text(AppStrings.autoBackupInfo),
                    value: _autoBackup,
                    onChanged: (v) => setState(() => _autoBackup = v),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.folder_outlined),
                    title: const Text('إدارة البيانات'),
                    subtitle: const Text('نسخ احتياطي، استيراد، تصدير'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.pushNamed(context, '/backup'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // About Section
            _buildSectionHeader(context, AppStrings.aboutSettings, Icons.info_outline),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text(AppStrings.aboutApp),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/about'),
              ),
            ),

            const SizedBox(height: 32),

            // Reset Button
            OutlinedButton.icon(
              onPressed: _showResetConfirmation,
              icon: const Icon(Icons.restore, color: Colors.orange),
              label: const Text(AppStrings.resetSettings, style: TextStyle(color: Colors.orange)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Future<void> _editField(
    BuildContext context, {
    required String title,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
  }) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: keyboardType ?? TextInputType.text,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text(AppStrings.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, 'save'), child: const Text(AppStrings.save)),
        ],
      ),
    );
    
    if (result == 'save' && mounted) {
      setState(() {});
    }
  }

  Future<void> _saveAll() async {
    try {
      final settings = ref.read(settingsRepositoryProvider);
      
      await settings.setStoreName(_storeNameController.text.trim());
      await settings.setPhone(_phoneController.text.trim());
      await settings.setAddress(_addressController.text.trim());
      await settings.setDefaultCurrency(_defaultCurrency);
      await settings.setExchangeRate(double.tryParse(_exchangeRateController.text) ?? 89500);
      await settings.setTaxRate(double.tryParse(_taxRateController.text) ?? 0);
      await settings.setAutoBackup(_autoBackup);
      await settings.setDarkMode(_isDarkMode);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('${AppStrings.success}: تم حفظ الإعدادات')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppStrings.failed}: $e')),
        );
      }
    }
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.resetSettings),
        content: const Text('هل أنت متأكد من إعادة تعيين جميع الإعدادات؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text(AppStrings.cancel)),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final settings = ref.read(settingsRepositoryProvider);
              await settings.setStoreName('متجري');
              await settings.setPhone('');
              await settings.setAddress('');
              await settings.setDefaultCurrency('USD');
              await settings.setExchangeRate(89500);
              await settings.setTaxRate(0);
              await settings.setAutoBackup(false);
              await settings.setDarkMode(false);
              
              _loadSettings();
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم إعادة تعيين الإعدادات')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('إعادة تعيين'),
          ),
        ],
      ),
    );
  }
}
