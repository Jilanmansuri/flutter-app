import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/constants.dart';
import '../../core/services/providers.dart';
import '../../models/budget_model.dart';
import '../../widgets/glass_card.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  final _monthStr = "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}";

  void _openAddBudgetDialog() {
    showDialog(
      context: context,
      builder: (context) => AddBudgetDialog(month: _monthStr),
    );
  }

  Color _getIndicatorColor(double progress) {
    if (progress >= 0.9) return Colors.red;
    if (progress >= 0.75) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final budgets = ref.watch(budgetsProvider);
    final settings = ref.watch(settingsNotifierProvider);
    final currency = settings.baseCurrency;

    // Separate total budget from category budgets
    final totalBudget = budgets.where((b) => b.category == 'Total').firstOrNull;
    final categoryBudgets = budgets.where((b) => b.category != 'Total').toList();

    double totalLimit = totalBudget?.limitAmount ?? 0.0;
    double totalSpent = totalBudget?.spentAmount ?? 0.0;
    double totalProgress = totalLimit > 0 ? (totalSpent / totalLimit) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Dashboard'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMMM yyyy').format(DateTime.now()),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _openAddBudgetDialog,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Set Budget'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Overall Total Budget Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getIndicatorColor(totalProgress),
                    _getIndicatorColor(totalProgress).withBlue(150),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TOTAL MONTHLY BUDGET',
                    style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$currency${totalSpent.toStringAsFixed(0)} / $currency${totalLimit.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  LinearProgressIndicator(
                    value: totalProgress > 1.0 ? 1.0 : totalProgress,
                    color: Colors.white,
                    backgroundColor: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    totalProgress >= 1.0 
                        ? 'Warning: You have exceeded your monthly budget!'
                        : 'You have used ${(totalProgress * 100).toStringAsFixed(0)}% of your limit.',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            const Text(
              'Category-wise Budgets',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            categoryBudgets.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(32),
                    alignment: Alignment.center,
                    child: const Text('No category budgets configured yet.', style: TextStyle(color: Colors.grey)),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: categoryBudgets.length,
                    itemBuilder: (context, index) {
                      final b = categoryBudgets[index];
                      final catProgress = b.limitAmount > 0 ? (b.spentAmount / b.limitAmount) : 0.0;
                      final catColor = _getIndicatorColor(catProgress);
                      
                      final categoryInfo = AppConstants.categories.firstWhere((c) => c.name == b.category, orElse: () => AppConstants.categories.last);

                      return Dismissible(
                        key: Key(b.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.redAccent,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (direction) {
                          ref.read(budgetsProvider.notifier).removeBudget(b.id);
                        },
                        child: GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: categoryInfo.color.withValues(alpha: 0.1),
                                    child: Icon(categoryInfo.icon, color: categoryInfo.color, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      b.category,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ),
                                  Text(
                                    '$currency${b.spentAmount.toStringAsFixed(0)} / $currency${b.limitAmount.toStringAsFixed(0)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              LinearProgressIndicator(
                                value: catProgress > 1.0 ? 1.0 : catProgress,
                                color: catColor,
                                backgroundColor: catColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${(catProgress * 100).toStringAsFixed(0)}% Spent',
                                    style: TextStyle(fontSize: 11, color: catColor, fontWeight: FontWeight.bold),
                                  ),
                                  if (catProgress >= 0.9)
                                    const Text('Critical Limit!', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}

// Interactive Dialog to configure budget settings
class AddBudgetDialog extends ConsumerStatefulWidget {
  final String month;
  const AddBudgetDialog({super.key, required this.month});

  @override
  ConsumerState<AddBudgetDialog> createState() => _AddBudgetDialogState();
}

class _AddBudgetDialogState extends ConsumerState<AddBudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  String _category = 'Total';
  double _limit = 0.0;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final user = ref.read(authNotifierProvider);
    if (user == null) return;

    final budget = BudgetModel(
      id: '${widget.month}_$_category',
      userId: user.id,
      month: widget.month,
      category: _category,
      limitAmount: _limit,
      updatedAt: DateTime.now(),
    );

    await ref.read(budgetsProvider.notifier).addBudget(budget);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Configure Limit'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Category Dropdown
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: InputDecoration(
                labelText: 'Target Category',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: [
                const DropdownMenuItem(value: 'Total', child: Text('Total Monthly')),
                ...AppConstants.categories
                    .where((c) => c.isExpense)
                    .map((c) => DropdownMenuItem(value: c.name, child: Text(c.name))),
              ],
              onChanged: (val) => setState(() => _category = val!),
            ),
            const SizedBox(height: 20),

            // Limit Input
            TextFormField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Limit Amount',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (val) {
                if (val == null || val.isEmpty || double.tryParse(val) == null || double.parse(val) <= 0) {
                  return 'Enter a valid budget limit';
                }
                return null;
              },
              onSaved: (val) => _limit = double.parse(val!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
