import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/transaction.dart';
import '../../bloc/transaction/transaction_bloc.dart';
import '../../bloc/transaction/transaction_event.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  bool _isScanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner un QR Code'),
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              if (_isScanned) return;
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                setState(() => _isScanned = true);
                _showPaymentDialog(context, barcodes.first.rawValue ?? 'Données inconnues');
              }
            },
          ),
          _buildOverlay(context),
        ],
      ),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Alignez le QR code dans le cadre',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, String data) {
    // Simuler un décodage de données commerçant
    final merchantName = "Boutique Benin Sarl";
    final amount = 5000.0;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, color: AppColors.success, size: 64),
            const SizedBox(height: 16),
            Text(
              'Paiement à $merchantName',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              '$amount FCFA',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() => _isScanned = false);
                      Navigator.pop(context);
                    },
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final transaction = Transaction(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: 'Paiement QR - $merchantName',
                        amount: amount,
                        date: DateTime.now(),
                        type: TransactionType.expense,
                        category: TransactionCategory.shopping,
                      );
                      
                      // Accéder au bloc via le contexte parent ou une instance globale si nécessaire
                      // Ici on assume que le bloc est disponible plus haut
                      // context.read<TransactionBloc>().add(AddTransaction(transaction));
                      
                      Navigator.pop(context);
                      context.pop(); // Retour au dashboard
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Paiement effectué avec succès !'), backgroundColor: AppColors.success),
                      );
                    },
                    child: const Text('Confirmer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
