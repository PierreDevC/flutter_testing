import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';

class ToolsPage extends StatelessWidget {
  const ToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 800;
        
        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: isWide ? 40 : 20, vertical: isWide ? 40 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tools', style: serif(isWide ? 44 : 32, weight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('Everything you need to plan your mortgage',
                    style: sans(16, color: Colors.grey[600])),
                const SizedBox(height: 32),
                
                if (isWide)
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 2.2,
                    children: _buildToolItems(context),
                  )
                else
                  Column(
                    children: _buildToolItems(context, withSpacing: true),
                  ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      }
    );
  }

  List<Widget> _buildToolItems(BuildContext context, {bool withSpacing = false}) {
    final items = [
      _toolItem(
        context: context,
        icon: Icons.how_to_reg_outlined,
        label: 'Prequalification Tool',
        description:
            'Estimate how much you can borrow based on your income and debts.',
        color: const Color(0xFF3DAA5C),
        bgColor: const Color(0xFFDCF5DC),
        onTap: () => context.push('/tools/prequal'),
      ),
      _toolItem(
        context: context,
        icon: Icons.calculate_outlined,
        label: 'Mortgage Calculator',
        description:
            'Calculate your monthly payments and total cost of borrowing.',
        color: const Color(0xFF2B82D0),
        bgColor: const Color(0xFFDCEEF9),
        onTap: () => context.push('/tools/mortgage'),
      ),
    ];

    if (!withSpacing) return items;

    return items.expand((w) => [w, const SizedBox(height: 12)]).toList()..removeLast();
  }

  Widget _toolItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    required Color bgColor,
    bool comingSoon = false,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: comingSoon ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                    color: bgColor, borderRadius: BorderRadius.circular(16)),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Text(label, style: serif(18, weight: FontWeight.w600)),
                        if (comingSoon) ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
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
                    const SizedBox(height: 6),
                    Text(description,
                        style: sans(14, color: Colors.grey[500], height: 1.4)),
                  ],
                ),
              ),
              if (!comingSoon)
                Icon(Icons.chevron_right_rounded,
                    color: Colors.grey[400], size: 28),
            ],
          ),
        ),
      ),
    );
  }
}
