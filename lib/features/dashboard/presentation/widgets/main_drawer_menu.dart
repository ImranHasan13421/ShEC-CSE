import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hidden_drawer_menu/hidden_drawer_menu.dart';
import 'package:ShEC_CSE/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ShEC_CSE/features/auth/presentation/bloc/auth_event.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ShEC_CSE/core/services/theme_service.dart';
import 'package:ShEC_CSE/features/profile/models/profile_state.dart';
import 'package:ShEC_CSE/core/services/tour_service.dart';
import 'package:ShEC_CSE/features/department/presentation/screens/department_screen.dart';
import 'package:ShEC_CSE/features/auth/screens/auth_animated_screen.dart';
import 'package:ShEC_CSE/backend/services/auth_service.dart';
import 'package:ShEC_CSE/backend/services/update_service.dart';
import 'package:ShEC_CSE/backend/services/notification_service.dart';
import 'package:ShEC_CSE/features/jobs/screens/jobs_screen.dart';
import 'package:ShEC_CSE/features/club/screens/club_screen.dart';
import 'package:ShEC_CSE/features/gallery/screens/gallery_screen.dart';
import 'package:ShEC_CSE/features/profile/presentation/screens/profile_screen.dart';
import 'package:ShEC_CSE/features/cgpa_calculator/screens/cgpa_calculator_screen.dart';
import 'package:ShEC_CSE/features/resources/screens/resources_screen.dart';
import 'package:ShEC_CSE/features/results/screens/results_screen.dart';
import 'package:ShEC_CSE/features/department/presentation/screens/teacher_contacts_screen.dart';
import 'package:ShEC_CSE/features/club/screens/club_members_screen.dart';
import 'package:ShEC_CSE/features/about/screens/contributors_screen.dart';
import 'package:ShEC_CSE/features/alumni/screens/alumni_screen.dart';
import 'package:ShEC_CSE/features/accounting/presentation/screens/accounting_dashboard_screen.dart';
import 'package:ShEC_CSE/features/dashboard/screens/aesthetics_settings_screen.dart';
import 'package:ShEC_CSE/features/permissions/screens/committee_permissions_screen.dart';

// ─── Custom Premium Interactive Tree Branch Painter ──────────────────────────

class _BranchLinePainter extends CustomPainter {
  final bool isLast;
  final Color color;

  _BranchLinePainter({required this.isLast, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.5;

    const double startX = 13.0;
    final double midY = size.height / 2;

    // Draw vertical line from top to mid (if last) or bottom (if not last)
    final double endY = isLast ? midY : size.height;
    canvas.drawLine(const Offset(startX, 0.0), Offset(startX, endY), paint);

    // Draw horizontal line from the vertical line to the right
    canvas.drawLine(Offset(startX, midY), Offset(startX + 18.0, midY), paint);

    // Draw a beautiful small node dot at the end of the branch
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(startX + 18.0, midY), 2.0, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _BranchLinePainter oldDelegate) {
    return oldDelegate.isLast != isLast || oldDelegate.color != color;
  }
}

class TreeBranchItem extends StatelessWidget {
  final Widget child;
  final bool isLast;
  final Color lineColor;

  const TreeBranchItem({
    super.key,
    required this.child,
    required this.isLast,
    required this.lineColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BranchLinePainter(isLast: isLast, color: lineColor),
      child: Padding(
        padding: const EdgeInsets.only(left: 24.0),
        child: child,
      ),
    );
  }
}

// ─── Custom Premium Accordion Group Widget ───────────────────────────────────

class DrawerAccordionGroup extends StatefulWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final bool isExpanded;
  final ValueChanged<bool> onToggle;

