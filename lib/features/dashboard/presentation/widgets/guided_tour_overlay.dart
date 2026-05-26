import 'dart:ui';
import 'package:flutter/material.dart';

class TourStep {
  final GlobalKey targetKey;
  final String title;
  final String description;

  TourStep({
    required this.targetKey,
    required this.title,
    required this.description,
  });
}

class GuidedTourOverlay extends StatefulWidget {
  final List<TourStep> steps;
  final VoidCallback onComplete;
  final VoidCallback onSkip;
  final Function(int)? onStepChanged;

  const GuidedTourOverlay({
    super.key,
    required this.steps,
    required this.onComplete,
    required this.onSkip,
    this.onStepChanged,
  });

  @override
  State<GuidedTourOverlay> createState() => _GuidedTourOverlayState();
}

class _GuidedTourOverlayState extends State<GuidedTourOverlay> with SingleTickerProviderStateMixin {
  int _currentStepIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  Rect? _previousRect;
  Rect? _targetRect;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.fastOutSlowIn,
    );

    // Bootstrap target position detection on first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.onStepChanged != null) {
        widget.onStepChanged!(_currentStepIndex);
      }
      _updateTargetBounds();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _updateTargetBounds() {
    if (widget.steps.isEmpty || _currentStepIndex >= widget.steps.length) return;

    // Small delay to allow bottom tab switching and rendering to fully settle
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;

      final step = widget.steps[_currentStepIndex];
      final context = step.targetKey.currentContext;

      if (context != null) {
        final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null && renderBox.hasSize) {
          final Offset position = renderBox.localToGlobal(Offset.zero);
          final Size size = renderBox.size;
          
          final newRect = Rect.fromLTWH(
            position.dx,
            position.dy,
            size.width,
            size.height,
          );

          setState(() {
            _previousRect = _targetRect ?? newRect;
            _targetRect = newRect;
          });

          _animationController.forward(from: 0.0);
          return;
        }
      }

      // Fallback if target cannot be found or is not rendered yet
      setState(() {
        final screenSize = MediaQuery.of(context ?? this.context).size;
        final newRect = Rect.fromLTWH(
          screenSize.width / 2 - 50,
          screenSize.height / 2 - 50,
          100,
          100,
        );
        _previousRect = _targetRect ?? newRect;
        _targetRect = newRect;
      });
      _animationController.forward(from: 0.0);
    });
  }

  void _nextStep() {
    if (_currentStepIndex < widget.steps.length - 1) {
      setState(() {
        _currentStepIndex++;
      });
      if (widget.onStepChanged != null) {
        widget.onStepChanged!(_currentStepIndex);
      }
      _updateTargetBounds();
    } else {
      widget.onComplete();
    }
  }

  void _previousStep() {
    if (_currentStepIndex > 0) {
      setState(() {
        _currentStepIndex--;
      });
      if (widget.onStepChanged != null) {
        widget.onStepChanged!(_currentStepIndex);
      }
      _updateTargetBounds();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.steps.isEmpty || _currentStepIndex >= widget.steps.length) {
      return const SizedBox.shrink();
    }

    final step = widget.steps[_currentStepIndex];
    final screenSize = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        Rect? activeRect;
        if (_previousRect != null && _targetRect != null) {
          activeRect = Rect.lerp(_previousRect!, _targetRect!, _animation.value);
        } else {
          activeRect = _targetRect;
        }

        // Safe coordinates for instruction card positioning
        double cardTop = screenSize.height / 2;
        double cardLeft = 20.0;
        double cardWidth = screenSize.width - 40.0;

        if (activeRect != null) {
          // If spotlight is in the upper half of screen, show instruction card below it
          if (activeRect.center.dy < screenSize.height / 2) {
            cardTop = activeRect.bottom + 24.0;
          } else {
            // Else show instruction card above the spotlight
            cardTop = activeRect.top - 180.0;
          }

          // Bound safe height limits
          if (cardTop < 60) cardTop = 60;
          if (cardTop > screenSize.height - 240) cardTop = screenSize.height - 240;
        }

        return Stack(
          children: [
            // Darkened spotlight mask overlay
            Positioned.fill(
              child: CustomPaint(
                painter: SpotlightPainter(
                  targetRect: activeRect,
                  pulseValue: _animation.value,
                ),
              ),
            ),

            // Absorb pointer block clicks outside target cutout (prevents misclicks on hidden elements)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  // Standard onboarding tapping: proceed to next step
                  _nextStep();
                },
                child: const SizedBox.expand(),
              ),
            ),

            // Allow interaction inside the spotlight area (optional, we block it to guide the user sequentially)
            if (activeRect != null)
              Positioned.fromRect(
                rect: activeRect.inflate(8.0),
                child: GestureDetector(
                  onTap: _nextStep,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),

            // Gorgeous Floating Glassmorphic Onboarding Instruction Card
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              top: cardTop,
              left: cardLeft,
              width: cardWidth,
              child: Card(
                elevation: 16,
                color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.white.withOpacity(0.12)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Step ${_currentStepIndex + 1} of ${widget.steps.length}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: widget.onSkip,
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  foregroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                                child: const Text('Skip Tour', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            step.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            step.description,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.35,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (_currentStepIndex > 0)
                                TextButton.icon(
                                  onPressed: _previousStep,
                                  icon: const Icon(Icons.arrow_back, size: 16),
                                  label: const Text('Back'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                  ),
                                )
                              else
                                const SizedBox.shrink(),
                              const Spacer(),
                              ElevatedButton(
                                onPressed: _nextStep,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  elevation: 2,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _currentStepIndex == widget.steps.length - 1
                                          ? 'Finish'
                                          : 'Next',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      _currentStepIndex == widget.steps.length - 1
                                          ? Icons.check
                                          : Icons.arrow_forward,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class SpotlightPainter extends CustomPainter {
  final Rect? targetRect;
  final double pulseValue;

  SpotlightPainter({
    required this.targetRect,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Save canvas layer
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    // 2. Draw standard dark transparent background sheet
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.black.withOpacity(0.72),
    );

    // 3. Apply rounded-rectangle cutout at the target bounds
    if (targetRect != null) {
      final Paint clearPaint = Paint()
        ..blendMode = BlendMode.dstOut
        ..color = Colors.white;

      // Inflate bounds slightly for comfortable visual padding around the widget
      final double padding = 8.0 + (3.0 * (1.0 - pulseValue)); // Pulsing breathing effect
      final Rect paddedRect = targetRect!.inflate(padding);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          paddedRect,
          const Radius.circular(16),
        ),
        clearPaint,
      );
    }

    // 4. Restore canvas layer
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SpotlightPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect || oldDelegate.pulseValue != pulseValue;
  }
}
