// lib/features/dashboard/screens/aesthetics_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:ShEC_CSE/features/dashboard/presentation/widgets/ambient_background.dart';
import 'package:ShEC_CSE/core/services/theme_service.dart';
import 'package:ShEC_CSE/core/services/tour_service.dart';
import 'package:ShEC_CSE/features/dashboard/presentation/widgets/guided_tour_overlay.dart';

class AestheticsSettingsScreen extends StatefulWidget {
  const AestheticsSettingsScreen({super.key});

  @override
  State<AestheticsSettingsScreen> createState() => _AestheticsSettingsScreenState();
}

class _AestheticsSettingsScreenState extends State<AestheticsSettingsScreen> {
  // Local isolated state variables
  late bool _localEnabled;
  late int _localDensity;
  late double _localSpeed;
  late String _localStyle;
  late AppColorTheme _localColorTheme;
  late AppThemeMode _localThemeMode;
  late int _localCustomColorValue;

  final GlobalKey _previewCardKey = GlobalKey();
  final GlobalKey _ambientSwitchKey = GlobalKey();
  final GlobalKey _styleSelectorKey = GlobalKey();
  final GlobalKey _colorGridKey = GlobalKey();
  final GlobalKey _saveButtonKey = GlobalKey();
  bool _showTour = false;

  // HSL Color Pick state
  late double _hueValue; // Hue value ranges from 0.0 to 360.0 degrees

