import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/chat_citation.dart';
import '../../../presentation/bloc/chat/chat_bloc.dart';
import '../../../presentation/bloc/chat/chat_event.dart';
import '../../../presentation/bloc/chat/chat_state.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendQuestion() {
    final question = _questionController.text.trim();
    if (question.isEmpty) return;
    final preferredLanguage = Localizations.localeOf(context).languageCode;
    context.read<ChatBloc>().add(
          SendChatMessage(
            question,
            preferredLanguage: preferredLanguage,
          ),
        );
    _questionController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSourcesSheet() {
    context.read<ChatBloc>().add(LoadFundingSources());
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return BlocProvider.value(
          value: context.read<ChatBloc>(),
          child: const _FundingSourcesSheet(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChatBloc, ChatState>(
      listenWhen: (previous, current) => previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        if (state.errorMessage == null || state.errorMessage!.trim().isEmpty) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
        context.read<ChatBloc>().add(ClearChatError());
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Assistant financement'),
          actions: [
            IconButton(
              tooltip: 'Voir les sources',
              onPressed: _showSourcesSheet,
              icon: const Icon(Icons.library_books_outlined),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: BlocBuilder<ChatBloc, ChatState>(
                builder: (context, state) {
                  if (state.messages.isEmpty) {
                    return const _ChatEmptyState();
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: state.messages.length + (state.isSending ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= state.messages.length) {
                        return const _TypingBubble();
                      }
                      final message = state.messages[index];
                      return _ChatMessageBubble(message: message);
                    },
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _questionController,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendQuestion(),
                        decoration: InputDecoration(
                          hintText: 'Posez une question sur les financements...',
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    BlocBuilder<ChatBloc, ChatState>(
                      builder: (context, state) {
                        return IconButton.filled(
                          onPressed: state.isSending ? null : _sendQuestion,
                          icon: const Icon(Icons.send_rounded),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatEmptyState extends StatelessWidget {
  const _ChatEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.chat_bubble_outline, size: 42, color: AppColors.primary),
            SizedBox(height: 12),
            Text(
              'Demandez des offres de financement disponibles pour votre activite.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _ChatMessageBubble extends StatelessWidget {
  final dynamic message;

  const _ChatMessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser as bool;
    final createdAt = message.createdAt as DateTime;
    final bubbleColor = isUser ? AppColors.primary : AppColors.surface;
    final textColor = isUser ? Colors.white : AppColors.textPrimary;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(12),
          border: isUser ? null : Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text as String,
              style: TextStyle(color: textColor),
            ),
            if (!isUser && ((message.detectedLanguage as String).trim().isNotEmpty ||
                (message.modelUsed as String).trim().isNotEmpty ||
                (message.fallbackReason as String).trim().isNotEmpty)) ...[
              const SizedBox(height: 8),
              Text(
                'Langue: ${(message.detectedLanguage as String).isEmpty ? '-' : message.detectedLanguage} • Modele: ${(message.modelUsed as String).isEmpty ? '-' : message.modelUsed}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              if ((message.fallbackReason as String).trim().isNotEmpty)
                Text(
                  'Fallback: ${message.fallbackReason}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.warning,
                  ),
                ),
            ],
            if (!isUser && (message.citations as List<ChatCitation>).isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: (message.citations as List<ChatCitation>)
                    .take(3)
                    .map(
                      (citation) => Chip(
                        label: Text(
                          citation.documentTitle,
                          overflow: TextOverflow.ellipsis,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                    .toList(),
              ),
            ],
            if (!isUser && (message.limits as List<String>).isNotEmpty) ...[
              const SizedBox(height: 8),
              ...(message.limits as List<String>)
                  .take(2)
                  .map(
                    (limit) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        '- $limit',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ],
            const SizedBox(height: 6),
            Text(
              DateFormat.Hm().format(createdAt),
              style: TextStyle(
                color: isUser ? Colors.white70 : AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FundingSourcesSheet extends StatelessWidget {
  const _FundingSourcesSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: BlocBuilder<ChatBloc, ChatState>(
          builder: (context, state) {
            if (state.isLoadingSources) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.sources.isEmpty) {
              return const Center(
                child: Text('Aucune source indexee pour le moment.'),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sources de financement',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: state.sources.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (context, index) {
                      final source = state.sources[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(source.title),
                        subtitle: Text(
                          '${source.sourceType.toUpperCase()} • ${source.country} • ${source.chunkCount} chunks',
                        ),
                        trailing: source.sourceUrl.trim().isEmpty
                            ? null
                            : const Icon(Icons.open_in_new, size: 18),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
