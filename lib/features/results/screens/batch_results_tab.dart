import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../profile/models/profile_state.dart';
import '../models/result_state.dart';
import '../models/batch_member_result.dart';
import '../../../backend/services/result_service.dart';
import '../presentation/bloc/result_bloc.dart';
import '../presentation/bloc/result_event.dart';
import '../presentation/bloc/result_state.dart';
import 'cgpa_prediction_chart.dart';
import 'batch_overview_chart.dart';

// ──────────────────────────────────────────────────────────────
//  Enums & helpers
// ──────────────────────────────────────────────────────────────

enum _SortOrder { classRoll, cgpaDesc, nameAsc }

class _ActiveFilterChip {
  final String label;
  final VoidCallback onRemove;
  _ActiveFilterChip(this.label, this.onRemove);
}

/// Pre-computed student summary used across the accordion and analytics.
class _StudentSummary {
  final String id;
  final ProfileData profile;
  final double latestCgpa;
  final int semCount;
  final bool hasFailedSubject;
  _StudentSummary({
    required this.id,
    required this.profile,
    required this.latestCgpa,
    required this.semCount,
    required this.hasFailedSubject,
  });
}

// ══════════════════════════════════════════════════════════════
//  BatchResultsTab
// ══════════════════════════════════════════════════════════════

class BatchResultsTab extends StatefulWidget {
  const BatchResultsTab({super.key});

  @override
  State<BatchResultsTab> createState() => _BatchResultsTabState();
}

class _BatchResultsTabState extends State<BatchResultsTab> {
  // ── Filter state ──────────────────────────────────────────
  String _selectedSession = '';
  String _studentSearchQuery = '';
  String _selectedSemester = 'All';
  String _subjectSearchQuery = '';
  String _selectedGpaRange = 'All';
  bool _showOnlyBacklogs = false;
  _SortOrder _sortOrder = _SortOrder.classRoll;

  final TextEditingController _studentSearchController = TextEditingController();
  final TextEditingController _subjectSearchController = TextEditingController();

  // ── Accordion state ───────────────────────────────────────
  String? _expandedStudentId;

  List<String> _availableSessions = [];

  bool get _hasActiveFilters =>
      _selectedSemester != 'All' ||
      _subjectSearchQuery.isNotEmpty ||
      _selectedGpaRange != 'All' ||
      _showOnlyBacklogs ||
      _sortOrder != _SortOrder.classRoll;

  @override
  void initState() {
    super.initState();
    _selectedSession = currentProfile.value.session;
    _loadAvailableSessions();
    _fetchBatchResults();
  }

