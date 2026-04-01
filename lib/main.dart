import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/navigation/app_router.dart';
import 'core/theme/app_theme.dart';
import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Local Database
  await Hive.initFlutter();
  
  // Initialize Dependency Injection
  await di.init();
  
  runApp(const TrustPayApp());
}

class TrustPayApp extends StatelessWidget {
  const TrustPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TrustPay',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: AppRouter.router,
    );
  }
}
