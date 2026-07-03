import '../core/services/hive_service.dart';
import '../core/services/sync_service.dart';
import '../models/bill_reminder_model.dart';

class BillRepository {
  final HiveService _hiveService = HiveService();
  final SyncService _syncService = SyncService();

  // Get list of reminders
  List<BillReminderModel> getBills() {
    return _hiveService.getBills()..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  // Create or Update reminder
  Future<void> saveBill(BillReminderModel bill) async {
    await _hiveService.saveBill(bill.copyWith(
      isPendingSync: true,
      updatedAt: DateTime.now(),
    ));
    _syncService.syncData();
  }

  // Delete bill reminder configuration
  Future<void> deleteBill(String id) async {
    await _hiveService.deleteBill(id);
    _syncService.syncData();
  }

  // Mark bill as paid
  Future<void> markAsPaid(String id) async {
    final bills = _hiveService.getBills();
    final bill = bills.where((b) => b.id == id).firstOrNull;

    if (bill != null) {
      if (bill.isRecurring) {
        // Increment next due date according to frequency
        DateTime nextDue;
        switch (bill.recurringFrequency.toLowerCase()) {
          case 'weekly':
            nextDue = bill.dueDate.add(const Duration(days: 7));
            break;
          case 'yearly':
            nextDue = DateTime(bill.dueDate.year + 1, bill.dueDate.month, bill.dueDate.day);
            break;
          case 'monthly':
          default:
            nextDue = DateTime(bill.dueDate.year, bill.dueDate.month + 1, bill.dueDate.day);
            break;
        }

        await _hiveService.saveBill(bill.copyWith(
          dueDate: nextDue,
          isPaid: false, // remains unpaid for the next cycle
          isPendingSync: true,
          updatedAt: DateTime.now(),
        ));
      } else {
        // One-time bill, mark paid
        await _hiveService.saveBill(bill.copyWith(
          isPaid: true,
          isPendingSync: true,
          updatedAt: DateTime.now(),
        ));
      }

      _syncService.syncData();
    }
  }
}
extension BillFirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
