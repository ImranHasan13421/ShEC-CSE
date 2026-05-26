class CommitteePermission {
  final String userId;
  final bool canManageNotices;
  final bool canManageJobs;
  final bool canManageContests;
  final bool canManageResources;
  final bool canManageAccounting;
  final bool canApproveMembers;

  CommitteePermission({
    required this.userId,
    this.canManageNotices = false,
    this.canManageJobs = false,
    this.canManageContests = false,
    this.canManageResources = false,
    this.canManageAccounting = false,
    this.canApproveMembers = false,
  });

  CommitteePermission copyWith({
    String? userId,
    bool? canManageNotices,
    bool? canManageJobs,
    bool? canManageContests,
    bool? canManageResources,
    bool? canManageAccounting,
    bool? canApproveMembers,
  }) {
    return CommitteePermission(
      userId: userId ?? this.userId,
      canManageNotices: canManageNotices ?? this.canManageNotices,
      canManageJobs: canManageJobs ?? this.canManageJobs,
      canManageContests: canManageContests ?? this.canManageContests,
      canManageResources: canManageResources ?? this.canManageResources,
      canManageAccounting: canManageAccounting ?? this.canManageAccounting,
      canApproveMembers: canApproveMembers ?? this.canApproveMembers,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'can_manage_notices': canManageNotices,
      'can_manage_jobs': canManageJobs,
      'can_manage_contests': canManageContests,
      'can_manage_resources': canManageResources,
      'can_manage_accounting': canManageAccounting,
      'can_approve_members': canApproveMembers,
    };
  }

  factory CommitteePermission.fromMap(Map<String, dynamic> map) {
    return CommitteePermission(
      userId: map['user_id'] ?? '',
      canManageNotices: map['can_manage_notices'] ?? false,
      canManageJobs: map['can_manage_jobs'] ?? false,
      canManageContests: map['can_manage_contests'] ?? false,
      canManageResources: map['can_manage_resources'] ?? false,
      canManageAccounting: map['can_manage_accounting'] ?? false,
      canApproveMembers: map['can_approve_members'] ?? false,
    );
  }

  factory CommitteePermission.treasurer(String userId) {
    return CommitteePermission(
      userId: userId,
      canManageAccounting: true,
    );
  }

  factory CommitteePermission.prOfficer(String userId) {
    return CommitteePermission(
      userId: userId,
      canManageNotices: true,
      canManageJobs: true,
    );
  }

  factory CommitteePermission.academicOfficer(String userId) {
    return CommitteePermission(
      userId: userId,
      canManageResources: true,
      canManageContests: true,
    );
  }

  factory CommitteePermission.hrManager(String userId) {
    return CommitteePermission(
      userId: userId,
      canApproveMembers: true,
    );
  }

  factory CommitteePermission.fullAdmin(String userId) {
    return CommitteePermission(
      userId: userId,
      canManageNotices: true,
      canManageJobs: true,
      canManageContests: true,
      canManageResources: true,
      canManageAccounting: true,
      canApproveMembers: true,
    );
  }

  factory CommitteePermission.viewOnly(String userId) {
    return CommitteePermission(
      userId: userId,
    );
  }
}
