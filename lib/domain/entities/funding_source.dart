import 'package:equatable/equatable.dart';

class FundingSource extends Equatable {
  final int id;
  final String title;
  final String sourceUrl;
  final String sourceType;
  final String language;
  final String country;
  final String status;
  final int version;
  final String? publishedAt;
  final int chunkCount;
  final String? updatedAt;

  const FundingSource({
    required this.id,
    required this.title,
    required this.sourceUrl,
    required this.sourceType,
    required this.language,
    required this.country,
    required this.status,
    required this.version,
    required this.publishedAt,
    required this.chunkCount,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        sourceUrl,
        sourceType,
        language,
        country,
        status,
        version,
        publishedAt,
        chunkCount,
        updatedAt,
      ];
}
