import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/repositories/export_repository.dart';
import '../../../injection_container.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthBloc>()..add(LoadProfileRequested()),
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state.user;
          final accountType = user?.phoneNumber == null ? 'Compte Individuel' : 'Compte Professionnel';

          return Scaffold(
            appBar: AppBar(
              title: const Text('Profil'),
              actions: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.settings_outlined),
                ),
              ],
            ),
            body: state.status == AuthStatus.loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        _buildProfileHeader(
                          user?.name ?? 'Utilisateur',
                          user?.email ?? '',
                        ),
                        const SizedBox(height: 32),
                        _buildSectionTitle('Type de compte'),
                        _buildAccountTypeCard(accountType),
                        const SizedBox(height: 24),
                        _buildSectionTitle('Connexions Mobile Money'),
                        _buildMomoConnection('MTN MoMo', 'Connexion via API backend', Colors.yellow.shade700, true),
                        _buildMomoConnection('Moov Money', 'Bientôt disponible', Colors.blue.shade800, false),
                        _buildMomoConnection('Wave', 'Bientôt disponible', Colors.blue.shade400, false),
                        const SizedBox(height: 24),
                        _buildSectionTitle('Préférences'),
                        _buildPreferenceItem(Icons.dark_mode_outlined, 'Mode Sombre', Switch(value: false, onChanged: (v) {})),
                        _buildPreferenceItem(Icons.euro_outlined, 'Devise', const Text('FCFA', style: TextStyle(fontWeight: FontWeight.bold))),
                        const SizedBox(height: 40),
                        _buildSectionTitle('Export des données'),
                        _buildExportActions(context),
                        const SizedBox(height: 28),
                        _buildLogoutButton(context),
                        const SizedBox(height: 20),
                        const Text('Version 1.0.0', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(String fullName, String email) {
    final initials = fullName
        .split(' ')
        .where((e) => e.isNotEmpty)
        .take(2)
        .map((e) => e[0].toUpperCase())
        .join();
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primary,
              child: Text(
                initials.isEmpty ? 'U' : initials,
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.edit, size: 20, color: AppColors.primary),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(fullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(email, style: const TextStyle(color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildAccountTypeCard(String accountType) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.business_center, color: AppColors.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(accountType, style: const TextStyle(fontWeight: FontWeight.bold)),
                const Text('Informations synchronisées avec le profil API', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          TextButton(onPressed: () {}, child: const Text('Changer')),
        ],
      ),
    );
  }

  Widget _buildMomoConnection(String name, String status, Color color, bool isConnected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.phone_android, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(status, style: TextStyle(fontSize: 12, color: isConnected ? AppColors.success : AppColors.textSecondary)),
              ],
            ),
          ),
          isConnected 
            ? const Icon(Icons.check_circle, color: AppColors.success)
            : const Icon(Icons.add_circle_outline, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  Widget _buildPreferenceItem(IconData icon, String title, Widget trailing) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w500))),
          trailing,
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: () {
          context.read<AuthBloc>().add(LogoutRequested());
          context.go(AppRoutes.login);
        },
        style: TextButton.styleFrom(foregroundColor: AppColors.error),
        child: const Text('Déconnexion', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildExportActions(BuildContext context) {
    return Column(
      children: [
        _buildExportItem(
          context: context,
          icon: Icons.table_view_outlined,
          title: 'Transactions CSV',
          subtitle: 'Exporte les transactions au format tableur',
          onTap: () async {
            final repo = sl<ExportRepository>();
            final bytes = await repo.exportTransactionsCsv();
            await _saveAndNotify(
              context: context,
              fileName: 'finetrack_transactions.csv',
              bytes: bytes,
            );
          },
        ),
        _buildExportItem(
          context: context,
          icon: Icons.account_balance_outlined,
          title: 'Bilans comptables CSV',
          subtitle: 'Exporte les bilans mensuels des 6 derniers mois',
          onTap: () async {
            final repo = sl<ExportRepository>();
            final now = DateTime.now();
            final startDate = DateTime(now.year, now.month - 5, 1);
            final bytes = await repo.exportAccountingBilansCsv(
              granularity: 'monthly',
              startDate: startDate,
              endDate: now,
            );
            await _saveAndNotify(
              context: context,
              fileName: 'finetrack_bilans.csv',
              bytes: bytes,
            );
          },
        ),
        _buildExportItem(
          context: context,
          icon: Icons.backup_outlined,
          title: 'Sauvegarde JSON',
          subtitle: 'Backup complet des données utilisateur',
          onTap: () async {
            final repo = sl<ExportRepository>();
            final jsonMap = await repo.exportBackupJson();
            final payload = const JsonEncoder.withIndent('  ').convert(jsonMap);
            await _saveAndNotify(
              context: context,
              fileName: 'finetrack_backup.json',
              bytes: utf8.encode(payload),
            );
          },
        ),
      ],
    );
  }

  Widget _buildExportItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Future<void> Function() onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.download_outlined),
        onTap: () => _runExport(context, onTap),
      ),
    );
  }

  Future<void> _runExport(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await action();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export échoué: $e')),
        );
      }
    } finally {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  Future<void> _saveAndNotify({
    required BuildContext context,
    required String fileName,
    required List<int> bytes,
  }) async {
    final dir = await _resolveExportDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fichier exporté: ${file.path}')),
      );
    }
  }

  Future<Directory> _resolveExportDirectory() async {
    try {
      final downloads = await getDownloadsDirectory();
      if (downloads != null) {
        if (!await downloads.exists()) {
          await downloads.create(recursive: true);
        }
        return downloads;
      }
    } catch (_) {
      // Fallbacks below.
    }

    if (Platform.isAndroid) {
      try {
        final dirs = await getExternalStorageDirectories(
          type: StorageDirectory.downloads,
        );
        if (dirs != null && dirs.isNotEmpty) {
          final dir = dirs.first;
          if (!await dir.exists()) {
            await dir.create(recursive: true);
          }
          return dir;
        }
      } catch (_) {
        // Ignore and continue.
      }

      try {
        final publicDownloads = Directory('/storage/emulated/0/Download');
        if (!await publicDownloads.exists()) {
          await publicDownloads.create(recursive: true);
        }
        return publicDownloads;
      } catch (_) {
        // Final fallback below.
      }
    }

    final appDocs = await getApplicationDocumentsDirectory();
    if (!await appDocs.exists()) {
      await appDocs.create(recursive: true);
    }
    return appDocs;
  }
}
