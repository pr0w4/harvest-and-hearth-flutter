import 'dart:async';

import 'package:clerk_auth/clerk_auth.dart' as clerk;
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'providers/app_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/recipes_screen.dart';
import 'screens/profile_screen.dart';
import 'services/backend_api_service.dart';
import 'services/expiry_reminder_service.dart';
import 'theme/app_theme.dart';
import 'widgets/add_food_modal.dart';
import 'widgets/time_simulator_console.dart';

/// Built once — avoids rebuilding [ColorScheme] / [ThemeData] on every [AppProvider] tick.
final ThemeData kAppLightTheme = buildAppTheme(isDark: false);
final ThemeData kAppDarkTheme = buildAppTheme(isDark: true);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}

  await ExpiryReminderService.instance.init();

  final api = dotenv.env['API_BASE_URL'] ?? '';
  BackendApiService.instance.configure(baseUrl: api);

  final pk = dotenv.env['CLERK_PUBLISHABLE_KEY'] ?? '';

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider()..init(),
      child: pk.trim().isEmpty
          ? const _MissingClerkKeyApp()
          : ClerkAuth(
              config: ClerkAuthConfig(publishableKey: pk.trim()),
              child: const HarvestAndHearthApp(),
            ),
    ),
  );
}

class _MissingClerkKeyApp extends StatelessWidget {
  const _MissingClerkKeyApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Harvest & Hearth',
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Thiếu CLERK_PUBLISHABLE_KEY trong .env.\n'
              'See .env.example.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

/// Only theme + routing inputs — avoids rebuilding [MaterialApp] when inventory/recipes change.
@immutable
class _AppUiState {
  const _AppUiState({
    required this.isDark,
    required this.isInitialized,
  });

  final bool isDark;
  final bool isInitialized;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _AppUiState &&
          runtimeType == other.runtimeType &&
          isDark == other.isDark &&
          isInitialized == other.isInitialized;

  @override
  int get hashCode => Object.hash(isDark, isInitialized);
}

class HarvestAndHearthApp extends StatelessWidget {
  const HarvestAndHearthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<AppProvider, _AppUiState>(
      selector: (_, p) => _AppUiState(
        isDark: p.isDark,
        isInitialized: p.isInitialized,
      ),
      builder: (context, state, _) {
        return MaterialApp(
          title: 'Harvest & Hearth',
          debugShowCheckedModeBanner: false,
          themeMode: state.isDark ? ThemeMode.dark : ThemeMode.light,
          theme: kAppLightTheme,
          darkTheme: kAppDarkTheme,
          home: !state.isInitialized
              ? const _SplashScreen()
              : ClerkErrorListener(
                  child: ClerkAuthBuilder(
                    signedOutBuilder: (context, _) => const _SignedOutShell(),
                    signedInBuilder: (context, _) => const _ClerkBootstrap(),
                  ),
                ),
        );
      },
    );
  }
}

/// Clears [AppProvider] once when showing the signed-out flow.
class _SignedOutShell extends StatefulWidget {
  const _SignedOutShell();

  @override
  State<_SignedOutShell> createState() => _SignedOutShellState();
}

class _SignedOutShellState extends State<_SignedOutShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppProvider>().clearSession();
    });
  }

  @override
  Widget build(BuildContext context) => const AuthScreen();
}

/// Loads profile/inventory from the API after Clerk session is ready.
class _ClerkBootstrap extends StatefulWidget {
  const _ClerkBootstrap();

  @override
  State<_ClerkBootstrap> createState() => _ClerkBootstrapState();
}

class _ClerkBootstrapState extends State<_ClerkBootstrap> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      setState(() => _started = true);
      final auth = ClerkAuth.of(context, listen: false);
      final user = auth.client.user;
      if (user is clerk.User) {
        await context.read<AppProvider>().bindClerkSession(auth, user);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Selector<AppProvider, ({bool loading, bool hasUser})>(
      selector: (_, p) => (loading: p.isLoadingUser, hasUser: p.user != null),
      builder: (context, s, _) {
        if (!_started || s.loading || !s.hasUser) {
          return const _SplashScreen();
        }
        return const MainShell();
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.eco_rounded,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Harvest & Hearth',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  StreamSubscription<String>? _notificationTapSub;

  static const List<Widget> _screens = [
    DashboardScreen(),
    InventoryScreen(),
    RecipesScreen(),
    ProfileScreen(),
  ];

  void _showAddFoodModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const AddFoodModal(),
    );
  }

  @override
  void initState() {
    super.initState();
    _notificationTapSub =
        ExpiryReminderService.instance.tapPayloadStream.listen(
      (payload) {
        if (!mounted) return;
        if (payload.startsWith('expiry:')) {
          setState(() => _currentIndex = 0);
        }
      },
    );
  }

  @override
  void dispose() {
    _notificationTapSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.read<AppProvider>().t;
    final showTimeSim = isTimeSimulatorFabVisible();

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          IndexedStack(index: _currentIndex, children: _screens),
          if (showTimeSim)
            Positioned(
              left: 16,
              bottom: MediaQuery.of(context).padding.bottom + 92,
              child: const TimeSimulatorFab(),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_food_fab_global',
        onPressed: _showAddFoodModal,
        tooltip: t('add_food'),
        elevation: 10,
        child: const Icon(Icons.add_rounded, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        height: 96,
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              _BottomNavItem(
                icon: Icons.dashboard_outlined,
                selectedIcon: Icons.dashboard,
                label: t('nav_home'),
                selected: _currentIndex == 0,
                onTap: () => setState(() => _currentIndex = 0),
              ),
              _BottomNavItem(
                icon: Icons.kitchen_outlined,
                selectedIcon: Icons.kitchen,
                label: t('nav_inventory'),
                selected: _currentIndex == 1,
                onTap: () => setState(() => _currentIndex = 1),
              ),
              const SizedBox(width: 56),
              _BottomNavItem(
                icon: Icons.restaurant_menu_outlined,
                selectedIcon: Icons.restaurant_menu,
                label: t('nav_recipes'),
                selected: _currentIndex == 2,
                onTap: () => setState(() => _currentIndex = 2),
              ),
              _BottomNavItem(
                icon: Icons.person_outline,
                selectedIcon: Icons.person,
                label: t('nav_profile'),
                selected: _currentIndex == 3,
                onTap: () => setState(() => _currentIndex = 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = selected ? cs.primary : cs.onSurfaceVariant;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(selected ? selectedIcon : icon, color: color, size: 22),
              const SizedBox(height: 4),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
