import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'core/theme.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_page.dart';
import 'screens/tools_page.dart';
import 'screens/account_page.dart';
import 'screens/scenario_list_page.dart';
import 'screens/mortgage_calculator_page.dart';
import 'screens/prequalification_page.dart';
import 'widgets/bottom_nav.dart';

// ─── Routing ──────────────────────────────────────────────────────────────────

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const WelcomeScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => MainScaffold(child: child),
      routes: [
        GoRoute(
          path: '/home', 
          pageBuilder: (context, state) => const NoTransitionPage(child: HomePage()),
        ),
        GoRoute(
          path: '/tools', 
          pageBuilder: (context, state) => const NoTransitionPage(child: ToolsPage()),
        ),
        GoRoute(
          path: '/account', 
          pageBuilder: (context, state) => const NoTransitionPage(child: AccountPage()),
        ),
        
        // Deep links for tools
        GoRoute(
          path: '/tools/mortgage', 
          pageBuilder: (context, state) => const NoTransitionPage(child: ScenarioListPage(type: ScenarioToolType.mortgage)),
        ),
        GoRoute(
          path: '/tools/prequal', 
          pageBuilder: (context, state) => const NoTransitionPage(child: ScenarioListPage(type: ScenarioToolType.prequal)),
        ),
      ],
    ),
  ],
);

void main() {
  runApp(const MortgageApp());
}

// ─── App ──────────────────────────────────────────────────────────────────────

class MortgageApp extends StatelessWidget {
  const MortgageApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(useMaterial3: true);
    return MaterialApp.router(
      title: 'MortWise',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: base.copyWith(
        textTheme: GoogleFonts.dmSansTextTheme(base.textTheme),
        scaffoldBackgroundColor: kMint,
      ),
    );
  }
}

// ─── Main Scaffold ────────────────────────────────────────────────────────────

class MainScaffold extends StatefulWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/tools')) return 1;
    if (location.startsWith('/account')) return 2;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/home');
      case 1:
        context.go('/tools');
      case 2:
        context.go('/account');
    }
  }

  @override
  Widget build(BuildContext context) {
    final index = _calculateSelectedIndex(context);
    final isDesktop = MediaQuery.of(context).size.width >= 900 || kIsWeb;

    return Scaffold(
      backgroundColor: kMint,
      body: isDesktop
          ? Row(
              children: [
                NavigationRail(
                  backgroundColor: Colors.white,
                  selectedIndex: index,
                  onDestinationSelected: (i) => _onItemTapped(i, context),
                  extended: MediaQuery.of(context).size.width >= 1200,
                  selectedLabelTextStyle: sans(14, weight: FontWeight.w700, color: kGreen),
                  unselectedLabelTextStyle: sans(14, weight: FontWeight.w500, color: Colors.grey),
                  selectedIconTheme: const IconThemeData(color: kGreen),
                  unselectedIconTheme: const IconThemeData(color: Colors.grey),
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text('MW', style: serif(28, color: kGreen, weight: FontWeight.w900)),
                    ),
                  ),
                  destinations: const [
                    NavigationRailDestination(icon: Icon(Icons.home_rounded), label: Text('Home')),
                    NavigationRailDestination(icon: Icon(Icons.calculate_rounded), label: Text('Tools')),
                    NavigationRailDestination(icon: Icon(Icons.person_rounded), label: Text('Account')),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1, color: Color(0xFFEEEEEE)),
                Expanded(
                  child: Scrollbar(
                    thumbVisibility: kIsWeb,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: widget.child,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : widget.child,
      bottomNavigationBar: isDesktop
          ? null
          : BottomNav(
              selectedIndex: index,
              onTap: (i) => _onItemTapped(i, context),
            ),
    );
  }
}
