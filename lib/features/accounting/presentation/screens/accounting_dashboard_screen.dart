import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../backend/services/accounting_service.dart';
import '../bloc/accounting_bloc.dart';
import '../bloc/accounting_event.dart';
import '../bloc/accounting_state.dart';
import '../widgets/payment_dialogs.dart';
import '../../../profile/models/profile_state.dart';

const Color _emerald = Color(0xFF10B981);

class AccountingDashboardScreen extends StatefulWidget {
  const AccountingDashboardScreen({super.key});

  @override
  State<AccountingDashboardScreen> createState() => _AccountingDashboardScreenState();
}

class _AccountingDashboardScreenState extends State<AccountingDashboardScreen> {
  late DateTime _selectedDuesMonth;
  String _searchQuery = '';
  String _expenseFilter = 'all';
  int? _selectedBarIndex;

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
    _loadData();
  }

  void _loadData() {
    context.read<AccountingBloc>().add(FetchAccountingDataRequested());
    _loadDues();
  }

  void _loadDues() {
    final monthStr = DateFormat('yyyy-MM').format(_selectedDuesMonth);
    context.read<AccountingBloc>().add(FetchDuesStatusRequested(monthStr));
  }

  void _previousMonth() {
    setState(() {
      _selectedDuesMonth = DateTime(_selectedDuesMonth.year, _selectedDuesMonth.month - 1);
    });
    _loadDues();
  }

  void _nextMonth() {
    setState(() {
      _selectedDuesMonth = DateTime(_selectedDuesMonth.year, _selectedDuesMonth.month + 1);
    });
    _loadDues();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tabLabelColor = isDark ? colors.primary : Colors.white;
    final tabUnselectedColor = isDark ? colors.onSurface.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.7);
    final tabIndicatorColor = isDark ? colors.primary : Colors.white;

    return BlocListener<AccountingBloc, AccountingState>(
      listener: (context, state) {
        if (state is AccountingActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(state.message),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          _loadData(); // Auto reload statistics and dues
        } else if (state is AccountingError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text(state.errorMessage)),
                ],
              ),
              backgroundColor: colors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Club Accounts'),
            bottom: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: tabLabelColor,
              unselectedLabelColor: tabUnselectedColor,
              indicatorColor: tabIndicatorColor,
              indicatorWeight: 3,
              physics: const BouncingScrollPhysics(),
              tabs: const [
                Tab(icon: Icon(Icons.dashboard_outlined), text: 'Overview'),
                Tab(icon: Icon(Icons.payments_outlined), text: 'Fee Tracker'),
                Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Expense Logger'),
                Tab(icon: Icon(Icons.assignment_ind_outlined), text: 'Dues Tracker'),
              ],
            ),
          ),
          body: BlocBuilder<AccountingBloc, AccountingState>(
            buildWhen: (previous, current) =>
                current is AccountingLoading ||
                current is AccountingDataLoaded ||
                current is AccountingDuesLoaded ||
                current is AccountingError,
            builder: (context, state) {
              if (state is AccountingLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              
              return TabBarView(
                physics: const BouncingScrollPhysics(),
                children: [
                  // 1. Overview Tab
                  _buildOverviewTab(colors),

                  // 2. Fee Tracker Tab
                  _buildFeeTrackerTab(colors),

                  // 3. Expense Logger Tab
                  _buildExpenseLoggerTab(colors),

                  // 4. Dues Tracker Tab
                  _buildDuesTrackerTab(colors),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // --- TAB 1: OVERVIEW ---
  Widget _buildOverviewTab(ColorScheme colors) {
    final state = context.watch<AccountingBloc>().state;
    final hasData = state is AccountingDataLoaded;
    final summary = hasData ? state.summary : null;

    final totalCol = summary?.totalCollection ?? 0.0;
    final totalExp = summary?.totalExpenses ?? 0.0;
    final balance = summary?.currentBalance ?? 0.0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
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
          Text(
            'Recent Ledger Activity',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.onSurface),
          ),
          const SizedBox(height: 12),

          _buildRecentActivityList(summary, colors),
        ],
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

  // --- TAB 2: FEE TRACKER ---
  Widget _buildFeeTrackerTab(ColorScheme colors) {
    final state = context.watch<AccountingBloc>().state;
    final hasData = state is AccountingDataLoaded;
    final payments = hasData ? state.summary.recentPayments : <FeePayment>[];

    final filtered = payments.where((p) {
      if (_searchQuery.isEmpty) return true;
      final term = _searchQuery.toLowerCase();
      return p.memberName.toLowerCase().contains(term) ||
          (p.memberIdRoll != null && p.memberIdRoll!.toLowerCase().contains(term)) ||
          p.month.contains(term);
    }).toList();

    return Scaffold(
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
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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

  // --- TAB 3: EXPENSE LOGGER ---
  Widget _buildExpenseLoggerTab(ColorScheme colors) {
    final state = context.watch<AccountingBloc>().state;
    final hasData = state is AccountingDataLoaded;
    final expenses = hasData ? state.summary.recentExpenses : <ClubExpense>[];

    final filtered = expenses.where((e) {
      if (_expenseFilter == 'all') return true;
      return e.category == _expenseFilter;
    }).toList();

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                const Text('Filter by:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(width: 12),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _filterChip('all', 'All Expenses', colors),
                        const SizedBox(width: 8),
                        _filterChip('monthly', 'Monthly', colors),
                        const SizedBox(width: 8),
                        _filterChip('event', 'Events', colors),
                        const SizedBox(width: 8),
                        _filterChip('yearly', 'Yearly', colors),
                        const SizedBox(width: 8),
                        _filterChip('others', 'Others', colors),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 48, color: colors.onSurface.withValues(alpha: 0.2)),
                        const SizedBox(height: 12),
                        const Text('No matching expenses logged.', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemBuilder: (context, index) {
                      final exp = filtered[index];
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                        color: colors.surfaceContainerLowest,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  exp.description,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text('- ৳ ${exp.amount.toStringAsFixed(0)}',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: colors.error, fontSize: 14)),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: colors.error.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      exp.category.toUpperCase(),
                                      style: TextStyle(fontSize: 9, color: colors.error, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  if (exp.eventName != null) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: colors.onSurface.withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        exp.eventName!,
                                        style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                  const Spacer(),
                                  Text(
                                    DateFormat('d MMM yyyy, h:mm a').format(exp.expenseDate),
                                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Logged by: ${exp.recordedByName}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                  if (exp.remarks != null && exp.remarks!.isNotEmpty)
                                    Text('Note: ${exp.remarks}', style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _showAddExpenseDialog(context),
              label: const Text('Log Expense'),
              icon: const Icon(Icons.remove),
              backgroundColor: colors.error,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _filterChip(String filterVal, String label, ColorScheme colors) {
    final isSelected = _expenseFilter == filterVal;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _expenseFilter = filterVal);
        }
      },
      selectedColor: colors.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected ? colors.primary : colors.onSurface.withValues(alpha: 0.7),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  // --- TAB 4: DUES TRACKER ---
  Widget _buildDuesTrackerTab(ColorScheme colors) {
    final state = context.watch<AccountingBloc>().state;
    final hasDues = state is AccountingDuesLoaded;
    final duesList = hasDues ? state.dues : <MemberDuesStatus>[];

    // Stats calculations
    final paidCount = duesList.where((d) => d.isPaid).length;
    final unpaidCount = duesList.length - paidCount;

    return Scaffold(
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
            child: !hasDues
                ? const Center(child: CircularProgressIndicator())
                : duesList.isEmpty
                    ? const Center(child: Text('No club members found.'))
                    : ListView.builder(
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
        ],
      ),
    );
  }

  // --- ACTIONS ---
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

  // --- CUSTOM GRAPHICAL GRAPH & CHARTS ---

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
}
