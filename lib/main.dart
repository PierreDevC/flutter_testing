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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kMint,
      body: IndexedStack(
        index: _index,
        children: const [HomePage(), ToolsPage(), AccountPage()],
      ),
      bottomNavigationBar: BottomNav(
        selectedIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
