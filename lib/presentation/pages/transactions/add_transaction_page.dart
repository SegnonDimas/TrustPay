import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/transaction.dart';
import '../../../domain/entities/account.dart';
import '../../bloc/transaction/transaction_bloc.dart';
import '../../bloc/transaction/transaction_event.dart';

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
  TransactionCategory _selectedCategory = TransactionCategory.shopping;
  DateTime _selectedDate = DateTime.now();
  String? _selectedAccountId;

  final List<Account> _mockAccounts = [
    const Account(id: '1', name: 'Cash', balance: 25000, type: AccountType.cash),
    const Account(id: '2', name: 'MTN MoMo', balance: 125000, type: AccountType.mobileMoney),
    const Account(id: '3', name: 'Ecobank', balance: 850000, type: AccountType.bank),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Compte', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedAccountId,
                          items: _mockAccounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
                          onChanged: (val) => setState(() => _selectedAccountId = val),
                          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Catégorie', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<TransactionCategory>(
                          value: _selectedCategory,
                          items: TransactionCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                          onChanged: (val) => setState(() => _selectedCategory = val!),
                          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                        ),
                      ],
                    ),
                  ),
                ],
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
                onPressed: _submitForm,
                child: const Text('Enregistrer'),
              ),
            ],
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
              onTap: () => setState(() => _selectedType = type),
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

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      final transaction = Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        amount: double.parse(_amountController.text),
        date: _selectedDate,
        type: _selectedType,
        category: _selectedCategory,
        accountId: _selectedAccountId,
        description: _noteController.text,
      );
      
      context.read<TransactionBloc>().add(AddTransaction(transaction));
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction ajoutée !'), backgroundColor: AppColors.success),
      );
    }
  }
}
