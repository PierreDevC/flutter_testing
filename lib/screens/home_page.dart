import 'package:flutter/material.dart';
import '../core/theme.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildHeader(),
            const SizedBox(height: 20),
            _buildScenarioCard(),
            _buildSeeAllButton(),
            const SizedBox(height: 20),
            _buildToolsSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ─── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 24,
              backgroundColor: kGreen,
              child: Text('P',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome back', style: sans(13, color: Colors.grey[600])),
                Text('Pierre', style: serif(22)),
              ],
            ),
          ],
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.notifications_none_rounded,
              size: 20, color: Color(0xFF1A1A1A)),
        ),
      ],
    );
  }

  // ─── Scenario Card ───────────────────────────────────────────────────────────

  Widget _buildScenarioCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: kAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.home_outlined,
                        color: kAccent, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Current Scenario',
                          style: sans(14, weight: FontWeight.w600)),
                      Text('Primary Residence',
                          style: sans(12, color: Colors.grey[500])),
                    ],
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: kAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Active',
                    style: sans(12, weight: FontWeight.w600, color: kAccent)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Monthly payment + 3D home image
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('\$ ',
                        style: sans(18,
                            weight: FontWeight.w300,
                            color: const Color(0xFF1A1A1A))),
                    Text('2,142',
                        style: serif(44, color: const Color(0xFF1A1A1A))
                            .copyWith(letterSpacing: -1.5, height: 1.0)),
                    Text('/mo',
                        style: sans(14,
                            weight: FontWeight.w400,
                            color: Colors.grey[400])
                            .copyWith(height: 1.0)),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  'assets/images/3dhome.jpg',
                  width: 110,
                  height: 90,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 14),
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statCol('Property', '\$485,000'),
              _vDivider(),
              _statCol('Loan', '\$388,000'),
              _vDivider(),
              _statCol('Rate', '5.25%'),
              _vDivider(),
              _statCol('Term', '25 yrs'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: sans(11, color: Colors.grey[500])),
        const SizedBox(height: 3),
        Text(value, style: sans(13, weight: FontWeight.w700)),
      ],
    );
  }

  Widget _vDivider() =>
      Container(width: 1, height: 30, color: const Color(0xFFEEEEEE));

  Widget _buildSeeAllButton() {
    return Center(
      child: TextButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.list_rounded, size: 16),
        label: Text('See all scenarios',
            style: sans(13, weight: FontWeight.w600)),
        style: TextButton.styleFrom(foregroundColor: kGreen),
      ),
    );
  }

  // ─── Tools Grid ──────────────────────────────────────────────────────────────

  Widget _buildToolsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Tools', style: serif(22)),
            Text('See all', style: sans(14, color: Colors.grey[500])),
          ],
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.05,
          children: [
            _toolCard(
              icon: Icons.how_to_reg_outlined,
              label: 'Pre-\nqualification',
              description: 'Estimate your budget',
              color: const Color(0xFF3DAA5C),
              bgColor: const Color(0xFFDCF5DC),
            ),
            _toolCard(
              icon: Icons.calculate_outlined,
              label: 'Mortgage\nCalculator',
              description: 'Calculate payments',
              color: const Color(0xFF2B82D0),
              bgColor: const Color(0xFFDCEEF9),
            ),
            _toolCard(
              icon: Icons.home_work_outlined,
              label: 'FSHA\nCalculator',
              description: 'Gov. home programs',
              color: const Color(0xFFD07A2B),
              bgColor: const Color(0xFFF9EEDC),
            ),
            _toolCard(
              icon: Icons.compare_arrows_rounded,
              label: 'Comparison\nTool',
              description: 'Compare scenarios',
              color: Colors.grey,
              bgColor: const Color(0xFFF0F0F0),
              comingSoon: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _toolCard({
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    required Color bgColor,
    bool comingSoon = false,
  }) {
    return Opacity(
      opacity: comingSoon ? 0.55 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: color, size: 20),
                ),
                if (comingSoon)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10)),
                    child: Text('Soon',
                        style: sans(10,
                            weight: FontWeight.w600,
                            color: Colors.grey[600])),
                  )
                else
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: Colors.grey[400]),
              ],
            ),
            const Spacer(),
            Text(label, style: serif(14).copyWith(height: 1.3)),
            const SizedBox(height: 3),
            Text(description, style: sans(11, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }
}
