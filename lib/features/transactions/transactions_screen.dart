import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/constants/constants.dart';
import '../../core/services/providers.dart';
import '../../models/transaction_model.dart';
import '../../widgets/premium_gradient_button.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  bool _ascending = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      ref.read(transactionFilterProvider.notifier).updateFilter(ref.read(transactionFilterProvider).copyWith(
            searchQuery: _searchController.text,
          ));
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddTransactionSheet({TransactionModel? existingTx}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransactionFormSheet(existingTx: existingTx),
    );
  }

  Future<void> _startOcrScanner() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    
    if (image != null) {
      if (!mounted) return;
      
      // Show loading indicator dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Analyzing receipt OCR details...', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
      );

      final ocrService = ref.read(ocrServiceProvider);
      final result = await ocrService.scanReceipt(image.path);

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        if (result != null) {
          // Pre-populate sheet with parsed values
          final mockTx = TransactionModel(
            id: '',
            userId: ref.read(authNotifierProvider)!.id,
            amount: result.amount,
            type: 'expense',
            category: result.suggestedCategory,
            date: result.date,
            time: "${result.date.hour.toString().padLeft(2, '0')}:${result.date.minute.toString().padLeft(2, '0')}",
            paymentMethod: 'Cash',
            notes: 'Scanned from receipt at ${result.merchantName}',
            receiptImageUrl: image.path,
            updatedAt: DateTime.now(),
          );
          _openAddTransactionSheet(existingTx: mockTx);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not recognize text. Please log manually.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final txList = ref.watch(transactionsListProvider);
    final settings = ref.watch(settingsNotifierProvider);
    final currency = settings.baseCurrency;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Ledger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.document_scanner_rounded),
            tooltip: 'OCR Receipt Scanner',
            onPressed: _startOcrScanner,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Panel
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search merchant, notes, category...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Category selection bubble
                      _buildFilterChip('All'),
                      ...AppConstants.categories.map((c) => _buildFilterChip(c.name)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      icon: Icon(_ascending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 16),
                      label: Text('Sort by Date'),
                      onPressed: () {
                        setState(() {
                          _ascending = !_ascending;
                          ref.read(transactionFilterProvider.notifier).updateFilter(ref.read(transactionFilterProvider).copyWith(
                                sortBy: 'date',
                                ascending: _ascending,
                              ));
                        });
                      },
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.monetization_on_outlined, size: 16),
                      label: const Text('Sort by Amount'),
                      onPressed: () {
                        setState(() {
                          _ascending = !_ascending;
                          ref.read(transactionFilterProvider.notifier).updateFilter(ref.read(transactionFilterProvider).copyWith(
                                sortBy: 'amount',
                                ascending: _ascending,
                              ));
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Ledger List
          Expanded(
            child: txList.isEmpty
                ? const Center(
                    child: Text('No transactions match the criteria.', style: TextStyle(color: Colors.grey)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: txList.length,
                    itemBuilder: (context, index) {
                      final tx = txList[index];
                      final cat = AppConstants.categories.firstWhere((c) => c.name == tx.category, orElse: () => AppConstants.categories.last);

                      return Dismissible(
                        key: Key(tx.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          color: Colors.redAccent,
                          child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 28),
                        ),
                        onDismissed: (dir) {
                          ref.read(transactionRepositoryProvider).deleteTransaction(tx.id);
                          ref.invalidate(transactionsListProvider);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Transaction deleted')),
                          );
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: cat.color.withValues(alpha: 0.1),
                              child: Icon(cat.icon, color: cat.color),
                            ),
                            title: Text(tx.notes ?? tx.category, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${DateFormat('dd MMM yyyy').format(tx.date)} • ${tx.paymentMethod}'),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${tx.type == 'expense' ? "-" : "+"}$currency${tx.amount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: tx.type == 'expense' ? Colors.redAccent : Colors.greenAccent,
                                  ),
                                ),
                                if (tx.isSmsAutoRead)
                                  const Text('SMS parsed', style: TextStyle(fontSize: 9, color: Colors.blue)),
                              ],
                            ),
                            onTap: () => _openAddTransactionSheet(existingTx: tx),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddTransactionSheet(),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final active = _selectedCategory == label;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: active,
        onSelected: (sel) {
          if (sel) {
            setState(() {
              _selectedCategory = label;
              ref.read(transactionFilterProvider.notifier).updateFilter(ref.read(transactionFilterProvider).copyWith(
                    categoryFilter: label,
                  ));
            });
          }
        },
      ),
    );
  }
}

