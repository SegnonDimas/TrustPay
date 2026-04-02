import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../config/api_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/transaction.dart';
import '../../../domain/entities/account.dart';
import '../../../domain/repositories/account_repository.dart';
import '../../../injection_container.dart';
import '../../bloc/transaction/transaction_bloc.dart';
import '../../bloc/transaction/transaction_event.dart';
import '../../bloc/transaction/transaction_state.dart';

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final Connectivity _connectivity = Connectivity();
  
  TransactionType _selectedType = TransactionType.expense;
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  DateTime _selectedDate = DateTime.now();
  String? _selectedAccountId;
  String? _selectedToAccountId;
  late final Future<List<Account>> _accountsFuture;
  Future<List<_ApiCategory>>? _categoriesFuture;
  bool _isSubmitting = false;
  bool _isSpeechAvailable = false;
  bool _isListening = false;
  bool _isVoiceProcessing = false;
  String _recognizedText = '';
  String? _voiceError;

  @override
  void initState() {
    super.initState();
    _accountsFuture = sl<AccountRepository>().getAccounts();
    _categoriesFuture = _loadCategories();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _noteController.dispose();
    try {
      _speechToText.cancel();
    } on MissingPluginException {
      // Plugin non disponible (ex: plateforme non supportee).
    }
    super.dispose();
  }

  Future<List<_ApiCategory>> _loadCategories() async {
    final dio = sl<Dio>();
    final response = await dio.get<dynamic>(ApiConfig.categories);
    final data = response.data;
    final list = data is Map<String, dynamic> && data['results'] is List
        ? data['results'] as List<dynamic>
        : (data as List<dynamic>? ?? const []);
    return list
        .map(
          (e) => _ApiCategory.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
  }

  List<_ApiCategory> _categoriesForType(
    List<_ApiCategory> allCategories,
    TransactionType type,
  ) {
    final neededType = type == TransactionType.income ? 'income' : 'expense';
    return allCategories
        .where((c) => c.categoryType.contains(neededType))
        .toList();
  }

  TransactionCategory _mapToDomainCategory(String categoryName) {
    final normalized = categoryName.toLowerCase();
    if (normalized.contains('food') || normalized.contains('alimentation')) {
      return TransactionCategory.food;
    }
    if (normalized.contains('transport')) return TransactionCategory.transport;
    if (normalized.contains('health') || normalized.contains('sante')) {
      return TransactionCategory.health;
    }
    if (normalized.contains('education')) return TransactionCategory.education;
    if (normalized.contains('business')) return TransactionCategory.business;
    if (normalized.contains('salary') || normalized.contains('revenu')) {
      return TransactionCategory.salary;
    }
    if (normalized.contains('entertain') || normalized.contains('loisir')) {
      return TransactionCategory.entertainment;
    }
    if (normalized.contains('shopping') || normalized.contains('achat')) {
      return TransactionCategory.shopping;
    }
    if (normalized.contains('utilit') || normalized.contains('facture')) {
      return TransactionCategory.utilities;
    }
    return TransactionCategory.other;
  }

  Account? _getSelectedSourceAccount(List<Account> accounts) {
    if (_selectedAccountId == null) return null;
    for (final account in accounts) {
      if (account.id == _selectedAccountId) return account;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TransactionBloc, TransactionState>(
      listener: (context, state) {
        if (state is TransactionSuccess) {
          setState(() => _isSubmitting = false);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transaction ajoutée !'),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop(true);
        } else if (state is TransactionError) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Nouvelle Transaction'),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _isVoiceProcessing
              ? null
              : () {
                  if (_isListening) {
                    unawaited(_stopVoiceCapture(processDraft: true));
                  } else {
                    unawaited(_startVoiceCapture());
                  }
                },
          icon: Icon(
            _isListening ? Icons.stop_circle_outlined : Icons.mic_none_outlined,
          ),
          label: Text(
            _isListening ? 'Arreter' : 'Dicter',
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              if (_isListening)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Ecoute en cours... decrivez votre transaction.',
                        ),
                      ),
                    ],
                  ),
                ),
              if (_isVoiceProcessing)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text('Analyse de la transcription en cours...'),
                      ),
                    ],
                  ),
                ),
              if (_voiceError != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _voiceError!,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              _buildTypeSelector(),
              const SizedBox(height: 32),
              const Text('Montant (FCFA)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary),
                decoration: const InputDecoration(
                  hintText: '0',
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Entrez un montant' : null,
              ),
              const SizedBox(height: 24),
              const Text('Titre', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(hintText: 'Ex: Courses supermarché'),
                validator: (value) => value == null || value.isEmpty ? 'Entrez un titre' : null,
              ),
              const SizedBox(height: 24),
              const Text('Note (optionnelle)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Details ou contexte de la transaction',
                ),
              ),
              const SizedBox(height: 24),
              FutureBuilder<List<Account>>(
                future: _accountsFuture,
                builder: (context, accountSnapshot) {
                  _categoriesFuture ??= _loadCategories();
                  return FutureBuilder<List<_ApiCategory>>(
                    future: _categoriesFuture!,
                    builder: (context, categorySnapshot) {
                      final accounts = accountSnapshot.data ?? const <Account>[];
                      final categories =
                          categorySnapshot.data ?? const <_ApiCategory>[];
                      final filteredCategories =
                          _categoriesForType(categories, _selectedType);
                      final sourceAccount =
                          _getSelectedSourceAccount(accounts);
                      final currencyFormat = NumberFormat.currency(
                        locale: 'fr_BJ',
                        symbol: 'FCFA',
                        decimalDigits: 0,
                      );

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Compte source',
                                        style: TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<String>(
                                      isExpanded: true,
                                      value: _selectedAccountId,
                                      items: accounts
                                          .map((a) => DropdownMenuItem(
                                              value: a.id, child: Text(a.name)))
                                          .toList(),
                                      onChanged: (val) =>
                                          setState(() => _selectedAccountId = val),
                                      decoration: const InputDecoration(
                                          contentPadding:
                                              EdgeInsets.symmetric(horizontal: 12)),
                                      validator: (value) => value == null
                                          ? 'Sélectionnez un compte'
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _selectedType == TransactionType.transfer
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('Compte destination',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      DropdownButtonFormField<String>(
                                        isExpanded: true,
                                        value: _selectedToAccountId,
                                        items: accounts
                                            .map((a) => DropdownMenuItem(
                                                value: a.id,
                                                child: Text(a.name)))
                                            .toList(),
                                        onChanged: (val) => setState(
                                            () => _selectedToAccountId = val),
                                        decoration: const InputDecoration(
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 12),
                                        ),
                                        validator: (value) {
                                          if (_selectedType !=
                                              TransactionType.transfer) {
                                            return null;
                                          }
                                          if (value == null) {
                                            return 'Compte destination requis';
                                          }
                                          if (value == _selectedAccountId) {
                                            return 'Doit etre different du compte source';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Catégorie',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          InkWell(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            onTap: () async {
                                              await context.push('/categories');
                                              setState(() {
                                                _categoriesFuture =
                                                    _loadCategories();
                                                _selectedCategoryId = null;
                                                _selectedCategoryName = null;
                                              });
                                            },
                                            child: const Padding(
                                              padding: EdgeInsets.all(2),
                                              child: Icon(
                                                Icons.add_circle_outline,
                                                size: 18,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      DropdownButtonFormField<String>(
                                        isExpanded: true,
                                        value: _selectedCategoryId,
                                        items: filteredCategories
                                            .map(
                                              (c) => DropdownMenuItem(
                                                value: c.id,
                                                child: Text(c.name),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (val) => setState(
                                          () {
                                            _selectedCategoryId = val;
                                            final selected = filteredCategories
                                                .where((c) => c.id == val)
                                                .toList();
                                            _selectedCategoryName = selected
                                                    .isNotEmpty
                                                ? selected.first.name
                                                : null;
                                          },
                                        ),
                                        decoration: const InputDecoration(
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 12),
                                        ),
                                        validator: (value) {
                                          if (_selectedType ==
                                              TransactionType.transfer) {
                                            return null;
                                          }
                                          if (filteredCategories.isEmpty) {
                                            return _selectedType ==
                                                    TransactionType.income
                                                ? 'Aucune catégorie revenu disponible'
                                                : 'Aucune catégorie dépense disponible';
                                          }
                                          if (value == null || value.isEmpty) {
                                            return 'Catégorie requise';
                                          }
                                          return null;
                                        },
                                      ),
                                      if (filteredCategories.isEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.info_outline,
                                                size: 14,
                                                color: AppColors.textSecondary,
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  _selectedType ==
                                                          TransactionType.income
                                                      ? 'Aucune catégorie revenu'
                                                      : 'Aucune catégorie dépense',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                              ),
                            ],
                          ),
                          if (_selectedType == TransactionType.transfer &&
                              sourceAccount != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Solde disponible: ${currencyFormat.format(sourceAccount.balance)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
              const Text('Date', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) setState(() => _selectedDate = date);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 20, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Text(DateFormat('dd MMMM yyyy').format(_selectedDate)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Enregistrer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _ensureSpeechInitialized() async {
    if (_isSpeechAvailable) return true;
    if (!_isSpeechSupportedPlatform()) {
      if (mounted) {
        setState(() {
          _voiceError =
              'La reconnaissance vocale n\'est pas supportee sur cette plateforme.';
        });
      }
      return false;
    }

    try {
      final available = await _speechToText.initialize(
        onStatus: (status) {
          if (status == 'done' && _isListening) {
            unawaited(_stopVoiceCapture(processDraft: true));
          }
        },
        onError: (error) {
          if (!mounted) return;
          setState(() {
            _isListening = false;
            _voiceError = 'Erreur vocale: ${error.errorMsg}';
          });
        },
      );
      if (!mounted) return false;
      setState(() => _isSpeechAvailable = available);
      return available;
    } on MissingPluginException {
      if (!mounted) return false;
      setState(() {
        _voiceError =
            'Plugin vocal indisponible. Faites un redemarrage complet de l\'app.';
      });
      return false;
    } on PlatformException catch (e) {
      if (!mounted) return false;
      setState(() {
        _voiceError = 'Initialisation vocale echouee: ${e.message ?? e.code}';
      });
      return false;
    } catch (_) {
      if (!mounted) return false;
      setState(() {
        _voiceError = 'Impossible d\'initialiser la reconnaissance vocale.';
      });
      return false;
    }
  }

  bool _isSpeechSupportedPlatform() {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows;
  }

  Future<void> _startVoiceCapture() async {
    setState(() => _voiceError = null);
    final available = await _ensureSpeechInitialized();
    if (!available) {
      if (!mounted) return;
      setState(() {
        _voiceError =
            'La reconnaissance vocale n\'est pas disponible sur cet appareil.';
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _recognizedText = '';
      _isListening = true;
    });

    try {
      await _speechToText.listen(
        onResult: (result) {
          if (!mounted) return;
          setState(() {
            _recognizedText = result.recognizedWords.trim();
          });
          if (result.finalResult) {
            unawaited(_stopVoiceCapture(processDraft: true));
          }
        },
        localeId: 'fr_FR',
        partialResults: true,
        cancelOnError: true,
        listenFor: const Duration(seconds: 35),
        pauseFor: const Duration(seconds: 3),
      );
    } on MissingPluginException {
      if (!mounted) return;
      setState(() {
        _isListening = false;
        _voiceError =
            'Plugin vocal non detecte. Redemarrez completement l\'application.';
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() {
        _isListening = false;
        _voiceError = 'Demarrage micro echoue: ${e.message ?? e.code}';
      });
    }
  }

  Future<void> _stopVoiceCapture({required bool processDraft}) async {
    if (_speechToText.isListening) {
      await _speechToText.stop();
    }
    if (!mounted) return;
    setState(() => _isListening = false);
    if (processDraft) {
      await _processRecognizedTextFlow();
    }
  }

  Future<void> _processRecognizedTextFlow() async {
    final transcript = _recognizedText.trim();
    if (transcript.isEmpty) {
      if (!mounted) return;
      setState(() => _voiceError = 'Aucun texte detecte. Reessayez.');
      return;
    }

    if (!mounted) return;
    setState(() {
      _isVoiceProcessing = true;
      _voiceError = null;
    });

    try {
      final categories = await (_categoriesFuture ??= _loadCategories());
      final accounts = await _accountsFuture;
      final localDraft = _buildLocalDraft(
        transcript,
        categories: categories,
        accounts: accounts,
      );

      var finalDraft = localDraft;
      var usedLlm = false;
      final isOnline = await _hasInternetConnection();
      final score = _draftCompletenessScore(localDraft);
      final canUseLlm = isOnline && ApiConfig.openRouterApiKey.isNotEmpty;

      if (canUseLlm && score < 0.7) {
        final llmDraft = await _tryEnhanceDraftWithLlm(
          transcript: transcript,
          localDraft: localDraft,
          categoryNames: categories.map((c) => c.name).toList(),
        );
        if (llmDraft != null) {
          usedLlm = true;
          finalDraft = _mergeDraft(localDraft, llmDraft);
        }
      }

      if (!mounted) return;
      final confirmed = await _showVoiceConfirmation(
        transcript: transcript,
        draft: finalDraft,
        usedLlm: usedLlm,
      );
      if (confirmed == true) {
        await _applyDraftToForm(finalDraft);
      }
    } finally {
      if (!mounted) return;
      setState(() => _isVoiceProcessing = false);
    }
  }

  Future<bool?> _showVoiceConfirmation({
    required String transcript,
    required _VoiceDraft draft,
    required bool usedLlm,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Confirmation vocale',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (usedLlm)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Enrichissement IA applique (en ligne).',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  transcript,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                _buildDraftRow('Type', draft.typeLabel ?? '-'),
                _buildDraftRow(
                  'Montant',
                  draft.amount != null
                      ? NumberFormat('#,##0', 'fr_BJ').format(draft.amount)
                      : '-',
                ),
                _buildDraftRow('Categorie', draft.categoryName ?? '-'),
                _buildDraftRow(
                  'Date',
                  draft.date != null
                      ? DateFormat('dd/MM/yyyy').format(draft.date!)
                      : '-',
                ),
                _buildDraftRow('Titre', draft.title ?? '-'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Annuler'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Appliquer'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDraftRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _applyDraftToForm(_VoiceDraft draft) async {
    final categories = await (_categoriesFuture ??= _loadCategories());
    final accounts = await _accountsFuture;

    if (!mounted) return;
    setState(() {
      if (draft.type != null) {
        _selectedType = draft.type!;
        if (_selectedType != TransactionType.transfer) {
          _selectedToAccountId = null;
        }
      }

      if (draft.amount != null && _amountController.text.trim().isEmpty) {
        _amountController.text = _formatAmountForInput(draft.amount!);
      }
      if ((draft.title ?? '').isNotEmpty && _titleController.text.trim().isEmpty) {
        _titleController.text = draft.title!;
      }
      if ((draft.note ?? '').isNotEmpty && _noteController.text.trim().isEmpty) {
        _noteController.text = draft.note!;
      }
      if (draft.date != null) {
        _selectedDate = draft.date!;
      }
    });

    if (_selectedType != TransactionType.transfer &&
        (draft.categoryName ?? '').isNotEmpty) {
      final filteredCategories = _categoriesForType(categories, _selectedType);
      final selected = _findCategoryByName(
        draft.categoryName!,
        filteredCategories,
      );
      if (selected != null && mounted) {
        setState(() {
          _selectedCategoryId = selected.id;
          _selectedCategoryName = selected.name;
        });
      }
    }

    final sourceId = _findAccountIdByName(draft.accountSourceName, accounts);
    final destinationId = _findAccountIdByName(draft.accountDestinationName, accounts);
    if (!mounted) return;
    setState(() {
      _selectedAccountId = sourceId ?? _selectedAccountId;
      if (_selectedType == TransactionType.transfer) {
        _selectedToAccountId = destinationId ?? _selectedToAccountId;
      }
    });
  }

  String _formatAmountForInput(double amount) {
    final rounded = amount.roundToDouble();
    if (rounded == amount) return rounded.toInt().toString();
    return amount.toStringAsFixed(2);
  }

  _VoiceDraft _buildLocalDraft(
    String transcript, {
    required List<_ApiCategory> categories,
    required List<Account> accounts,
  }) {
    final normalized = _normalizeText(transcript);
    final type = _inferTypeFromText(normalized);
    final amount = _extractAmount(normalized);
    final date = _extractDate(normalized) ?? DateTime.now();
    final category = type == TransactionType.transfer
        ? null
        : _findCategoryByName(normalized, _categoriesForType(categories, type));

    final sourceName = _extractAccountAfterKeyword(normalized, 'depuis', accounts);
    final destinationName = _extractAccountAfterKeyword(
      normalized,
      'vers',
      accounts,
    );

    return _VoiceDraft(
      type: type,
      amount: amount,
      categoryName: category?.name,
      date: date,
      title: _suggestTitle(type, category?.name, amount),
      note: transcript,
      accountSourceName: sourceName,
      accountDestinationName: destinationName,
      confidence: 0.6,
    );
  }

  String _suggestTitle(TransactionType type, String? categoryName, double? amount) {
    if ((categoryName ?? '').isNotEmpty) {
      return categoryName!;
    }
    if (type == TransactionType.transfer) return 'Transfert';
    if (type == TransactionType.income) return 'Revenu';
    if (amount != null) return 'Depense ${_formatAmountForInput(amount)}';
    return 'Transaction';
  }

  TransactionType _inferTypeFromText(String normalized) {
    if (_containsAny(normalized, const ['transfert', 'envoye', 'virement'])) {
      return TransactionType.transfer;
    }
    if (_containsAny(normalized, const ['recu', 'gagne', 'salaire', 'vente'])) {
      return TransactionType.income;
    }
    return TransactionType.expense;
  }

  bool _containsAny(String text, List<String> words) {
    for (final word in words) {
      if (text.contains(word)) return true;
    }
    return false;
  }

  double? _extractAmount(String text) {
    final match = RegExp(r'(\d[\d\s.,]{0,15})').firstMatch(text);
    if (match == null) return null;
    final raw = match.group(1);
    if (raw == null) return null;
    final normalized = raw.replaceAll(RegExp(r'\s'), '').replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  DateTime? _extractDate(String text) {
    final now = DateTime.now();
    if (text.contains('hier')) {
      return DateTime(now.year, now.month, now.day - 1);
    }
    if (text.contains('aujourd') || text.contains('ce matin')) {
      return DateTime(now.year, now.month, now.day);
    }
    return null;
  }

  _ApiCategory? _findCategoryByName(String value, List<_ApiCategory> categories) {
    if (value.trim().isEmpty) return null;
    final normalizedValue = _normalizeText(value);
    for (final category in categories) {
      final normalizedName = _normalizeText(category.name);
      if (normalizedValue.contains(normalizedName) ||
          normalizedName.contains(normalizedValue)) {
        return category;
      }
    }
    return null;
  }

  String? _extractAccountAfterKeyword(
    String normalizedText,
    String keyword,
    List<Account> accounts,
  ) {
    final pattern = RegExp('$keyword\\s+([a-zA-Z0-9\\s_-]{2,30})');
    final match = pattern.firstMatch(normalizedText);
    if (match == null) return null;
    final candidate = match.group(1)?.trim();
    if (candidate == null || candidate.isEmpty) return null;
    for (final account in accounts) {
      final normalizedName = _normalizeText(account.name);
      if (candidate.contains(normalizedName) || normalizedName.contains(candidate)) {
        return account.name;
      }
    }
    return null;
  }

  String? _findAccountIdByName(String? name, List<Account> accounts) {
    if ((name ?? '').trim().isEmpty) return null;
    final target = _normalizeText(name!);
    for (final account in accounts) {
      if (_normalizeText(account.name) == target) {
        return account.id;
      }
    }
    return null;
  }

  String _normalizeText(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[àáâãäå]'), 'a')
        .replaceAll(RegExp(r'[èéêë]'), 'e')
        .replaceAll(RegExp(r'[ìíîï]'), 'i')
        .replaceAll(RegExp(r'[òóôõö]'), 'o')
        .replaceAll(RegExp(r'[ùúûü]'), 'u')
        .replaceAll(RegExp(r'ç'), 'c')
        .replaceAll(RegExp(r'[^a-z0-9\s._-]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  double _draftCompletenessScore(_VoiceDraft draft) {
    var score = 0.0;
    if (draft.type != null) score += 0.25;
    if (draft.amount != null && draft.amount! > 0) score += 0.35;
    if (draft.type == TransactionType.transfer ||
        (draft.categoryName ?? '').isNotEmpty) {
      score += 0.25;
    }
    if ((draft.title ?? '').isNotEmpty) score += 0.15;
    return score.clamp(0.0, 1.0).toDouble();
  }

  Future<bool> _hasInternetConnection() async {
    final result = await _connectivity.checkConnectivity();
    return result.any((e) => e != ConnectivityResult.none);
  }

  Future<_VoiceDraft?> _tryEnhanceDraftWithLlm({
    required String transcript,
    required _VoiceDraft localDraft,
    required List<String> categoryNames,
  }) async {
    final apiKey = ApiConfig.openRouterApiKey.trim();
    if (apiKey.isEmpty) return null;

    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
        headers: <String, String>{
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      ),
    );

    final prompt = '''
      Tu extrais des champs de transaction depuis une transcription vocale.
      Renvoie STRICTEMENT un JSON valide, sans markdown.

      Schema JSON attendu:
      {
        "type": "income|expense|transfer|null",
        "amount": number|null,
        "category_name": string|null,
        "date_iso": string|null,
        "title": string|null,
        "note": string|null,
        "account_source_name": string|null,
        "account_destination_name": string|null,
        "confidence": number
      }

      Categories autorisees: ${categoryNames.join(', ')}
      Draft local actuel: ${jsonEncode(localDraft.toJson())}
      Transcription: "$transcript"
      ''';

    try {
      final response = await dio.post<Map<String, dynamic>>(
        ApiConfig.openRouterBaseUrl,
        data: <String, dynamic>{
          'model': 'openai/gpt-4o-mini',
          'temperature': 0,
          'messages': [
            {
              'role': 'system',
              'content':
                  'Tu es un extracteur de champs. Reponds seulement avec du JSON.'
            },
            {'role': 'user', 'content': prompt},
          ],
        },
      );

      final content = response.data?['choices']?[0]?['message']?['content'];
      if (content is! String || content.trim().isEmpty) return null;
      final jsonText = _extractJsonFromText(content);
      if (jsonText == null) return null;
      final decoded = jsonDecode(jsonText);
      if (decoded is! Map<String, dynamic>) return null;
      return _VoiceDraft.fromLlmJson(decoded);
    } catch (_) {
      return null;
    }
  }

  String? _extractJsonFromText(String text) {
    final trimmed = text.trim();
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      return trimmed;
    }
    final start = trimmed.indexOf('{');
    final end = trimmed.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) return null;
    return trimmed.substring(start, end + 1);
  }

  _VoiceDraft _mergeDraft(_VoiceDraft local, _VoiceDraft llm) {
    final llmConfidence = llm.confidence ?? 0;
    final canOverride = llmConfidence >= 0.75;
    return _VoiceDraft(
      type: local.type ?? llm.type,
      amount: local.amount ?? llm.amount,
      categoryName: local.categoryName ?? llm.categoryName,
      date: local.date ?? llm.date,
      title: local.title ?? llm.title,
      note: local.note ?? llm.note,
      accountSourceName: local.accountSourceName ?? llm.accountSourceName,
      accountDestinationName:
          local.accountDestinationName ?? llm.accountDestinationName,
      confidence: local.confidence ?? llm.confidence,
    ).withOptionalOverrides(
      llm: llm,
      enabled: canOverride,
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: TransactionType.values.map((type) {
          final isSelected = _selectedType == type;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _selectedType = type;
                if (type != TransactionType.transfer) {
                  _selectedToAccountId = null;
                }
                _selectedCategoryId = null;
                _selectedCategoryName = null;
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : null,
                ),
                child: Center(
                  child: Text(
                    type == TransactionType.income ? 'Revenu' : type == TransactionType.expense ? 'Dépense' : 'Transfert',
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedType == TransactionType.transfer) {
        final accounts = await _accountsFuture;
        final source = _getSelectedSourceAccount(accounts);
        final amount = double.tryParse(_amountController.text.trim()) ?? 0;
        if (source != null && amount > source.balance) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Montant supérieur au solde disponible.'),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }
      }

      final selectedApiCategory = _selectedCategoryId;
      final transaction = Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        amount: double.parse(_amountController.text),
        date: _selectedDate,
        type: _selectedType,
        category: _selectedType == TransactionType.transfer
            ? TransactionCategory.other
            : _mapToDomainCategory(_selectedCategoryName ?? ''),
        categoryId:
            _selectedType == TransactionType.transfer ? null : selectedApiCategory,
        accountId: _selectedAccountId,
        toAccountId: _selectedToAccountId,
        description: _noteController.text,
      );

      setState(() => _isSubmitting = true);
      context.read<TransactionBloc>().add(AddTransaction(transaction));
    }
  }
}

class _VoiceDraft {
  final TransactionType? type;
  final double? amount;
  final String? categoryName;
  final DateTime? date;
  final String? title;
  final String? note;
  final String? accountSourceName;
  final String? accountDestinationName;
  final double? confidence;

  const _VoiceDraft({
    this.type,
    this.amount,
    this.categoryName,
    this.date,
    this.title,
    this.note,
    this.accountSourceName,
    this.accountDestinationName,
    this.confidence,
  });

  String? get typeLabel {
    if (type == null) return null;
    switch (type!) {
      case TransactionType.income:
        return 'Revenu';
      case TransactionType.expense:
        return 'Depense';
      case TransactionType.transfer:
        return 'Transfert';
    }
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'type': type?.name,
      'amount': amount,
      'category_name': categoryName,
      'date_iso': date?.toIso8601String(),
      'title': title,
      'note': note,
      'account_source_name': accountSourceName,
      'account_destination_name': accountDestinationName,
      'confidence': confidence,
    };
  }

  _VoiceDraft withOptionalOverrides({
    required _VoiceDraft llm,
    required bool enabled,
  }) {
    if (!enabled) return this;
    return _VoiceDraft(
      type: llm.type ?? type,
      amount: llm.amount ?? amount,
      categoryName: llm.categoryName ?? categoryName,
      date: llm.date ?? date,
      title: llm.title ?? title,
      note: llm.note ?? note,
      accountSourceName: llm.accountSourceName ?? accountSourceName,
      accountDestinationName: llm.accountDestinationName ?? accountDestinationName,
      confidence: llm.confidence ?? confidence,
    );
  }

  static _VoiceDraft fromLlmJson(Map<String, dynamic> json) {
    final rawType = (json['type'] as String?)?.trim().toLowerCase();
    TransactionType? type;
    if (rawType == 'income') {
      type = TransactionType.income;
    } else if (rawType == 'expense') {
      type = TransactionType.expense;
    } else if (rawType == 'transfer') {
      type = TransactionType.transfer;
    }

    final rawAmount = json['amount'];
    final amount = rawAmount is num
        ? rawAmount.toDouble()
        : double.tryParse((rawAmount ?? '').toString());

    DateTime? date;
    final rawDate = (json['date_iso'] as String?)?.trim();
    if (rawDate != null && rawDate.isNotEmpty) {
      date = DateTime.tryParse(rawDate);
    }

    final rawConfidence = json['confidence'];
    final confidence = rawConfidence is num
        ? rawConfidence.toDouble().clamp(0.0, 1.0).toDouble()
        : double.tryParse(
            (rawConfidence ?? '').toString(),
          )?.clamp(0.0, 1.0).toDouble();

    return _VoiceDraft(
      type: type,
      amount: amount != null && amount > 0 ? amount : null,
      categoryName: (json['category_name'] as String?)?.trim(),
      date: date,
      title: (json['title'] as String?)?.trim(),
      note: (json['note'] as String?)?.trim(),
      accountSourceName: (json['account_source_name'] as String?)?.trim(),
      accountDestinationName:
          (json['account_destination_name'] as String?)?.trim(),
      confidence: confidence,
    );
  }
}

class _ApiCategory {
  final String id;
  final String name;
  final String categoryType;

  const _ApiCategory({
    required this.id,
    required this.name,
    required this.categoryType,
  });

  factory _ApiCategory.fromJson(Map<String, dynamic> json) {
    final rawType =
        ((json['category_type'] as String?) ?? 'expense').trim().toLowerCase();
    final normalizedType =
        rawType.contains('income') ? 'income' : 'expense';
    return _ApiCategory(
      id: json['id'].toString(),
      name: (json['name'] as String?) ?? '',
      categoryType: normalizedType,
    );
  }
}
