import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'core/themes/app_theme.dart';
import 'core/platform/platform_service.dart';
import 'core/services/providers/fcm_provider.dart';
import 'core/services/navigation_service.dart';
import 'core/providers/locale_provider.dart';
import 'features/auth/presentation/providers/auth_providers.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/calendar/presentation/pages/calendar_page.dart';
import 'shared/widgets/loading_screen.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase only on platforms that support SDK (Web/Android)
  // iOS uses REST API to avoid gRPC/Xcode 16 issues
  if (PlatformService.useFirebaseSDK) {
    print('🔥 Initializing Firebase SDK...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase SDK initialized');
  } else {
    print('📱 Using Firebase REST API (iOS - no gRPC dependencies)');
  }

  runApp(
    const ProviderScope(
      child: FamilyPlannerApp(),
    ),
  );
}

class FamilyPlannerApp extends ConsumerWidget {
  const FamilyPlannerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'Family Planner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // Localization support
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // English
        Locale('zh', ''), // Chinese
      ],

      navigatorKey: NavigationService.navigatorKey,
      home: const AuthWrapper(),
      routes: {
        '/calendar': (context) => const CalendarPage(),
        '/login': (context) => const LoginPage(),
      },
      onGenerateRoute: (settings) {
        // Handle routes with arguments
        if (settings.name == '/calendar') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (context) => CalendarPage(
              initialTaskId: args?['taskId'],
              shouldOpenTask: args?['openTask'] ?? false,
            ),
          );
        }
        return null;
      },
    );
  }
}

/// Wrapper widget to handle authentication state
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(currentUserProvider);

    return userState.when(
      data: (user) {
        if (user == null) {
          return const LoginPage();
        }

        // Initialize FCM when user is logged in
        ref.listen(fcmInitializerProvider, (previous, next) {
          next.when(
            data: (_) => print('✅ FCM initialized successfully'),
            loading: () => print('🔄 Initializing FCM...'),
            error: (error, stack) => print('❌ FCM initialization error: $error'),
          );
        });

        return const CalendarPage();
      },
      loading: () => const LoadingScreen(),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Retry initialization
                  ref.refresh(currentUserProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
