import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trustpay/presentation/widgets/app_button.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_colors.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingContent> _contents = [
    OnboardingContent(
      title: 'Gérez vos finances',
      description: 'Suivez vos revenus et dépenses en un clin d\'œil avec une interface intuitive.',
      icon: Icons.account_balance_wallet_outlined,
    ),
    OnboardingContent(
      title: 'Paiements QR rapides',
      description: 'Payez vos marchands et amis instantanément grâce au scan de code QR.',
      icon: Icons.qr_code_scanner_rounded,
    ),
    OnboardingContent(
      title: 'Score Financier',
      description: 'Améliorez votre santé financière et accédez à des services exclusifs.',
      icon: Icons.trending_up_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _contents.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _contents[index].icon,
                          size: 120,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 40),
                        Text(
                          _contents[index].title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _contents[index].description,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _contents.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index ? AppColors.primary : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  AppButton(
                    onTap: () {
                      if (_currentPage == _contents.length - 1) {
                        context.go(AppRoutes.login);
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Text(_currentPage == _contents.length - 1 ? 'Commencer' : 'Suivant', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingContent {
  final String title;
  final String description;
  final IconData icon;

  OnboardingContent({
    required this.title,
    required this.description,
    required this.icon,
  });
}
