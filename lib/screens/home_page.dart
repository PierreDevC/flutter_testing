import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        return Scaffold(
          backgroundColor: kMint,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 40 : 20,
                vertical: isWide ? 40 : 0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, isWide),
                  const SizedBox(height: 32),
                  
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: _buildMainContent(context, service),
                        ),
                        const SizedBox(width: 40),
                        Expanded(
                          flex: 2,
                          child: _buildToolsSection(context, isWide: true),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _buildMainContent(context, service),
                        const SizedBox(height: 32),
                        _buildToolsSection(context, isWide: false),
                      ],
                    ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildMainContent(BuildContext context, ScenarioService service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your Active Scenario', style: serif(20, weight: FontWeight.w700)),
        const SizedBox(height: 16),
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
      ],
    );
  }

  // ─── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, bool isWide) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: kGreen,
              child: Text('P',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome back', style: sans(14, color: Colors.grey[600])),
                Text('Pierre', style: serif(isWide ? 32 : 26)),
              ],
            ),
          ],
        ),
        _aiAgentButton(context),
      ],
    );
  }

  Widget _aiAgentButton(BuildContext context) {
    return InkWell(
      onTap: () => _openAiAgent(context),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.auto_awesome_rounded, size: 20, color: kGreen),
            const SizedBox(width: 8),
            Text('Ask AI', style: sans(14, weight: FontWeight.w600, color: kGreen)),
          ],
        ),
      ),
    );
  }

  void _openAiAgent(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    
    if (isWide) {
      showDialog(
        context: context,
        builder: (context) => const Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 100, vertical: 40),
          child: AiAgentSheet(isDialog: true),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const AiAgentSheet(),
      );
    }
  }

  // ─── Scenario Card ───────────────────────────────────────────────────────────

  Widget _buildNoScenarioCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        children: [
          Icon(Icons.dashboard_customize_outlined, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No current scenario active', 
            style: serif(18, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text('Use one of the tools to start planning your mortgage.', 
            style: sans(14, color: Colors.grey[400])),
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
      price = fmt.format(s.mortgageAmount.isNaN || s.mortgageAmount.isInfinite ? 0 : s.mortgageAmount);
      rate = '${s.annualRatePct.toStringAsFixed(2)}%';
      amort = '${s.amortizationYears} yrs';
      
      switch (s.calcType) {
        case MortgageCalcType.payment:
          label = '${s.frequency.label} Payment';
          mainValue = NumberFormat.currency(symbol: '', decimalDigits: 0).format(s.monthlyPayment.isNaN || s.monthlyPayment.isInfinite ? 0 : s.monthlyPayment);
          mainSuffix = ' ${s.frequency.shortLabel}';
        case MortgageCalcType.remainingBalance:
          label = 'Remaining Balance';
          mainValue = NumberFormat.currency(symbol: '', decimalDigits: 0).format(s.monthlyPayment.isNaN || s.monthlyPayment.isInfinite ? 0 : s.monthlyPayment);
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
          mainValue = NumberFormat.currency(symbol: '', decimalDigits: 0).format(s.monthlyPayment.isNaN || s.monthlyPayment.isInfinite ? 0 : s.monthlyPayment);
      }
    } else {
      // Prequal Logic (simplified for summary)
      final monthlyIncome = s.grossIncome / 12;
      final monthlyDebt = s.debts.fold(0.0, (sum, d) => sum + d.monthlyPayment);
      final maxHousingPayment = min(monthlyIncome * 0.32, (monthlyIncome * 0.40) - monthlyDebt).toDouble();
      final maxPrincipal = MortgageMath.calcPrincipal(payment: maxHousingPayment, annualRate: 0.0725, amortizationYears: 25, frequency: PaymentFrequency.monthly);
      final purchasePrice = maxPrincipal + s.downPayment;
      
      price = fmt.format(purchasePrice);
      rate = s.credit.label;
      amort = s.city;
      mainValue = NumberFormat.currency(symbol: '', decimalDigits: 0).format(maxHousingPayment);
      label = 'Est. Monthly Payment';
      mainSuffix = '/mo';
    }

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: InkWell(
        onTap: () => _openActiveScenario(context, s),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: kAccent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(isMortgage ? Icons.calculate_outlined : Icons.how_to_reg_outlined,
                            color: kAccent, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isPinned ? 'Pinned Scenario' : 'Recent Scenario',
                              style: sans(16, weight: FontWeight.w600)),
                          Text(s.name,
                              style: sans(14, color: Colors.grey[500])),
                        ],
                      ),
                    ],
                  ),
                  if (isPinned)
                    const Icon(Icons.push_pin_rounded, size: 20, color: kGreen),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label,
                            style: sans(14,
                                weight: FontWeight.w600,
                                color: Colors.grey[500])),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            if (mainPrefix.isNotEmpty)
                              Text(mainPrefix,
                                  style: sans(22,
                                      weight: FontWeight.w300,
                                      color: const Color(0xFF1A1A1A))),
                            Text(mainValue,
                                style: serif(52, color: const Color(0xFF1A1A1A))
                                    .copyWith(letterSpacing: -1.5, height: 1.0)),
                            if (mainSuffix.isNotEmpty)
                              Text(mainSuffix,
                                  style: sans(16,
                                      weight: FontWeight.w400,
                                      color: Colors.grey[400])
                                      .copyWith(height: 1.0)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!kIsWeb || MediaQuery.of(context).size.width > 600)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/images/3dhome.jpg',
                        width: 140,
                        height: 110,
                        fit: BoxFit.cover,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
              const SizedBox(height: 20),
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
        Text(label, style: sans(12, color: Colors.grey[500])),
        const SizedBox(height: 4),
        Text(value, style: sans(15, weight: FontWeight.w700)),
      ],
    );
  }

  Widget _vDivider() =>
      Container(width: 1, height: 36, color: const Color(0xFFEEEEEE));

  // ─── Tools Grid ──────────────────────────────────────────────────────────────

  Widget _buildToolsSection(BuildContext context, {required bool isWide}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Planning Tools', style: serif(20, weight: FontWeight.w700)),
            if (!isWide) Text('See all', style: sans(14, color: Colors.grey[500])),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: isWide ? 1 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: isWide ? 2.5 : 1.05,
          children: [
            _toolCard(
              icon: Icons.how_to_reg_outlined,
              label: 'Pre-qualification',
              description: 'Estimate your buying budget',
              color: const Color(0xFF3DAA5C),
              bgColor: const Color(0xFFDCF5DC),
              onTap: () => context.push('/tools/prequal'),
            ),
            _toolCard(
              icon: Icons.calculate_outlined,
              label: 'Mortgage Calc',
              description: 'Calculate monthly payments',
              color: const Color(0xFF2B82D0),
              bgColor: const Color(0xFFDCEEF9),
              onTap: () => context.push('/tools/mortgage'),
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
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: comingSoon ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(14)),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  if (comingSoon)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
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
                        size: 16, color: Colors.grey[400]),
                ],
              ),
              const Spacer(),
              Text(label, style: serif(16, weight: FontWeight.w600).copyWith(height: 1.2)),
              const SizedBox(height: 4),
              Text(description, style: sans(12, color: Colors.grey[500])),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── AI Agent Sheet ──────────────────────────────────────────────────────────

