import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
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
  
  TransactionType _selectedType = TransactionType.expense;
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  DateTime _selectedDate = DateTime.now();
  String? _selectedAccountId;
  String? _selectedToAccountId;
  late final Future<List<Account>> _accountsFuture;
  Future<List<_ApiCategory>>? _categoriesFuture;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _accountsFuture = sl<AccountRepository>().getAccounts();
    _categoriesFuture = _loadCategories();
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
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
