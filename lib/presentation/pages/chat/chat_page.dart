import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

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
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isSpeechAvailable = false;
  bool _isListening = false;
  String? _speechError;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      final available = await _speechToText.initialize();
      if (!mounted) return;
      setState(() {
        _isSpeechAvailable = available;
      });
    } on MissingPluginException {
      if (!mounted) return;
      setState(() {
        _isSpeechAvailable = false;
        _speechError = "La reconnaissance vocale n'est pas disponible sur cet appareil.";
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSpeechAvailable = false;
      });
    }
  }

  @override
  void dispose() {
    try {
      _speechToText.cancel();
    } on MissingPluginException {
      // Ignore if plugin unavailable on this platform.
    }
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _toggleVoiceCapture() async {
    if (_isListening) {
      await _stopVoiceCapture();
      return;
    }
    await _startVoiceCapture();
  }

  Future<void> _startVoiceCapture() async {
    if (!_isSpeechAvailable) {
      await _initSpeech();
      if (!_isSpeechAvailable) return;
    }
    final locale = Localizations.localeOf(context).languageCode;
    final localeId = switch (locale) {
      'fr' => 'fr_FR',
      'en' => 'en_US',
      _ => null,
    };
    final startedResult = await _speechToText.listen(
      localeId: localeId,
      partialResults: true,
      onResult: (result) {
        if (!mounted) return;
        setState(() {
          _questionController.text = result.recognizedWords;
          _questionController.selection = TextSelection.fromPosition(
            TextPosition(offset: _questionController.text.length),
          );
        });
      },
      onSoundLevelChange: (_) {},
    );
    final started = startedResult is bool ? startedResult : _speechToText.isListening;
    if (!mounted) return;
    setState(() {
      _isListening = started;
      _speechError = started ? null : "Impossible de demarrer l'ecoute vocale.";
    });
  }

  Future<void> _stopVoiceCapture() async {
    await _speechToText.stop();
    if (!mounted) return;
    setState(() {
      _isListening = false;
    });
  }

  String _detectQuestionLanguage(String question) {
    final text = question.toLowerCase();
    final tokens = text
        .split(RegExp(r'[^a-zA-ZÀ-ÿ]+'))
        .where((item) => item.trim().isNotEmpty)
        .toSet();

    const english = {
      'what',
      'where',
      'funding',
      'loan',
      'business',
      'eligible',
      'requirements',
    };
    const french = {
      'quel',
      'quels',
      'quelle',
      'quelles',
      'financement',
      'financements',
      'credit',
      'subvention',
      'entreprise',
      'pme',
    };
    const yoruba = {'owo', 'kini', 'awon', 'ise'};
    const fon = {'gbeta', 'wema', 'kpin', 'xo'};

    final scoreEn = tokens.intersection(english).length;
    final scoreFr = tokens.intersection(french).length;
    final scoreYo = tokens.intersection(yoruba).length;
    final scoreFon = tokens.intersection(fon).length;

    if (scoreYo > 0 && scoreYo >= scoreEn && scoreYo >= scoreFr && scoreYo >= scoreFon) {
      return 'yo';
    }
    if (scoreFon > 0 && scoreFon >= scoreEn && scoreFon >= scoreFr && scoreFon >= scoreYo) {
      return 'fon';
    }
    if (scoreFr > 0 && scoreFr >= scoreEn) {
      return 'fr';
    }
    if (scoreEn > 0) {
      return 'en';
    }
    if (RegExp(r'[éèàùç]').hasMatch(text)) {
      return 'fr';
    }
    return Localizations.localeOf(context).languageCode;
  }

  void _sendQuestion() {
    final question = _questionController.text.trim();
    if (question.isEmpty) return;
    final detectedLanguage = _detectQuestionLanguage(question);
    context.read<ChatBloc>().add(
          SendChatMessage(
            question,
            language: detectedLanguage,
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
            if (_isListening || _speechError != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: _isListening
                      ? AppColors.primary.withOpacity(0.1)
                      : AppColors.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _isListening
                      ? 'Ecoute en cours... Parlez maintenant.'
                      : (_speechError ?? ''),
                  style: TextStyle(
                    color: _isListening ? AppColors.primary : AppColors.error,
                    fontSize: 12,
                  ),
                ),
              ),
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
                    IconButton.filledTonal(
                      onPressed: _isSpeechAvailable || _isListening ? _toggleVoiceCapture : null,
                      icon: Icon(
                        _isListening ? Icons.mic_off_outlined : Icons.mic_none_outlined,
                      ),
                      tooltip: _isListening ? 'Arreter la dictée' : 'Dicter la question',
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
