import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../backend/services/accounting_service.dart';
import '../bloc/accounting_bloc.dart';
import '../bloc/accounting_event.dart';
import '../bloc/accounting_state.dart';
import '../../../profile/models/profile_state.dart';
import 'payment_dialogs.dart';

const Color _emerald = Color(0xFF10B981);

class DuesTrackerTab extends StatefulWidget {
  const DuesTrackerTab({super.key});

  @override
  State<DuesTrackerTab> createState() => _DuesTrackerTabState();
}

class _DuesTrackerTabState extends State<DuesTrackerTab> {
  late DateTime _selectedDuesMonth;
  List<MemberDuesStatus>? _duesList;
  bool _isDuesLoading = false;
  String? _duesError;

  bool get _isAdmin {
    final designation = currentProfile.value.designation;
    return designation == 'Treasurer' ||
        designation == 'President' ||
        designation == 'Vice President';
  }

  @override
  void initState() {
    super.initState();
    _selectedDuesMonth = DateTime.now();
    _loadDuesLocal();
  }

  Future<void> _loadDuesLocal() async {
    if (!mounted) return;
    setState(() {
      _isDuesLoading = true;
      _duesError = null;
    });
    try {
      final monthStr = DateFormat('yyyy-MM').format(_selectedDuesMonth);
      final dues = await AccountingService.fetchDuesStatus(monthStr);
      if (mounted) {
        setState(() {
          _duesList = dues;
          _isDuesLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _duesError = e.toString();
          _isDuesLoading = false;
        });
      }
    }
  }

  void _previousMonth() {
    setState(() {
      _selectedDuesMonth = DateTime(_selectedDuesMonth.year, _selectedDuesMonth.month - 1);
    });
    _loadDuesLocal();
  }

  void _nextMonth() {
    setState(() {
      _selectedDuesMonth = DateTime(_selectedDuesMonth.year, _selectedDuesMonth.month + 1);
    });
    _loadDuesLocal();
  }

  void _showAddPaymentDialog(BuildContext context, {ProfileData? member, String? month}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: context.read<AccountingBloc>(),
          child: AddPaymentDialog(
            preselectedMember: member,
            preselectedMonth: month,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasDues = _duesList != null;
    final duesList = _duesList ?? <MemberDuesStatus>[];

    // Stats calculations
    final paidCount = duesList.where((d) => d.isPaid).length;
    final unpaidCount = duesList.length - paidCount;

    return BlocListener<AccountingBloc, AccountingState>(
      listenWhen: (previous, current) => current is AccountingActionSuccess,
      listener: (context, state) {
        if (state is AccountingActionSuccess && state.isPaymentAdded) {
          _loadDuesLocal();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
        children: [
          // 1. Month Chevron Switcher Row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: colors.surfaceContainer,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _previousMonth,
                ),
                Text(
                  DateFormat('MMMM yyyy').format(_selectedDuesMonth),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _nextMonth,
                ),
              ],
            ),
          ),

          // 2. Simple Stats Row
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _emerald.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _emerald.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        Text('$paidCount Members',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: _emerald, fontSize: 15)),
                        const SizedBox(height: 2),
                        const Text('PAID DUES', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: colors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colors.error.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        Text('$unpaidCount Members',
                            style: TextStyle(fontWeight: FontWeight.bold, color: colors.error, fontSize: 15)),
                        const SizedBox(height: 2),
                        const Text('UNPAID DUES', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Members Dues List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadDuesLocal,
              child: _isDuesLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _duesError != null
                      ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Container(
                            height: MediaQuery.of(context).size.height * 0.5,
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Error: $_duesError', style: TextStyle(color: colors.error)),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: _loadDuesLocal,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : !hasDues
                          ? const Center(child: CircularProgressIndicator())
                          : duesList.isEmpty
                              ? SingleChildScrollView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  child: Container(
                                    height: MediaQuery.of(context).size.height * 0.5,
                                    alignment: Alignment.center,
                                    child: const Text('No club members found.'),
                                  ),
                                )
                              : ListView.builder(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  itemCount: duesList.length,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  itemBuilder: (context, index) {
                                    final due = duesList[index];
                                    return Card(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      color: colors.surfaceContainerLowest,
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                        leading: CircleAvatar(
                                          radius: 20,
                                          backgroundImage: due.profile.imagePath != null &&
                                                  due.profile.imagePath!.startsWith('http')
                                              ? NetworkImage(due.profile.imagePath!) as ImageProvider
                                              : null,
                                          child: (due.profile.imagePath == null ||
                                                  !due.profile.imagePath!.startsWith('http'))
                                              ? Icon(Icons.person, color: colors.primary)
                                              : null,
                                        ),
                                        title: Text(due.profile.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                                        subtitle: Text(due.profile.studentFullId,
                                            style: const TextStyle(fontSize: 10.5, color: Colors.grey)),
                                        trailing: due.isPaid
                                            ? Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: _emerald.withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.check_circle_outline, color: _emerald, size: 14),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      'Paid (৳${due.paidAmount?.toStringAsFixed(0)})',
                                                      style: const TextStyle(
                                                          color: _emerald, fontWeight: FontWeight.bold, fontSize: 11),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : _isAdmin
                                                ? ElevatedButton(
                                                    onPressed: () {
                                                      _showAddPaymentDialog(
                                                        context,
                                                        member: due.profile,
                                                        month: DateFormat('yyyy-MM').format(_selectedDuesMonth),
                                                      );
                                                    },
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: colors.error.withValues(alpha: 0.1),
                                                      foregroundColor: colors.error,
                                                      elevation: 0,
                                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(6),
                                                        side: BorderSide(color: colors.error.withValues(alpha: 0.2)),
                                                      ),
                                                    ),
                                                    child: const Text('Mark Paid', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                                  )
                                                : Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                    decoration: BoxDecoration(
                                                      color: colors.error.withValues(alpha: 0.15),
                                                      borderRadius: BorderRadius.circular(6),
                                                      border: Border.all(color: colors.error.withValues(alpha: 0.3)),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(Icons.info_outline, color: colors.error, size: 14),
                                                        const SizedBox(width: 6),
                                                        Text(
                                                          'Unpaid',
                                                          style: TextStyle(
                                                              color: colors.error, fontWeight: FontWeight.bold, fontSize: 11),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                      ),
                                    );
                                  },
                                ),
            ),
          ),
        ],
      ),
    ),
  );
}
}
