import 'package:flutter/material.dart';
import '../models/notice_state.dart';
import 'package:ShEC_CSE/features/profile/models/profile_state.dart';

class NoticeDetailScreen extends StatelessWidget {
  final NoticeItem notice;

  const NoticeDetailScreen({super.key, required this.notice});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isAdmin = currentProfile.value.role != UserRole.student;

    return Scaffold(
      backgroundColor: colors.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: notice.imagePath != null && notice.imagePath!.isNotEmpty ? 300 : 120,
            pinned: true,
            stretch: true,
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
              background: notice.imagePath != null && notice.imagePath!.isNotEmpty
                  ? Image.network(
                      notice.imagePath!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: colors.primaryContainer,
                        child: const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.white54)),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [colors.primary, colors.secondary],
                        ),
                      ),
                      child: Center(
                        child: Icon(notice.icon, size: 64, color: Colors.white.withValues(alpha: 0.5)),
                      ),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: notice.iconColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(notice.icon, size: 16, color: notice.iconColor),
                            const SizedBox(width: 8),
                            Text(
                              'Notice',
                              style: TextStyle(color: notice.iconColor, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        notice.date,
                        style: TextStyle(color: colors.onSurface.withValues(alpha: 0.5), fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    notice.title,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, height: 1.2),
                  ),
                  const SizedBox(height: 12),
                  if (notice.subtitle.isNotEmpty)
                    Text(
                      notice.subtitle,
                      style: TextStyle(fontSize: 18, color: colors.onSurface.withValues(alpha: 0.7), fontWeight: FontWeight.w500),
                    ),
                  const SizedBox(height: 16),
                  if (notice.tags.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: notice.tags.map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: colors.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(color: colors.onSecondaryContainer, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      )).toList(),
                    ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Divider(),
                  ),
                  Text(
                    notice.description,
                    style: TextStyle(fontSize: 16, height: 1.8, color: colors.onSurface.withValues(alpha: 0.8)),
                  ),
                  if (isAdmin && notice.createdByName.isNotEmpty) ...[
                    const SizedBox(height: 48),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: colors.primaryContainer,
                          child: Icon(Icons.person, size: 14, color: colors.primary),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Posted by ${notice.createdByName}',
                          style: TextStyle(color: colors.onSurface.withValues(alpha: 0.5), fontStyle: FontStyle.italic, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
