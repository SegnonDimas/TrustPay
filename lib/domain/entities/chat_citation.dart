import 'package:equatable/equatable.dart';

class ChatCitation extends Equatable {
  final int chunkId;
  final int documentId;
  final String documentTitle;
  final String sourceUrl;
  final double score;
  final String excerpt;

  const ChatCitation({
    required this.chunkId,
    required this.documentId,
    required this.documentTitle,
    required this.sourceUrl,
    required this.score,
    required this.excerpt,
  });

  @override
  List<Object?> get props => [
        chunkId,
        documentId,
        documentTitle,
        sourceUrl,
        score,
        excerpt,
      ];
}
