import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router/app_router.dart';
import 'utils/theme.dart';
// import 'services/local_storage_service.dart'; // Local storage removed

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize API Service if needed, or other startup logic
  // LocalStorageService.init() removed as we use API now

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'AusadhiTrack',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
