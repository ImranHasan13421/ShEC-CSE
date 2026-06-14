import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../profile/models/profile_state.dart';

class MemberDetailsSheet extends StatefulWidget {
  final ProfileData member;
  final bool canManage;
  final bool isSuperuser;
  final VoidCallback? onApprove;
  final VoidCallback? onUpdateInfo;
  final VoidCallback? onChangeRank;
  final VoidCallback? onMoveToAlumni;
  final VoidCallback? onDemote;
  final VoidCallback? onDelete;
  final VoidCallback? onCall;
  final VoidCallback? onEmail;
  final VoidCallback? onGenerateCertificate;
  final ProfileData currentProfileData;

  const MemberDetailsSheet({
    super.key,
    required this.member,
    required this.canManage,
    required this.isSuperuser,
    required this.currentProfileData,
    this.onApprove,
    this.onUpdateInfo,
    this.onChangeRank,
    this.onMoveToAlumni,
    this.onDemote,
    this.onDelete,
    this.onCall,
    this.onEmail,
    this.onGenerateCertificate,
  });

  @override
  State<MemberDetailsSheet> createState() => _MemberDetailsSheetState();
}

class _MemberDetailsSheetState extends State<MemberDetailsSheet> {
  String? _copiedValue;

  Widget _actionButton(ColorScheme colors, IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: (MediaQuery.of(context).size.width - 60) / 2,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernInfoRow(IconData icon, String label, String value, {
    bool isCopyable = false,
    VoidCallback? onActionTap,
    IconData? actionIcon,
  }) {
    final colors = Theme.of(context).colorScheme;
    final isCopied = _copiedValue == value;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: colors.primary.withOpacity(0.7)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(value.isNotEmpty ? value : 'N/A', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            if (onActionTap != null && value.isNotEmpty) ...[
              GestureDetector(
                onTap: onActionTap,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    actionIcon ?? Icons.open_in_new, 
                    size: 18, 
                    color: colors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (isCopyable && value.isNotEmpty)
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  setState(() => _copiedValue = value);
                  Future.delayed(const Duration(seconds: 2), () {
                    if (mounted) setState(() => _copiedValue = null);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$label copied!'), 
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 1),
                      width: 150,
                    ),
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isCopied ? Colors.green.withOpacity(0.1) : colors.primary.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCopied ? Icons.check : Icons.copy_rounded, 
                    size: 18, 
                    color: isCopied ? Colors.green : colors.primary
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildElevatedContactCard({
    required IconData icon,
    required String label,
    required String value,
    required Color accentColor,
    required VoidCallback? onActionTap,
  }) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCopied = _copiedValue == value;

    if (value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.3) : accentColor.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
          ],
        ),
        child: Material(
          color: isDark ? colors.surfaceContainerLow : Colors.white,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onActionTap,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark 
                      ? accentColor.withOpacity(0.2) 
                      : accentColor.withOpacity(0.15),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, size: 26, color: accentColor),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1.2,
                            color: isDark ? colors.onSurfaceVariant.withOpacity(0.8) : colors.onSurfaceVariant,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          value,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : colors.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: accentColor.withOpacity(0.15), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label == 'Phone' ? 'Call' : 'Mail',
                          style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          label == 'Phone' ? Icons.phone_forwarded : Icons.alternate_email,
                          size: 14,
                          color: accentColor,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: value));
                      setState(() => _copiedValue = value);
                      Future.delayed(const Duration(seconds: 2), () {
                        if (mounted) setState(() => _copiedValue = null);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$label copied!'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          duration: const Duration(seconds: 1),
                          width: 220,
                        ),
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isCopied ? Colors.green.withOpacity(0.1) : colors.onSurface.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCopied ? Icons.check : Icons.copy_rounded,
                        size: 16,
                        color: isCopied ? Colors.green : colors.onSurface.withOpacity(0.6),
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: colors.onSurfaceVariant.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            CircleAvatar(
              radius: 54,
              backgroundColor: colors.primary.withOpacity(0.1),
              child: CircleAvatar(
                radius: 50,
                backgroundImage: widget.member.imagePath != null && widget.member.imagePath!.isNotEmpty 
                    ? NetworkImage(widget.member.imagePath!) 
                    : null,
                child: widget.member.imagePath == null || widget.member.imagePath!.isEmpty
                    ? Text(widget.member.name[0].toUpperCase(), style: const TextStyle(fontSize: 40))
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Text(widget.member.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.member.designation, 
                style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            const SizedBox(height: 32),
            
            _buildModernInfoRow(Icons.badge_outlined, 'Student ID', widget.member.studentFullId, isCopyable: true),
            _buildModernInfoRow(Icons.school_outlined, 'Session', widget.member.session),
            _buildModernInfoRow(Icons.numbers_outlined, 'DU Reg', widget.member.duRegNo, isCopyable: true),
            const SizedBox(height: 8),
            _buildElevatedContactCard(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: widget.member.phone,
              accentColor: Colors.teal,
              onActionTap: widget.member.phone.isNotEmpty ? widget.onCall : null,
            ),
            _buildElevatedContactCard(
              icon: Icons.email_outlined,
              label: 'Email',
              value: widget.member.email,
              accentColor: Colors.blue,
              onActionTap: widget.member.email.isNotEmpty ? widget.onEmail : null,
            ),
            
            if (widget.canManage && widget.member.id != widget.currentProfileData.id) ...[
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(child: Divider(color: colors.outlineVariant)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('ADMIN ACTIONS', style: TextStyle(
                      fontSize: 11, 
                      fontWeight: FontWeight.w800, 
                      color: colors.onSurfaceVariant,
                      letterSpacing: 1.5,
                    )),
                  ),
                  Expanded(child: Divider(color: colors.outlineVariant)),
                ],
              ),
              const SizedBox(height: 20),
              
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  if (!widget.member.isApproved)
                    _actionButton(
                      colors, 
                      Icons.check_circle_outline, 
                      'Approve User', 
                      Colors.green,
                      widget.onApprove ?? () {}
                    ),
                  
                  _actionButton(
                    colors, 
                    Icons.edit_outlined, 
                    'Update Info', 
                    colors.primary,
                    widget.onUpdateInfo ?? () {}
                  ),

                  if (widget.isSuperuser) ...[
                    _actionButton(
                      colors, 
                      Icons.star_outline, 
                      'Change Rank', 
                      Colors.orange,
                      widget.onChangeRank ?? () {}
                    ),
                    _actionButton(
                      colors, 
                      Icons.history_edu_outlined, 
                      'Move To Alumni',
                      Colors.blueGrey,
                      widget.onMoveToAlumni ?? () {}
                    ),
                  ],

                  if (widget.member.isApproved && 
                      (widget.isSuperuser || 
                       widget.currentProfileData.designation == 'President' || 
                       widget.currentProfileData.designation == 'Vice President'))
                    _actionButton(
                      colors, 
                      Icons.military_tech_outlined, 
                      'Generate Certificate', 
                      Colors.indigo,
                      widget.onGenerateCertificate ?? () {}
                    ),
                  
                  if (widget.isSuperuser && (widget.member.role == UserRole.committeeMember || widget.member.role == UserRole.superUser))
                    _actionButton(
                      colors, 
                      Icons.person_remove_outlined, 
                      'Demote', 
                      Colors.deepOrange,
                      widget.onDemote ?? () {}
                    ),
                    
                  if (widget.isSuperuser)
                    _actionButton(
                      colors, 
                      Icons.delete_outline, 
                      'Delete', 
                      Colors.red,
                      widget.onDelete ?? () {}
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