  @override
  void initState() {
    super.initState();
    final themeService = ThemeService.instance;

    // Load initial states from global persistent settings
    _localEnabled = ambientBackgroundEnabled.value;
    _localDensity = ambientSparkleDensity.value;
    _localSpeed = ambientAnimationSpeed.value;
    _localStyle = ambientStyle.value;
    _localColorTheme = themeService.colorTheme;
    _localThemeMode = themeService.themeMode;
    _localCustomColorValue = themeService.customColorValue;

    // Derive HSL Hue value from saved custom hex color
    final Color currentCustomColor = Color(_localCustomColorValue);
    final HSVColor hsv = HSVColor.fromColor(currentCustomColor);
    _hueValue = hsv.hue;

    TourService.instance.hasCompletedScreenTour('aesthetics_settings').then((completed) {
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

  // Generate a local ColorScheme representation to pass into the mockup preview card
  ColorScheme _getLocalColorScheme() {
    Color primaryColor;
    switch (_localColorTheme) {
      case AppColorTheme.teal:
        primaryColor = const Color(0xFF00ADB5);
        break;
      case AppColorTheme.blue:
        primaryColor = const Color(0xFF1E88E5);
        break;
      case AppColorTheme.purple:
        primaryColor = const Color(0xFF8E24AA);
        break;
      case AppColorTheme.green:
        primaryColor = const Color(0xFF43A047);
        break;
      case AppColorTheme.amber:
        primaryColor = const Color(0xFFFFB300);
        break;
      case AppColorTheme.crimson:
        primaryColor = const Color(0xFFE53935);
        break;
      case AppColorTheme.custom:
        primaryColor = Color(_localCustomColorValue);
        break;
    }

    final isDark = _localThemeMode == AppThemeMode.dark ||
        _localThemeMode == AppThemeMode.night ||
        (_localThemeMode == AppThemeMode.system &&
            Theme.of(context).brightness == Brightness.dark);

    return ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: primaryColor,
    );
  }

  void _updateCustomColorFromHue() {
    setState(() {
      // Saturation: 0.85, Value: 0.95 keeps picked colors vibrant, rich and highly visible
      _localCustomColorValue = HSVColor.fromAHSV(1.0, _hueValue, 0.85, 0.95).toColor().value;
    });
  }

  void _applySettingsGlobally() {
    final themeService = ThemeService.instance;

    // Commit isolated variables to globalValueNotifiers (instantly updates background stack)
    ambientBackgroundEnabled.value = _localEnabled;
    ambientSparkleDensity.value = _localDensity;
    ambientAnimationSpeed.value = _localSpeed;
    ambientStyle.value = _localStyle;

    // Commit dynamic ThemeService settings (propagates to MaterialApp builder)
    themeService.setThemeMode(_localThemeMode);
    themeService.setColorTheme(_localColorTheme);
    themeService.setCustomColorValue(_localCustomColorValue);

    // Show high-end verification toast
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 12),
            Text(
              'Aesthetic settings applied globally!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(20),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final currentThemeScheme = Theme.of(context).colorScheme;
    final ColorScheme previewScheme = _getLocalColorScheme();

    return Stack(
      children: [
        AmbientTimeBackground(
          overrideEnabled: _localEnabled,
          overrideSpeed: _localSpeed,
          overrideDensity: _localDensity,
          overrideStyle: _localStyle,
          overrideColorScheme: previewScheme,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: const Text(
                'Aesthetics & Themes',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            body: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Live Preview Panel (decopled - reads only local _local variables)
                        _buildLivePreviewCard(previewScheme),
                        const SizedBox(height: 20),
    
                        // 2. Ambient Background Switch Control
                        _buildGlassCard(
                          key: _ambientSwitchKey,
                          child: SwitchListTile(
                            activeColor: previewScheme.primary,
                            title: Row(
                              children: [
                                Icon(Icons.auto_awesome, color: previewScheme.primary),
                                const SizedBox(width: 12),
                                const Text(
                                  'Ambient Background',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            subtitle: const Padding(
                              padding: EdgeInsets.only(top: 4.0),
                              child: Text(
                                'Enable live, time-based drifting aurora meshes, soft blurs, and sparkling particles. Disabling this is helpful for battery savings or solid readability.',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            value: _localEnabled,
                            onChanged: (val) {
                              setState(() => _localEnabled = val);
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
    
                        // 3. Aesthetic Styles Selector ( Aurora, Cyberpunk, Cosmic, Ocean, Autumn )
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 250),
                          opacity: _localEnabled ? 1.0 : 0.4,
                          child: AbsorbPointer(
                            absorbing: !_localEnabled,
                            child: _buildGlassCard(
                              key: _styleSelectorKey,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'AESTHETIC STYLE',
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
                        const SizedBox(height: 16),
    
                        // 4. Ambient Sliders (Density and Speed) - decoupled
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 250),
                          opacity: _localEnabled ? 1.0 : 0.4,
                          child: AbsorbPointer(
                            absorbing: !_localEnabled,
                            child: _buildGlassCard(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ANIMATION PREFERENCES',
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
                                        Text('$_localDensity particles',
                                            style: TextStyle(color: previewScheme.primary, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    Slider(
                                      value: _localDensity.toDouble(),
                                      min: 10.0,
                                      max: 150.0,
                                      divisions: 14,
                                      activeColor: previewScheme.primary,
                                      inactiveColor: previewScheme.primary.withOpacity(0.2),
                                      onChanged: (val) {
                                        setState(() => _localDensity = val.toInt());
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    // Speed Slider
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Drift Speed', style: TextStyle(fontWeight: FontWeight.bold)),
                                        Text('${_localSpeed.toStringAsFixed(1)}x',
                                            style: TextStyle(color: previewScheme.primary, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    Slider(
                                      value: _localSpeed,
                                      min: 0.2,
                                      max: 3.0,
                                      divisions: 28,
                                      activeColor: previewScheme.primary,
                                      inactiveColor: previewScheme.primary.withOpacity(0.2),
                                      onChanged: (val) {
                                        setState(() => _localSpeed = val);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
    
                        // 5. Theme Selection (Theme Mode Grid) - decoupled
                        _buildGlassCard(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'THEME MODE',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                    color: previewScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    _buildThemeModeItem(AppThemeMode.system, 'System', Icons.brightness_auto, previewScheme),
                                    const SizedBox(width: 8),
                                    _buildThemeModeItem(AppThemeMode.light, 'Light', Icons.light_mode, previewScheme),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _buildThemeModeItem(AppThemeMode.dark, 'Dark', Icons.dark_mode, previewScheme),
                                    const SizedBox(width: 8),
                                    _buildThemeModeItem(AppThemeMode.night, 'Night', Icons.nights_stay, previewScheme),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
    
                        // 6. Color Scheme Palette Selector - decoupled
                        _buildGlassCard(
                          key: _colorGridKey,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'COLOR SCHEME',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                    color: previewScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildColorGrid(previewScheme),
                                
                                // Rainbow HSL custom color picker (displays if _localColorTheme is custom)
                                if (_localColorTheme == AppColorTheme.custom) ...[
                                  const Divider(height: 32),
                                  _buildCustomColorPicker(previewScheme),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
                
                // Fixed bottom Apply Settings panel
                _buildBottomActionBar(currentThemeScheme, previewScheme),
              ],
            ),
          ),
        ),
        if (_showTour)
          GuidedTourOverlay(
            steps: [
              TourStep(
                targetKey: _previewCardKey,
                title: 'Aesthetics Preview Canvas',
                description: 'This interactive canvas immediately previews your custom style, color selections, sparkle density, and animation speeds in real-time.',
              ),
              TourStep(
                targetKey: _ambientSwitchKey,
                title: 'Ambient Toggle',
                description: 'Toggle this switch to turn off the drifting animations completely for a clean look and maximum battery savings.',
              ),
              TourStep(
                targetKey: _styleSelectorKey,
                title: 'Drift Styles',
                description: 'Pick between premium visual engines: Time-based Aurora, cyberpunk grids, starry nebulae, gentle waves, or autumn leaf diamond falls.',
              ),
              TourStep(
                targetKey: _colorGridKey,
                title: 'Dynamic Palette Seeds',
                description: 'Select a theme color scheme or seed a vibrant HSL customized color directly from the custom picker wheel.',
              ),
              TourStep(
                targetKey: _saveButtonKey,
                title: 'Commit Aesthetics Globally',
                description: 'Satisfied with your styling adjustments? Tapping Apply immediately saves and deploys your custom configurations globally across the entire app.',
              ),
            ],
            onComplete: () {
              setState(() => _showTour = false);
              TourService.instance.completeScreenTour('aesthetics_settings');
            },
            onSkip: () {
              setState(() => _showTour = false);
              TourService.instance.completeScreenTour('aesthetics_settings');
            },
          ),
      ],
    );
  }

  Widget _buildGlassCard({Key? key, required Widget child}) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      key: key,
      elevation: 0,
      color: colors.surfaceContainer.withOpacity(0.7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.outline.withOpacity(0.1)),
      ),
      child: child,
    );
  }

  Widget _buildLivePreviewCard(ColorScheme previewScheme) {
    return Container(
      key: _previewCardKey,
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: previewScheme.primary.withOpacity(0.6),
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: previewScheme.primary.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          )
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Decoupled preview background - loads local override parameters in real-time
          Positioned.fill(
            child: AmbientTimeBackground(
              overrideEnabled: _localEnabled,
              overrideSpeed: _localSpeed,
              overrideDensity: _localDensity,
              overrideStyle: _localStyle,
              overrideColorScheme: previewScheme,
              child: const SizedBox.expand(),
            ),
          ),

          // High-end glassmorphic information card overlay
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: previewScheme.surfaceContainer.withOpacity(0.8),
                child: Row(
                  children: [
                    Icon(
                      _localEnabled ? Icons.auto_awesome : Icons.do_not_disturb_on,
                      color: _localEnabled ? previewScheme.primary : Colors.grey,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _localEnabled
                                ? 'Live Preview Canvas'
                                : 'Background Disabled',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: previewScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _localEnabled
                                ? 'Style: ${_getStyleTitle(_localStyle)} • Speed: ${_localSpeed.toStringAsFixed(1)}x'
                                : 'Saving performance with flat base colors.',
                            style: TextStyle(
                              fontSize: 10,
                              color: previewScheme.onSurfaceVariant.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: previewScheme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'PREVIEW',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: previewScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleSelectionGrid(ColorScheme previewScheme) {
    final stylesList = [
      {'id': 'aurora', 'title': 'Time Aurora', 'desc': 'Time-based gradients & rising sparkles', 'icon': Icons.auto_awesome},
      {'id': 'cyberpunk', 'title': 'Cyber Neon', 'desc': 'Digital code grids & horizontal tracks', 'icon': Icons.terminal},
      {'id': 'cosmic', 'title': 'Cosmic Space', 'desc': 'Deep purple nebula & expanding stars', 'icon': Icons.brightness_3},
      {'id': 'ocean', 'title': 'Ocean Calm', 'desc': 'Soothing wavy teals & floating bubble rings', 'icon': Icons.water},
      {'id': 'autumn', 'title': 'Autumn Leaf', 'desc': 'Warm copper forest & falling leaf diamonds', 'icon': Icons.nature},
    ];

    return Column(
      children: stylesList.map((st) {
        final isSelected = _localStyle == st['id'];
        return GestureDetector(
          onTap: () {
            setState(() {
              _localStyle = st['id'] as String;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8.0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? previewScheme.primary.withOpacity(0.08) : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? previewScheme.primary : previewScheme.outline.withOpacity(0.1),
                width: isSelected ? 2.0 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  st['icon'] as IconData,
                  color: isSelected ? previewScheme.primary : previewScheme.onSurface.withOpacity(0.6),
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
                          color: previewScheme.onSurfaceVariant.withOpacity(0.7),
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

  Widget _buildColorGrid(ColorScheme previewScheme) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 2.1,
      ),
      itemCount: AppColorTheme.values.length,
      itemBuilder: (context, index) {
        final colorTheme = AppColorTheme.values[index];
        final isSelected = _localColorTheme == colorTheme;

        Color primaryVal;
        String title;
        switch (colorTheme) {
          case AppColorTheme.teal:
            primaryVal = const Color(0xFF00ADB5);
            title = 'Teal';
            break;
          case AppColorTheme.blue:
            primaryVal = const Color(0xFF1E88E5);
            title = 'Ocean Blue';
            break;
          case AppColorTheme.purple:
            primaryVal = const Color(0xFF8E24AA);
            title = 'Cosmic';
            break;
          case AppColorTheme.green:
            primaryVal = const Color(0xFF43A047);
            title = 'Emerald';
            break;
          case AppColorTheme.amber:
            primaryVal = const Color(0xFFFFB300);
            title = 'Amber';
            break;
          case AppColorTheme.crimson:
            primaryVal = const Color(0xFFE53935);
            title = 'Crimson';
            break;
          case AppColorTheme.custom:
            primaryVal = Color(_localCustomColorValue);
            title = 'Custom';
            break;
        }

        return InkWell(
          onTap: () {
            setState(() {
              _localColorTheme = colorTheme;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: primaryVal.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? primaryVal : previewScheme.outline.withOpacity(0.1),
                width: isSelected ? 2.0 : 1.0,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (colorTheme == AppColorTheme.custom)
                  // Sleek rainbow custom indicator
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                      gradient: const SweepGradient(
                        colors: [Colors.red, Colors.yellow, Colors.green, Colors.blue, Colors.purple, Colors.red],
                      ),
                    ),
                  )
                else
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: primaryVal,
                      shape: BoxShape.circle,
                    ),
                  ),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? primaryVal : previewScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomColorPicker(ColorScheme previewScheme) {
    // Custom presets list inside picker card
    final customSwatches = [
      {'color': const Color(0xFFFFC107), 'hue': 45.0},  // Vibrant Gold
      {'color': const Color(0xFFFF007F), 'hue': 330.0}, // Electric Pink
      {'color': const Color(0xFF39FF14), 'hue': 111.0}, // Neon Green
      {'color': const Color(0xFF00E5FF), 'hue': 187.0}, // Sky Blue
      {'color': const Color(0xFFD783FF), 'hue': 280.0}, // Cosmic Lavender
      {'color': const Color(0xFFFF5722), 'hue': 14.0},  // Fire Orange
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.palette, size: 16),
            SizedBox(width: 8),
            Text(
              'CUSTOM RAINBOW PICKER',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // HSL rainbow gradient track representing Hue
        Container(
          height: 16,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: const LinearGradient(
              colors: [
                Colors.red,
                Colors.orange,
                Colors.yellow,
                Colors.green,
                Colors.blue,
                Colors.indigo,
                Colors.purple,
                Colors.red,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
          ),
        ),

        // Hue Slider overlay
        Slider(
          value: _hueValue,
          min: 0.0,
          max: 360.0,
          activeColor: Color(_localCustomColorValue),
          inactiveColor: Colors.transparent,
          onChanged: (val) {
            setState(() {
              _hueValue = val;
              _updateCustomColorFromHue();
            });
          },
        ),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Hue Angle', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            Text('${_hueValue.toStringAsFixed(0)}°',
                style: TextStyle(color: Color(_localCustomColorValue), fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 16),

        const Text('Quick Swatches', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        
        // Horizontal preset swatches selection row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: customSwatches.map((sw) {
            final swatchColor = sw['color'] as Color;
            final isSelected = Color(_localCustomColorValue).value == swatchColor.value ||
                               (_hueValue - (sw['hue'] as double)).abs() < 5.0;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _hueValue = sw['hue'] as double;
                  _localCustomColorValue = swatchColor.value;
                });
              },
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: swatchColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? previewScheme.onSurface : Colors.transparent,
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: swatchColor.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildThemeModeItem(AppThemeMode mode, String label, IconData icon, ColorScheme previewScheme) {
    final isSelected = _localThemeMode == mode;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _localThemeMode = mode;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? previewScheme.primary : previewScheme.surfaceContainer.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? previewScheme.primary : previewScheme.outline.withOpacity(0.08),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : previewScheme.onSurface.withOpacity(0.7),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : previewScheme.onSurface.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActionBar(ColorScheme currentScheme, ColorScheme previewScheme) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: currentScheme.surface,
        border: Border(top: BorderSide(color: currentScheme.outline.withOpacity(0.08))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, -3),
          )
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: currentScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                key: _saveButtonKey,
                onPressed: _applySettingsGlobally,
                style: ElevatedButton.styleFrom(
                  backgroundColor: previewScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: const Text(
                  'Apply Settings',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStyleTitle(String styleId) {
    switch (styleId) {
      case 'aurora':
        return 'Aurora';
      case 'cyberpunk':
        return 'Cyber Neon';
      case 'cosmic':
        return 'Cosmic Space';
      case 'ocean':
        return 'Ocean';
      case 'autumn':
        return 'Autumn';
      default:
        return 'Default';
    }
  }
}
