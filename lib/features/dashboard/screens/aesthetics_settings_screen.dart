import 'package:flutter/material.dart';
import 'package:ShEC_CSE/features/dashboard/presentation/widgets/ambient_background.dart';
import 'package:ShEC_CSE/core/services/theme_service.dart';
import 'package:ShEC_CSE/core/services/tour_service.dart';
import 'package:ShEC_CSE/features/dashboard/presentation/widgets/guided_tour_overlay.dart';
import 'aesthetics/widgets/live_preview_card.dart';
import 'aesthetics/widgets/aesthetics_dialogs.dart';
import 'aesthetics/tabs/colors_tab.dart';
import 'aesthetics/tabs/visuals_tab.dart';
import 'aesthetics/tabs/canvas_tab.dart';

class AestheticsSettingsScreen extends StatefulWidget {
  const AestheticsSettingsScreen({super.key});

  @override
  State<AestheticsSettingsScreen> createState() => _AestheticsSettingsScreenState();
}

class _AestheticsSettingsScreenState extends State<AestheticsSettingsScreen> with TickerProviderStateMixin {
  late bool _localEnabled;
  late int _localDensity;
  late double _localSpeed;
  late String _localStyle;
  late bool _localAuroraEnabled;
  late String _localPattern;
  late String _localWallpaper;
  late bool _localWallpaperEnabled;
  late double _localWallpaperDensity;
  late AppColorTheme _localColorTheme;
  late AppThemeMode _localThemeMode;
  late int _localCustomColorValue;
  late TabController _tabController;

  final GlobalKey _previewCardKey = GlobalKey();
  final GlobalKey _themeModeKey = GlobalKey();
  final GlobalKey _colorGridKey = GlobalKey();
  final GlobalKey _ambientSwitchKey = GlobalKey();
  final GlobalKey _styleSelectorKey = GlobalKey();
  final GlobalKey _canvasElementsKey = GlobalKey();
  final GlobalKey _saveButtonKey = GlobalKey();
  bool _showTour = false;

  // HSL Color Pick state
  late double _hueValue; // Hue value ranges from 0.0 to 360.0 degrees

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final themeService = ThemeService.instance;

    _localEnabled = ambientBackgroundEnabled.value;
    _localDensity = ambientSparkleDensity.value;
    _localSpeed = ambientAnimationSpeed.value;
    _localStyle = ambientStyle.value;
    _localAuroraEnabled = ambientAuroraEnabled.value;
    _localPattern = ambientPattern.value;
    _localWallpaper = ambientWallpaper.value;
    _localWallpaperEnabled = ambientWallpaperEnabled.value;
    _localWallpaperDensity = ambientWallpaperDensity.value;
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

