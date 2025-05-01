import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/mastodon_provider.dart';
import 'providers/timeline_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/settings_provider.dart';
import 'services/storage_service.dart';
import 'services/mastodon_service.dart';
import 'screens/splash_screen.dart';
import 'screens/token_input_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // StorageServiceの提供
        Provider<StorageService>(
          create: (_) => StorageService(),
        ),
        
        // AuthProviderの提供
        ChangeNotifierProxyProvider<StorageService, AuthProvider>(
          create: (context) => AuthProvider(context.read<StorageService>()),
          update: (context, storageService, previous) => 
              previous ?? AuthProvider(storageService),
        ),
        
        // MastodonServiceの提供（AuthProviderから生成）
        ProxyProvider<AuthProvider, MastodonService?>(
          update: (context, authProvider, _) => authProvider.mastodonService,
        ),
        
        // MastodonProviderの提供
        ChangeNotifierProxyProvider<MastodonService?, MastodonProvider>(
          create: (context) => MastodonProvider(null),
          update: (context, mastodonService, previous) => 
              mastodonService != null ? MastodonProvider(mastodonService) : (previous ?? MastodonProvider(null)),
        ),
        
        // TimelineProviderの提供
        ChangeNotifierProxyProvider<MastodonService?, TimelineProvider>(
          create: (context) => TimelineProvider(null),
          update: (context, mastodonService, previous) =>
              mastodonService != null ? TimelineProvider(mastodonService) : (previous ?? TimelineProvider(null)),
        ),
        
        // ThemeProviderの提供
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ),
        
        // SettingsProviderの提供
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'BlueWinter',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
              useMaterial3: true,
            ),
            darkTheme: ThemeData.dark(useMaterial3: true),
            themeMode: themeProvider.themeMode,
            initialRoute: '/',
            routes: {
              '/': (context) => const SplashScreen(),
              '/login': (context) => const TokenInputScreen(),
              '/home': (context) => const HomeScreen(),
            },
          );
        }
      ),
    );
  }
}
