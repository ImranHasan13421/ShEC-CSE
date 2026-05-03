import 'package:flutter/material.dart';
import '../../../backend/services/notice_service.dart';
import '../models/notice_state.dart';
import '../screens/notice_detail_screen.dart';

class NoticeCard extends StatelessWidget {
  final NoticeItem notice;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onApprove;
  final VoidCallback? onToggleVisibility;
  final bool isAdmin;
  final bool isSuperUser;

  const NoticeCard({
    super.key,
    required this.notice,
    this.onEdit,
    this.onDelete,
    this.onApprove,
    this.onToggleVisibility,
    this.isAdmin = false,
    this.isSuperUser = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const defaultColor = Colors.blue;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outline.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NoticeDetailScreen(notice: notice)),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 60,
                  height: 60,
                  color: defaultColor.withOpacity(0.1),
                  child: notice.imagePath != null && notice.imagePath!.isNotEmpty && notice.imagePath!.startsWith('http')
                      ? Image.network(notice.imagePath!, fit: BoxFit.cover, 
                          errorBuilder: (_, __, ___) => const Icon(Icons.notifications, color: defaultColor, size: 24))
                      : const Icon(Icons.notifications, color: defaultColor, size: 24),
                ),
              ),
              const SizedBox(width: 14),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notice.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isAdmin)
                          _buildAdminMenu(context),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 10, color: colors.onSurface.withOpacity(0.4)),
                        const SizedBox(width: 4),
                        Text(
                          notice.date,
                          style: TextStyle(color: colors.onSurface.withOpacity(0.4), fontSize: 11),
                        ),
                        const Spacer(),
                        if (notice.tags.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: defaultColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              notice.tags.first,
                              style: const TextStyle(color: defaultColor, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    if (!notice.isApproved || !notice.isVisible)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            if (!notice.isApproved)
                              _buildBadge('PENDING', Colors.red),
                            if (!notice.isVisible)
                              Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: _buildBadge('HIDDEN', Colors.orange),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildAdminMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 18),
      onSelected: (val) {
        if (val == 'edit') onEdit?.call();
        if (val == 'delete') onDelete?.call();
        if (val == 'approve') onApprove?.call();
        if (val == 'visibility') onToggleVisibility?.call();
        if (val == 'pin') NoticeService.toggleNoticePin(notice.id, !notice.isPinned);
      },
      itemBuilder: (_) => [
        if (!notice.isApproved && isSuperUser)
          const PopupMenuItem(value: 'approve', child: Text('Approve', style: TextStyle(color: Colors.green))),
        if (isSuperUser)
          PopupMenuItem(value: 'pin', child: Text(notice.isPinned ? 'Unpin' : 'Pin')),
        PopupMenuItem(value: 'visibility', child: Text(notice.isVisible ? 'Hide' : 'Show')),
        const PopupMenuItem(value: 'edit', child: Text('Edit')),
        const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
      ],
    );
  }
}
