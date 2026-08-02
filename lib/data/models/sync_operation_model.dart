class SyncOperationModel {
  final String id;
  final String entityType;
  final String entityLocalId;
  final String operationType;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int retryCount;
  final String? lastError;

  const SyncOperationModel({
    required this.id,
    required this.entityType,
    required this.entityLocalId,
    required this.operationType,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
    this.lastError,
  });

  SyncOperationModel copyWith({
    int? retryCount,
    String? lastError,
    Map<String, dynamic>? payload,
  }) {
    return SyncOperationModel(
      id: id,
      entityType: entityType,
      entityLocalId: entityLocalId,
      operationType: operationType,
      payload: payload ?? this.payload,
      createdAt: createdAt,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
    );
  }

  factory SyncOperationModel.fromJson(Map<String, dynamic> json) {
    return SyncOperationModel(
      id: json['id']?.toString() ?? '',
      entityType: json['entity_type']?.toString() ?? '',
      entityLocalId: json['entity_local_id']?.toString() ?? '',
      operationType: json['operation_type']?.toString() ?? '',
      payload: Map<String, dynamic>.from(
        (json['payload'] as Map?) ?? const <String, dynamic>{},
      ),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      retryCount: (json['retry_count'] as int?) ?? 0,
      lastError: json['last_error']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entity_type': entityType,
      'entity_local_id': entityLocalId,
      'operation_type': operationType,
      'payload': payload,
      'created_at': createdAt.toIso8601String(),
      'retry_count': retryCount,
      'last_error': lastError,
    };
  }
}
