import 'package:flutter_test/flutter_test.dart';
import 'package:trustpay/data/datasources/remote/chat_remote_datasource.dart';

void main() {
  group('Chat parsing', () {
    test('parseChatResponse parses answer and citations', () {
      final response = parseChatResponse({
        'answer': 'Voici des options.',
        'confidence': 0.82,
        'citations': [
          {
            'chunk_id': 11,
            'document_id': 7,
            'document_title': 'Fonds PME',
            'source_url': 'https://example.org/source',
            'score': 0.91,
            'excerpt': 'Extrait...',
          },
        ],
        'limits': ['Base sur sources indexees.'],
        'detected_language': 'fr',
        'model_used': 'openai/gpt-4o-mini',
        'fallback_reason': 'preferred_language',
      });

      expect(response.answer, 'Voici des options.');
      expect(response.confidence, closeTo(0.82, 0.0001));
      expect(response.citations.length, 1);
      expect(response.citations.first.documentId, 7);
      expect(response.limits, isNotEmpty);
      expect(response.detectedLanguage, 'fr');
      expect(response.modelUsed, 'openai/gpt-4o-mini');
      expect(response.fallbackReason, 'preferred_language');
    });

    test('parseFundingSources handles list and results formats', () {
      final rows = parseFundingSources([
        {
          'id': 1,
          'title': 'Programme A',
          'source_url': '',
          'source_type': 'grant',
          'language': 'fr',
          'country': 'BJ',
          'status': 'published',
          'version': 1,
          'chunk_count': 3,
        },
      ]);
      expect(rows.length, 1);
      expect(rows.first.title, 'Programme A');

      final paged = parseFundingSources({
        'results': [
          {
            'id': 2,
            'title': 'Programme B',
            'source_url': 'https://example.org',
            'source_type': 'loan',
            'language': 'fr',
            'country': 'BJ',
            'status': 'published',
            'version': 2,
            'chunk_count': 5,
          },
        ],
      });
      expect(paged.length, 1);
      expect(paged.first.id, 2);
    });
  });
}
