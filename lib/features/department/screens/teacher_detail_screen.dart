import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/teacher_state.dart';

class TeacherDetailScreen extends StatelessWidget {
  final TeacherContact teacher;
  const TeacherDetailScreen({super.key, required this.teacher});

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: CustomScrollView(
        slivers: [
          // ── Header with photo ──
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: colors.primary,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Background gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [colors.primary, colors.secondary],
                      ),
                    ),
                  ),
                  // Profile photo
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white,
                          backgroundImage: teacher.imagePath.isNotEmpty
                              ? NetworkImage(teacher.imagePath)
                              : null,
                          child: teacher.imagePath.isEmpty
                              ? Text(
                                  teacher.name[0].toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: colors.primary,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          teacher.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          teacher.designation,
                          style: const TextStyle(color: Colors.white70, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Role badge ──
          if (teacher.role.isNotEmpty)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      teacher.role,
                      style: TextStyle(color: colors.onPrimaryContainer, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Contact Buttons ──
                  if (teacher.phone.isNotEmpty || teacher.email.isNotEmpty) ...[
                    Row(
                      children: [
                        if (teacher.phone.isNotEmpty)
                          Expanded(
                            child: _ActionButton(
                              icon: Icons.phone,
                              label: 'Call',
                              color: Colors.green,
                              onTap: () => _launch('tel:${teacher.phone}'),
                            ),
                          ),
                        if (teacher.phone.isNotEmpty && teacher.email.isNotEmpty)
                          const SizedBox(width: 12),
                        if (teacher.email.isNotEmpty)
                          Expanded(
                            child: _ActionButton(
                              icon: Icons.email,
                              label: 'Email',
                              color: colors.primary,
                              onTap: () => _launch('mailto:${teacher.email}'),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ── Info Cards ──
                  _SectionCard(
                    children: [
                      if (teacher.department.isNotEmpty)
                        _InfoRow(Icons.apartment, 'Department', teacher.department, colors),
                      if (teacher.officeRoom.isNotEmpty)
                        _InfoRow(Icons.room, 'Office', teacher.officeRoom, colors),
                      if (teacher.joinYear.isNotEmpty)
                        _InfoRow(Icons.calendar_today, 'Joined', teacher.joinYear, colors),
                      if (teacher.phone.isNotEmpty)
                        _InfoRow(Icons.phone, 'Phone', teacher.phone, colors),
                      if (teacher.email.isNotEmpty)
                        _InfoRow(Icons.email, 'Email', teacher.email, colors),
                    ],
                  ),

                  // ── Areas of Expertise ──
                  if (teacher.areasOfExpertise.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Areas of Expertise',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: teacher.areasOfExpertise.map((area) => Chip(
                        label: Text(area, style: TextStyle(color: colors.onPrimaryContainer, fontSize: 13)),
                        backgroundColor: colors.primaryContainer,
                        side: BorderSide.none,
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final validChildren = children.where((c) => c is _InfoRow).toList();
    if (validChildren.isEmpty) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: validChildren),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme colors;

  const _InfoRow(this.icon, this.label, this.value, this.colors);

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colors.primary),
          const SizedBox(width: 12),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
