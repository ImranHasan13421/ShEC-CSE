import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/accounting_bloc.dart';
import '../bloc/accounting_event.dart';
import '../bloc/accounting_state.dart';
import '../widgets/overview_tab.dart';
import '../widgets/fee_tracker_tab.dart';
import '../widgets/expense_logger_tab.dart';
import '../widgets/dues_tracker_tab.dart';
import 'package:ShEC_CSE/features/dashboard/presentation/widgets/ambient_background.dart';
import 'package:ShEC_CSE/core/services/tour_service.dart';
import 'package:ShEC_CSE/features/dashboard/presentation/widgets/guided_tour_overlay.dart';

class AccountingDashboardScreen extends StatefulWidget {
  const AccountingDashboardScreen({super.key});

  @override
  State<AccountingDashboardScreen> createState() => _AccountingDashboardScreenState();
}

class _AccountingDashboardScreenState extends State<AccountingDashboardScreen> {
  final GlobalKey _tabBarKey = GlobalKey();
  bool _showTour = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    TourService.instance.hasCompletedScreenTour('accounting').then((completed) {
      if (!completed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(milliseconds: 1000), () {
            if (mounted) {
              setState(() {
                _showTour = true;
              });
            }
          });
        });
      }
    });
  }

  void _loadData() {
    context.read<AccountingBloc>().add(FetchAccountingDataRequested());
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tabLabelColor = isDark ? colors.primary : Colors.white;
    final tabUnselectedColor = isDark ? colors.onSurface.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.7);
    final tabIndicatorColor = isDark ? colors.primary : Colors.white;

    return Stack(
      children: [
        BlocListener<AccountingBloc, AccountingState>(
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
            child: AmbientTimeBackground(
              child: Scaffold(
                backgroundColor: Colors.transparent,
                appBar: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  title: const Text('Club Accounts'),
                  bottom: TabBar(
                    key: _tabBarKey,
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
                  buildWhen: (previous, current) {
                    if (current is AccountingLoading) {
                      return previous is AccountingInitial;
                    }
                    return current is AccountingDataLoaded || current is AccountingError;
                  },
                  builder: (context, state) {
                    if (state is AccountingLoading || state is AccountingInitial) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    return const TabBarView(
                      physics: BouncingScrollPhysics(),
                      children: [
                        OverviewTab(),
                        FeeTrackerTab(),
                        ExpenseLoggerTab(),
                        DuesTrackerTab(),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        if (_showTour)
          GuidedTourOverlay(
            steps: [
              TourStep(
                targetKey: _tabBarKey,
                title: 'Club Treasury & Accounts',
                description: 'Manage and review club financial records. Tapping different tabs switches between the general Dashboard Overview, Student Fee Tracking, Expense Logging, and Outstanding Dues tracking.',
              ),
            ],
            onComplete: () {
              setState(() => _showTour = false);
              TourService.instance.completeScreenTour('accounting');
            },
            onSkip: () {
              setState(() => _showTour = false);
              TourService.instance.completeScreenTour('accounting');
            },
          ),
      ],
    );
  }
}
