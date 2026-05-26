import 'package:flutter/material.dart';
import 'package:hidden_drawer_menu/hidden_drawer_menu.dart';
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

class MainDrawerMenu extends StatelessWidget {
  final ColorScheme colors;

  const MainDrawerMenu({super.key, required this.colors});

  @override
  Widget build(BuildContext context) {
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
                          _menuSectionHeader('Academic & Career'),
                          _menuItem(
                            context,
                            controller,
                            icon: Icons.assignment_outlined,
                            title: 'Results',
                            destination: const ResultsScreen(),
                          ),
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
                            icon: Icons.folder_copy_outlined,
                            title: 'Previous Resources',
                            destination: const YearsScreen(),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Divider(color: Colors.grey, thickness: 0.1),
                          ),
                          _menuSectionHeader('Department & People'),
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
                            icon: Icons.people_outline,
                            title: 'Club Members',
                            destination: const ClubMembersScreen(),
                          ),
                          _menuItem(
                            context,
                            controller,
                            icon: Icons.school_outlined,
                            title: 'Alumni',
                            destination: const AlumniScreen(),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Divider(color: Colors.grey, thickness: 0.1),
                          ),
                          _menuSectionHeader('Media & Tools'),
                          _menuItem(
                            context,
                            controller,
                            icon: Icons.photo_library_outlined,
                            title: 'Gallery',
                            destination: const GalleryScreen(),
                          ),
                          _menuItem(
                            context,
                            controller,
                            icon: Icons.calculate_outlined,
                            title: 'CGPA Calculator',
                            destination: const CGPACalculatorScreen(),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Divider(color: Colors.grey, thickness: 0.1),
                          ),
                          _menuSectionHeader('Treasury & Accounts'),
                          _menuItem(
                            context,
                            controller,
                            icon: Icons.account_balance_wallet_outlined,
                            title: 'Club Accounts',
                            destination: const AccountingDashboardScreen(),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Divider(color: Colors.grey, thickness: 0.1),
                          ),
                          _menuSectionHeader('Abouts'),
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
                                  _showUpdateDialog(context);
                                },
                              );
                            },
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Divider(color: Colors.grey, thickness: 0.1),
                          ),
                          _menuSectionHeader('Appearance & Help'),
                          _menuItem(
                            context,
                            controller,
                            icon: Icons.palette_outlined,
                            title: 'Aesthetics & Themes',
                            destination: const AestheticsSettingsScreen(),
                          ),
                          _menuItem(
                            context,
                            controller,
                            icon: Icons.map_outlined,
                            title: 'Show Guided Tour',
                            onTap: () async {
                              await TourService.instance.resetAllScreenTours();
                              TourService.instance.startTour();
                            },
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: InkWell(
                      onTap: () async {
                        await AuthService.signOut();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const AuthAnimatedScreen()),
                            (route) => false,
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.redAccent.withValues(alpha: 0.05),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.logout, color: Colors.redAccent, size: 20),
                            SizedBox(width: 12),
                            Text(
                              'Log Out',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
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
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                ),
                CircleAvatar(
                  radius: 30,
                  backgroundColor: colors.surfaceContainer,
                  backgroundImage: profile.imagePath != null && profile.imagePath!.startsWith('http')
                      ? NetworkImage(profile.imagePath!) as ImageProvider
                      : null,
                  child: (profile.imagePath == null || !profile.imagePath!.startsWith('http'))
                      ? Icon(Icons.person, size: 30, color: colors.primary)
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.designation,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        profile.email,
                        style: TextStyle(
                          fontSize: 11,
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

  Widget _menuSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, top: 12.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
          color: Colors.white.withValues(alpha: 0.45),
        ),
      ),
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
  }) {
    return InkWell(
      onTap: () {
        controller.toggle();
        if (onTap != null) onTap();
        if (destination != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            if (badgeCount != 0)
              Badge(
                label: badgeCount > 0 ? Text('$badgeCount') : null,
                child: Icon(icon, color: Colors.white.withValues(alpha: 0.75), size: 22),
              )
            else
              Icon(icon, color: Colors.white.withValues(alpha: 0.75), size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 16,
              color: Colors.white.withValues(alpha: 0.35),
            ),
          ],
        ),
      ),
    );
  }



  void _showUpdateDialog(BuildContext parentContext) {
    final updateService = UpdateService.instance;

    showDialog(
      context: parentContext,
      barrierDismissible: true,
      builder: (dialogContext) {
        final versionController = TextEditingController(text: '1.0.1');
        final buildController = TextEditingController(text: '${UpdateService.currentBuildNumber + 1}');
        final urlController = TextEditingController();
        final notesController = TextEditingController();
        bool isPublishTab = false;
        bool isActionLoading = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isSuperUser = currentProfile.value.role == UserRole.superUser;

            return Dialog(
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
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const Divider(thickness: 0.5),
                      const SizedBox(height: 10),

                      if (isSuperUser) ...[
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

                      if (isPublishTab && isSuperUser) ...[
                        _buildInputField(colors, 'Version Name', versionController, 'e.g. 1.0.1'),
                        const SizedBox(height: 10),
                        _buildInputField(colors, 'Build Number', buildController, 'e.g. 2', isNumber: true),
                        const SizedBox(height: 10),
                        _buildInputField(colors, 'APK Download URL', urlController, 'e.g. https://...'),
                        const SizedBox(height: 10),
                        _buildInputField(colors, 'Release Notes', notesController, 'What\'s new in this build...', maxLines: 3),
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
                                                'New Version Available!',
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
                                const SizedBox(height: 8),
                                _buildGitHubButton(colors),
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
          },
        );
      },
    );
  }

  Widget _buildInputField(
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

  Widget _buildGitHubButton(ColorScheme colors) {
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
}
