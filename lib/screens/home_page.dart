import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../core/mortgage_math.dart';
import '../services/scenario_service.dart';
import '../models/mortgage_scenario.dart';
import '../models/prequalification_scenario.dart';
import 'scenario_list_page.dart';
import 'prequalification_page.dart';
import 'mortgage_calculator_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = ScenarioService.instance;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildHeader(context),
            const SizedBox(height: 20),
            
            // Scenario Card / Empty State
            ListenableBuilder(
              listenable: Listenable.merge([
                service.mortgageScenarios,
                service.prequalScenarios,
                service.pinnedScenarioId,
              ]),
              builder: (context, _) {
                final active = service.activeScenario;
                if (active == null) {
                  return _buildNoScenarioCard();
                }
                return _buildScenarioCard(context, active);
              },
            ),
            
            const SizedBox(height: 20),
            _buildToolsSection(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ─── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
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
        GestureDetector(
          onTap: () => _openAiAgent(context),
          child: Container(
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
            child: const Icon(Icons.auto_awesome_rounded,
                size: 20, color: kGreen),
          ),
        ),
      ],
    );
  }

  void _openAiAgent(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AiAgentSheet(),
    );
  }

  // ─── Scenario Card ───────────────────────────────────────────────────────────

  Widget _buildNoScenarioCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        children: [
          Icon(Icons.dashboard_customize_outlined, size: 40, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text('No current scenario active', 
            style: serif(16, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text('Use one of the tools below to start.', 
            style: sans(12, color: Colors.grey[400])),
        ],
      ),
    );
  }

  Widget _buildScenarioCard(BuildContext context, dynamic s) {
    final isMortgage = s is MortgageScenario;
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final pinnedId = ScenarioService.instance.pinnedScenarioId.value;
    final isPinned = pinnedId == s.id;

    String price = '—';
    String rate = '—';
    String amort = '—';
    String mainValue = '0';
    String mainSuffix = '';
    String mainPrefix = '\$ ';
    String label = 'Estimated Payment';

    if (isMortgage) {
      price = fmt.format(s.mortgageAmount);
      rate = '${s.annualRatePct.toStringAsFixed(2)}%';
      amort = '${s.amortizationYears} yrs';
      
      switch (s.calcType) {
        case MortgageCalcType.payment:
          label = '${s.frequency.label} Payment';
          mainValue = NumberFormat.currency(symbol: '', decimalDigits: 0).format(s.monthlyPayment);
          mainSuffix = ' ${s.frequency.shortLabel}';
        case MortgageCalcType.remainingBalance:
          label = 'Remaining Balance';
          mainValue = NumberFormat.currency(symbol: '', decimalDigits: 0).format(s.monthlyPayment);
        case MortgageCalcType.rate:
          label = 'Implied Interest Rate';
          mainValue = s.annualRatePct.toStringAsFixed(2);
          mainSuffix = '%';
          mainPrefix = '';
        case MortgageCalcType.amortization:
          label = 'Amortization Period';
          mainValue = '${s.amortizationYears}';
          mainSuffix = ' years';
          mainPrefix = '';
        case MortgageCalcType.reverse:
          label = 'Future Balance';
          mainValue = NumberFormat.currency(symbol: '', decimalDigits: 0).format(s.monthlyPayment);
      }
    } else {
      // Prequal Logic
      final monthlyIncome = s.grossIncome / 12;
      final monthlyDebt = s.debts.fold(0.0, (sum, d) => sum + d.monthlyPayment);
      
      final maxHousingGds = monthlyIncome * 0.32;
      final maxHousingTds = (monthlyIncome * 0.40) - monthlyDebt;
      final maxHousingPayment = min(maxHousingGds, maxHousingTds);
      
      final numerator = maxHousingPayment - 150 - ((s.downPayment * 0.01) / 12);
      final denominator = 1 + (0.01 / 12);
      final maxMortgagePaymentStress = max(0.0, numerator / denominator);

      final maxPrincipal = MortgageMath.calcPrincipal(
        payment: maxMortgagePaymentStress,
        annualRate: 0.0725, 
        amortizationYears: 25,
        frequency: PaymentFrequency.monthly,
      );

      final purchasePrice = maxPrincipal + s.downPayment;
      
      final actualPayment = MortgageMath.calcPayment(
        principal: maxPrincipal + MortgageMath.cmhcPremium(maxPrincipal, purchasePrice),
        annualRate: 0.0525,
        amortizationYears: 25,
        frequency: PaymentFrequency.monthly,
      );

      price = fmt.format(purchasePrice);
      rate = s.credit.label;
      amort = s.city;
      mainValue = NumberFormat.currency(symbol: '', decimalDigits: 0).format(actualPayment);
      label = 'Est. Monthly Payment';
      mainSuffix = '/mo';
    }

    return GestureDetector(
      onTap: () => _openActiveScenario(context, s),
      child: Container(
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
                      child: Icon(isMortgage ? Icons.calculate_outlined : Icons.how_to_reg_outlined,
                          color: kAccent, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isPinned ? 'Pinned Scenario' : 'Recent Scenario',
                            style: sans(14, weight: FontWeight.w600)),
                        Text(s.name,
                            style: sans(12, color: Colors.grey[500])),
                      ],
                    ),
                  ],
                ),
                if (isPinned)
                  const Icon(Icons.push_pin_rounded, size: 16, color: kGreen),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: sans(12,
                              weight: FontWeight.w600,
                              color: Colors.grey[500])),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          if (mainPrefix.isNotEmpty)
                            Text(mainPrefix,
                                style: sans(18,
                                    weight: FontWeight.w300,
                                    color: const Color(0xFF1A1A1A))),
                          Text(mainValue,
                              style: serif(44, color: const Color(0xFF1A1A1A))
                                  .copyWith(letterSpacing: -1.5, height: 1.0)),
                          if (mainSuffix.isNotEmpty)
                            Text(mainSuffix,
                                style: sans(14,
                                    weight: FontWeight.w400,
                                    color: Colors.grey[400])
                                    .copyWith(height: 1.0)),
                        ],
                      ),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _statCol(isMortgage ? 'Mortgage' : 'Income', price),
                _vDivider(),
                _statCol(isMortgage ? 'Rate' : 'Credit', rate),
                _vDivider(),
                _statCol(isMortgage ? 'Amort.' : 'City', amort),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openActiveScenario(BuildContext context, dynamic s) {
    if (s is MortgageScenario) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MortgageCalculatorPage(initialScenario: s)),
      );
    } else if (s is PrequalScenario) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PrequalificationResults(
            originalId: s.id,
            income: s.grossIncome,
            downPayment: s.downPayment,
            debts: s.debts,
            city: s.city,
            scenarioName: s.name,
            residency: s.residency,
            isFirstTimeBuyer: s.isFirstTimeBuyer,
            isCondo: s.isCondo,
            isNewlyBuilt: s.isNewlyBuilt,
            usage: s.usage,
            employment: s.employment,
            credit: s.credit,
          ),
        ),
      );
    }
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

  // ─── Tools Grid ──────────────────────────────────────────────────────────────

  Widget _buildToolsSection(BuildContext context) {
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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ScenarioListPage(type: ScenarioToolType.prequal),
                  ),
                );
              },
            ),
            _toolCard(
              icon: Icons.calculate_outlined,
              label: 'Mortgage\nCalculator',
              description: 'Calculate payments',
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
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: comingSoon ? null : onTap,
      child: Opacity(
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
      ),
    );
  }
}

