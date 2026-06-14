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

class OverviewTab extends StatefulWidget {
  const OverviewTab({super.key});

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> {
  int? _selectedBarIndex;

  bool get _isAdmin {
    final designation = currentProfile.value.designation;
    return designation == 'Treasurer' ||
        designation == 'President' ||
        designation == 'Vice President';
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

  void _showAddExpenseDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: context.read<AccountingBloc>(),
          child: const AddExpenseDialog(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final state = context.watch<AccountingBloc>().state;
    final hasData = state is AccountingDataLoaded;
    final summary = hasData ? state.summary : null;

    final totalCol = summary?.totalCollection ?? 0.0;
    final totalExp = summary?.totalExpenses ?? 0.0;
    final balance = summary?.currentBalance ?? 0.0;

    return RefreshIndicator(
      onRefresh: () async {
        context.read<AccountingBloc>().add(FetchAccountingDataRequested());
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Visual Premium Cards
            _buildSummaryCards(totalCol, totalExp, balance, colors),
            const SizedBox(height: 16),
  
            // Funds Composition Ratio Bar
            _buildRatioComposition(totalCol, totalExp, colors),
            const SizedBox(height: 16),
  
            // Cash Flow Trend Chart
            if (hasData) ...[
              _buildTrendChart(summary, colors),
              const SizedBox(height: 20),
            ],
  
            // Overview Action buttons (Admins only)
            if (_isAdmin) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showAddPaymentDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Fee Payment'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: colors.primaryContainer,
                        foregroundColor: colors.onPrimaryContainer,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showAddExpenseDialog(context),
                      icon: const Icon(Icons.remove),
                      label: const Text('Log Expense'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: colors.errorContainer,
                        foregroundColor: colors.onErrorContainer,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
  
            // Recent Activity Ledger
            if (currentProfile.value.role == UserRole.committeeMember ||
                currentProfile.value.role == UserRole.superUser) ...[
              Text(
                'Recent Ledger Activity',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.onSurface),
              ),
              const SizedBox(height: 12),
  
              _buildRecentActivityList(summary, colors),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(double collection, double expenses, double balance, ColorScheme colors) {
    return Column(
      children: [
        // Balance Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colors.primary, colors.primary.withValues(alpha: 0.6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Current Net Balance',
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '৳ ${balance.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Icon(Icons.shield_outlined, color: Colors.white70, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Vault Protected Ledger',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Collection vs Expenses Row
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _emerald.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.arrow_downward, color: _emerald, size: 16),
                        SizedBox(width: 6),
                        Text('Total Collections', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '৳ ${collection.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _emerald),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.error.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.arrow_upward, color: colors.error, size: 16),
                        const SizedBox(width: 6),
                        const Text('Total Expenses', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '৳ ${expenses.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.error),
                    ),
                  ],
                ),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildRatioComposition(double collection, double expenses, ColorScheme colors) {
    final total = collection + expenses;
    final colPercent = total > 0 ? (collection / total) : 0.5;
    final expPercent = total > 0 ? (expenses / total) : 0.5;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.onSurface.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Funds Composition',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colors.onSurface),
              ),
              Text(
                '${(colPercent * 100).toStringAsFixed(0)}% vs ${(expPercent * 100).toStringAsFixed(0)}%',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: colors.primary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 16,
              child: Row(
                children: [
                  Expanded(
                    flex: (colPercent * 100).round().clamp(1, 99),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF059669), _emerald],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: (expPercent * 100).round().clamp(1, 99),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [colors.error, colors.errorContainer],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(width: 10, height: 10, decoration: const BoxDecoration(color: _emerald, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  const Text('Collections', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
              Row(
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: colors.error, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  const Text('Expenses', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart(AccountingSummary? summary, ColorScheme colors) {
    if (summary == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final List<DateTime> months = List.generate(5, (i) => DateTime(now.year, now.month - (4 - i), 1));
    
    double maxVal = 1000.0; // Fallback min ceiling
    final List<Map<String, dynamic>> chartData = [];

    for (var month in months) {
      double collection = 0.0;
      for (var p in summary.recentPayments) {
        if (p.paymentDate.year == month.year && p.paymentDate.month == month.month) {
          collection += p.amount;
        }
      }

      double expense = 0.0;
      for (var e in summary.recentExpenses) {
        if (e.expenseDate.year == month.year && e.expenseDate.month == month.month) {
          expense += e.amount;
        }
      }

      if (collection > maxVal) maxVal = collection;
      if (expense > maxVal) maxVal = expense;

      chartData.add({
        'month': DateFormat('MMM').format(month),
        'collection': collection,
        'expense': expense,
      });
    }

    // Boost maxVal slightly for aesthetic padding
    maxVal *= 1.15;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.onSurface.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cash Flow Trend (Last 5 Months)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colors.onSurface),
              ),
              if (_selectedBarIndex != null)
                Text(
                  'Tap to hide detail',
                  style: TextStyle(fontSize: 10, color: colors.primary.withValues(alpha: 0.6)),
                )
              else
                const Text(
                  'Tap bars for details',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
            ],
          ),
          const SizedBox(height: 18),
          
          // Render the selected month's tooltip details
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: _selectedBarIndex == null
                ? const SizedBox.shrink()
                : Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${chartData[_selectedBarIndex!]['month']} Breakdown:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: colors.primary),
                        ),
                        Text(
                          'Col: ৳${chartData[_selectedBarIndex!]['collection'].toStringAsFixed(0)}  |  Exp: ৳${chartData[_selectedBarIndex!]['expense'].toStringAsFixed(0)}',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: colors.onSurface),
                        ),
                      ],
                    ),
                  ),
          ),

          // Core chart canvas
          SizedBox(
            height: 180,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(chartData.length, (index) {
                final data = chartData[index];
                final colHeight = (data['collection'] / maxVal) * 140;
                final expHeight = (data['expense'] / maxVal) * 140;
                final isSelected = _selectedBarIndex == index;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_selectedBarIndex == index) {
                        _selectedBarIndex = null;
                      } else {
                        _selectedBarIndex = index;
                      }
                    });
                  },
                  child: Container(
                    color: Colors.transparent, // Expand tap target
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Collections Bar
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeOutBack,
                              width: 14,
                              height: colHeight.clamp(4.0, 140.0),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isSelected
                                      ? [const Color(0xFF047857), _emerald]
                                      : [_emerald.withValues(alpha: 0.7), _emerald],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: _emerald.withValues(alpha: 0.4),
                                          blurRadius: 6,
                                          offset: const Offset(0, -2),
                                        )
                                      ]
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Expenses Bar
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeOutBack,
                              width: 14,
                              height: expHeight.clamp(4.0, 140.0),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isSelected
                                      ? [colors.error, colors.errorContainer]
                                      : [colors.error.withValues(alpha: 0.7), colors.errorContainer.withValues(alpha: 0.8)],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: colors.error.withValues(alpha: 0.4),
                                          blurRadius: 6,
                                          offset: const Offset(0, -2),
                                        )
                                      ]
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          data['month'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? colors.primary : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityList(AccountingSummary? summary, ColorScheme colors) {
    if (summary == null) return const Center(child: CircularProgressIndicator());

    // Mix payments and expenses together
    final List<dynamic> combined = [];
    combined.addAll(summary.recentPayments);
    combined.addAll(summary.recentExpenses);

    // Sort by date descending
    combined.sort((a, b) {
      final DateTime dateA = a is FeePayment ? a.paymentDate : (a as ClubExpense).expenseDate;
      final DateTime dateB = b is FeePayment ? b.paymentDate : (b as ClubExpense).expenseDate;
      return dateB.compareTo(dateA);
    });

    final displayList = combined.take(15).toList();

    if (displayList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(Icons.receipt_long, size: 48, color: colors.onSurface.withValues(alpha: 0.2)),
              const SizedBox(height: 12),
              const Text('No recent activities logged.', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayList.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = displayList[index];
        final isPayment = item is FeePayment;

        if (isPayment) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: _emerald.withValues(alpha: 0.1),
              child: const Icon(Icons.arrow_downward, color: _emerald, size: 18),
            ),
            title: Text(
              item.memberName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(
              'Fee • ${item.month} • ${DateFormat('d MMM, h:mm a').format(item.paymentDate)}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            trailing: Text(
              '+ ৳ ${item.amount.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: _emerald, fontSize: 14),
            ),
          );
        } else {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: colors.error.withValues(alpha: 0.1),
              child: Icon(Icons.arrow_upward, color: colors.error, size: 18),
            ),
            title: Text(
              item.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(
              'Expense • ${item.category} • ${DateFormat('d MMM, h:mm a').format(item.expenseDate)}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            trailing: Text(
              '- ৳ ${item.amount.toStringAsFixed(0)}',
              style: TextStyle(fontWeight: FontWeight.bold, color: colors.error, fontSize: 14),
            ),
          );
        }
      },
    );
  }
}