class AiAgentSheet extends StatefulWidget {
  final bool isDialog;
  const AiAgentSheet({super.key, this.isDialog = false});

  @override
  State<AiAgentSheet> createState() => _AiAgentSheetState();
}

class _AiAgentSheetState extends State<AiAgentSheet> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final service = ScenarioService.instance;

    final content = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: widget.isDialog 
          ? BorderRadius.circular(30)
          : const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          if (!widget.isDialog) ...[
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          ],
          const SizedBox(height: 20),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(color: kGreen, shape: BoxShape.circle),
                  child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MortWise AI Assistant', style: serif(20, weight: FontWeight.w700)),
                      Text('Ask anything about your mortgage', style: sans(13, color: Colors.grey[500])),
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tag a scenario to analyze:', style: sans(12, weight: FontWeight.w600, color: Colors.grey[500])),
                const SizedBox(height: 12),
                SizedBox(
                  height: 36,
                  child: ListenableBuilder(
                    listenable: Listenable.merge([service.mortgageScenarios, service.prequalScenarios]),
                    builder: (context, _) {
                      final all = [...service.mortgageScenarios.value, ...service.prequalScenarios.value];
                      if (all.isEmpty) {
                        return Text('No scenarios created yet.', style: sans(12, color: Colors.grey[400]));
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
            padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + (widget.isDialog ? 0 : max(0.0, MediaQuery.of(context).viewInsets.bottom))),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: _selectedId != null ? 'Ask about this scenario...' : 'Ask MortWise AI...',
                hintStyle: sans(15, color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                prefixIcon: IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded, color: kGreen),
                  onPressed: () {},
                ),
                suffixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: kGreen, shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (widget.isDialog) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: content,
      );
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.95,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, __) => content,
    );
  }

  Widget _tagChip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? kGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? kGreen : Colors.grey[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.link_rounded, size: 14, color: active ? Colors.white : Colors.grey[500]),
            const SizedBox(width: 8),
            Text(label, style: sans(12, weight: FontWeight.w600, color: active ? Colors.white : Colors.grey[700])),
          ],
        ),
      ),
    );
  }

  Widget _aiMessage(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20, right: 60),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: kMint.withOpacity(0.5),
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24), bottomRight: Radius.circular(24)),
        ),
        child: Text(text, style: sans(15, height: 1.5, color: Colors.black87)),
      ),
    );
  }

  Widget _userMessage(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20, left: 60),
        padding: const EdgeInsets.all(18),
        decoration: const BoxDecoration(
          color: kGreen,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24), bottomLeft: Radius.circular(24)),
        ),
        child: Text(text, style: sans(15, height: 1.5, color: Colors.white)),
      ),
    );
  }
}
