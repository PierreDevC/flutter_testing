import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../main.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _goToApp(BuildContext context) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const MainScaffold(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 450),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWelcomeBg,
      body: Stack(
        children: [
          Positioned(top: -90, right: -70, child: _decorCircle(280, 0.07)),
          Positioned(top: 60, right: -20, child: _decorCircle(120, 0.05)),
          Positioned(bottom: 140, left: -90, child: _decorCircle(200, 0.06)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 64),
                          _buildBranding(),
                          const Spacer(),
                          _buildAuthButtons(context),
                          const SizedBox(height: 44),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _decorCircle(double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: opacity),
        ),
      );

  Widget _buildBranding() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: kBeige.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.home_work_outlined, color: kBeige, size: 28),
        ),
        const SizedBox(height: 28),
        Text('MortWise', style: serif(58, color: kBeige)),
        const SizedBox(height: 12),
        Text(
          'Mortgage planning,\nsimplified.',
          style: sans(17, color: Colors.white.withValues(alpha: 0.60), height: 1.55),
        ),
      ],
    );
  }

  Widget _buildAuthButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _authButton(
          onTap: () {},
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: Color(0xFF4285F4)),
                child: Center(
                  child: Text('G',
                      style: sans(12, weight: FontWeight.w700, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 12),
              Text('Continue with Google',
                  style: sans(15, weight: FontWeight.w600, color: kWelcomeBg)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _authButton(
          onTap: () {},
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: Colors.black87),
                child: Center(
                  child: Text('', style: sans(13, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 12),
              Text('Continue with Apple',
                  style: sans(15, weight: FontWeight.w600, color: kWelcomeBg)),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: Divider(
                  color: Colors.white.withValues(alpha: 0.18), thickness: 1),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text('or',
                  style: sans(13, color: Colors.white.withValues(alpha: 0.45))),
            ),
            Expanded(
              child: Divider(
                  color: Colors.white.withValues(alpha: 0.18), thickness: 1),
            ),
          ],
        ),
        const SizedBox(height: 28),
        GestureDetector(
          onTap: () => _goToApp(context),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(
                  color: kBeige.withValues(alpha: 0.45), width: 1.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text('Try Demo',
                  style: sans(15, weight: FontWeight.w600, color: kBeige)),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Text('No account needed',
              style: sans(12, color: Colors.white.withValues(alpha: 0.35))),
        ),
      ],
    );
  }

  Widget _authButton({required VoidCallback onTap, required Widget child}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: kBeige,
          borderRadius: BorderRadius.circular(14),
        ),
        child: child,
      ),
    );
  }
}
