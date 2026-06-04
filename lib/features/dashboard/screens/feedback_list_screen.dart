import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../backend/services/feedback_service.dart';
import '../presentation/widgets/ambient_background.dart';
import 'feedback_screen.dart';
import 'package:intl/intl.dart';
import 'package:ShEC_CSE/core/utils/snackbar_utils.dart';


class FeedbackListScreen extends StatefulWidget {
  const FeedbackListScreen({super.key});

  @override
  State<FeedbackListScreen> createState() => _FeedbackListScreenState();
}

class _FeedbackListScreenState extends State<FeedbackListScreen> {
  List<Map<String, dynamic>> _feedbacks = [];
  bool _isLoading = true;
  String _errorMessage = '';
  int _selectedFilter = 0; // 0 = All, 1-5 = specifically that star rating

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final list = await FeedbackService.getFeedbacks();
      setState(() {
        _feedbacks = list;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load feedbacks: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteItem(String id) async {
    final colors = Theme.of(context).colorScheme;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: colors.surface,
        title: const Text('Delete Feedback', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this feedback? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await HapticFeedback.mediumImpact();
      try {
        await FeedbackService.deleteFeedback(id);
        SnackBarUtils.showSuccess(context, 'Feedback deleted successfully.');
        _fetchData();
      } catch (e) {
        SnackBarUtils.showError(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = colors.brightness == Brightness.dark;

    // Filter feedbacks based on selection
    final filteredFeedbacks = _selectedFilter == 0
        ? _feedbacks
        : _feedbacks.where((f) => f['rating'] == _selectedFilter).toList();

    // Stats calculations
    int totalCount = _feedbacks.length;
    double avgRating = 0.0;
    Map<int, int> starsCount = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

    if (totalCount > 0) {
      double sum = 0;
      for (var f in _feedbacks) {
        int r = f['rating'] ?? 0;
        sum += r;
        if (starsCount.containsKey(r)) {
          starsCount[r] = (starsCount[r] ?? 0) + 1;
        }
      }
      avgRating = sum / totalCount;
    }

    return AmbientTimeBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('User Feedbacks'),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _fetchData,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline_rounded, size: 48, color: colors.error),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colors.onSurface.withValues(alpha: 0.8)),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _fetchData,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchData,
                    color: colors.primary,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        // ── Statistics Section ──
                        if (totalCount > 0)
                          SliverToBoxAdapter(
                            child: _buildStatsCard(colors, isDark, avgRating, totalCount, starsCount),
                          ),

                        // ── Filter Selector Section ──
                        SliverToBoxAdapter(
                          child: _buildFilterChips(colors, totalCount),
                        ),

                        // ── Feedbacks List ──
                        filteredFeedbacks.isEmpty
                            ? SliverFillRemaining(
                                hasScrollBody: false,
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(32.0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.rate_review_outlined,
                                          size: 56,
                                          color: colors.onSurface.withValues(alpha: 0.25),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No feedbacks found matching your filter.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: colors.onSurface.withValues(alpha: 0.45),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : SliverPadding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      final item = filteredFeedbacks[index];
                                      return _buildFeedbackCard(context, colors, item);
                                    },
                                    childCount: filteredFeedbacks.length,
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final navigator = Navigator.of(context);
            await HapticFeedback.lightImpact();
            navigator.push(
              MaterialPageRoute(builder: (_) => const FeedbackScreen()),
            ).then((_) => _fetchData());
          },
          label: const Text('Add Feedback', style: TextStyle(fontWeight: FontWeight.bold)),
          icon: const Icon(Icons.add_rounded),
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildStatsCard(
    ColorScheme colors,
    bool isDark,
    double avgRating,
    int totalCount,
    Map<int, int> starsCount,
  ) {
    // Emojis for feedback levels
    String ratingEmoji = '😊';
    if (avgRating >= 4.5) {
      ratingEmoji = '😍';
    } else if (avgRating >= 3.5) {
      ratingEmoji = '😊';
    } else if (avgRating >= 2.5) {
      ratingEmoji = '🙂';
    } else if (avgRating >= 1.5) {
      ratingEmoji = '😐';
    } else {
      ratingEmoji = '😞';
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest.withValues(alpha: isDark ? 0.35 : 0.65),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.onSurface.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          // Average stars details
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Average Score',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.onSurface.withValues(alpha: 0.7)),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      avgRating.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      ratingEmoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(5, (index) {
                    final starVal = index + 1;
                    return Icon(
                      starVal <= avgRating.round()
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 16,
                      color: Colors.amber,
                    );
                  }),
                ),
                const SizedBox(height: 6),
                Text(
                  'From $totalCount ratings',
                  style: TextStyle(fontSize: 11, color: colors.onSurface.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ),
          
          // Vertical divider line
          Container(
            height: 80,
            width: 1,
            color: colors.onSurface.withValues(alpha: 0.08),
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),

          // Rating breakdown visual meters
          Expanded(
            flex: 6,
            child: Column(
              children: List.generate(5, (index) {
                final starNum = 5 - index;
                final count = starsCount[starNum] ?? 0;
                final ratio = totalCount > 0 ? count / totalCount : 0.0;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    children: [
                      Text(
                        '$starNum',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.star_rounded, size: 10, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: ratio,
                            minHeight: 6,
                            backgroundColor: colors.onSurface.withValues(alpha: 0.05),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              starNum >= 4
                                  ? Colors.green
                                  : starNum >= 3
                                      ? Colors.amber
                                      : Colors.orangeAccent,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 20,
                        child: Text(
                          '$count',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: colors.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(ColorScheme colors, int totalCount) {
    return Container(
      height: 38,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 6,
        itemBuilder: (context, index) {
          final filterVal = index; // 0 = All, 1-5 = stars
          final isSelected = _selectedFilter == filterVal;
          
          String label = 'All';
          if (filterVal > 0) {
            int count = _feedbacks.where((f) => f['rating'] == filterVal).length;
            label = '$filterVal ★ ($count)';
          } else {
            label = 'All ($totalCount)';
          }

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : colors.onSurface.withValues(alpha: 0.7),
                ),
              ),
              selected: isSelected,
              onSelected: (val) {
                if (val) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedFilter = filterVal;
                  });
                }
              },
              selectedColor: colors.primary,
              backgroundColor: colors.surfaceContainerHighest.withValues(alpha: 0.15),
              checkmarkColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: BorderSide(
                color: isSelected ? colors.primary : colors.onSurface.withValues(alpha: 0.08),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeedbackCard(BuildContext context, ColorScheme colors, Map<String, dynamic> item) {
    final String id = item['id'] ?? '';
    final int rating = item['rating'] ?? 0;
    final String comment = item['comment'] ?? '';
    final String userName = item['user_name'] ?? 'Anonymous';
    final String? createdAtStr = item['created_at'];

    String formattedTime = '';
    if (createdAtStr != null) {
      try {
        final parsed = DateTime.parse(createdAtStr).toLocal();
        formattedTime = DateFormat('MMM dd, yyyy  •  hh:mm a').format(parsed);
      } catch (_) {}
    }

    final isDark = colors.brightness == Brightness.dark;
    
    // Get corresponding emojis/colors for specific stars
    Color starColor = Colors.amber;
    String emoji = '🙂';
    switch (rating) {
      case 5:
        starColor = Colors.green;
        emoji = '😍';
        break;
      case 4:
        starColor = Colors.lightGreen;
        emoji = '😊';
        break;
      case 3:
        starColor = Colors.amber;
        emoji = '🙂';
        break;
      case 2:
        starColor = Colors.orangeAccent;
        emoji = '😐';
        break;
      case 1:
        starColor = Colors.redAccent;
        emoji = '😞';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest.withValues(alpha: isDark ? 0.25 : 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Beautiful circular avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: starColor.withValues(alpha: 0.1),
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),
              
              // Name and rating
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: List.generate(5, (index) {
                        final starIdx = index + 1;
                        return Icon(
                          starIdx <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: 14,
                          color: starIdx <= rating ? starColor : colors.onSurface.withValues(alpha: 0.15),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              // Delete button for administration
              IconButton(
                icon: Icon(Icons.delete_outline_rounded, size: 18, color: colors.error.withValues(alpha: 0.7)),
                onPressed: () => _deleteItem(id),
                tooltip: 'Delete Feedback',
              ),
            ],
          ),
          
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.onSurface.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                comment,
                style: TextStyle(
                  fontSize: 13,
                  color: colors.onSurface.withValues(alpha: 0.85),
                  height: 1.45,
                ),
              ),
            ),
          ],
          
          if (formattedTime.isNotEmpty) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                formattedTime,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface.withValues(alpha: 0.35),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