// Bottom sheet input form for transaction records
class TransactionFormSheet extends ConsumerStatefulWidget {
  final TransactionModel? existingTx;

  const TransactionFormSheet({super.key, this.existingTx});

  @override
  ConsumerState<TransactionFormSheet> createState() => _TransactionFormSheetState();
}

class _TransactionFormSheetState extends ConsumerState<TransactionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late String _type;
  late String _category;
  late double _amount;
  late DateTime _date;
  late String _paymentMethod;
  final _notesController = TextEditingController();
  String? _receiptPath;

  @override
  void initState() {
    super.initState();
    final tx = widget.existingTx;
    _type = tx?.type ?? 'expense';
    _category = tx?.category ?? AppConstants.categories.first.name;
    _amount = tx?.amount ?? 0.0;
    _date = tx?.date ?? DateTime.now();
    _paymentMethod = tx?.paymentMethod ?? AppConstants.paymentMethods.first;
    _notesController.text = tx?.notes ?? '';
    _receiptPath = tx?.receiptImageUrl;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _pickReceiptImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _receiptPath = image.path);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final user = ref.read(authNotifierProvider);
    if (user == null) return;

    final tx = TransactionModel(
      id: widget.existingTx?.id ?? 'tx_${DateTime.now().millisecondsSinceEpoch}',
      userId: user.id,
      amount: _amount,
      type: _type,
      category: _category,
      date: _date,
      time: DateFormat('HH:mm').format(DateTime.now()),
      paymentMethod: _paymentMethod,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      receiptImageUrl: _receiptPath,
      isSmsAutoRead: widget.existingTx?.isSmsAutoRead ?? false,
      updatedAt: DateTime.now(),
    );

    await ref.read(transactionRepositoryProvider).saveTransaction(tx);
    ref.invalidate(transactionsListProvider);
    ref.read(budgetsProvider.notifier).loadBudgets(); // Refresh active budget spent amounts
    
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;
    
    return Container(
      margin: const EdgeInsets.only(top: 80),
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 20 + keyboardPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Segmented Type picker
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'expense', label: Text('Expense'), icon: Icon(Icons.arrow_downward)),
                  ButtonSegment(value: 'income', label: Text('Income'), icon: Icon(Icons.arrow_upward)),
                ],
                selected: {_type},
                onSelectionChanged: (val) {
                  setState(() {
                    _type = val.first;
                    // reset category match
                    final matches = AppConstants.categories.where((c) => c.isExpense == (_type == 'expense'));
                    _category = matches.first.name;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Amount textfield
              TextFormField(
                initialValue: widget.existingTx != null ? _amount.toString() : '',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  hintText: '0.00',
                  border: InputBorder.none,
                ),
                validator: (val) {
                  if (val == null || val.isEmpty || double.tryParse(val) == null || double.parse(val) <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
                onSaved: (val) => _amount = double.parse(val!),
              ),
              const Divider(),
              const SizedBox(height: 16),

              // Category grid selector
              const Text('Select Category', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                items: AppConstants.categories
                    .where((c) => c.isExpense == (_type == 'expense'))
                    .map((c) => DropdownMenuItem(
                          value: c.name,
                          child: Row(
                            children: [
                              Icon(c.icon, color: c.color),
                              const SizedBox(width: 12),
                              Text(c.name),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _category = val!),
              ),
              const SizedBox(height: 20),

              // Date Picker Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Date:', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: _selectDate,
                    icon: const Icon(Icons.calendar_today_rounded),
                    label: Text(DateFormat('dd MMMM yyyy').format(_date)),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Payment Method
              DropdownButtonFormField<String>(
                initialValue: _paymentMethod,
                decoration: InputDecoration(
                  labelText: 'Payment Method',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                items: AppConstants.paymentMethods
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (val) => setState(() => _paymentMethod = val!),
              ),
              const SizedBox(height: 20),

              // Notes Input
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Notes / Description',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 20),

              // Receipt Image Picker UI
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Receipt Image', style: TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: Icon(_receiptPath != null ? Icons.image_rounded : Icons.add_a_photo_outlined),
                    color: Theme.of(context).colorScheme.primary,
                    onPressed: _pickReceiptImage,
                  ),
                ],
              ),
              if (_receiptPath != null) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(_receiptPath!),
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              const SizedBox(height: 32),

              PremiumGradientButton(
                text: widget.existingTx != null ? 'Update Ledger' : 'Add to Ledger',
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
