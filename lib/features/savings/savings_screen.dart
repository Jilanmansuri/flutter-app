import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/services/providers.dart';
import '../../models/savings_goal_model.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/premium_gradient_button.dart';

class SavingsScreen extends ConsumerStatefulWidget {
  const SavingsScreen({super.key});

  @override
  ConsumerState<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends ConsumerState<SavingsScreen> {
  void _openAddGoalDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddSavingsGoalDialog(),
    );
  }

  void _openAddFundsDialog(SavingsGoalModel goal) {
    showDialog(
      context: context,
      builder: (context) => AddFundsDialog(goal: goal),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goals = ref.watch(savingsProvider);
    final settings = ref.watch(settingsNotifierProvider);
    final currency = settings.baseCurrency;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Goals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: _openAddGoalDialog,
          ),
        ],
      ),
      body: goals.isEmpty
          ? const Center(
              child: Text('Create savings goals to track milestones.', style: TextStyle(color: Colors.grey)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: goals.length,
              itemBuilder: (context, index) {
                final goal = goals[index];
                final progress = goal.progressPercentage;

                return Card(
                  margin: const EdgeInsets.only(bottom: 20),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      // Goal image headers
                      if (goal.imageUrl != null)
                        Image.file(
                          File(goal.imageUrl!),
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      else
                        Container(
                          height: 100,
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          alignment: Alignment.center,
                          child: Icon(Icons.laptop_mac_rounded, size: 48, color: Theme.of(context).colorScheme.primary),
                        ),
                      
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(goal.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                Text(
                                  goal.isCompleted ? 'Completed! 🎉' : 'Deadline: ${DateFormat('dd MMM yyyy').format(goal.deadline)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: goal.isCompleted ? Colors.green : Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                              value: progress / 100,
                              color: Colors.green,
                              backgroundColor: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Saved: $currency${goal.savedAmount.toStringAsFixed(0)} / $currency${goal.targetAmount.toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                Text('${progress.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    ref.read(savingsProvider.notifier).deleteGoal(goal.id);
                                  },
                                  child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                                ),
                                const SizedBox(width: 8),
                                if (!goal.isCompleted)
                                  ElevatedButton(
                                    onPressed: () => _openAddFundsDialog(goal),
                                    child: const Text('Add Funds'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

// Dialog to create a savings goal
class AddSavingsGoalDialog extends ConsumerStatefulWidget {
  const AddSavingsGoalDialog({super.key});

  @override
  ConsumerState<AddSavingsGoalDialog> createState() => _AddSavingsGoalDialogState();
}

class _AddSavingsGoalDialogState extends ConsumerState<AddSavingsGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  double _target = 0.0;
  DateTime _deadline = DateTime.now().add(const Duration(days: 30));
  String? _imagePath;

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _deadline = picked);
    }
  }

  Future<void> _pickGoalImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _imagePath = image.path);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final user = ref.read(authNotifierProvider);
    if (user == null) return;

    final goal = SavingsGoalModel(
      id: 'goal_${DateTime.now().millisecondsSinceEpoch}',
      userId: user.id,
      title: _title,
      targetAmount: _target,
      savedAmount: 0.0,
      deadline: _deadline,
      imageUrl: _imagePath,
      updatedAt: DateTime.now(),
    );

    await ref.read(savingsProvider.notifier).saveGoal(goal);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Savings Goal'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Goal Title (e.g. Buy Laptop)'),
                validator: (val) => val == null || val.isEmpty ? 'Please enter a goal title' : null,
                onSaved: (val) => _title = val!,
              ),
              const SizedBox(height: 12),
              TextFormField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Target Amount'),
                validator: (val) => val == null || double.tryParse(val) == null || double.parse(val) <= 0 ? 'Enter target amount' : null,
                onSaved: (val) => _target = double.parse(val!),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Deadline:', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: _selectDate,
                    child: Text(DateFormat('dd MMM yyyy').format(_deadline)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_a_photo),
                label: const Text('Add Goal Image'),
                onPressed: _pickGoalImage,
              ),
              if (_imagePath != null) ...[
                const SizedBox(height: 8),
                Text('Image selected: ${_imagePath!.split('/').last}'),
              ],
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

// Dialog to add funds to savings goals
class AddFundsDialog extends ConsumerStatefulWidget {
  final SavingsGoalModel goal;
  const AddFundsDialog({super.key, required this.goal});

  @override
  ConsumerState<AddFundsDialog> createState() => _AddFundsDialogState();
}

class _AddFundsDialogState extends ConsumerState<AddFundsDialog> {
  final _formKey = GlobalKey<FormState>();
  double _amount = 0.0;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    await ref.read(savingsProvider.notifier).addSavings(widget.goal.id, _amount);
    
    if (mounted) {
      Navigator.pop(context);
      
      // Goal completion celebration animation snackbar
      final updatedGoals = ref.read(savingsProvider);
      final checkGoal = updatedGoals.where((g) => g.id == widget.goal.id).firstOrNull;
      if (checkGoal != null && checkGoal.isCompleted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Congratulations! You completed your savings goal: "${widget.goal.title}"! 🎉'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Funds to "${widget.goal.title}"'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Amount to add'),
          validator: (val) => val == null || double.tryParse(val) == null || double.parse(val) <= 0 ? 'Enter valid amount' : null,
          onSaved: (val) => _amount = double.parse(val!),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }
}
extension SavingsGoalsFirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
