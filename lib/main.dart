import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/services/hive_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/providers.dart';
import 'core/navigation/app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Local Databases (Hive)
  final hiveService = HiveService();
  await hiveService.init();

  // Initialize Local Notifications
  final notificationService = NotificationService();
  await notificationService.init();

  // Initialize Firebase (safely catches exceptions if config files are not provided yet)
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print('Firebase initialization skipped/failed: $e. Using local database fallback mode.');
  }

  runApp(
    const ProviderScope(
      child: SmartFinanceApp(),
    ),
  );
}

class SmartFinanceApp extends ConsumerWidget {
  const SmartFinanceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsNotifierProvider);

    return MaterialApp.router(
      title: 'Smart Finance',
      debugShowCheckedModeBanner: false,
      
      // Theme settings
      themeMode: settings.isDarkTheme ? ThemeMode.dark : ThemeMode.light,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      
      // Router settings
      routerConfig: appRouter,
    );
  }
}
