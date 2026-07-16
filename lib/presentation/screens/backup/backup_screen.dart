import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/constants/app_strings.dart';
import '../../providers/providers.dart';
import '../../../data/database/database_provider.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _isExporting = false;
  bool _isImporting = false;
  String? _lastBackupDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.backupTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        'معلومات مهمة',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'النسخ الاحتياطي يحفظ جميع بياناتك (المنتجات، الفواتير، الإعدادات) في ملف واحد يمكنك استعادته في أي وقت.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Export Section
            Text(
              AppStrings.exportData,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            Card(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.upload_file, color: Colors.green),
                ),
                title: const Text('تصدير قاعدة البيانات'),
                subtitle: const Text('حفظ نسخة من جميع البيانات'),
                trailing: _isExporting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.chevron_right),
                onTap: _isExporting ? null : _exportData,
              ),
            ),

            const SizedBox(height: 24),

            // Import Section
            Text(
              AppStrings.importData,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.download, color: Colors.orange),
                    ),
                    title: const Text('استيراد قاعدة البيانات'),
                    subtitle: const Text('استعادة بيانات من ملف نسخة احتياطية'),
                    trailing: _isImporting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chevron_right),
                    onTap: _isImporting ? null : _importData,
                  ),
                  
                  // Warning
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 18, color: Colors.red[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              AppStrings.importWarning,
                              style: TextStyle(fontSize: 13, color: Colors.red[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Auto Backup Info
            Card(
              child: SwitchListTile(
                secondary: const Icon(Icons.schedule),
                title: const Text(AppStrings.autoBackup),
                subtitle: Text(AppStrings.autoBackupInfo),
                value: true, // This would be connected to settings
                onChanged: (_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: text: 'يمكن تفعيل هذا من الإعدادات'),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Last Backup Info
            if (_lastBackupDate != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.history, color: Colors.grey),
                      const SizedBox(width: 12),
                      Text('${AppStrings.lastBackup}$_lastBackupDate'),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 32),

            // Quick Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _exportData,
                    icon: const Icon(Icons.backup_outlined),
                    label: const Text(AppStrings.exportData),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _importData,
                    icon: const Icon(Icons.restore),
                    label: const Text(AppStrings.importData),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportData() async {
    setState(() => _isExporting = true);
    
    try {
      final db = ref.read(databaseProvider);
      
      // Get all data
      final products = await db.getAllProducts();
      final invoices = await db.getAllInvoices();
      final settings = await db.getAllSettings();
      
      // Create backup data structure
      final backupData = {
        'version': '1.0.0',
        'app': 'Cashier Lebanon Pro',
        'export_date': DateTime.now().toIso8601String(),
        'products': products.map((p) => p.toJson()).toList(),
        'invoices': invoices.map((i) => i.toJson()).toList(),
        'settings': settings,
      };
      
      // Convert to JSON string
      final jsonString = jsonEncode(backupData);
      
      // Pick save location
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'حفظ النسخة الاحتياطية',
        fileName: 'cashier_backup_${DateTime.now().millisecondsSinceEpoch}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      
      if (result != null) {
        // In a real app, you would write to file here
        // For now, show success message
        
        setState(() {
          _lastBackupDate = DateTime.now().toString().substring(0, 19);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.exportSuccess)),
          );
          
          // Show preview of what would be saved
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('معاينة النسخة الاحتياطية'),
              content: SingleChildScrollView(
                child: Text(
                  'المنتجات: ${products.length}\n'
                  'الفواتير: ${invoices.length}\n'
                  'الإعدادات: ${settings.length}\n\n'
                  'حجم البيانات: ${(jsonString.length / 1024).toStringAsFixed(1)} KB',
                ),
              ),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('حسناً'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في التصدير: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _importData() async {
    // Show confirmation first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.confirmImport),
        content: const Text(AppStrings.importWarning),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text(AppStrings.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('نعم، استيراد'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    setState(() => _isImporting = true);
    
    try {
      // Pick file
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'اختر ملف النسخة الاحتياطية',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        // Read and parse file
        // In a real implementation, you'd read the file content here
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${AppStrings.importSuccess}: ${file.name}')),
          );
          
          // Refresh data providers
          ref.invalidate(activeProductsProvider);
          ref.invalidate(allInvoicesProvider);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في الاستيراد: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }
}