// ─── AI Agent Sheet ──────────────────────────────────────────────────────────

class AiAgentSheet extends StatefulWidget {
  const AiAgentSheet({super.key});

  @override
  State<AiAgentSheet> createState() => _AiAgentSheetState();
}

class _AiAgentSheetState extends State<AiAgentSheet> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final service = ScenarioService.instance;

    return DraggableScrollableSheet(
      initialChildSize: 0.95,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(color: kGreen, shape: BoxShape.circle),
                    child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('MortWise AI Assistant', style: serif(18)),
                        Text('Ask anything about your mortgage', style: sans(12, color: Colors.grey[500])),
                      ],
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                ],
              ),
            ),
            const Divider(height: 32),

            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _aiMessage("Hello Pierre! I can help you analyze your mortgage scenarios or answer general questions about the home-buying process. What's on your mind?"),
                  _userMessage('Can you compare my "Primary Residence" scenario with a shorter amortization?'),
                  _aiMessage("Looking at your \"Primary Residence\" scenario (\$485k price, 25yr amort, 5.25% rate):\n\nIf we reduce the amortization to 20 years, your payment would increase by about \$310/mo, but you would save over \$64,000 in total interest over the life of the loan. Would you like me to save this as a new comparison scenario?"),
                ],
              ),
            ),

            // Reference / Tagging Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tag a scenario to analyze:', style: sans(11, weight: FontWeight.w600, color: Colors.grey[500])),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 32,
                    child: ListenableBuilder(
                      listenable: Listenable.merge([service.mortgageScenarios, service.prequalScenarios]),
                      builder: (context, _) {
                        final all = [...service.mortgageScenarios.value, ...service.prequalScenarios.value];
                        if (all.isEmpty) {
                          return Text('No scenarios created yet.', style: sans(11, color: Colors.grey[400]));
                        }
                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: all.length,
                          itemBuilder: (context, i) {
                            final dynamic s = all[i];
                            final active = _selectedId == s.id;
                            return _tagChip(s.name, active, () => setState(() => _selectedId = active ? null : s.id));
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            Container(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + max(MediaQuery.of(context).padding.bottom, MediaQuery.of(context).viewInsets.bottom)),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: _selectedId != null ? 'Ask about this scenario...' : 'Ask MortWise AI...',
                  hintStyle: sans(14, color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                  prefixIcon: IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded, color: kGreen),
                    onPressed: () => _showScenarioPicker(context, service),
                  ),
                  suffixIcon: Container(
                    margin: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: kGreen, shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showScenarioPicker(BuildContext context, ScenarioService service) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Attach a scenario', style: serif(20)),
            const SizedBox(height: 16),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ...service.mortgageScenarios.value.map((s) => _pickerItem(s, Icons.calculate_outlined)),
                  ...service.prequalScenarios.value.map((s) => _pickerItem(s, Icons.how_to_reg_outlined)),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _pickerItem(dynamic s, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: kGreen),
      title: Text(s.name, style: sans(14, weight: FontWeight.w600)),
      onTap: () {
        setState(() => _selectedId = s.id);
        Navigator.pop(context);
      },
    );
  }

  Widget _tagChip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? kGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? kGreen : Colors.grey[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.link_rounded, size: 12, color: active ? Colors.white : Colors.grey[500]),
            const SizedBox(width: 6),
            Text(label, style: sans(11, weight: FontWeight.w600, color: active ? Colors.white : Colors.grey[700])),
          ],
        ),
      ),
    );
  }

  Widget _aiMessage(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, right: 40),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kMint.withValues(alpha: 0.5),
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20), bottomRight: Radius.circular(20)),
        ),
        child: Text(text, style: sans(14, height: 1.5, color: Colors.black87)),
      ),
    );
  }

  Widget _userMessage(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, left: 40),
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: kGreen,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20), bottomLeft: Radius.circular(20)),
        ),
        child: Text(text, style: sans(14, height: 1.5, color: Colors.white)),
      ),
    );
  }
}
