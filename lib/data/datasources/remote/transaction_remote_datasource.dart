import 'package:dio/dio.dart';

import '../../../config/api_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../domain/entities/transaction.dart';
import '../../models/transaction_model.dart';

abstract class TransactionRemoteDataSource {
  Future<List<TransactionModel>> getTransactions();
  Future<TransactionModel> createTransaction(TransactionModel transaction);
  Future<void> updateTransaction(TransactionModel transaction);
  Future<void> deleteTransaction(String transactionId);
}

class TransactionRemoteDataSourceImpl implements TransactionRemoteDataSource {
  final Dio _dio;
  List<Map<String, dynamic>>? _categoriesCache;

  TransactionRemoteDataSourceImpl(this._dio);

  String _typeToApi(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return 'income';
      case TransactionType.expense:
        return 'expense';
      case TransactionType.transfer:
        return 'transfer';
    }
  }

  List<String> _categoryCandidates(TransactionCategory category) {
    switch (category) {
      case TransactionCategory.food:
        return ['food', 'alimentation', 'nourriture'];
      case TransactionCategory.transport:
        return ['transport', 'deplacement'];
      case TransactionCategory.health:
        return ['health', 'sante'];
      case TransactionCategory.education:
        return ['education', 'ecole'];
      case TransactionCategory.business:
        return ['business', 'entreprise'];
      case TransactionCategory.salary:
        return ['salary', 'salaire', 'revenu'];
      case TransactionCategory.entertainment:
        return ['entertainment', 'loisir'];
      case TransactionCategory.shopping:
        return ['shopping', 'achat'];
      case TransactionCategory.utilities:
        return ['utilities', 'facture'];
      case TransactionCategory.other:
        return ['other', 'autre'];
    }
  }

  Future<List<Map<String, dynamic>>> _getCategories() async {
    if (_categoriesCache != null) return _categoriesCache!;
    final response = await _dio.get<dynamic>(ApiConfig.categories);
    final data = response.data;
    final list = data is Map<String, dynamic> && data['results'] is List
        ? data['results'] as List<dynamic>
        : (data as List<dynamic>? ?? const []);
    _categoriesCache = list
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    return _categoriesCache!;
  }

  Future<int?> _resolveCategoryId(TransactionModel transaction) async {
    if (transaction.type == TransactionType.transfer) return null;

    final categories = await _getCategories();
    final neededType = transaction.type == TransactionType.income
        ? 'income'
        : 'expense';

    if (transaction.categoryId != null && transaction.categoryId!.isNotEmpty) {
      final selectedId = int.tryParse(transaction.categoryId!);
      if (selectedId != null) {
        final selected = categories.firstWhere(
          (c) => int.tryParse(c['id']?.toString() ?? '') == selectedId,
          orElse: () => <String, dynamic>{},
        );
        final selectedType =
            selected['category_type']?.toString().toLowerCase() ?? '';
        if (selected.isNotEmpty && selectedType == neededType) {
          return selectedId;
        }
      }
    }

    final candidates = _categoryCandidates(transaction.category);

    final exactMatch = categories.firstWhere(
      (c) {
        final type = c['category_type']?.toString().toLowerCase();
        final name = c['name']?.toString().toLowerCase() ?? '';
        return type == neededType && candidates.contains(name);
      },
      orElse: () => <String, dynamic>{},
    );
    if (exactMatch.isNotEmpty) {
      return int.tryParse(exactMatch['id']?.toString() ?? '');
    }

    final fuzzyMatch = categories.firstWhere(
      (c) {
        final type = c['category_type']?.toString().toLowerCase();
        final name = c['name']?.toString().toLowerCase() ?? '';
        return type == neededType &&
            candidates.any((candidate) => name.contains(candidate));
      },
      orElse: () => <String, dynamic>{},
    );
    if (fuzzyMatch.isNotEmpty) {
      return int.tryParse(fuzzyMatch['id']?.toString() ?? '');
    }

    final firstByType = categories.firstWhere(
      (c) => c['category_type']?.toString().toLowerCase() == neededType,
      orElse: () => <String, dynamic>{},
    );
    return int.tryParse(firstByType['id']?.toString() ?? '');
  }

  Future<Map<String, dynamic>> _buildPayload(TransactionModel transaction) async {
    final categoryId = await _resolveCategoryId(transaction);
    final note = transaction.description != null && transaction.description!.isNotEmpty
        ? '${transaction.title} - ${transaction.description}'
        : transaction.title;

    return {
      'transaction_type': _typeToApi(transaction.type),
      'amount': transaction.amount,
      'date': transaction.date.toIso8601String(),
      'account': transaction.accountId == null
          ? null
          : int.tryParse(transaction.accountId!),
      'to_account': transaction.toAccountId == null
          ? null
          : int.tryParse(transaction.toAccountId!),
      'category': categoryId,
      'note': note,
    };
  }

  @override
  Future<List<TransactionModel>> getTransactions() async {
    try {
      final response = await _dio.get<dynamic>(ApiConfig.transactions);
      final data = response.data;
      final list = data is Map<String, dynamic> && data['results'] is List
          ? data['results'] as List<dynamic>
          : (data as List<dynamic>? ?? const []);
      return list
          .map((e) => TransactionModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<TransactionModel> createTransaction(TransactionModel transaction) async {
    try {
      final payload = await _buildPayload(transaction);
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConfig.transactions,
        data: payload,
      );
      return TransactionModel.fromJson(response.data ?? <String, dynamic>{});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<void> updateTransaction(TransactionModel transaction) async {
    try {
      final payload = await _buildPayload(transaction);
      await _dio.patch<void>(
        '${ApiConfig.transactions}${transaction.id}/',
        data: payload,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<void> deleteTransaction(String transactionId) async {
    try {
      await _dio.delete<void>('${ApiConfig.transactions}$transactionId/');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