  @override
  void dispose() {
    _studentSearchController.dispose();
    _subjectSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableSessions() async {
    final sessions = await ResultService.fetchSessions();
    if (!mounted) return;
    setState(() {
      _availableSessions = sessions;
      if (_selectedSession.isNotEmpty && !_availableSessions.contains(_selectedSession)) {
        _availableSessions.add(_selectedSession);
      }
      _availableSessions.sort((a, b) => b.compareTo(a));
    });
  }

  void _fetchBatchResults() {
    if (_selectedSession.isNotEmpty) {
      context.read<ResultBloc>().add(LoadBatchResultsRequested(session: _selectedSession));
    }
  }

  void _clearAllFilters() {
    setState(() {
      _subjectSearchController.clear();
      _subjectSearchQuery = '';
      _selectedSemester = 'All';
      _selectedGpaRange = 'All';
      _showOnlyBacklogs = false;
      _sortOrder = _SortOrder.classRoll;
    });
  }

  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final profile = currentProfile.value;
    final isCommittee = profile.role == UserRole.committeeMember || profile.role == UserRole.superUser;
    final mySession = profile.session;

    return BlocBuilder<ResultBloc, ResultState>(
      builder: (context, state) {
        // ── Loading ──
        if (state.isBatchLoading && state.batchResults.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        // ── Error ──
        if (state.errorMessage != null && state.batchResults.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.errorMessage!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _fetchBatchResults, child: const Text('Try Again')),
                ],
              ),
            ),
          );
        }

        if (state.batchResults.isNotEmpty || (!state.isBatchLoading && _selectedSession.isNotEmpty)) {
          // Available semesters list
          final List<String> availableSemesters = ['All'];
          for (var r in state.batchResults) {
            if (!availableSemesters.contains(r.result.examName)) {
              availableSemesters.add(r.result.examName);
            }
          }

          // Access control
          final effectiveSession = isCommittee ? state.selectedSession : mySession;

          // Step 1 – base filter
          final basicFiltered = state.batchResults.where((item) {
            if (item.profile.session != effectiveSession) return false;
            final sq = _studentSearchQuery.toLowerCase();
            if (sq.isNotEmpty) {
              final match =
                  item.profile.name.toLowerCase().contains(sq) ||
                  item.profile.classRoll.toLowerCase().contains(sq) ||
                  item.profile.universityId.toLowerCase().contains(sq) ||
                  item.profile.duRegNo.toLowerCase().contains(sq);
              if (!match) return false;
            }
            if (_selectedSemester != 'All' && item.result.examName != _selectedSemester) return false;
            if (_subjectSearchQuery.isNotEmpty) {
              final subQ = _subjectSearchQuery.toLowerCase();
              final match = item.result.subjects.any(
                (s) => s.code.toLowerCase().contains(subQ) || s.name.toLowerCase().contains(subQ),
              );
              if (!match) return false;
            }
            return true;
          }).toList();

          // Step 2 – group by student
          final Map<String, List<BatchMemberResult>> grouped = {};
          for (var item in basicFiltered) {
            grouped.putIfAbsent(item.profile.id, () => []).add(item);
          }

          // Pre-compute student summaries for all grouped students
          final Map<String, _StudentSummary> summaries = {};
          for (var id in grouped.keys) {
            final items = grouped[id]!;
            summaries[id] = _StudentSummary(
              id: id,
              profile: items.first.profile,
              latestCgpa: _getLatestStudentCgpa(id, state.batchResults),
              semCount: items.map((i) => i.result.examName).toSet().length,
              hasFailedSubject: items.any(
                (i) => i.result.subjects.any((s) => s.grade.trim().toUpperCase() == 'F'),
              ),
            );
          }

          // Step 3 – Apply GPA range and Backlog filters
          var studentIds = grouped.keys.toList();

          if (_showOnlyBacklogs) {
            studentIds = studentIds.where((id) => summaries[id]?.hasFailedSubject ?? false).toList();
          }

          if (_selectedGpaRange != 'All') {
            studentIds = studentIds.where((id) {
              final c = summaries[id]?.latestCgpa ?? 0.0;
              switch (_selectedGpaRange) {
                case '< 2.0':   return c > 0 && c < 2.0;
                case '2.0–2.5': return c >= 2.0 && c < 2.5;
                case '2.5–3.0': return c >= 2.5 && c < 3.0;
                case '3.0–3.5': return c >= 3.0 && c < 3.5;
                case '3.5–3.75': return c >= 3.5 && c < 3.75;
                case '3.75+':    return c >= 3.75;
                default:        return true;
              }
            }).toList();
          }

          // Step 4 – sort
          switch (_sortOrder) {
            case _SortOrder.classRoll:
              studentIds.sort((a, b) {
                final pa = summaries[a]!.profile;
                final pb = summaries[b]!.profile;
                final ra = int.tryParse(pa.classRoll.replaceAll(RegExp(r'\D'), '')) ?? 999999;
                final rb = int.tryParse(pb.classRoll.replaceAll(RegExp(r'\D'), '')) ?? 999999;
                return ra != rb ? ra.compareTo(rb) : pa.name.compareTo(pb.name);
              });
            case _SortOrder.cgpaDesc:
              studentIds.sort((a, b) =>
                  summaries[b]!.latestCgpa.compareTo(summaries[a]!.latestCgpa));
            case _SortOrder.nameAsc:
              studentIds.sort((a, b) =>
                  summaries[a]!.profile.name.compareTo(summaries[b]!.profile.name));
          }

          // Session-level results (for charts – not affected by non-session filters)
          final sessionResults = state.batchResults
              .where((r) => r.profile.session == effectiveSession)
              .toList();
          final totalInSession = sessionResults.map((r) => r.profile.id).toSet().length;

          final activeFilterCount = [
            _studentSearchQuery.isNotEmpty,
            _selectedSemester != 'All',
            _subjectSearchQuery.isNotEmpty,
            _selectedGpaRange != 'All',
            _showOnlyBacklogs,
            _sortOrder != _SortOrder.classRoll,
          ].where((b) => b).length;

          return Stack(
            children: [
              Column(
                children: [
                  // ── Search bar + action buttons ──
                  _buildSearchBar(
                    context, colors, isCommittee,
                    state, availableSemesters,
                    sessionResults, basicFiltered,
                    activeFilterCount,
                  ),

                  // ── Active filter chips ──
                  if (_hasActiveFilters) _buildActiveFiltersRow(colors),

                  // ── Info bar ──
                  _buildInfoBar(studentIds.length, totalInSession, colors),

                  // ── Student list ──
                  Expanded(
                    child: studentIds.isEmpty
                        ? _buildEmptyState(colors)
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 14).copyWith(bottom: 20),
                            itemCount: studentIds.length,
                            itemBuilder: (context, index) {
                              final id = studentIds[index];
                              final rank = _sortOrder == _SortOrder.cgpaDesc ? index + 1 : null;
                              return _StudentAccordionWidget(
                                studentItems: grouped[id]!,
                                allResults: state.batchResults,
                                summary: summaries[id]!,
                                rank: rank,
                                colors: colors,
                                subjectSearchQuery: _subjectSearchQuery,
                                isExpanded: id == _expandedStudentId,
                                onExpansionChanged: (expanded) {
                                  setState(() {
                                    if (expanded) {
                                      _expandedStudentId = id;
                                    } else if (_expandedStudentId == id) {
                                      _expandedStudentId = null;
                                    }
                                  });
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
              if (state.isBatchLoading)
                const Positioned(top: 0, left: 0, right: 0, child: LinearProgressIndicator()),
            ],
          );
        }

        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.group_outlined, size: 56, color: colors.onSurface.withValues(alpha: 0.2)),
              const SizedBox(height: 16),
              const Text('No results loaded yet.', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _fetchBatchResults,
                icon: const Icon(Icons.refresh),
                label: const Text('Load Results'),
              ),
            ],
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════
  //  SEARCH BAR  +  FILTER / ANALYTICS BUTTONS
  // ══════════════════════════════════════════════════════════

  Widget _buildSearchBar(
    BuildContext context,
    ColorScheme colors,
    bool isCommittee,
    ResultState state,
    List<String> availableSemesters,
    List<BatchMemberResult> sessionResults,
    List<BatchMemberResult> basicFiltered,
    int activeFilterCount,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Row(
        children: [
          // Search text field
          Expanded(
            child: TextField(
              controller: _studentSearchController,
              decoration: InputDecoration(
                hintText: 'Search by name, roll, reg no...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _studentSearchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setState(() {
                          _studentSearchController.clear();
                          _studentSearchQuery = '';
                        }),
                      )
                    : null,
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: colors.surfaceContainerLow,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (val) => setState(() => _studentSearchQuery = val),
            ),
          ),
          const SizedBox(width: 8),

          // Filter button (with badge counter)
          _BadgedIconButton(
            count: activeFilterCount,
            icon: Icons.tune_rounded,
            tooltip: 'Filters',
            backgroundColor: activeFilterCount > 0
                ? colors.primary.withValues(alpha: 0.14)
                : colors.surfaceContainerHigh,
            iconColor: activeFilterCount > 0 ? colors.primary : colors.onSurface.withValues(alpha: 0.7),
            onPressed: () => _openFilterSheet(
              context, colors, isCommittee, state, availableSemesters,
            ),
          ),

          // Analytics button
          _BadgedIconButton(
            count: 0,
            icon: Icons.bar_chart_rounded,
            tooltip: 'Batch Analytics',
            backgroundColor: colors.secondaryContainer,
            iconColor: colors.onSecondaryContainer,
            onPressed: () => _openAnalyticsSheet(context, colors, sessionResults, basicFiltered),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBar(int filteredCount, int totalCount, ColorScheme colors) {
    final sortLabel = switch (_sortOrder) {
      _SortOrder.classRoll => 'Roll ↑',
      _SortOrder.cgpaDesc  => 'CGPA ↓',
      _SortOrder.nameAsc   => 'A–Z',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        children: [
          Icon(Icons.people_outline, size: 13, color: colors.onSurface.withValues(alpha: 0.45)),
          const SizedBox(width: 5),
          Text(
            filteredCount == totalCount
                ? '$totalCount students'
                : '$filteredCount / $totalCount students',
            style: TextStyle(fontSize: 12, color: colors.onSurface.withValues(alpha: 0.5)),
          ),
          const Spacer(),
          _infoPill(sortLabel, Icons.sort_rounded, colors.primary, colors),
          const SizedBox(width: 6),
          _infoPill(_selectedSession, Icons.class_outlined, colors.secondary, colors),
        ],
      ),
    );
  }

  Widget _infoPill(String text, IconData icon, Color color, ColorScheme colors) {
    if (text.isEmpty) return const SizedBox.shrink();
    final displayText = text.length > 14 ? '${text.substring(0, 12)}…' : text;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(displayText, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildActiveFiltersRow(ColorScheme colors) {
    final chips = <_ActiveFilterChip>[];
    if (_selectedSemester != 'All') {
      final short = _selectedSemester.length > 20 ? '${_selectedSemester.substring(0, 18)}…' : _selectedSemester;
      chips.add(_ActiveFilterChip('📚 $short', () => setState(() => _selectedSemester = 'All')));
    }
    if (_subjectSearchQuery.isNotEmpty) {
      chips.add(_ActiveFilterChip('📖 $_subjectSearchQuery', () {
        setState(() { _subjectSearchController.clear(); _subjectSearchQuery = ''; });
      }));
    }
    if (_selectedGpaRange != 'All') {
      chips.add(_ActiveFilterChip('⭐ $_selectedGpaRange', () => setState(() => _selectedGpaRange = 'All')));
    }
    if (_showOnlyBacklogs) {
      chips.add(_ActiveFilterChip('⚠️ Backlogs Only', () => setState(() => _showOnlyBacklogs = false)));
    }
    if (_sortOrder != _SortOrder.classRoll) {
      final label = _sortOrder == _SortOrder.cgpaDesc ? 'Sort: CGPA↓' : 'Sort: A→Z';
      chips.add(_ActiveFilterChip(label, () => setState(() => _sortOrder = _SortOrder.classRoll)));
    }
    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ...chips.map((chip) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Chip(
                label: Text(chip.label, style: const TextStyle(fontSize: 11)),
                deleteIcon: const Icon(Icons.close_rounded, size: 13),
                onDeleted: chip.onRemove,
                backgroundColor: colors.primary.withValues(alpha: 0.08),
                deleteIconColor: colors.primary,
                side: BorderSide(color: colors.primary.withValues(alpha: 0.2)),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            )),
            TextButton(
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6), minimumSize: Size.zero),
              onPressed: _clearAllFilters,
              child: const Text('Clear all', style: TextStyle(fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  FILTER BOTTOM SHEET
  // ══════════════════════════════════════════════════════════

  void _openFilterSheet(
    BuildContext context,
    ColorScheme colors,
    bool isCommittee,
    ResultState state,
    List<String> availableSemesters,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          // applyFilter keeps parent list and sheet UI in sync
          void applyFilter(VoidCallback fn) {
            setState(fn);
            setSheetState(() {});
          }

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: DraggableScrollableSheet(
              initialChildSize: 0.72,
              minChildSize: 0.4,
              maxChildSize: 0.93,
              expand: false,
              builder: (_, ctrl) => ListView(
                controller: ctrl,
                padding: const EdgeInsets.symmetric(horizontal: 22),
                children: [
                  const SizedBox(height: 12),
                  // Handle
                  Center(child: Container(width: 40, height: 4,
                    decoration: BoxDecoration(color: colors.outline.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 14),

                  // Title row
                  Row(children: [
                    Icon(Icons.tune_rounded, color: colors.primary, size: 22),
                    const SizedBox(width: 8),
                    Text('Filter & Search', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.primary)),
                    const Spacer(),
                    TextButton(
                      onPressed: () => applyFilter(() {
                        _studentSearchController.clear();
                        _subjectSearchController.clear();
                        _studentSearchQuery = '';
                        _selectedSemester = 'All';
                        _subjectSearchQuery = '';
                        _selectedGpaRange = 'All';
                        _showOnlyBacklogs = false;
                        _sortOrder = _SortOrder.classRoll;
                      }),
                      child: const Text('Reset All'),
                    ),
                  ]),
                  const Divider(height: 20),

                  // ── Session (committee only) ──
                  if (isCommittee) ...[
                    _sheetLabel('Session', Icons.class_outlined, colors),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _selectedSession,
                      decoration: const InputDecoration(border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                      items: _availableSessions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (val) {
                        if (val == null) return;
                        applyFilter(() {
                          _selectedSession = val;
                          _selectedSemester = 'All';
                          _studentSearchController.clear();
                          _subjectSearchController.clear();
                          _studentSearchQuery = '';
                          _subjectSearchQuery = '';
                          _selectedGpaRange = 'All';
                          _sortOrder = _SortOrder.classRoll;
                        });
                        _fetchBatchResults();
                      },
                    ),
                    const SizedBox(height: 18),
                  ],

                  // ── Semester ──
                  _sheetLabel('Semester', Icons.book_outlined, colors),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _selectedSemester,
                    decoration: const InputDecoration(border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                    items: availableSemesters
                        .map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (val) { if (val != null) applyFilter(() => _selectedSemester = val); },
                  ),
                  const SizedBox(height: 18),

                  // ── Subject search ──
                  _sheetLabel('Filter by Subject', Icons.science_outlined, colors),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _subjectSearchController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, size: 20),
                      hintText: 'Subject code or name...',
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      suffixIcon: _subjectSearchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () => applyFilter(() { _subjectSearchController.clear(); _subjectSearchQuery = ''; }),
                            )
                          : null,
                    ),
                    onChanged: (val) => applyFilter(() => _subjectSearchQuery = val),
                  ),
                  const SizedBox(height: 18),

                  // ── CGPA Range ──
                  _sheetLabel('CGPA Range', Icons.star_half_rounded, colors),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['All', '< 2.0', '2.0–2.5', '2.5–3.0', '3.0–3.5', '3.5–3.75', '3.75+'].map((range) {
                      final sel = _selectedGpaRange == range;
                      return ChoiceChip(
                        label: Text(range),
                        selected: sel,
                        onSelected: (_) => applyFilter(() => _selectedGpaRange = range),
                        selectedColor: colors.primary.withValues(alpha: 0.15),
                        side: BorderSide(color: sel ? colors.primary : colors.outline.withValues(alpha: 0.35)),
                        labelStyle: TextStyle(
                          fontSize: 13,
                          color: sel ? colors.primary : null,
                          fontWeight: sel ? FontWeight.bold : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

                  // ── Backlogs Only ──
                  _sheetLabel('Backlogs / F-Grades', Icons.warning_amber_rounded, colors),
                  const SizedBox(height: 4),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Show Only Students with F-Grades', style: TextStyle(fontSize: 13)),
                    subtitle: Text('Filters batch to students who failed one or more courses', style: TextStyle(fontSize: 11, color: colors.onSurface.withValues(alpha: 0.5))),
                    value: _showOnlyBacklogs,
                    activeColor: colors.primary,
                    onChanged: (val) {
                      applyFilter(() {
                        _showOnlyBacklogs = val;
                      });
                    },
                  ),
                  const SizedBox(height: 18),

                  // ── Sort Order ──
                  _sheetLabel('Sort Order', Icons.sort_rounded, colors),
                  const SizedBox(height: 4),
                  _buildSortRadioTile(
                    _SortOrder.classRoll, Icons.format_list_numbered,
                    'By Class Roll (default)', colors,
                    (v) => applyFilter(() => _sortOrder = v),
                  ),
                  _buildSortRadioTile(
                    _SortOrder.cgpaDesc, Icons.trending_down,
                    'By CGPA — Highest First', colors,
                    (v) => applyFilter(() => _sortOrder = v),
                  ),
                  _buildSortRadioTile(
                    _SortOrder.nameAsc, Icons.sort_by_alpha,
                    'By Name (A → Z)', colors,
                    (v) => applyFilter(() => _sortOrder = v),
                  ),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sheetLabel(String label, IconData icon, ColorScheme colors) {
    return Row(children: [
      Icon(icon, size: 16, color: colors.primary),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colors.onSurface.withValues(alpha: 0.75))),
    ]);
  }

  Widget _buildSortRadioTile(_SortOrder value, IconData icon, String label, ColorScheme colors, void Function(_SortOrder) onChanged) {
    final selected = _sortOrder == value;
    return RadioListTile<_SortOrder>(
      dense: true,
      contentPadding: EdgeInsets.zero,
      value: value,
      groupValue: _sortOrder,
      activeColor: colors.primary,
      onChanged: (v) { if (v != null) onChanged(v); },
      title: Row(children: [
        Icon(icon, size: 18, color: selected ? colors.primary : colors.onSurface.withValues(alpha: 0.55)),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(
          fontSize: 13,
          color: selected ? colors.primary : null,
          fontWeight: selected ? FontWeight.bold : null,
        )),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  ANALYTICS BOTTOM SHEET
  // ══════════════════════════════════════════════════════════

  void _openAnalyticsSheet(
    BuildContext context,
    ColorScheme colors,
    List<BatchMemberResult> sessionResults,
    List<BatchMemberResult> basicFiltered,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, ctrl) => ListView(
          controller: ctrl,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            const SizedBox(height: 12),
            Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: colors.outline.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),

            // Title
            Row(children: [
              Icon(Icons.analytics_outlined, color: colors.primary, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Batch Analytics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.primary)),
                  Text(_selectedSession, style: TextStyle(fontSize: 12, color: colors.onSurface.withValues(alpha: 0.5))),
                ]),
              ),
            ]),
            const SizedBox(height: 16),

            // Quick stats
            _buildAnalyticsQuickStats(sessionResults, colors),
            const SizedBox(height: 20),
            const Divider(),

            // CGPA Distribution
            const SizedBox(height: 16),
            _analyticsSection('CGPA Distribution', 'Students grouped by current cumulative GPA', Icons.bar_chart_rounded, colors),
            const SizedBox(height: 14),
            SizedBox(height: 218, child: BatchCgpaDistributionChart(results: sessionResults)),
            const SizedBox(height: 20),
            const Divider(),

            // GPA Trend
            const SizedBox(height: 16),
            _analyticsSection('Semester-Wise Avg GPA', 'Batch average GPA across all 8 semesters', Icons.show_chart_rounded, colors),
            const SizedBox(height: 14),
            SizedBox(height: 196, child: BatchGpaTrendChart(results: sessionResults)),
            const SizedBox(height: 20),

            // Semester overview if a semester is selected
            if (_selectedSemester != 'All') ...[
              const Divider(),
              const SizedBox(height: 16),
              _analyticsSection('Semester GPA Breakdown', _selectedSemester, Icons.school_outlined, colors),
              const SizedBox(height: 12),
              _buildSemesterGradeOverviewCard(basicFiltered, colors),
              const SizedBox(height: 12),
            ],

            // Difficult subjects
            const Divider(),
            const SizedBox(height: 16),
            _analyticsSection('Subject Challenge Index', 'Courses with highest failure or lowest average GPA', Icons.psychology_outlined, colors),
            const SizedBox(height: 12),
            _buildDifficultSubjectsCard(sessionResults, colors),

            // Top performers
            const Divider(),
            const SizedBox(height: 16),
            _analyticsSection('Top Performers', 'Top 5 students by cumulative CGPA', Icons.workspace_premium_outlined, colors),
            const SizedBox(height: 12),
            _buildTopPerformersCard(sessionResults, colors),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _analyticsSection(String title, String subtitle, IconData icon, ColorScheme colors) {
    return Row(children: [
      Icon(icon, color: colors.primary, size: 18),
      const SizedBox(width: 8),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: colors.onSurface)),
        Text(subtitle, style: TextStyle(fontSize: 11, color: colors.onSurface.withValues(alpha: 0.5))),
      ]),
    ]);
  }

  Widget _buildAnalyticsQuickStats(List<BatchMemberResult> sessionResults, ColorScheme colors) {
    final ids = sessionResults.map((r) => r.profile.id).toSet().toList();
    final cgpas = ids.map((id) => _getLatestStudentCgpa(id, sessionResults)).where((c) => c > 0).toList();
    final avg = cgpas.isEmpty ? 0.0 : cgpas.reduce((a, b) => a + b) / cgpas.length;
    final excellentCount = cgpas.where((c) => c >= 3.5).length;
    final failCount = ids.where((id) => sessionResults.any(
      (r) => r.profile.id == id && r.result.subjects.any((s) => s.grade.trim().toUpperCase() == 'F'),
    )).length;
    final passCount = ids.length - failCount;
    final passRate = ids.isEmpty ? 0.0 : (passCount / ids.length * 100);

    return Row(children: [
      _quickStatCard('${ids.length}', 'Total', Icons.people_outline, colors.primary, colors),
      _quickStatCard(avg > 0 ? avg.toStringAsFixed(2) : '—', 'Avg CGPA', Icons.analytics_outlined, colors.tertiary, colors),
      _quickStatCard('${passRate.round()}%', 'Pass Rate', Icons.check_circle_outline, Colors.green, colors),
      _quickStatCard('$excellentCount', '≥ 3.5', Icons.workspace_premium_outlined, Colors.purple, colors),
    ]);
  }

  Widget _quickStatCard(String value, String label, IconData icon, Color color, ColorScheme colors) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
          Text(label, style: TextStyle(fontSize: 9, color: color.withValues(alpha: 0.75)), textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  Widget _buildTopPerformersCard(List<BatchMemberResult> sessionResults, ColorScheme colors) {
    final ids = sessionResults.map((r) => r.profile.id).toSet().toList();
    final students = ids.map((id) {
      final c = _getLatestStudentCgpa(id, sessionResults);
      final prof = sessionResults.firstWhere((r) => r.profile.id == id).profile;
      final sems = sessionResults.where((r) => r.profile.id == id).map((r) => r.result.examName).toSet().length;
      return _StudentSummary(id: id, profile: prof, latestCgpa: c, semCount: sems, hasFailedSubject: false);
    }).where((s) => s.latestCgpa > 0).toList()
      ..sort((a, b) => b.latestCgpa.compareTo(a.latestCgpa));

    final top5 = students.take(5).toList();
    if (top5.isEmpty) return const SizedBox.shrink();

    final rankColors = [
      const Color(0xFFFFD700),   // gold
      const Color(0xFFB0BEC5),   // silver
      const Color(0xFFCD7F32),   // bronze
      null, null,
    ];

    return Column(
      children: top5.asMap().entries.map((e) {
        final rank = e.key + 1;
        final s = e.value;
        final rColor = rankColors[e.key] ?? colors.primary;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: rank == 1 ? const Color(0xFFFFD700).withValues(alpha: 0.05) : colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: rColor.withValues(alpha: rank <= 3 ? 0.35 : 0.1)),
          ),
          child: Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: rColor.withValues(alpha: 0.15), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text('$rank', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: rColor)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.profile.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
              Text('Roll: ${s.profile.classRoll}  •  ${s.semCount} sems',
                  style: TextStyle(fontSize: 11, color: colors.onSurface.withValues(alpha: 0.5))),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: rColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(s.latestCgpa.toStringAsFixed(2),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: rColor)),
            ),
          ]),
        );
      }).toList(),
    );
  }

  Widget _buildDifficultSubjectsCard(List<BatchMemberResult> sessionResults, ColorScheme colors) {
    final Map<String, List<SubjectResult>> subjectGroups = {};
    
    for (var r in sessionResults) {
      for (var s in r.result.subjects) {
        if (s.code.isNotEmpty) {
          subjectGroups.putIfAbsent(s.code.trim().toUpperCase(), () => []).add(s);
        }
      }
    }

    if (subjectGroups.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          'No subject data available',
          style: TextStyle(color: colors.onSurface.withValues(alpha: 0.5), fontSize: 12),
        ),
      );
    }

    final List<_SubjectStat> stats = [];
    subjectGroups.forEach((code, list) {
      int fails = 0;
      double totalPoints = 0;
      int validPointsCount = 0;
      String name = '';

      for (var s in list) {
        if (s.name.isNotEmpty && name.isEmpty) name = s.name;
        final grade = s.grade.trim().toUpperCase();
        if (grade == 'F') fails++;
        
        final pts = double.tryParse(s.point) ?? 0.0;
        if (pts > 0 || grade == 'F') {
          totalPoints += pts;
          validPointsCount++;
        }
      }

      final avgPt = validPointsCount > 0 ? totalPoints / validPointsCount : 0.0;
      final failRate = list.isNotEmpty ? (fails / list.length) : 0.0;

      stats.add(_SubjectStat(
        code: code,
        name: name,
        failRate: failRate,
        avgGp: avgPt,
        totalStudents: list.length,
        failCount: fails,
      ));
    });

    // Sort by fail rate descending, then by average GP ascending
    stats.sort((a, b) {
      if (b.failRate != a.failRate) {
        return b.failRate.compareTo(a.failRate);
      }
      return a.avgGp.compareTo(b.avgGp);
    });

    final difficultList = stats.take(3).toList();

    return Column(
      children: difficultList.map((s) {
        final pct = (s.failRate * 100).round();
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: s.failRate > 0.1 
                  ? Colors.red.withValues(alpha: 0.25) 
                  : colors.outline.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: s.failRate > 0.1 ? Colors.red.withValues(alpha: 0.1) : colors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  s.failRate > 0.1 ? Icons.warning_amber_rounded : Icons.menu_book_rounded,
                  color: s.failRate > 0.1 ? Colors.red : colors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.code, 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      s.name, 
                      style: TextStyle(fontSize: 11, color: colors.onSurface.withValues(alpha: 0.5)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Avg GP: ${s.avgGp.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12, 
                      fontWeight: FontWeight.bold, 
                      color: s.avgGp < 2.5 ? Colors.orange : colors.onSurface,
                    ),
                  ),
                  Text(
                    '$pct% Failed (${s.failCount}/${s.totalStudents})',
                    style: TextStyle(
                      fontSize: 10, 
                      fontWeight: FontWeight.w500, 
                      color: s.failCount > 0 ? Colors.red : colors.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  SEMESTER GRADE OVERVIEW  (used inside analytics sheet)
  // ══════════════════════════════════════════════════════════

  Widget _buildSemesterGradeOverviewCard(List<BatchMemberResult> semFiltered, ColorScheme colors) {
    if (semFiltered.isEmpty) return const SizedBox.shrink();
    if (_subjectSearchQuery.isNotEmpty) return _buildGradeDistributionAnalysisCard(semFiltered, colors);

    final gpas = semFiltered
        .map((r) => double.tryParse(r.result.gpa) ?? 0.0)
        .where((g) => g > 0)
        .toList();
    if (gpas.isEmpty) return const SizedBox.shrink();

    final avg = gpas.reduce((a, b) => a + b) / gpas.length;
    final max = gpas.reduce((a, b) => a > b ? a : b);
    final min = gpas.reduce((a, b) => a < b ? a : b);

    const bracketLabels = ['A (≥3.5)', 'B (3.0–3.5)', 'C (2.5–3.0)', 'D (2.0–2.5)', 'F (<2.0)'];
    final bracketColors = <String, Color>{
      'A (≥3.5)':    Colors.green,
      'B (3.0–3.5)': const Color(0xFF00897B),
      'C (2.5–3.0)': Colors.amber,
      'D (2.0–2.5)': Colors.orange,
      'F (<2.0)':    Colors.red,
    };
    final counts = <String, int>{for (var l in bracketLabels) l: 0};
    for (var g in gpas) {
      if (g >= 3.5)      counts['A (≥3.5)'] = (counts['A (≥3.5)'] ?? 0) + 1;
      else if (g >= 3.0) counts['B (3.0–3.5)'] = (counts['B (3.0–3.5)'] ?? 0) + 1;
      else if (g >= 2.5) counts['C (2.5–3.0)'] = (counts['C (2.5–3.0)'] ?? 0) + 1;
      else if (g >= 2.0) counts['D (2.0–2.5)'] = (counts['D (2.0–2.5)'] ?? 0) + 1;
      else               counts['F (<2.0)'] = (counts['F (<2.0)'] ?? 0) + 1;
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Stat pills
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          _statPill('Avg', avg.toStringAsFixed(2), colors.primary, colors),
          const SizedBox(width: 8),
          _statPill('Max', max.toStringAsFixed(2), Colors.green, colors),
          const SizedBox(width: 8),
          _statPill('Min', min.toStringAsFixed(2), Colors.orange, colors),
          const SizedBox(width: 8),
          _statPill('n', '${gpas.length}', colors.secondary, colors),
        ]),
      ),
      const SizedBox(height: 10),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: bracketLabels.map((label) {
            final count = counts[label] ?? 0;
            if (count == 0) return const SizedBox.shrink();
            final color = bracketColors[label] ?? colors.primary;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withValues(alpha: 0.35)),
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
                  Text('$count', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
                ]),
              ),
            );
          }).toList(),
        ),
      ),
    ]);
  }

  Widget _statPill(String label, String value, Color color, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.75))),
        const SizedBox(width: 5),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      ]),
    );
  }

  Widget _buildGradeDistributionAnalysisCard(List<BatchMemberResult> filteredList, ColorScheme colors) {
    final Map<String, int> gradeCounts = {
      'A+': 0, 'A': 0, 'A-': 0, 'B+': 0, 'B': 0, 'B-': 0, 'C+': 0, 'C': 0, 'D': 0, 'F': 0,
    };
    int totalEvaluated = 0;
    double totalPoints = 0.0;
    for (var r in filteredList) {
      final sub = r.result.subjects.firstWhere(
        (s) => s.code.toLowerCase().contains(_subjectSearchQuery.toLowerCase()) ||
               s.name.toLowerCase().contains(_subjectSearchQuery.toLowerCase()),
        orElse: () => SubjectResult(code: '', name: '', grade: '', point: ''),
      );
      if (sub.grade.isNotEmpty) {
        final g = sub.grade.trim().toUpperCase();
        if (gradeCounts.containsKey(g)) gradeCounts[g] = gradeCounts[g]! + 1;
        final pts = double.tryParse(sub.point) ?? 0.0;
        if (pts > 0 || g == 'F') { totalPoints += pts; totalEvaluated++; }
      }
    }
    if (totalEvaluated == 0) return const SizedBox.shrink();
    final avgGpa = totalPoints / totalEvaluated;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        '"$_subjectSearchQuery"  •  Avg GP: ${avgGpa.toStringAsFixed(2)}',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colors.primary),
      ),
      const SizedBox(height: 10),
      SizedBox(
        height: 48,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: gradeCounts.entries.map((e) {
            if (e.value == 0) return const SizedBox.shrink();
            return Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.outline.withValues(alpha: 0.12)),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                Text('${e.value}', style: TextStyle(fontSize: 9, color: colors.onSurface.withValues(alpha: 0.6))),
              ]),
            );
          }).toList(),
        ),
      ),
    ]);
  }

  // ══════════════════════════════════════════════════════════
  //  STUDENT ACCORDION  (enhanced)
  // ══════════════════════════════════════════════════════════

  Widget _buildEmptyState(ColorScheme colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.person_search, size: 48, color: colors.onSurface.withValues(alpha: 0.25)),
          const SizedBox(height: 16),
          const Text('No students match your filters.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Try adjusting or clearing your filters.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: colors.onSurface.withValues(alpha: 0.5))),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _clearAllFilters,
            icon: const Icon(Icons.clear_all, size: 18),
            label: const Text('Clear All Filters'),
          ),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  _BadgedIconButton — Icon button with an optional count badge
