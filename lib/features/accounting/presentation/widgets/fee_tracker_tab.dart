import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../backend/services/accounting_service.dart';
import '../bloc/accounting_bloc.dart';
import '../bloc/accounting_state.dart';
import '../bloc/accounting_event.dart';
import '../../../profile/models/profile_state.dart';
import 'package:ShEC_CSE/features/permissions/services/permissions_service.dart';
import 'payment_dialogs.dart';

const Color _emerald = Color(0xFF10B981);

class FeeTrackerTab extends StatefulWidget {
  const FeeTrackerTab({super.key});

  @override
  State<FeeTrackerTab> createState() => _FeeTrackerTabState();
}

class _FeeTrackerTabState extends State<FeeTrackerTab> {
  String _searchQuery = '';

  bool get _isAdmin {
    final profile = currentProfile.value;
    return profile.role == UserRole.superUser ||
        (profile.role == UserRole.committeeMember && (PermissionsService.currentPermissions.value?.canManageAccounting ?? false)) ||
        profile.designation == 'Treasurer' ||
        profile.designation == 'President' ||
        profile.designation == 'Vice President';
  }

  bool _isCreator(FeePayment payment) {
    return currentProfile.value.id == payment.receivedBy;
  }

  void _showAddPaymentDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: context.read<AccountingBloc>(),
          child: const AddPaymentDialog(),
        );
      },
    );
  }

  void _showEditPaymentDialog(BuildContext context, FeePayment payment) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: context.read<AccountingBloc>(),
          child: EditPaymentDialog(payment: payment),
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, FeePayment payment) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final colors = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Delete Fee Payment?'),
          content: Text(
              'Are you sure you want to remove this fee payment of ৳ ${payment.amount.toStringAsFixed(0)} recorded for ${payment.memberName}? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<AccountingBloc>().add(DeleteFeePaymentSubmitted(payment.id));
                Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final state = context.watch<AccountingBloc>().state;
    final hasData = state is AccountingDataLoaded;
    final payments = hasData ? state.summary.recentPayments : <FeePayment>[];

    final profile = currentProfile.value;
    final isCommittee = profile.role == UserRole.committeeMember || profile.role == UserRole.superUser;
    
    final visiblePayments = isCommittee 
        ? payments 
        : payments.where((p) => p.memberId == profile.id).toList();

    final filtered = visiblePayments.where((p) {
      if (_searchQuery.isEmpty) return true;
      final term = _searchQuery.toLowerCase();
      return p.memberName.toLowerCase().contains(term) ||
          (p.memberIdRoll != null && p.memberIdRoll!.toLowerCase().contains(term)) ||
          p.month.contains(term);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search payments by name, roll, month...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val);
              },
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.payment, size: 48, color: colors.onSurface.withValues(alpha: 0.2)),
                        const SizedBox(height: 12),
                        const Text('No payment transactions found.', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemBuilder: (context, index) {
                      final payment = filtered[index];
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                        color: colors.surfaceContainerLowest,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.only(left: 16, right: 8, top: 6, bottom: 6),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(payment.memberName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text('+ ৳ ${payment.amount.toStringAsFixed(0)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: _emerald, fontSize: 14)),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (payment.memberIdRoll != null) ...[
                                const SizedBox(height: 4),
                                Text(payment.memberIdRoll!, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: colors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      payment.paymentType.toUpperCase(),
                                      style: TextStyle(fontSize: 9, color: colors.primary, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: colors.onSurface.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      payment.month,
                                      style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    DateFormat('d MMM yyyy, h:mm a').format(payment.paymentDate),
                                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                                ],
                              ),
                              if (payment.remarks != null && payment.remarks!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text('Remarks: ${payment.remarks}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
                              ]
                            ],
                          ),
                          trailing: _isCreator(payment)
                              ? PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, size: 20),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _showEditPaymentDialog(context, payment);
                                    } else if (value == 'delete') {
                                      _showDeleteConfirmationDialog(context, payment);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_outlined, size: 18),
                                          SizedBox(width: 8),
                                          Text('Edit'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                          const SizedBox(width: 8),
                                          Text('Delete', style: TextStyle(color: colors.error)),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : null,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _showAddPaymentDialog(context),
              label: const Text('Add Payment'),
              icon: const Icon(Icons.add),
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }
}
