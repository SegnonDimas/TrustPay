import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;

  const ApiException(this.message);

  factory ApiException.fromDioException(DioException error) {
    final response = error.response;
    final data = response?.data;

    if (response == null) {
      return const ApiException(
        'Impossible de contacter le serveur. Verifiez votre connexion internet.',
      );
    }

    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail is String && detail.trim().isNotEmpty) {
        return ApiException(detail);
      }

      for (final entry in data.entries) {
        final value = entry.value;
        if (value is List && value.isNotEmpty) {
          return ApiException(value.first.toString());
        }
        if (value is String && value.trim().isNotEmpty) {
          return ApiException(value);
        }
      }
    }

    switch (response.statusCode) {
      case 400:
        return const ApiException('La requete est invalide.');
      case 401:
        return const ApiException('Session expiree. Reconnectez-vous.');
      case 403:
        return const ApiException('Vous n avez pas la permission.');
      case 404:
        return const ApiException('Ressource introuvable.');
      case 500:
        return const ApiException('Erreur serveur. Reessayez plus tard.');
      default:
        return ApiException('Erreur API (${response.statusCode}).');
    }
  }

  @override
  String toString() => message;
}