// ══════════════════════════════════════════════════════════════

class _BadgedIconButton extends StatelessWidget {
  final int count;
  final IconData icon;
  final String tooltip;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onPressed;

  const _BadgedIconButton({
    required this.count,
    required this.icon,
    required this.tooltip,
    required this.backgroundColor,
    required this.iconColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onPressed,
            child: Tooltip(
              message: tooltip,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(icon, size: 22, color: iconColor),
              ),
            ),
          ),
        ),
        if (count > 0)
          Positioned(
            top: -5, right: -5,
            child: Container(
              width: 18, height: 18,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Theme.of(context).colorScheme.surface, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                '$count',
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Top-Level Helper Functions (Shared)
// ──────────────────────────────────────────────────────────────

int _parseSemesterNumber(String examName) {
  final n = examName.toLowerCase();
  if (n.contains('1st year 1st') || n.contains('1st sem') || n.contains('1-1') || (n.contains('1st year') && n.contains('1st'))) return 1;
  if (n.contains('1st year 2nd') || n.contains('2nd sem') || n.contains('1-2') || (n.contains('1st year') && n.contains('2nd'))) return 2;
  if (n.contains('2nd year 1st') || n.contains('3rd sem') || n.contains('2-1') || (n.contains('2nd year') && n.contains('1st'))) return 3;
  if (n.contains('2nd year 2nd') || n.contains('4th sem') || n.contains('2-2') || (n.contains('2nd year') && n.contains('2nd'))) return 4;
  if (n.contains('3rd year 1st') || n.contains('5th sem') || n.contains('3-1') || (n.contains('3rd year') && n.contains('1st'))) return 5;
  if (n.contains('3rd year 2nd') || n.contains('6th sem') || n.contains('3-2') || (n.contains('3rd year') && n.contains('2nd'))) return 6;
  if (n.contains('4th year 1st') || n.contains('7th sem') || n.contains('4-1') || (n.contains('4th year') && n.contains('1st'))) return 7;
  if (n.contains('4th year 2nd') || n.contains('8th sem') || n.contains('4-2') || (n.contains('4th year') && n.contains('2nd'))) return 8;
  if (n.contains('1st')) return 1;
  if (n.contains('2nd')) return 2;
  if (n.contains('3rd')) return 3;
  if (n.contains('4th')) return 4;
  if (n.contains('5th')) return 5;
  if (n.contains('6th')) return 6;
  if (n.contains('7th')) return 7;
  if (n.contains('8th')) return 8;
  return 1;
}

String _getOrdinalSuffix(int n) {
  if (n == 1) return 'st';
  if (n == 2) return 'nd';
  if (n == 3) return 'rd';
  return 'th';
}

double _getLatestStudentCgpa(String studentId, List<BatchMemberResult> allResults) {
  double latestCgpa = 0.0;
  int maxSem = 0;
  for (var r in allResults) {
    if (r.profile.id != studentId) continue;
    final sem = r.result.semester ?? _parseSemesterNumber(r.result.examName);
    if (sem > maxSem) {
      maxSem = sem;
      final v = double.tryParse(r.result.cgpa) ?? 0.0;
      if (v > 0.0) latestCgpa = v;
    }
  }
  if (latestCgpa == 0.0) {
    double sum = 0; int cnt = 0;
    for (var r in allResults) {
      if (r.profile.id != studentId) continue;
      final g = double.tryParse(r.result.gpa) ?? 0.0;
      if (g > 0.0) { sum += g; cnt++; }
    }
    if (cnt > 0) latestCgpa = sum / cnt;
  }
  return latestCgpa;
}

class _SubjectStat {
  final String code;
  final String name;
  final double failRate;
  final double avgGp;
  final int totalStudents;
  final int failCount;

  _SubjectStat({
    required this.code,
    required this.name,
    required this.failRate,
    required this.avgGp,
    required this.totalStudents,
    required this.failCount,
  });
}

// ══════════════════════════════════════════════════════════════
//  _StudentAccordionWidget (encapsulates student result card)
// ══════════════════════════════════════════════════════════════

class _StudentAccordionWidget extends StatefulWidget {
  final List<BatchMemberResult> studentItems;
  final List<BatchMemberResult> allResults;
  final _StudentSummary summary;
  final int? rank;
  final ColorScheme colors;
  final String subjectSearchQuery;
  final bool isExpanded;
  final ValueChanged<bool> onExpansionChanged;

  const _StudentAccordionWidget({
    required this.studentItems,
    required this.allResults,
    required this.summary,
    required this.rank,
    required this.colors,
    required this.subjectSearchQuery,
    required this.isExpanded,
    required this.onExpansionChanged,
  });

  @override
  State<_StudentAccordionWidget> createState() => _StudentAccordionWidgetState();
}

class _StudentAccordionWidgetState extends State<_StudentAccordionWidget> {
  String _selectedYear = 'All';
  String _selectedSemester = 'All';
  String? _expandedSemesterResultId;

  @override
  Widget build(BuildContext context) {
    final profile = widget.summary.profile;
    final cgpa = widget.summary.latestCgpa;
    final studentResults = widget.studentItems.map((i) => i.result).toList();

    // Performance color
    Color cgpaColor;
    String perfLabel;
    IconData perfIcon;
    if (cgpa >= 3.5)       { cgpaColor = Colors.green;       perfLabel = 'Excellent';  perfIcon = Icons.workspace_premium; }
    else if (cgpa >= 3.0)  { cgpaColor = const Color(0xFF00897B); perfLabel = 'Very Good'; perfIcon = Icons.thumb_up_outlined; }
    else if (cgpa >= 2.5)  { cgpaColor = Colors.orange;      perfLabel = 'Good';       perfIcon = Icons.sentiment_satisfied_outlined; }
    else if (cgpa >= 2.0)  { cgpaColor = Colors.deepOrange;  perfLabel = 'Fair';       perfIcon = Icons.sentiment_neutral_outlined; }
    else if (cgpa > 0)     { cgpaColor = Colors.red;         perfLabel = 'Needs Work'; perfIcon = Icons.warning_amber_outlined; }
    else                   { cgpaColor = widget.colors.onSurface.withValues(alpha: 0.35); perfLabel = 'No Data'; perfIcon = Icons.help_outline; }

    // Filter results based on year and semester dropdown selection
    final filteredItems = widget.studentItems.where((item) {
      final sem = item.result.semester ?? _parseSemesterNumber(item.result.examName);
      final year = (sem - 1) ~/ 2 + 1; // 1, 2, 3, 4
      final isOdd = sem % 2 == 1; // 1st Semester of that year
      
      bool matchesYear = true;
      if (_selectedYear == '1st Year') matchesYear = (year == 1);
      else if (_selectedYear == '2nd Year') matchesYear = (year == 2);
      else if (_selectedYear == '3rd Year') matchesYear = (year == 3);
      else if (_selectedYear == '4th Year') matchesYear = (year == 4);

      bool matchesSemester = true;
      if (_selectedSemester == '1st Semester') matchesSemester = isOdd;
      else if (_selectedSemester == '2nd Semester') matchesSemester = !isOdd;

      return matchesYear && matchesSemester;
    }).toList()
      ..sort((a, b) {
        final sa = a.result.semester ?? _parseSemesterNumber(a.result.examName);
        final sb = b.result.semester ?? _parseSemesterNumber(b.result.examName);
        return sa.compareTo(sb);
      });

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: widget.summary.hasFailedSubject
              ? Colors.red.withValues(alpha: 0.25)
              : widget.colors.outline.withValues(alpha: 0.1),
        ),
      ),
      color: widget.summary.hasFailedSubject ? Colors.red.withValues(alpha: 0.02) : widget.colors.surface,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: Key('${profile.id}_${widget.isExpanded}'),
          initiallyExpanded: widget.isExpanded,
          onExpansionChanged: widget.onExpansionChanged,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          childrenPadding: const EdgeInsets.only(bottom: 12),
          leading: Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: cgpaColor.withValues(alpha: 0.12),
                backgroundImage: profile.imagePath != null ? NetworkImage(profile.imagePath!) : null,
                child: profile.imagePath == null
                    ? Text((profile.name.isNotEmpty ? profile.name[0] : '?').toUpperCase(),
                        style: TextStyle(color: cgpaColor, fontWeight: FontWeight.bold, fontSize: 16))
                    : null,
              ),
              if (widget.rank != null && widget.rank! <= 5)
                Positioned(
                  bottom: -3, right: -5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: widget.rank == 1 
                          ? const Color(0xFFFFD700) 
                          : widget.rank == 2 
                              ? const Color(0xFFB0BEC5) 
                              : widget.rank == 3 
                                  ? const Color(0xFFCD7F32) 
                                  : widget.colors.primary,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: widget.colors.surface, width: 1.5),
                    ),
                    child: Text('#${widget.rank}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              if (widget.summary.hasFailedSubject)
                Positioned(
                  top: -3, right: -3,
                  child: Container(
                    width: 14, height: 14,
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: const Icon(Icons.priority_high, size: 9, color: Colors.white),
                  ),
                ),
            ],
          ),
          title: Row(children: [
            Expanded(
              child: Text(profile.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), overflow: TextOverflow.ellipsis),
            ),
            if (profile.isAlumni)
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: widget.colors.tertiary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: widget.colors.tertiary.withValues(alpha: 0.3)),
                ),
                child: Text('Alumni', style: TextStyle(fontSize: 9, color: widget.colors.tertiary, fontWeight: FontWeight.bold)),
              ),
          ]),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                'Roll: ${profile.classRoll.isNotEmpty ? profile.classRoll : "—"}  •  ID: ${profile.universityId.isNotEmpty ? profile.universityId : "—"}',
                style: TextStyle(fontSize: 11, color: widget.colors.onSurface.withValues(alpha: 0.5)),
              ),
              const SizedBox(height: 5),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: cgpaColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: cgpaColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(perfIcon, size: 12, color: cgpaColor),
                    const SizedBox(width: 4),
                    Text(
                      cgpa > 0 ? 'CGPA: ${cgpa.toStringAsFixed(2)}' : 'No CGPA',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: cgpaColor),
                    ),
                  ]),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: widget.colors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${widget.summary.semCount} sem${widget.summary.semCount != 1 ? "s" : ""}',
                    style: TextStyle(fontSize: 10, color: widget.colors.onSurface.withValues(alpha: 0.6)),
                  ),
                ),
                if (widget.summary.hasFailedSubject) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: const Text('Has F', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red)),
                  ),
                ],
              ]),
            ]),
          ),
          children: [
            const Divider(height: 1),
            // CGPA chart
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: CgpaPredictionChart(results: studentResults, showPredictions: false),
            ),
            const Divider(height: 1),
            
            // Year & Semester Dropdown selection
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedYear,
                      decoration: InputDecoration(
                        labelText: 'Year',
                        labelStyle: TextStyle(fontSize: 12, color: widget.colors.primary, fontWeight: FontWeight.bold),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        filled: true,
                        fillColor: widget.colors.surfaceContainerLow,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'All', child: Text('All Years', style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: '1st Year', child: Text('1st Year', style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: '2nd Year', child: Text('2nd Year', style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: '3rd Year', child: Text('3rd Year', style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: '4th Year', child: Text('4th Year', style: TextStyle(fontSize: 12))),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedYear = val;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedSemester,
                      decoration: InputDecoration(
                        labelText: 'Semester',
                        labelStyle: TextStyle(fontSize: 12, color: widget.colors.primary, fontWeight: FontWeight.bold),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        filled: true,
                        fillColor: widget.colors.surfaceContainerLow,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'All', child: Text('All Semesters', style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: '1st Semester', child: Text('1st Sem', style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: '2nd Semester', child: Text('2nd Sem', style: TextStyle(fontSize: 12))),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedSemester = val;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Results List
            if (filteredItems.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Text(
                    'No results for selected Year/Semester',
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.colors.onSurface.withValues(alpha: 0.45),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              )
            else
              ...filteredItems.map((item) => _buildSemesterSubTile(item, widget.colors)),
          ],
        ),
      ),
    );
  }

  Widget _buildSemesterSubTile(BatchMemberResult item, ColorScheme colors) {
    SubjectResult? searchedSub;
    if (widget.subjectSearchQuery.isNotEmpty) {
      for (var s in item.result.subjects) {
        if (s.code.toLowerCase().contains(widget.subjectSearchQuery.toLowerCase()) ||
            s.name.toLowerCase().contains(widget.subjectSearchQuery.toLowerCase())) {
          searchedSub = s;
          break;
        }
      }
    }
    final semNum = item.result.semester ?? _parseSemesterNumber(item.result.examName);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5).copyWith(bottom: 8),
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: colors.outline.withValues(alpha: 0.1)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: Key('${item.profile.id}_s${item.result.id}_${item.result.id == _expandedSemesterResultId}'),
          initiallyExpanded: item.result.id == _expandedSemesterResultId,
          onExpansionChanged: (exp) => setState(() {
            if (exp) _expandedSemesterResultId = item.result.id;
            else if (_expandedSemesterResultId == item.result.id) _expandedSemesterResultId = null;
          }),
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          childrenPadding: const EdgeInsets.all(12).copyWith(top: 0),
          title: Text('Semester $semNum', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.result.examName, style: TextStyle(fontSize: 10, color: colors.onSurface.withValues(alpha: 0.5))),
              const SizedBox(height: 4),
              Row(children: [
                _gpaBadge('GPA: ${item.result.gpa}', Colors.blue),
                const SizedBox(width: 6),
                _gpaBadge('CGPA: ${item.result.cgpa}', Colors.green),
                if (searchedSub != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('${searchedSub.code}: ${searchedSub.grade}',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: colors.primary),
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ]),
            ]),
          ),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 8),
            Text('Reg: ${item.profile.duRegNo.isNotEmpty ? item.profile.duRegNo : "N/A"}',
                style: TextStyle(fontSize: 10, color: colors.onSurface.withValues(alpha: 0.5))),
            const SizedBox(height: 8),
            ...item.result.subjects.map((sub) => _buildSubjectRow(sub, colors)),
          ],
        ),
      ),
    );
  }

  Widget _gpaBadge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(4)),
    child: Text(text, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
  );

  Widget _buildSubjectRow(SubjectResult subject, ColorScheme colors) {
    Color gradeColor = Colors.grey;
    if (subject.grade.startsWith('A'))     gradeColor = Colors.green;
    else if (subject.grade.startsWith('B')) gradeColor = Colors.blue;
    else if (subject.grade.startsWith('C')) gradeColor = Colors.orange;
    else if (subject.grade == 'F')          gradeColor = Colors.red;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(subject.code, style: TextStyle(color: colors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
          Text(subject.name, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(subject.grade, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: gradeColor)),
          Text(subject.point, style: TextStyle(fontSize: 10, color: colors.onSurface.withValues(alpha: 0.5))),
        ]),
      ]),
    );
  }
}
