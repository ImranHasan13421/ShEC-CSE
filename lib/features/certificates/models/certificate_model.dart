class CertificateModel {
  final String id;
  final String serialNumber;
  final int? serialIndex;
  final String userId;
  final String issuedBy;
  final String memberName;
  final String? memberBatch;
  final String? memberSession;
  final String? memberDesignation;
  final String storagePath;
  final DateTime generatedAt;

  CertificateModel({
    required this.id,
    required this.serialNumber,
    this.serialIndex,
    required this.userId,
    required this.issuedBy,
    required this.memberName,
    this.memberBatch,
    this.memberSession,
    this.memberDesignation,
    required this.storagePath,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serial_number': serialNumber,
      'serial_index': serialIndex,
      'user_id': userId,
      'issued_by': issuedBy,
      'member_name': memberName,
      'member_batch': memberBatch,
      'member_session': memberSession,
      'member_designation': memberDesignation,
      'storage_path': storagePath,
      'generated_at': generatedAt.toIso8601String(),
    };
  }

  factory CertificateModel.fromJson(Map<String, dynamic> json) {
    return CertificateModel(
      id: json['id'] ?? '',
      serialNumber: json['serial_number'] ?? '',
      serialIndex: json['serial_index'],
      userId: json['user_id'] ?? '',
      issuedBy: json['issued_by'] ?? '',
      memberName: json['member_name'] ?? '',
      memberBatch: json['member_batch'],
      memberSession: json['member_session'],
      memberDesignation: json['member_designation'],
      storagePath: json['storage_path'] ?? '',
      generatedAt: json['generated_at'] != null
          ? DateTime.parse(json['generated_at'])
          : DateTime.now(),
    );
  }
}
