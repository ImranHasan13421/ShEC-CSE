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
      appBar: AppBar(
        title: const Text('Notice Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (notice.imagePath != null && notice.imagePath!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  notice.imagePath!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    color: colors.surfaceContainerHighest,
                    child: const Center(child: Icon(Icons.broken_image, size: 50)),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: notice.iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(notice.icon, color: notice.iconColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(notice.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      Text(notice.date, style: TextStyle(color: colors.onSurface.withOpacity(0.6))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: notice.tags.map((tag) => Chip(
                label: Text(tag, style: const TextStyle(fontSize: 12)),
                backgroundColor: notice.tagColor.withOpacity(0.1),
                side: BorderSide.none,
              )).toList(),
            ),
            const Divider(height: 48),
            Text(notice.subtitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              notice.description,
              style: const TextStyle(fontSize: 16, height: 1.6),
            ),
            
            if (isAdmin && notice.createdByName.isNotEmpty) ...[
              const Divider(height: 48),
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Added by: ${notice.createdByName}',
                    style: const TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
