import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/services/providers.dart';
import '../../models/loan_model.dart';
import '../../models/transaction_model.dart';
import '../../widgets/glass_card.dart';

class LoansScreen extends ConsumerStatefulWidget {
  const LoansScreen({super.key});

  @override
  ConsumerState<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends ConsumerState<LoansScreen> {
  void _openAddLoanDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddLoanDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loans = ref.watch(loansProvider);
    final settings = ref.watch(settingsNotifierProvider);
    final currency = settings.baseCurrency;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loans & EMI Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: _openAddLoanDialog,
          ),
        ],
      ),
      body: loans.isEmpty
          ? const Center(
              child: Text('No active loans or EMI schedules found.', style: TextStyle(color: Colors.grey)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: loans.length,
              itemBuilder: (context, index) {
                final loan = loans[index];
                final progress = loan.progressPercentage;

                return GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(loan.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          Text(
                            'Interest: ${loan.interestRate}% P.A.',
                            style: const TextStyle(fontSize: 12, color: Colors.blueAccent, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Progress Bar
                      LinearProgressIndicator(
                        value: progress / 100,
                        color: Colors.blueAccent,
                        backgroundColor: Colors.blueAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Paid: $currency${(loan.loanAmount - loan.remainingAmount).toStringAsFixed(0)} / $currency${loan.loanAmount.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          Text('${progress.toStringAsFixed(0)}% Clear', style: const TextStyle(fontSize: 12, color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Divider(height: 24),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'EMI Amount: $currency${loan.emiAmount.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Next Due: ${DateFormat('dd MMMM yyyy').format(loan.dueDate)}',
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () {
                                  ref.read(loansProvider.notifier).deleteLoan(loan.id);
                                },
                                child: const Text('Remove', style: TextStyle(color: Colors.redAccent)),
                              ),
                              if (loan.remainingAmount > 0) ...[
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    ref.read(loansProvider.notifier).makeEmiPayment(loan.id);
                                    // Log this transaction automatically
                                    final user = ref.read(authNotifierProvider);
                                    if (user != null) {
                                      ref.read(transactionRepositoryProvider).saveTransaction(
                                        TransactionModel(
                                          id: 'loan_payment_${DateTime.now().millisecondsSinceEpoch}',
                                          userId: user.id,
                                          amount: loan.emiAmount,
                                          type: 'expense',
                                          category: 'Bills',
                                          date: DateTime.now(),
                                          time: DateFormat('HH:mm').format(DateTime.now()),
                                          paymentMethod: 'Bank Transfer',
                                          notes: 'EMI Repayment for ${loan.name}',
                                          updatedAt: DateTime.now(),
                                        ),
                                      );
                                      ref.invalidate(transactionsListProvider);
                                    }
                                  },
                                  child: const Text('Pay EMI'),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

// Dialog to create a loan schedule
class AddLoanDialog extends ConsumerStatefulWidget {
  const AddLoanDialog({super.key});

  @override
  ConsumerState<AddLoanDialog> createState() => _AddLoanDialogState();
}

class _AddLoanDialogState extends ConsumerState<AddLoanDialog> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  double _amount = 0.0;
  double _interest = 0.0;
  double _emi = 0.0;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));

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

    final loan = LoanModel(
      id: 'loan_${DateTime.now().millisecondsSinceEpoch}',
      userId: user.id,
      name: _name,
      loanAmount: _amount,
      interestRate: _interest,
      emiAmount: _emi,
      remainingAmount: _amount,
      dueDate: _dueDate,
      updatedAt: DateTime.now(),
    );

    await ref.read(loansProvider.notifier).saveLoan(loan);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Loan Tracker'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Loan Name (e.g. Home Loan)'),
                validator: (val) => val == null || val.isEmpty ? 'Please enter loan name' : null,
                onSaved: (val) => _name = val!,
              ),
              const SizedBox(height: 12),
              TextFormField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Total Principal Amount'),
                validator: (val) => val == null || double.tryParse(val) == null || double.parse(val) <= 0 ? 'Enter principal amount' : null,
                onSaved: (val) => _amount = double.parse(val!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Annual Interest Rate (%)'),
                validator: (val) => val == null || double.tryParse(val) == null ? 'Enter interest rate' : null,
                onSaved: (val) => _interest = double.parse(val!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Monthly EMI Amount'),
                validator: (val) => val == null || double.tryParse(val) == null || double.parse(val) <= 0 ? 'Enter EMI amount' : null,
                onSaved: (val) => _emi = double.parse(val!),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('First Due Date:', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: _selectDate,
                    child: Text(DateFormat('dd MMM yyyy').format(_dueDate)),
                  ),
                ],
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
