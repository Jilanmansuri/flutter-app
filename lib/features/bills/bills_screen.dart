import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/services/providers.dart';
import '../../models/bill_reminder_model.dart';
import '../../models/transaction_model.dart';
import '../../widgets/glass_card.dart';

class BillsScreen extends ConsumerStatefulWidget {
  const BillsScreen({super.key});

  @override
  ConsumerState<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends ConsumerState<BillsScreen> {
  void _openAddBillDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddBillDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bills = ref.watch(billsProvider);
    final settings = ref.watch(settingsNotifierProvider);
    final currency = settings.baseCurrency;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Utility & Bills'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: _openAddBillDialog,
          ),
        ],
      ),
      body: bills.isEmpty
          ? const Center(
              child: Text('No active bill reminders set.', style: TextStyle(color: Colors.grey)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: bills.length,
              itemBuilder: (context, index) {
                final bill = bills[index];

                return GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getCategoryIcon(bill.category),
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(bill.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(
                              'Due: ${DateFormat('dd MMM yyyy').format(bill.dueDate)} ${bill.isRecurring ? "(${bill.recurringFrequency})" : ""}',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$currency${bill.amount.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () {
                              ref.read(billsProvider.notifier).deleteBill(bill.id);
                            },
                          ),
                          if (!bill.isPaid)
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                textStyle: const TextStyle(fontSize: 11),
                              ),
                              onPressed: () {
                                ref.read(billsProvider.notifier).payBill(bill.id);
                                // Log to transaction database automatically
                                final user = ref.read(authNotifierProvider);
                                if (user != null) {
                                  ref.read(transactionRepositoryProvider).saveTransaction(
                                    TransactionModel(
                                      id: 'bill_payment_${DateTime.now().millisecondsSinceEpoch}',
                                      userId: user.id,
                                      amount: bill.amount,
                                      type: 'expense',
                                      category: 'Bills',
                                      date: DateTime.now(),
                                      time: DateFormat('HH:mm').format(DateTime.now()),
                                      paymentMethod: 'Bank Transfer',
                                      notes: 'Paid: ${bill.title}',
                                      updatedAt: DateTime.now(),
                                    ),
                                  );
                                  ref.invalidate(transactionsListProvider);
                                }
                              },
                              child: const Text('Pay'),
                            )
                          else
                            const Text('Paid ✓', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'netflix':
      case 'spotify':
      case 'amazon prime':
        return Icons.subscriptions_rounded;
      case 'rent':
        return Icons.house_rounded;
      case 'electricity':
        return Icons.electric_bolt_rounded;
      case 'internet':
        return Icons.wifi_rounded;
      case 'insurance':
        return Icons.security_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }
}

// Dialog to add a new bill reminder
class AddBillDialog extends ConsumerStatefulWidget {
  const AddBillDialog({super.key});

  @override
  ConsumerState<AddBillDialog> createState() => _AddBillDialogState();
}

class _AddBillDialogState extends ConsumerState<AddBillDialog> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  double _amount = 0.0;
  String _category = 'Electricity';
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  bool _isRecurring = false;
  String _frequency = 'monthly';

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final user = ref.read(authNotifierProvider);
    if (user == null) return;

    final bill = BillReminderModel(
      id: 'bill_${DateTime.now().millisecondsSinceEpoch}',
      userId: user.id,
      title: _title,
      amount: _amount,
      category: _category,
      dueDate: _dueDate,
      isRecurring: _isRecurring,
      recurringFrequency: _frequency,
      updatedAt: DateTime.now(),
    );

    await ref.read(billsProvider.notifier).saveBill(bill);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Bill Reminder'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Bill Title (e.g. Netflix Subscription)'),
                validator: (val) => val == null || val.isEmpty ? 'Please enter a title' : null,
                onSaved: (val) => _title = val!,
              ),
              const SizedBox(height: 12),
              TextFormField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Due Amount'),
                validator: (val) => val == null || double.tryParse(val) == null || double.parse(val) <= 0 ? 'Enter valid amount' : null,
                onSaved: (val) => _amount = double.parse(val!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Utility Type'),
                items: ['Electricity', 'Internet', 'Mobile Recharge', 'Rent', 'Insurance', 'Netflix', 'Amazon Prime', 'Spotify', 'Others']
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (val) => setState(() => _category = val!),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Due Date:', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: _selectDate,
                    child: Text(DateFormat('dd MMM yyyy').format(_dueDate)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Recurring Bill'),
                value: _isRecurring,
                onChanged: (val) => setState(() => _isRecurring = val),
              ),
              if (_isRecurring)
                DropdownButtonFormField<String>(
                  value: _frequency,
                  decoration: const InputDecoration(labelText: 'Frequency'),
                  items: ['weekly', 'monthly', 'yearly']
                      .map((freq) => DropdownMenuItem(value: freq, child: Text(freq.toUpperCase())))
                      .toList(),
                  onChanged: (val) => setState(() => _frequency = val!),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
