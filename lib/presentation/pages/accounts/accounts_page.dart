import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/account.dart';
import '../../../domain/entities/transaction.dart';
import '../../../domain/repositories/account_repository.dart';
import '../../../domain/repositories/transaction_repository.dart';
import '../../../injection_container.dart';
import '../../widgets/transaction_item.dart';

class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key});

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  late final AccountRepository _accountRepository;
  late final TransactionRepository _transactionRepository;
  late Future<_AccountsPageData> _pageFuture;
  final Set<String> _expandedAccountIds = <String>{};

  @override
  void initState() {
    super.initState();
    _accountRepository = sl<AccountRepository>();
    _transactionRepository = sl<TransactionRepository>();
    _pageFuture = _loadPageData();
  }

  Future<_AccountsPageData> _loadPageData() async {
    final accounts = await _accountRepository.getAccounts();
    final transactions = await _transactionRepository.getTransactions();
    return _AccountsPageData(accounts: accounts, transactions: transactions);
  }

  void _reload() {
    setState(() {
      _pageFuture = _loadPageData();
    });
  }

  Future<void> _createAccount() async {
    final nameController = TextEditingController();
    final balanceController = TextEditingController(text: '0');
    final phoneController = TextEditingController();
    String selectedCurrency = 'XOF';
    AccountType selectedType = AccountType.cash;
    String selectedProvider = 'MTN';
    final formKey = GlobalKey<FormState>();

    final created = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nouveau compte'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<AccountType>(
                      value: selectedType,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: const [
                        DropdownMenuItem(
                          value: AccountType.cash,
                          child: Text('Cash'),
                        ),
                        DropdownMenuItem(
                          value: AccountType.bank,
                          child: Text('Banque'),
                        ),
                        DropdownMenuItem(
                          value: AccountType.mobileMoney,
                          child: Text('Mobile Money'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => selectedType = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedCurrency,
                      decoration: const InputDecoration(labelText: 'Devise'),
                      items: const [
                        DropdownMenuItem(value: 'XOF', child: Text('XOF')),
                        DropdownMenuItem(value: 'USD', child: Text('USD')),
                        DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => selectedCurrency = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nom'),
                      validator: (value) => selectedType == AccountType.mobileMoney
                          ? null
                          : (value == null || value.trim().isEmpty)
                              ? 'Nom requis'
                              : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: balanceController,
                      decoration:
                          const InputDecoration(labelText: 'Solde initial (FCFA)'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (selectedType == AccountType.mobileMoney) return null;
                        final parsed = double.tryParse(value ?? '');
                        if (parsed == null) return 'Montant invalide';
                        if (parsed < 0) return 'Le montant doit etre positif';
                        return null;
                      },
                    ),
                    if (selectedType == AccountType.mobileMoney) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedProvider,
                        decoration: const InputDecoration(labelText: 'Operateur'),
                        items: const [
                          DropdownMenuItem(value: 'MTN', child: Text('MTN MoMo')),
                          DropdownMenuItem(value: 'MOOV', child: Text('Moov Money')),
                          DropdownMenuItem(value: 'WAVE', child: Text('Wave')),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() => selectedProvider = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Numero mobile money',
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Numero requis';
                          }
                          return null;
                        },
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Creer'),
            ),
          ],
        );
      },
    );

    if (created != true) return;
    if (!(formKey.currentState?.validate() ?? false)) return;

    try {
      if (selectedType == AccountType.mobileMoney) {
        await _accountRepository.createMobileMoneyWallet(
          provider: selectedProvider,
          phoneNumber: phoneController.text,
        );
      } else {
        await _accountRepository.createAccount(
          Account(
            id: '',
            name: nameController.text.trim(),
            balance: double.parse(balanceController.text),
            currency: selectedCurrency,
            type: selectedType,
          ),
        );
      }
      _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compte cree avec succes.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Echec creation compte: $e')),
      );
    }
  }

  Future<void> _deleteAccount(Account account) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: Text(
            'Supprimer le compte "${account.name}" ? Cette action est irreversible.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      await _accountRepository.deleteAccount(account.id);
      _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compte supprime.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Echec suppression: $e')),
      );
    }
  }

  Future<void> _editAccount(Account account) async {
    final nameController = TextEditingController(text: account.name);
    final balanceController = TextEditingController(
      text: account.balance.toStringAsFixed(0),
    );
    String selectedCurrency = account.currency;
    final walletProvider = account.provider;
    final formKey = GlobalKey<FormState>();

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Modifier le compte'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nom'),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                              ? 'Nom requis'
                              : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: balanceController,
                      decoration: const InputDecoration(
                        labelText: 'Solde actuel',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final parsed = double.tryParse(value ?? '');
                        if (parsed == null) return 'Montant invalide';
                        if (parsed < 0) return 'Le montant doit etre positif';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedCurrency,
                      decoration: const InputDecoration(labelText: 'Devise'),
                      items: const [
                        DropdownMenuItem(value: 'XOF', child: Text('XOF')),
                        DropdownMenuItem(value: 'USD', child: Text('USD')),
                        DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => selectedCurrency = value);
                      },
                    ),
                    if (account.type == AccountType.mobileMoney) ...[
                      const SizedBox(height: 12),
                      InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Provider Mobile Money',
                        ),
                        child: Text(walletProvider ?? 'Inconnu'),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Le provider d’un wallet n’est pas modifiable via cet endpoint.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    InputDecorator(
                      decoration: const InputDecoration(labelText: 'Type'),
                      child: Text(
                        account.type == AccountType.bank
                            ? 'Banque'
                            : account.type == AccountType.mobileMoney
                                ? 'Mobile Money'
                                : 'Cash',
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );

    if (shouldSave != true) return;
    if (!(formKey.currentState?.validate() ?? false)) return;

    try {
      await _accountRepository.updateAccount(
        Account(
          id: account.id,
          name: nameController.text.trim(),
          balance: double.parse(balanceController.text),
          currency: selectedCurrency,
          type: account.type,
          iconPath: account.iconPath,
          accountNumber: account.accountNumber,
        ),
      );
      _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compte mis a jour.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Echec mise a jour: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Comptes'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createAccount,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nouveau compte',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
      ),
      body: FutureBuilder<_AccountsPageData>(
        future: _pageFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erreur chargement comptes: ${snapshot.error}'));
          }

          final pageData = snapshot.data;
          final accounts = pageData?.accounts ?? const <Account>[];
          final allTransactions = pageData?.transactions ?? const <Transaction>[];
          if (accounts.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => _reload(),
              child: ListView(
                children: const [
                  SizedBox(height: 200),
                  Center(child: Text('Aucun compte trouve.')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final account = accounts[index];
                final provider = account.type == AccountType.mobileMoney
                    ? account.provider
                    : null;
                final isExpanded = _expandedAccountIds.contains(account.id);
                final accountTransactions = allTransactions.where((tx) {
                  return tx.accountId == account.id || tx.toAccountId == account.id;
                }).toList();

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        onTap: () {
                          setState(() {
                            if (isExpanded) {
                              _expandedAccountIds.remove(account.id);
                            } else {
                              _expandedAccountIds.add(account.id);
                            }
                          });
                        },
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: Icon(
                            account.type == AccountType.bank
                                ? Icons.account_balance
                                : account.type == AccountType.mobileMoney
                                    ? Icons.phone_android
                                    : Icons.payments,
                            color: AppColors.primary,
                          ),
                        ),
                        title: Text(account.name),
                        subtitle: Text(
                          provider == null
                              ? '${account.balance.toStringAsFixed(0)} ${account.currency}'
                              : '$provider • ${account.balance.toStringAsFixed(0)} ${account.currency}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: AppColors.textSecondary,
                            ),
                            IconButton(
                              onPressed: () => _editAccount(account),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              onPressed: () => _deleteAccount(account),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isExpanded)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          child: Column(
                            children: [
                              const Divider(height: 1),
                              const SizedBox(height: 10),
                              if (accountTransactions.isEmpty)
                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Aucune transaction sur ce compte.',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                )
                              else
                                ...accountTransactions.map(
                                  (tx) => TransactionItem(transaction: tx),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: accounts.length,
            ),
          );
        },
      ),
    );
  }
}

class _AccountsPageData {
  final List<Account> accounts;
  final List<Transaction> transactions;

  const _AccountsPageData({
    required this.accounts,
    required this.transactions,
  });
}
