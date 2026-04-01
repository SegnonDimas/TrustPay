import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_colors.dart';

class GenerateQrPage extends StatelessWidget {
  const GenerateQrPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock user data
    const String userId = "user_123456";
    const String userName = "Jean Dupont";

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Code QR'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Présentez ce code pour recevoir un paiement',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: QrImageView(
                  data: '{"id": "$userId", "name": "$userName"}',
                  version: QrVersions.auto,
                  size: 250.0,
                  gapless: false,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.circle,
                    color: AppColors.primary,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.circle,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                userName,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Text(
                'Identifiant: TP-8829-X',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 200,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Simuler partage
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lien de partage copié !')),
                    );
                  },
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Partager'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
