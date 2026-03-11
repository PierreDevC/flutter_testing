import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/theme.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_page.dart';
import 'screens/tools_page.dart';
import 'screens/account_page.dart';
import 'widgets/bottom_nav.dart';

void main() => runApp(const MortgageApp());

// ─── App ──────────────────────────────────────────────────────────────────────

class MortgageApp extends StatelessWidget {
  const MortgageApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(useMaterial3: true);
    return MaterialApp(
      title: 'MortWise',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        textTheme: GoogleFonts.dmSansTextTheme(base.textTheme),
        scaffoldBackgroundColor: kMint,
      ),
      home: const WelcomeScreen(),
    );
  }
}

// ─── Main Scaffold ────────────────────────────────────────────────────────────

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _index = 0;

  final List<Widget> _pages = const [HomePage(), ToolsPage(), AccountPage()];

  @override
  Widget build(BuildContext context) {
    // Determine screen width to decide layout
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: kMint,
      body: isDesktop
          ? Row(
              children: [
                NavigationRail(
                  backgroundColor: Colors.white,
                  selectedIndex: _index,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  selectedLabelTextStyle: sans(14, weight: FontWeight.w700, color: kGreen),
                  unselectedLabelTextStyle: sans(14, weight: FontWeight.w500, color: Colors.grey),
                  selectedIconTheme: const IconThemeData(color: kGreen),
                  unselectedIconTheme: const IconThemeData(color: Colors.grey),
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(icon: Icon(Icons.home_rounded), label: Text('Home')),
                    NavigationRailDestination(icon: Icon(Icons.calculate_rounded), label: Text('Tools')),
                    NavigationRailDestination(icon: Icon(Icons.person_rounded), label: Text('Account')),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1, color: Color(0xFFEEEEEE)),
                Expanded(
                  child: ResponsiveMaxWidth(
                    child: IndexedStack(index: _index, children: _pages),
                  ),
                ),
              ],
            )
          : ResponsiveMaxWidth(
              child: IndexedStack(index: _index, children: _pages),
            ),
      bottomNavigationBar: isDesktop
          ? null
          : BottomNav(
              selectedIndex: _index,
              onTap: (i) => setState(() => _index = i),
            ),
    );
  }
}
