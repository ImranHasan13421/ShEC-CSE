import 'package:flutter/material.dart';

class VisualsTab extends StatelessWidget {
  final GlobalKey ambientSwitchKey;
  final GlobalKey styleSelectorKey;
  final bool localEnabled;
  final int localDensity;
  final double localSpeed;
  final bool localAuroraEnabled;
  final String localStyle;
  final ColorScheme previewScheme;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<int> onDensityChanged;
  final ValueChanged<double> onSpeedChanged;
  final ValueChanged<bool> onAuroraEnabledChanged;
  final ValueChanged<String> onStyleChanged;
  final VoidCallback onTimeTableDialogRequested;

  const VisualsTab({
    super.key,
    required this.ambientSwitchKey,
    required this.styleSelectorKey,
    required this.localEnabled,
    required this.localDensity,
    required this.localSpeed,
    required this.localAuroraEnabled,
    required this.localStyle,
    required this.previewScheme,
    required this.onEnabledChanged,
    required this.onDensityChanged,
    required this.onSpeedChanged,
    required this.onAuroraEnabledChanged,
    required this.onStyleChanged,
    required this.onTimeTableDialogRequested,
  });

  @override
  Widget build(BuildContext context) {
    final isPreviewLight = previewScheme.brightness == Brightness.light;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Twinkling Sparkles Switch
          _buildGlassCard(
            context: context,
            key: ambientSwitchKey,
            child: SwitchListTile(
              activeColor: previewScheme.primary,
              title: Row(
                children: [
                  Icon(Icons.star_border, color: previewScheme.primary),
                  const SizedBox(width: 12),
                  const Text(
                    'Twinkling Sparkles',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              subtitle: const Padding(
                padding: EdgeInsets.only(top: 4.0),
                child: Text(
                  'Enable twinkling star sparkles and floating motes. Can be combined with dynamic auroras or custom wallpapers.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              value: localEnabled,
              onChanged: onEnabledChanged,
            ),
          ),
          const SizedBox(height: 16),

          // Ambient Sparkle Sliders (Only active if Twinkling Sparkles is on)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: localEnabled ? 1.0 : 0.4,
            child: AbsorbPointer(
              absorbing: !localEnabled,
              child: _buildGlassCard(
                context: context,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SPARKLE PREFERENCES',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: previewScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Density Slider
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Sparkle Density', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('$localDensity particles',
                              style: TextStyle(color: previewScheme.primary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Slider(
                        value: localDensity.toDouble(),
                        min: 10.0,
                        max: 150.0,
                        divisions: 14,
                        activeColor: previewScheme.primary,
                        inactiveColor: previewScheme.primary.withValues(alpha: 0.2),
                        onChanged: (val) => onDensityChanged(val.toInt()),
                      ),
                      const SizedBox(height: 12),
                      // Speed Slider
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Drift Speed', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('${localSpeed.toStringAsFixed(1)}x',
                              style: TextStyle(color: previewScheme.primary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Slider(
                        value: localSpeed,
                        min: 0.2,
                        max: 3.0,
                        divisions: 28,
                        activeColor: previewScheme.primary,
                        inactiveColor: previewScheme.primary.withValues(alpha: 0.2),
                        onChanged: onSpeedChanged,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Aesthetic Mesh Auroras Switch
          _buildGlassCard(
            context: context,
            child: SwitchListTile(
              activeColor: previewScheme.primary,
              title: Row(
                children: [
                  Icon(Icons.bubble_chart, color: isPreviewLight ? previewScheme.primary.withValues(alpha: 0.5) : previewScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Aesthetic Mesh Auroras',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isPreviewLight ? previewScheme.onSurface.withValues(alpha: 0.5) : null,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: isPreviewLight ? null : onTimeTableDialogRequested,
                    child: Icon(
                      Icons.info_outline,
                      size: 16,
                      color: isPreviewLight ? previewScheme.primary.withValues(alpha: 0.5) : previewScheme.primary,
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  isPreviewLight
                      ? 'Mesh Auroras are turned off in Light Mode to ensure contrast and visual clarity.'
                      : 'Enable beautifully drifting background color blobs based on current time. Disabling this displays a flat gradient background or static wallpaper.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isPreviewLight ? previewScheme.onSurfaceVariant.withValues(alpha: 0.6) : null,
                  ),
                ),
              ),
              value: isPreviewLight ? false : localAuroraEnabled,
              onChanged: isPreviewLight ? null : onAuroraEnabledChanged,
            ),
          ),
          const SizedBox(height: 16),
      
          // Aesthetic Styles Selector (Only enabled if Aesthetic Mesh Auroras is active and not in light mode)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: localAuroraEnabled && !isPreviewLight ? 1.0 : 0.4,
            child: AbsorbPointer(
              absorbing: !localAuroraEnabled || isPreviewLight,
              child: _buildGlassCard(
                context: context,
                key: styleSelectorKey,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AESTHETIC AURORA STYLE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: previewScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildStyleSelectionGrid(previewScheme),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({required BuildContext context, Key? key, required Widget child}) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      key: key,
      elevation: isDark ? 0 : 2,
      color: isDark ? colors.surfaceContainer.withValues(alpha: 0.7) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.outline.withValues(alpha: isDark ? 0.1 : 0.2)),
      ),
      child: child,
    );
  }

  Widget _buildStyleSelectionGrid(ColorScheme previewScheme) {
    final stylesList = [
      {'id': 'shec', 'title': 'ShEC CSE', 'desc': 'College brand-color sparkles and floating digital code', 'icon': Icons.school},
      {'id': 'aurora', 'title': 'Time Aurora', 'desc': 'Time-based gradients & rising sparkles', 'icon': Icons.auto_awesome},
      {'id': 'cyberpunk', 'title': 'Cyber Neon', 'desc': 'Digital code grids & horizontal tracks', 'icon': Icons.terminal},
      {'id': 'cosmic', 'title': 'Cosmic Space', 'desc': 'Deep purple nebula & expanding stars', 'icon': Icons.brightness_3},
      {'id': 'ocean', 'title': 'Ocean Calm', 'desc': 'Soothing wavy teals & floating bubble rings', 'icon': Icons.water},
      {'id': 'autumn', 'title': 'Autumn Leaf', 'desc': 'Warm copper forest & falling leaf diamonds', 'icon': Icons.nature},
    ];

    return Column(
      children: stylesList.map((st) {
        final isSelected = localStyle == st['id'];
        return GestureDetector(
          onTap: () => onStyleChanged(st['id'] as String),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8.0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? previewScheme.primary.withValues(alpha: 0.08) : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? previewScheme.primary : previewScheme.outline.withValues(alpha: 0.1),
                width: isSelected ? 2.0 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  st['icon'] as IconData,
                  color: isSelected ? previewScheme.primary : previewScheme.onSurface.withValues(alpha: 0.6),
                  size: 24,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        st['title'] as String,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isSelected ? previewScheme.primary : previewScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        st['desc'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          color: previewScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: previewScheme.primary, size: 20),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
