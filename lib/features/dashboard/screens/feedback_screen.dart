import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ShEC_CSE/core/utils/snackbar_utils.dart';
import '../../../backend/services/feedback_service.dart';
import '../presentation/widgets/ambient_background.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  int _selectedRating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = false;

  final Map<int, ({String label, String emoji, Color color})> _ratingInfo = {
    1: (label: 'Poor', emoji: '😞', color: Colors.redAccent),
    2: (label: 'Fair', emoji: '😐', color: Colors.orangeAccent),
    3: (label: 'Good', emoji: '🙂', color: Colors.amber),
    4: (label: 'Very Good', emoji: '😊', color: Colors.lightGreen),
    5: (label: 'Excellent!', emoji: '😍', color: Colors.green),
  };

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedRating == 0) return;
    
    setState(() => _isLoading = true);
    await HapticFeedback.mediumImpact();

    try {
      await FeedbackService.submitFeedback(
        rating: _selectedRating,
        comment: _commentController.text.trim(),
      );

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog() {
    final colors = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: colors.surface,
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('Thank You!', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Your feedback has been submitted successfully. We appreciate your valuable suggestions to improve ShEC CSE App!',
          style: TextStyle(color: colors.onSurface, fontSize: 14, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(dialogCtx); // Close dialog
              Navigator.pop(context); // Pop back to dashboard
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final ratingDetails = _selectedRating > 0 ? _ratingInfo[_selectedRating] : null;

    return AmbientTimeBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Send Feedback'),
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.rate_review_rounded, size: 48, color: colors.primary),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Help Us Improve!',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your thoughts and suggestions help us make ShEC CSE App better for everyone.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.onSurface.withValues(alpha: 0.6),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              
              // ── Rating Stars section ──
              Text(
                'Rate your experience *',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.onSurface),
              ),
              const SizedBox(height: 16),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (index) {
                    final starRating = index + 1;
                    final isSelected = starRating <= _selectedRating;
                    return IconButton(
                      icon: Icon(
                        isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 40,
                      ),
                      color: isSelected
                          ? (ratingDetails?.color ?? Colors.amber)
                          : colors.onSurface.withValues(alpha: 0.2),
                      onPressed: () async {
                        await HapticFeedback.selectionClick();
                        setState(() => _selectedRating = starRating);
                      },
                    );
                  }),
                ),
              ),
              const SizedBox(height: 8),
              if (ratingDetails != null)
                Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: ratingDetails.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: ratingDetails.color.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          ratingDetails.emoji,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          ratingDetails.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: ratingDetails.color.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 28),

              // ── Comment suggestion section ──
              Text(
                'Tell us more about it (optional)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.onSurface),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _commentController,
                maxLines: 5,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'What did you like? What can we do better? Type your feedback here...',
                  hintStyle: TextStyle(fontSize: 13, color: colors.onSurface.withValues(alpha: 0.35)),
                  contentPadding: const EdgeInsets.all(16),
                  filled: true,
                  fillColor: colors.surfaceContainerHighest.withValues(alpha: 0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: colors.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // ── Submit button ──
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _selectedRating == 0 || _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: colors.onSurface.withValues(alpha: 0.08),
                    disabledForegroundColor: colors.onSurface.withValues(alpha: 0.35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Submit Feedback',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
