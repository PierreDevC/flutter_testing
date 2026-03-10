import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'scenario_list_page.dart';

class ToolsPage extends StatelessWidget {
  const ToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text('Tools', style: serif(32)),
            const SizedBox(height: 4),
            Text('Everything you need to plan your mortgage',
                style: sans(14, color: Colors.grey[600])),
            const SizedBox(height: 24),
            _toolItem(
              icon: Icons.how_to_reg_outlined,
              label: 'Prequalification Tool',
              description:
                  'Estimate how much you can borrow based on your income and debts.',
              color: const Color(0xFF3DAA5C),
              bgColor: const Color(0xFFDCF5DC),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ScenarioListPage(type: ScenarioToolType.prequal),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _toolItem(
              icon: Icons.calculate_outlined,
              label: 'Mortgage Calculator',
              description:
                  'Calculate your monthly payments and total cost of borrowing.',
              color: const Color(0xFF2B82D0),
              bgColor: const Color(0xFFDCEEF9),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ScenarioListPage(type: ScenarioToolType.mortgage),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _toolItem({
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    required Color bgColor,
    bool comingSoon = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: comingSoon ? null : onTap,
      child: Opacity(
        opacity: comingSoon ? 0.55 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                    color: bgColor, borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(label, style: serif(16)),
                        if (comingSoon) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(10)),
                            child: Text('Coming Soon',
                                style: sans(10,
                                    weight: FontWeight.w600,
                                    color: Colors.grey[600])),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(description,
                        style: sans(13, color: Colors.grey[500], height: 1.4)),
                  ],
                ),
              ),
              if (!comingSoon)
                Icon(Icons.chevron_right_rounded,
                    color: Colors.grey[400], size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
