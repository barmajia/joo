class FactoryConnection {
  final String id;
  final String factoryId;
  final String sellerId;
  final String status; // 'pending', 'accepted', 'rejected', 'blocked'
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? vaultSecretId;
  final Map<String, dynamic>? metadata;

  FactoryConnection({
    required this.id,
    required this.factoryId,
    required this.sellerId,
    this.status = 'pending',
    this.notes,
    this.isActive = false,
    required this.createdAt,
    required this.updatedAt,
    this.vaultSecretId,
    this.metadata,
  });

  factory FactoryConnection.fromJson(Map<String, dynamic> json) {
    return FactoryConnection(
      id: json['id']?.toString() ?? '',
      factoryId: json['factory_id'] ?? '',
      sellerId: json['seller_id'] ?? '',
      status: json['status'] ?? 'pending',
      notes: json['notes'],
      isActive: json['is_active'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      vaultSecretId: json['vault_secret_id'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'factory_id': factoryId,
      'seller_id': sellerId,
      'status': status,
      'notes': notes,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'vault_secret_id': vaultSecretId,
      'metadata': metadata,
    };
  }

  FactoryConnection copyWith({
    String? id,
    String? factoryId,
    String? sellerId,
    String? status,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? vaultSecretId,
    Map<String, dynamic>? metadata,
  }) {
    return FactoryConnection(
      id: id ?? this.id,
      factoryId: factoryId ?? this.factoryId,
      sellerId: sellerId ?? this.sellerId,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      vaultSecretId: vaultSecretId ?? this.vaultSecretId,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
  bool get isBlocked => status == 'blocked';

  String getOtherUserId(String currentUserId) {
    return currentUserId == factoryId ? sellerId : factoryId;
  }
}
