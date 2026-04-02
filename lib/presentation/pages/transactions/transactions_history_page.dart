import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/transaction.dart';
import '../../../injection_container.dart';
import '../../bloc/transaction/transaction_bloc.dart';
import '../../bloc/transaction/transaction_event.dart';
import '../../bloc/transaction/transaction_state.dart';
import '../../widgets/transaction_item.dart';

class TransactionsHistoryPage extends StatefulWidget {
  const TransactionsHistoryPage({super.key});

  @override
  State<TransactionsHistoryPage> createState() => _TransactionsHistoryPageState();
}

class _TransactionsHistoryPageState extends State<TransactionsHistoryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedType = 'all';
  String _selectedCategory = 'all';
  String _selectedPeriod = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Transaction> _applyFilters(List<Transaction> input) {
    var output = input;
    final query = _searchController.text.trim().toLowerCase();

    if (query.isNotEmpty) {
      output = output.where((tx) {
        final title = tx.title.toLowerCase();
        final desc = (tx.description ?? '').toLowerCase();
        return title.contains(query) || desc.contains(query);
      }).toList();
    }

    if (_selectedType != 'all') {
      output = output.where((tx) => tx.type.name == _selectedType).toList();
    }

    if (_selectedCategory != 'all') {
      output = output.where((tx) => tx.category.name == _selectedCategory).toList();
    }

    if (_selectedPeriod == '30d') {
      final cutoff = DateTime.now().subtract(const Duration(days: 30));
      output = output.where((tx) => tx.date.isAfter(cutoff)).toList();
    } else if (_selectedPeriod == 'month') {
      final now = DateTime.now();
      output = output
          .where((tx) => tx.date.year == now.year && tx.date.month == now.month)
          .toList();
    }

    return output;
  }

  String _categoryLabel(String value) {
    switch (value) {
      case 'food':
        return 'Alimentation';
      case 'transport':
        return 'Transport';
      case 'health':
        return 'Santé';
      case 'education':
        return 'Éducation';
      case 'business':
        return 'Business';
      case 'salary':
        return 'Salaire';
      case 'entertainment':
        return 'Divertissement';
      case 'shopping':
        return 'Shopping';
      case 'utilities':
        return 'Charges';
      case 'other':
        return 'Autres';
      default:
        return 'Toutes les catégories';
    }
  }

  List<String> _availableCategoryKeys(List<Transaction> transactions) {
    final keys = transactions.map((tx) => tx.category.name).toSet().toList();
    keys.sort((a, b) => _categoryLabel(a).compareTo(_categoryLabel(b)));
    return keys;
  }

  Widget _buildFiltersCard(List<String> categoryKeys) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 380;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Rechercher une transaction...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close),
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              if (compact) ...[
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  isDense: true,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Tous les types')),
                    DropdownMenuItem(value: 'income', child: Text('Revenus')),
                    DropdownMenuItem(value: 'expense', child: Text('Dépenses')),
                    DropdownMenuItem(value: 'transfer', child: Text('Transferts')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value ?? 'all';
                    });
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  isDense: true,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Catégorie',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 'all',
                      child: Text('Toutes catégories'),
                    ),
                    ...categoryKeys.map(
                      (key) => DropdownMenuItem(
                        value: key,
                        child: Text(_categoryLabel(key)),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value ?? 'all';
                    });
                  },
                ),
              ] else
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedType,
                        isDense: true,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Type',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('Tous les types')),
                          DropdownMenuItem(value: 'income', child: Text('Revenus')),
                          DropdownMenuItem(value: 'expense', child: Text('Dépenses')),
                          DropdownMenuItem(value: 'transfer', child: Text('Transferts')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value ?? 'all';
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        isDense: true,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Catégorie',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: 'all',
                            child: Text('Toutes catégories'),
                          ),
                          ...categoryKeys.map(
                            (key) => DropdownMenuItem(
                              value: key,
                              child: Text(_categoryLabel(key)),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value ?? 'all';
                          });
                        },
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Tout'),
                    selected: _selectedPeriod == 'all',
                    onSelected: (_) => setState(() => _selectedPeriod = 'all'),
                  ),
                  ChoiceChip(
                    label: const Text('30 jours'),
                    selected: _selectedPeriod == '30d',
                    onSelected: (_) => setState(() => _selectedPeriod = '30d'),
                  ),
                  ChoiceChip(
                    label: const Text('Ce mois'),
                    selected: _selectedPeriod == 'month',
                    onSelected: (_) => setState(() => _selectedPeriod = 'month'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _selectedType = 'all';
                      _selectedCategory = 'all';
                      _selectedPeriod = 'all';
                    });
                  },
                  child: const Text('Réinitialiser'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<TransactionBloc>()..add(LoadTransactions()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Historique des transactions'),
        ),
        body: BlocBuilder<TransactionBloc, TransactionState>(
          builder: (context, state) {
            if (state is TransactionLoading || state is TransactionInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is TransactionError) {
              return Center(child: Text(state.message));
            }
            if (state is! TransactionLoaded) {
              return const SizedBox.shrink();
            }

            final categoryKeys = _availableCategoryKeys(state.transactions);
            if (_selectedCategory != 'all' &&
                !categoryKeys.contains(_selectedCategory)) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() {
                  _selectedCategory = 'all';
                });
              });
            }

            final transactions = _applyFilters(state.transactions);
            if (transactions.isEmpty) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<TransactionBloc>().add(LoadTransactions());
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildFiltersCard(categoryKeys),
                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        'Aucune transaction disponible pour ces filtres.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<TransactionBloc>().add(LoadTransactions());
              },
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemBuilder: (_, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildFiltersCard(categoryKeys),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: TransactionItem(transaction: transactions[index - 1]),
                  );
                },
                itemCount: transactions.length + 1,
              ),
            );
          },
        ),
      ),
    );
  }
}