  const DrawerAccordionGroup({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  State<DrawerAccordionGroup> createState() => _DrawerAccordionGroupState();
}

class _DrawerAccordionGroupState extends State<DrawerAccordionGroup> {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // Dynamic folder icon swapping or filled visual states
    IconData getGroupIcon() {
      if (widget.icon == Icons.school_outlined) {
        return widget.isExpanded ? Icons.school : Icons.school_outlined;
      } else if (widget.icon == Icons.people_outline) {
        return widget.isExpanded ? Icons.people : Icons.people_outline;
      } else if (widget.icon == Icons.account_balance_wallet_outlined) {
        return widget.isExpanded ? Icons.account_balance_wallet : Icons.account_balance_wallet_outlined;
      } else if (widget.icon == Icons.info_outline) {
        return widget.isExpanded ? Icons.info : Icons.info_outline;
      } else if (widget.icon == Icons.settings_outlined) {
        return widget.isExpanded ? Icons.settings : Icons.settings_outlined;
      }
      return widget.isExpanded ? Icons.folder_open_rounded : Icons.folder_rounded;
    }

    final treeChildren = <Widget>[];
    final childrenCount = widget.children.length;
    for (int i = 0; i < childrenCount; i++) {
      treeChildren.add(
        TreeBranchItem(
          isLast: i == childrenCount - 1,
          lineColor: colors.primary.withValues(alpha: 0.35),
          child: widget.children[i],
        ),
      );
    }

    return Column(
      children: [
        ListTile(
          onTap: () => widget.onToggle(!widget.isExpanded),
          leading: Icon(
            getGroupIcon(), 
            color: widget.isExpanded 
                ? colors.primary.withValues(alpha: 0.95) 
                : Colors.white.withValues(alpha: 0.85), 
            size: 22
          ),
          title: Text(
            widget.title,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: widget.isExpanded ? FontWeight.bold : FontWeight.w700,
              color: widget.isExpanded ? Colors.white : Colors.white.withValues(alpha: 0.85),
            ),
          ),
          trailing: AnimatedRotation(
            turns: widget.isExpanded ? 0.5 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              Icons.expand_more, 
              color: widget.isExpanded ? colors.primary.withValues(alpha: 0.8) : Colors.white60, 
              size: 18
            ),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          tileColor: widget.isExpanded ? colors.primary.withValues(alpha: 0.08) : Colors.transparent,
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: widget.isExpanded
              ? Padding(
                  padding: const EdgeInsets.only(left: 14.0),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: widget.isExpanded ? 1.0 : 0.0,
                    child: Column(children: treeChildren),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ─── Main Drawer Menu ─────────────────────────────────────────────────────────

class MainDrawerMenu extends StatefulWidget {
  final ColorScheme colors;

  const MainDrawerMenu({super.key, required this.colors});

  // Global static method so we can easily trigger it from anywhere (e.g. main_screen)
  static void showUpdateDialog(BuildContext parentContext, {bool force = false}) {
    final colors = Theme.of(parentContext).colorScheme;
    final updateService = UpdateService.instance;

    showDialog(
      context: parentContext,
      barrierDismissible: !force,
      builder: (dialogContext) {
        final versionController = TextEditingController(text: '1.0.1');
        final buildController = TextEditingController(text: '${UpdateService.currentBuildNumber + 1}');
        final urlController = TextEditingController();
        final notesController = TextEditingController();
        bool isPublishTab = false;
        bool isActionLoading = false;
        bool isMajorSelected = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isSuperUser = currentProfile.value.role == UserRole.superUser;

            Widget dialogBody = Dialog(
              backgroundColor: colors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: MediaQuery.of(context).size.width * 0.85,
                padding: const EdgeInsets.all(20.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.system_update_outlined, color: colors.primary, size: 24),
                          const SizedBox(width: 10),
                          const Text(
                            'App Update',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          if (!force)
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () => Navigator.pop(context),
                            ),
                        ],
                      ),
                      const Divider(thickness: 0.5),
                      const SizedBox(height: 10),

                      if (isSuperUser && !force) ...[
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => setDialogState(() => isPublishTab = false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: !isPublishTab ? colors.primary : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    'Check Update',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: !isPublishTab ? colors.primary : colors.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: () => setDialogState(() => isPublishTab = true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: isPublishTab ? colors.primary : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    'Publish Update',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isPublishTab ? colors.primary : colors.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                      ],

                      if (isPublishTab && isSuperUser && !force) ...[
                        _buildInputField(colors, 'Version Name', versionController, 'e.g. 1.0.1'),
                        const SizedBox(height: 10),
                        _buildInputField(colors, 'Build Number', buildController, 'e.g. 2', isNumber: true),
                        const SizedBox(height: 10),
                        _buildInputField(colors, 'APK Download URL', urlController, 'e.g. https://...'),
                        const SizedBox(height: 10),
                        _buildInputField(colors, 'Release Notes', notesController, 'What\'s new in this build...', maxLines: 3),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            const Text('Mark as Major Update', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const Spacer(),
                            Switch.adaptive(
                              value: isMajorSelected,
                              activeColor: colors.primary,
                              onChanged: (val) => setDialogState(() => isMajorSelected = val),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: isActionLoading
                              ? null
                              : () async {
                                  final version = versionController.text.trim();
                                  final buildStr = buildController.text.trim();
                                  final url = urlController.text.trim();
                                  final notes = notesController.text.trim();

                                  if (version.isEmpty || buildStr.isEmpty || url.isEmpty) {
                                    ScaffoldMessenger.of(parentContext).showSnackBar(
                                      const SnackBar(content: Text('Please fill out all required fields.')),
                                    );
                                    return;
                                  }

                                  final buildNum = int.tryParse(buildStr);
                                  if (buildNum == null) {
                                    ScaffoldMessenger.of(parentContext).showSnackBar(
                                      const SnackBar(content: Text('Build number must be a valid integer.')),
                                    );
                                    return;
                                  }

                                  setDialogState(() => isActionLoading = true);
                                  try {
                                    await updateService.uploadNewVersion(
                                      version: version,
                                      buildNumber: buildNum,
                                      downloadUrl: url,
                                      releaseNotes: notes,
                                      isMajor: isMajorSelected,
                                    );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(parentContext).showSnackBar(
                                        const SnackBar(content: Text('New version published successfully!')),
                                      );
                                      Navigator.pop(context);
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(parentContext).showSnackBar(
                                        SnackBar(content: Text('Error: $e')),
                                      );
                                    }
                                  } finally {
                                    setDialogState(() => isActionLoading = false);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 45),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: isActionLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text('Publish Build', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ] else ...[
                        ListenableBuilder(
                          listenable: updateService,
                          builder: (context, _) {
                            final hasUpdate = updateService.hasUpdate;
                            final isLoading = updateService.isLoading;

                            if (isLoading) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 40),
                                child: CircularProgressIndicator(),
                              );
                            }

                            if (hasUpdate) {
                              return Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: colors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.stars, color: colors.primary, size: 28),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                force ? 'Critical Update Required!' : 'New Version Available!',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: colors.primary,
                                                ),
                                              ),
                                              Text(
                                                'Version ${updateService.latestVersion} (Build ${updateService.latestBuildNumber})',
                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  if (updateService.releaseNotes.isNotEmpty) ...[
                                    const Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Release Notes:',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: colors.onSurface.withValues(alpha: 0.03),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      constraints: const BoxConstraints(maxHeight: 120),
                                      child: SingleChildScrollView(
                                        child: Text(
                                          updateService.releaseNotes,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: colors.onSurface.withValues(alpha: 0.7),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                  ],
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      try {
                                        await updateService.triggerUpdate();
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(parentContext).showSnackBar(
                                            SnackBar(content: Text('Error: $e')),
                                          );
                                        }
                                      }
                                    },
                                    icon: const Icon(Icons.download, size: 18),
                                    label: const Text('Download & Install Now', style: TextStyle(fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(double.infinity, 45),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      elevation: 2,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildGitHubButton(colors),
                                  if (force) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      'This is a major release containing critical updates. You must download it to stay up-to-date.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                        color: colors.onSurface.withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            }

                            return Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.green.withValues(alpha: 0.1),
                                        ),
                                        child: const Icon(Icons.check_circle, color: Colors.green, size: 48),
                                      ),
                                      const SizedBox(height: 15),
                                      const Text(
                                        'You are on the latest version!',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Current Version: v${UpdateService.currentVersion} (${UpdateService.currentBuildNumber})',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: colors.onSurface.withValues(alpha: 0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    await updateService.checkForUpdates();
                                  },
                                  icon: const Icon(Icons.refresh, size: 16),
                                  label: const Text('Check for Updates'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: colors.primary,
                                    side: BorderSide(color: colors.primary.withValues(alpha: 0.5)),
                                    minimumSize: const Size(double.infinity, 40),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );

            if (force) {
              return PopScope(
                canPop: false,
                child: dialogBody,
              );
            }
            return dialogBody;
          },
        );
      },
    );
  }

  static Widget _buildInputField(
    ColorScheme colors,
    String label,
    TextEditingController controller,
    String hint, {
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 13, color: colors.onSurface.withValues(alpha: 0.35)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: true,
            fillColor: colors.onSurface.withValues(alpha: 0.03),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colors.onSurface.withValues(alpha: 0.08)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colors.onSurface.withValues(alpha: 0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  static Widget _buildGitHubButton(ColorScheme colors) {
    return OutlinedButton.icon(
      onPressed: () async {
        final Uri uri = Uri.parse('https://github.com/ImranHasan13421/ShEC-CSE');
        try {
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        } catch (e) {
          debugPrint('Error launching GitHub link: $e');
        }
      },
      icon: const Icon(Icons.code, size: 16),
      label: const Text('View on GitHub', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.onSurface.withValues(alpha: 0.6),
        side: BorderSide(color: colors.onSurface.withValues(alpha: 0.15)),
        minimumSize: const Size(double.infinity, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  State<MainDrawerMenu> createState() => _MainDrawerMenuState();
}

class _MainDrawerMenuState extends State<MainDrawerMenu> {
  String? _expandedGroupTitle = 'Academic Hub';

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final themeService = ThemeService.instance;
    final isNight = themeService.themeMode == AppThemeMode.night;
    final controller = SimpleHiddenDrawerController.of(context);

    final bgGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isNight
          ? [const Color(0xFF0A0B0D), const Color(0xFF121316)]
          : themeService.themeMode == AppThemeMode.dark
              ? [const Color(0xFF16181F), const Color(0xFF0E1014)]
              : [
                  colors.primary.withValues(alpha: 0.22),
                  const Color(0xFF101216),
                ],
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          child: Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.55,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Group 1: Academic Hub ──────────────────────────────────
                          DrawerAccordionGroup(
                            title: 'Academic Hub',
                            icon: Icons.school_outlined,
                            isExpanded: _expandedGroupTitle == 'Academic Hub',
                            onToggle: (expanded) {
                              setState(() {
                                _expandedGroupTitle = expanded ? 'Academic Hub' : null;
                              });
                            },
                            children: [
                              _menuItem(
                                context,
                                controller,
                                icon: Icons.assignment_outlined,
                                title: 'Results',
                                destination: const ResultsScreen(),
                              ),
                              _menuItem(
                                context,
                                controller,
                                icon: Icons.folder_copy_outlined,
                                title: 'Previous Resources',
                                destination: const YearsScreen(),
                              ),
                              _menuItem(
                                context,
                                controller,
                                icon: Icons.calculate_outlined,
                                title: 'CGPA Calculator',
                                destination: const CGPACalculatorScreen(),
                              ),
                            ],
                          ),

                          // ── Group 2: Careers & Network ─────────────────────────────
                          DrawerAccordionGroup(
                            title: 'Careers & Network',
                            icon: Icons.people_outline,
                            isExpanded: _expandedGroupTitle == 'Careers & Network',
                            onToggle: (expanded) {
                              setState(() {
                                _expandedGroupTitle = expanded ? 'Careers & Network' : null;
                              });
                            },
                            children: [
                              ValueListenableBuilder<Map<String, int>>(
                                valueListenable: NotificationService.unreadCounts,
                                builder: (context, unread, _) {
                                  final count = unread['jobs'] ?? 0;
                                  return _menuItem(
                                    context,
                                    controller,
                                    icon: Icons.work_outline,
                                    title: 'Job Board',
                                    destination: const JobsScreen(),
                                    badgeCount: count,
                                    onTap: () => NotificationService.clearUnread('jobs'),
                                  );
                                },
                              ),
                              _menuItem(
                                context,
                                controller,
                                icon: Icons.group_outlined,
                                title: 'Club Members',
                                destination: const ClubMembersScreen(),
                              ),
                              _menuItem(
                                context,
                                controller,
                                icon: Icons.co_present_outlined,
                                title: 'Alumni Network',
                                destination: const AlumniScreen(),
                              ),
                              _menuItem(
                                context,
                                controller,
                                icon: Icons.photo_library_outlined,
                                title: 'Gallery Media',
                                destination: const GalleryScreen(),
                              ),
                            ],
                          ),

                          // ── Group 3: Finance & Management ──────────────────────────
                          DrawerAccordionGroup(
                            title: 'Finance & Admin',
                            icon: Icons.account_balance_wallet_outlined,
                            isExpanded: _expandedGroupTitle == 'Finance & Admin',
                            onToggle: (expanded) {
                              setState(() {
                                _expandedGroupTitle = expanded ? 'Finance & Admin' : null;
                              });
                            },
                            children: [
                              _menuItem(
                                context,
                                controller,
                                icon: Icons.account_balance_wallet_outlined,
                                title: 'Club Accounts',
                                destination: const AccountingDashboardScreen(),
                              ),
                              ValueListenableBuilder<ProfileData>(
                                valueListenable: currentProfile,
                                builder: (context, profile, _) {
                                  final isCommitteeOrAdmin = profile.role == UserRole.committeeMember ||
                                      profile.role == UserRole.superUser ||
                                      profile.designation == 'President' ||
                                      profile.designation == 'Vice President';

                                  if (!isCommitteeOrAdmin) return const SizedBox.shrink();

                                  return _menuItem(
                                    context,
                                    controller,
                                    icon: Icons.shield_outlined,
                                    title: 'Permissions',
                                    destination: const CommitteePermissionsScreen(),
                                  );
                                },
                              ),
                            ],
                          ),

                          // ── Group 4: Info & System ──────────────────────────────────
                          DrawerAccordionGroup(
                            title: 'Information & System',
                            icon: Icons.info_outline,
                            isExpanded: _expandedGroupTitle == 'Information & System',
                            onToggle: (expanded) {
                              setState(() {
                                _expandedGroupTitle = expanded ? 'Information & System' : null;
                              });
                            },
                            children: [
                              _menuItem(
                                context,
                                controller,
                                icon: Icons.contact_phone_outlined,
                                title: 'Teacher Contacts',
                                destination: const TeacherContactsScreen(),
                              ),
                              _menuItem(
                                context,
                                controller,
                                icon: Icons.account_balance_outlined,
                                title: 'CSE Department Info',
                                destination: const DepartmentScreen(),
                              ),
                              _menuItem(
                                context,
                                controller,
                                icon: Icons.code,
                                title: 'Programming Club',
                                destination: const ClubScreen(),
                              ),
                              _menuItem(
                                context,
                                controller,
                                icon: Icons.group_work_outlined,
                                title: 'Contributors',
                                destination: const ContributorsScreen(),
                              ),
                              ListenableBuilder(
                                listenable: UpdateService.instance,
                                builder: (context, _) {
                                  final hasUpdate = UpdateService.instance.hasUpdate;
                                  return _menuItem(
                                    context,
                                    controller,
                                    icon: Icons.system_update_outlined,
                                    title: 'App Update',
                                    badgeCount: hasUpdate ? -1 : 0,
                                    onTap: () {
                                      MainDrawerMenu.showUpdateDialog(context);
                                    },
                                  );
                                },
                              ),
                            ],
                          ),

                          // ── Group 5: Aesthetics & Support ───────────────────────────
                          DrawerAccordionGroup(
                            title: 'Support & Aesthetics',
                            icon: Icons.settings_outlined,
                            isExpanded: _expandedGroupTitle == 'Support & Aesthetics',
                            onToggle: (expanded) {
                              setState(() {
                                _expandedGroupTitle = expanded ? 'Support & Aesthetics' : null;
                              });
                            },
                            children: [
                              _menuItem(
                                context,
                                controller,
                                icon: Icons.palette_outlined,
                                title: 'Themes & Colors',
                                destination: const AestheticsSettingsScreen(),
                              ),
                              _menuItem(
                                context,
                                controller,
                                icon: Icons.map_outlined,
                                title: 'Guided Screen Tour',
                                onTap: () async {
                                  await TourService.instance.resetAllScreenTours();
                                  TourService.instance.startTour();
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),
                          const Divider(color: Colors.grey, thickness: 0.1),
                          const SizedBox(height: 8),

                          // ── Logout ─────────────────────────────────────────
                          _menuItem(
                            context,
                            controller,
                            icon: Icons.logout_outlined,
                            title: 'Sign Out',
                            onTap: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: colors.surface,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
                                  content: const Text('Are you sure you want to sign out of CPC App?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: colors.error,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text('Sign Out'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                final authState = context.read<AuthBloc>();
                                try {
                                  await AuthService.signOut();
                                  authState.add(AuthSignOutRequested());
                                } catch (_) {}

                                if (context.mounted) {
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(builder: (_) => const AuthAnimatedScreen()),
                                    (route) => false,
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colors = widget.colors;
    final controller = SimpleHiddenDrawerController.of(context);
    return ValueListenableBuilder<ProfileData>(
      valueListenable: currentProfile,
      builder: (context, profile, _) {
        return InkWell(
          onTap: () {
            controller.toggle();
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
          },
          child: Container(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: colors.surfaceContainer,
                  backgroundImage: profile.imagePath != null && profile.imagePath!.startsWith('http')
                      ? NetworkImage(profile.imagePath!) as ImageProvider
                      : null,
                  child: (profile.imagePath == null || !profile.imagePath!.startsWith('http'))
                      ? Icon(Icons.person, size: 28, color: colors.primary)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        profile.designation,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        profile.email,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _menuItem(
    BuildContext context,
    SimpleHiddenDrawerController controller, {
    required IconData icon,
    required String title,
    Widget? destination,
    int badgeCount = 0,
    VoidCallback? onTap,
    bool showChevron = false,
  }) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () {
        controller.toggle();
        if (onTap != null) onTap();
        if (destination != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
        }
      },
      borderRadius: BorderRadius.circular(10),
      hoverColor: colors.primary.withValues(alpha: 0.08),
      splashColor: colors.primary.withValues(alpha: 0.15),
      highlightColor: colors.primary.withValues(alpha: 0.05),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            if (badgeCount != 0)
              Badge(
                label: badgeCount > 0 ? Text('$badgeCount') : null,
                child: Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 18),
              )
            else
              Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ),
            if (showChevron)
              Icon(
                Icons.chevron_right,
                size: 14,
                color: Colors.white.withValues(alpha: 0.35),
              ),
          ],
        ),
      ),
    );
  }
}