    ambientBackgroundEnabled.value = _localEnabled;
    ambientSparkleDensity.value = _localDensity;
    ambientAnimationSpeed.value = _localSpeed;
    ambientStyle.value = _localStyle;
    ambientAuroraEnabled.value = _localAuroraEnabled;
    ambientPattern.value = _localPattern;
    ambientWallpaper.value = _localWallpaper;
    ambientWallpaperEnabled.value = _localWallpaperEnabled;
    ambientWallpaperDensity.value = _localWallpaperDensity;

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
          overridePattern: _localPattern,
          overrideAuroraEnabled: _localAuroraEnabled,
          overrideWallpaper: _localWallpaper,
          overrideWallpaperEnabled: _localWallpaperEnabled,
          overrideWallpaperDensity: _localWallpaperDensity,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              elevation: 0,
              title: const Text(
                'Aesthetics & Themes',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            body: Column(
              children: [
                // 1. Sticky Real-Time Preview Canvas (Always visible at the top!)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  child: LivePreviewCard(
                    previewCardKey: _previewCardKey,
                    previewScheme: previewScheme,
                    localEnabled: _localEnabled,
                    localSpeed: _localSpeed,
                    localDensity: _localDensity,
                    localStyle: _localStyle,
                    localAuroraEnabled: _localAuroraEnabled,
                    localPattern: _localPattern,
                    localWallpaper: _localWallpaper,
                    localWallpaperEnabled: _localWallpaperEnabled,
                    getStyleTitle: _getStyleTitle,
                  ),
                ),

                // 2. Custom Premium Sliding TabBar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
                  decoration: BoxDecoration(
                    color: currentThemeScheme.surfaceContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: currentThemeScheme.outline.withValues(alpha: 0.08)),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: previewScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: currentThemeScheme.onSurface.withValues(alpha: 0.6),
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.palette_outlined, size: 18),
                        text: 'Colors',
                      ),
                      Tab(
                        icon: Icon(Icons.auto_awesome_outlined, size: 18),
                        text: 'Visuals',
                      ),
                      Tab(
                        icon: Icon(Icons.wallpaper_outlined, size: 18),
                        text: 'Canvas',
                      ),
                    ],
                  ),
                ),

                // 3. Segmented Tab Contents
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // TAB 1: COLORS & MODES
                      ColorsTab(
                        themeModeKey: _themeModeKey,
                        colorGridKey: _colorGridKey,
                        localThemeMode: _localThemeMode,
                        localColorTheme: _localColorTheme,
                        localCustomColorValue: _localCustomColorValue,
                        hueValue: _hueValue,
                        previewScheme: previewScheme,
                        onThemeModeChanged: (val) {
                          setState(() => _localThemeMode = val);
                        },
                        onColorThemeChanged: (val) {
                          setState(() => _localColorTheme = val);
                        },
                        onHueValueChanged: (val) {
                          setState(() {
                            _hueValue = val;
                            _updateCustomColorFromHue();
                          });
                        },
                        onCustomColorSwatchSelected: (colorVal, hueVal) {
                          setState(() {
                            _localCustomColorValue = colorVal;
                            _hueValue = hueVal;
                          });
                        },
                      ),

                      // TAB 2: ANIMATIONS & SLIDERS
                      VisualsTab(
                        ambientSwitchKey: _ambientSwitchKey,
                        styleSelectorKey: _styleSelectorKey,
                        localEnabled: _localEnabled,
                        localDensity: _localDensity,
                        localSpeed: _localSpeed,
                        localAuroraEnabled: _localAuroraEnabled,
                        localStyle: _localStyle,
                        previewScheme: previewScheme,
                        onEnabledChanged: (val) {
                          setState(() => _localEnabled = val);
                        },
                        onDensityChanged: (val) {
                          setState(() => _localDensity = val);
                        },
                        onSpeedChanged: (val) {
                          setState(() => _localSpeed = val);
                        },
                        onAuroraEnabledChanged: (val) {
                          setState(() => _localAuroraEnabled = val);
                        },
                        onStyleChanged: (val) {
                          setState(() => _localStyle = val);
                        },
                        onTimeTableDialogRequested: () {
                          showTimeTableDialog(context, previewScheme);
                        },
                      ),

                      // TAB 3: WALLPAPERS & PATTERNS
                      CanvasTab(
                        canvasElementsKey: _canvasElementsKey,
                        localWallpaperEnabled: _localWallpaperEnabled,
                        localWallpaper: _localWallpaper,
                        localPattern: _localPattern,
                        localWallpaperDensity: _localWallpaperDensity,
                        previewScheme: previewScheme,
                        onWallpaperEnabledChanged: (val) {
                          setState(() => _localWallpaperEnabled = val);
                        },
                        onWallpaperChanged: (val) {
                          setState(() => _localWallpaper = val);
                        },
                        onPatternChanged: (val) {
                          setState(() => _localPattern = val);
                        },
                        onWallpaperDensityChanged: (val) {
                          setState(() => _localWallpaperDensity = val);
                        },
                      ),
                    ],
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
                title: '✨ Live Aesthetics Preview',
                description: 'This is your real-time canvas — every change you make to colors, themes, sparkles, wallpapers, and animations is instantly reflected here before applying globally.',
              ),
              TourStep(
                targetKey: _themeModeKey,
                title: '🌙 Choose Your Theme Mode',
                description: 'Pick between System (auto), Light, Dark, or the premium Night mode. Night mode uses a pure black canvas that makes colors pop beautifully on AMOLED screens.',
              ),
              TourStep(
                targetKey: _colorGridKey,
                title: '🎨 Color Palette & Custom Hue',
                description: 'Select a built-in palette — Teal, Ocean Blue, Cosmic Purple, Emerald, Amber or Crimson. Choose Custom to open a rainbow HSL hue wheel and dial in your perfect accent color.',
              ),
              TourStep(
                targetKey: _ambientSwitchKey,
                title: '⭐ Twinkling Sparkles',
                description: 'Toggle floating particle motes that drift across the background. Adjust sparkle density (up to 150 particles) and drift speed from sluggish to blazing fast.',
              ),
              TourStep(
                targetKey: _styleSelectorKey,
                title: '🌌 Aesthetic Aurora Styles',
                description: 'In Dark or Night mode, choose your animated aurora engine: time-adaptive Aurora, electric Cyberpunk grids, deep Cosmic nebulae, calming Ocean waves, or warm Autumn leaf falls.',
              ),
              TourStep(
                targetKey: _canvasElementsKey,
                title: '🖼️ Static Canvas Elements',
                description: 'Layer crisp vector wallpapers (Starry constellations, Geometric shapes, Waves, Tech Blueprint grid) and geometric patterns over your background. Use the density slider to dial in complexity.',
              ),
              TourStep(
                targetKey: _saveButtonKey,
                title: '💾 Apply Settings Globally',
                description: 'Once you are happy with your aesthetic configuration, tap Apply to save and instantly propagate your theme, colors, and visual effects across the entire app.',
              ),
            ],
            onStepChanged: (stepIndex) {
              if (stepIndex == 1 || stepIndex == 2) {
                _tabController.animateTo(0);
              } else if (stepIndex == 3 || stepIndex == 4) {
                _tabController.animateTo(1);
              } else if (stepIndex == 5) {
                _tabController.animateTo(2);
              } else if (stepIndex == 6) {
                _tabController.animateTo(0);
              }
            },
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

  Widget _buildBottomActionBar(ColorScheme currentScheme, ColorScheme previewScheme) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: currentScheme.surface,
        border: Border(top: BorderSide(color: currentScheme.outline.withValues(alpha: 0.08))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                    color: currentScheme.onSurface.withValues(alpha: 0.6),
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
      case 'shec':
        return 'ShEC CSE';
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
