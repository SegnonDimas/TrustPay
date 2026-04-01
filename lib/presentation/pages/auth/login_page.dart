import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trustpay/presentation/widgets/app_text.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/app_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Center(child: Icon(Icons.account_circle, size: 100, color: AppColors.primary)),
                const SizedBox(height: 40),
                Text(
                  'Bon retour !',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Connectez-vous pour gérer vos finances.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 48),
                const Text(
                  'Email',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  decoration: const InputDecoration(
                    hintText: 'exemple@mail.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Champ requis' : null,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Mot de passe',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) => (value?.length ?? 0) < 6 ? 'Trop court' : null,
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text('Mot de passe oublié ?'),
                  ),
                ),
                const SizedBox(height: 40),
                AppButton(
                  onTap: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      context.go(AppRoutes.dashboard);
                    }
                  },
                  child:  AppText('Se connecter', color: Colors.white, fontWeight: FontWeight.w900,),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Nouveau sur TrustPay ?'),
                    TextButton(
                      onPressed: () {
                        context.go(AppRoutes.register);
                      },
                      child: const Text('Créer un compte'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
