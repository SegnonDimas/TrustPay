import 'package:dio/dio.dart';

import '../../../config/api_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../domain/entities/chat_citation.dart';
import '../../../domain/entities/chat_response.dart';
import '../../../domain/entities/funding_source.dart';

abstract class ChatRemoteDataSource {
  Future<ChatResponse> askFunding({
    required String question,
    int topK,
    String? country,
    String? language,
    String? preferredLanguage,
  });

  Future<List<FundingSource>> getFundingSources();
}

ChatResponse parseChatResponse(Map<String, dynamic> json) {
  final citationsRaw = (json['citations'] as List<dynamic>? ?? const []);
  final citations = citationsRaw
      .whereType<Map>()
      .map((item) {
        final citation = Map<String, dynamic>.from(item);
        return ChatCitation(
          chunkId: int.tryParse(citation['chunk_id']?.toString() ?? '') ?? 0,
          documentId: int.tryParse(citation['document_id']?.toString() ?? '') ?? 0,
          documentTitle: citation['document_title']?.toString() ?? '',
          sourceUrl: citation['source_url']?.toString() ?? '',
          score: double.tryParse(citation['score']?.toString() ?? '') ?? 0,
          excerpt: citation['excerpt']?.toString() ?? '',
        );
      })
      .toList();

  final limitsRaw = (json['limits'] as List<dynamic>? ?? const []);
  return ChatResponse(
    answer: json['answer']?.toString() ?? '',
    confidence: double.tryParse(json['confidence']?.toString() ?? '') ?? 0,
    citations: citations,
    limits: limitsRaw.map((item) => item.toString()).toList(),
    detectedLanguage: json['detected_language']?.toString() ?? '',
    modelUsed: json['model_used']?.toString() ?? '',
    fallbackReason: json['fallback_reason']?.toString() ?? '',
  );
}

List<FundingSource> parseFundingSources(dynamic data) {
  final rows = data is Map<String, dynamic> && data['results'] is List
      ? data['results'] as List<dynamic>
      : (data as List<dynamic>? ?? const []);

  return rows
      .whereType<Map>()
      .map((item) {
        final source = Map<String, dynamic>.from(item);
        return FundingSource(
          id: int.tryParse(source['id']?.toString() ?? '') ?? 0,
          title: source['title']?.toString() ?? '',
          sourceUrl: source['source_url']?.toString() ?? '',
          sourceType: source['source_type']?.toString() ?? '',
          language: source['language']?.toString() ?? '',
          country: source['country']?.toString() ?? '',
          status: source['status']?.toString() ?? '',
          version: int.tryParse(source['version']?.toString() ?? '') ?? 1,
          publishedAt: source['published_at']?.toString(),
          chunkCount: int.tryParse(source['chunk_count']?.toString() ?? '') ?? 0,
          updatedAt: source['updated_at']?.toString(),
        );
      })
      .toList();
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final Dio _dio;

  ChatRemoteDataSourceImpl(this._dio);

  @override
  Future<ChatResponse> askFunding({
    required String question,
    int topK = 5,
    String? country,
    String? language,
    String? preferredLanguage,
  }) async {
    try {
      final payload = <String, dynamic>{
        'question': question,
        'top_k': topK,
        if (country != null && country.trim().isNotEmpty) 'country': country.trim(),
        if (language != null && language.trim().isNotEmpty) 'language': language.trim(),
        if (preferredLanguage != null && preferredLanguage.trim().isNotEmpty)
          'preferred_language': preferredLanguage.trim(),
      };
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConfig.fundingAsk,
        data: payload,
      );
      return parseChatResponse(response.data ?? const <String, dynamic>{});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<List<FundingSource>> getFundingSources() async {
    try {
      final response = await _dio.get<dynamic>(ApiConfig.fundingSources);
      return parseFundingSources(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
