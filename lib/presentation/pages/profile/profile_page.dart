import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/statistics/financial_score_widget.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 32),
            _buildSectionTitle('Type de compte'),
            _buildAccountTypeCard(),
            const SizedBox(height: 24),
            _buildSectionTitle('Connexions Mobile Money'),
            _buildMomoConnection('MTN MoMo', '229 97 00 00 00', Colors.yellow.shade700, true),
            _buildMomoConnection('Moov Money', '229 95 00 00 00', Colors.blue.shade800, false),
            _buildMomoConnection('Wave', 'Non connecté', Colors.blue.shade400, false),
            const SizedBox(height: 24),
            _buildSectionTitle('Préférences'),
            _buildPreferenceItem(Icons.dark_mode_outlined, 'Mode Sombre', Switch(value: false, onChanged: (v) {})),
            _buildPreferenceItem(Icons.euro_outlined, 'Devise', const Text('FCFA', style: TextStyle(fontWeight: FontWeight.bold))),
            const SizedBox(height: 40),
            _buildLogoutButton(context),
            const SizedBox(height: 20),
            const Text('Version 1.0.0', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primary,
              child: Text('JD', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.edit, size: 20, color: AppColors.primary),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Jean Dupont', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const Text('jean.dupont@email.com', style: TextStyle(color: AppColors.textSecondary)),
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

  Widget _buildAccountTypeCard() {
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Compte Business', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('PME / Freelance', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
        onPressed: () {},
        style: TextButton.styleFrom(foregroundColor: AppColors.error),
        child: const Text('Déconnexion', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
