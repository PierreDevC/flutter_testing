import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../core/mortgage_math.dart';
import '../models/prequalification_scenario.dart';
import '../services/scenario_service.dart';
import '../core/prequal_models.dart';

// ─── Page ─────────────────────────────────────────────────────────────────────

class PrequalificationPage extends StatefulWidget {
  final PrequalScenario? initialScenario;
  const PrequalificationPage({super.key, this.initialScenario});

  @override
  State<PrequalificationPage> createState() => _PrequalificationPageState();
}

class _PrequalificationPageState extends State<PrequalificationPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Data
  late String _city;
  late ResidencyStatus _residency;
  late bool _isFirstTimeBuyer;
  late bool _isCondo;
  late bool _isNewlyBuilt;
  late PropertyUsage _usage;
  late double _downPayment;
  late List<DebtItem> _debts;
  late EmploymentStatus _employment;
  late double _grossIncome;
  late CreditScore _credit;
  late String _scenarioName;

  bool _isEditing = false;
  bool _customIncome = false;
  String? _nameError;

  final List<String> _quebecCities = [
    'Montréal', 'Québec City', 'Laval', 'Gatineau', 'Longueuil', 'Sherbrooke', 
    'Lévis', 'Saguenay', 'Trois-Rivières', 'Terrebonne', 'Saint-Jean-sur-Richelieu'
  ];

  @override
  void initState() {
    super.initState();
    final s = widget.initialScenario;
    if (s != null) {
      _isEditing = true;
      _city = s.city;
      _residency = s.residency;
      _isFirstTimeBuyer = s.isFirstTimeBuyer;
      _isCondo = s.isCondo;
      _isNewlyBuilt = s.isNewlyBuilt;
      _usage = s.usage;
      _downPayment = s.downPayment;
      _debts = s.debts.map((d) => DebtItem(type: d.type, balance: d.balance, monthlyPayment: d.monthlyPayment)).toList();
      _employment = s.employment;
      _grossIncome = s.grossIncome;
      _credit = s.credit;
      _scenarioName = s.name;
    } else {
      _city = 'Montréal';
      _residency = ResidencyStatus.citizen;
      _isFirstTimeBuyer = true;
      _isCondo = false;
      _isNewlyBuilt = false;
      _usage = PropertyUsage.reside;
      _downPayment = 50000;
      _debts = [];
      _employment = EmploymentStatus.employed;
      _grossIncome = 85000;
      _credit = CreditScore.excellent;
      _scenarioName = '';
    }
  }

  void _next() {
    if (_currentPage < 11) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _back() {
    if (_currentPage > 0) {
      _pageController.previousPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      Navigator.pop(context);
    }
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Discard progress?', style: serif(20)),
        content: Text('Are you sure you want to exit? Your answers will not be saved.', style: sans(14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: sans(14, color: Colors.grey))),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close questionnaire
            }, 
            child: Text('Discard', style: sans(14, weight: FontWeight.w600, color: Colors.red))
          ),
        ],
      ),
    );
  }

  void _quickSave() {
    final scenario = PrequalScenario(
      id: widget.initialScenario!.id,
      name: _scenarioName.isEmpty ? 'Untitled Scenario' : _scenarioName,
      city: _city,
      residency: _residency,
      isFirstTimeBuyer: _isFirstTimeBuyer,
      isCondo: _isCondo,
      isNewlyBuilt: _isNewlyBuilt,
      usage: _usage,
      downPayment: _downPayment,
      debts: _debts,
      employment: _employment,
      grossIncome: _grossIncome,
      credit: _credit,
      savedAt: DateTime.now(),
    );
    ScenarioService.instance.updatePrequal(scenario);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Changes saved!', style: sans(14, weight: FontWeight.w600, color: Colors.white)),
        backgroundColor: kGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(20),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20, color: Colors.black),
          onPressed: _back,
        ),
        title: _currentPage > 0 
          ? LinearProgressIndicator(
              value: (_currentPage) / 11,
              backgroundColor: kMint,
              color: kGreen,
              borderRadius: BorderRadius.circular(10),
            )
          : null,
        actions: [
          if (_currentPage > 0)
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.black),
              onPressed: _showExitConfirmation,
            ),
        ],
      ),
      body: ResponsiveMaxWidth(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (i) => setState(() => _currentPage = i),
          children: [
            _buildStep1(),
            _buildStep2(),
            _buildStep3(),
            _buildStep4(),
            _buildStep5(),
            _buildStep6(),
            _buildStep7(),
            _buildStep8(),
            _buildStep9(),
            _buildStep10(),
            _buildStep11(),
            _buildStep12(),
          ],
        ),
      ),
    );
  }

  // ─── Step Builders ──────────────────────────────────────────────────────────

  Widget _buildStep1() {
    return _stepLayout(
      title: 'Get prequalified for a mortgage in easy steps.',
      content: [
        const SizedBox(height: 20),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: kMint,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(child: Icon(Icons.analytics_outlined, size: 80, color: kGreen)),
        ),
        const SizedBox(height: 30),
        Text(
          'Answer a few questions and estimate your maximum purchase price without the need for a credit check.',
          style: sans(16, color: Colors.grey[700], height: 1.5),
          textAlign: TextAlign.center,
        ),
      ],
      buttonLabel: 'Get started',
      onPressed: _next,
    );
  }

  Widget _buildStep2() {
    return _stepLayout(
      title: 'Where do you plan to purchase?',
      content: [
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _quebecCities.map((c) {
            final active = _city == c;
            return GestureDetector(
              onTap: () => setState(() => _city = c),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: active ? kGreen : Colors.white,
                  border: Border.all(color: active ? kGreen : Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(c, style: sans(14, weight: active ? FontWeight.w600 : FontWeight.w400, color: active ? Colors.white : Colors.black)),
              ),
            );
          }).toList(),
        ),
      ],
      onPressed: _next,
    );
  }

  Widget _buildStep3() {
    return _stepLayout(
      title: 'What is your residency status?',
      content: [
        ...ResidencyStatus.values.map((s) => _selectionTile(
          label: s.label,
          active: _residency == s,
          onTap: () => setState(() => _residency = s),
        )),
        if (_residency == ResidencyStatus.nonResident)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _infoBanner('Non-residents may be subject to additional taxes (e.g., Speculation and Vacancy Tax) and typically require a higher down payment (min. 35%).', Colors.blueGrey, const Color(0xFFECEFF1)),
          ),
      ],
      onPressed: _next,
    );
  }

  Widget _buildStep4() {
    return _stepLayout(
      title: 'Are you a first time homebuyer?',
      content: [
        _selectionTile(label: 'Yes', active: _isFirstTimeBuyer, onTap: () => setState(() => _isFirstTimeBuyer = true)),
        _selectionTile(label: 'No', active: !_isFirstTimeBuyer, onTap: () => setState(() => _isFirstTimeBuyer = false)),
      ],
      onPressed: _next,
    );
  }

  Widget _buildStep5() {
    return _stepLayout(
      title: 'Are you buying a house or a condo?',
      content: [
        _selectionTile(label: 'House', active: !_isCondo, onTap: () => setState(() => _isCondo = false)),
        _selectionTile(label: 'Condo', active: _isCondo, onTap: () => setState(() => _isCondo = true)),
        const SizedBox(height: 20),
        Row(
          children: [
            Text('Is it a newly built home?', style: sans(15, weight: FontWeight.w500)),
            const Spacer(),
            Switch.adaptive(value: _isNewlyBuilt, activeColor: kGreen, onChanged: (v) => setState(() => _isNewlyBuilt = v)),
          ],
        ),
      ],
      onPressed: _next,
    );
  }

  Widget _buildStep6() {
    return _stepLayout(
      title: 'How do you plan to use this property?',
      content: [
        ...PropertyUsage.values.map((u) => _selectionTile(
          label: u.label,
          active: _usage == u,
          onTap: () => setState(() => _usage = u),
        )),
      ],
      onPressed: _next,
    );
  }

  Widget _buildStep7() {
    return _stepLayout(
      title: 'How many funds do you have available for a down payment?',
      content: [
        const SizedBox(height: 20),
        TextField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            prefixText: '\$ ',
            filled: true,
            fillColor: kMint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          ),
          style: serif(24),
          controller: TextEditingController(text: _downPayment.toStringAsFixed(0))..selection = TextSelection.collapsed(offset: _downPayment.toStringAsFixed(0).length),
          onChanged: (v) => setState(() => _downPayment = double.tryParse(v) ?? 0),
        ),
        Slider(
          value: _downPayment.clamp(0, 500000),
          min: 0,
          max: 500000,
          divisions: 100,
          activeColor: kGreen,
          onChanged: (v) => setState(() => _downPayment = v),
        ),
        if (_downPayment >= 500000)
          Center(child: Text('Slide to max for 500k+, or type amount above', style: sans(11, color: Colors.grey))),
      ],
      onPressed: _next,
    );
  }

  Widget _buildStep8() {
    final debtTypes = ['Credit Card', 'Line of Credit', 'Personal Loan', 'Car Loan/Lease', 'Student Loan', 'Spouse/Child Support', 'Other'];
    return _stepLayout(
      title: 'Do you have any outstanding debt?',
      content: [
        Column(
          children: debtTypes.map((t) {
            final existingDebt = _debts.cast<DebtItem?>().firstWhere((d) => d?.type == t, orElse: () => null);
            final hasDebt = existingDebt != null;
            return GestureDetector(
              onTap: () => _openDebtSheet(t),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: hasDebt ? kGreen.withOpacity(0.05) : Colors.white,
                  border: Border.all(color: hasDebt ? kGreen : Colors.grey[200]!, width: hasDebt ? 2 : 1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t, style: sans(15, weight: hasDebt ? FontWeight.w700 : FontWeight.w500)),
                          if (hasDebt)
                            Text(
                              'Payment: ${NumberFormat.currency(symbol: '\$').format(existingDebt.monthlyPayment.isNaN || existingDebt.monthlyPayment.isInfinite ? 0 : existingDebt.monthlyPayment)}/mo',
                              style: sans(12, color: kGreen, weight: FontWeight.w600),
                            ),
                        ],
                      ),
                    ),
                    if (hasDebt) 
                      const Icon(Icons.check_circle, color: kGreen)
                    else 
                      Icon(Icons.add_circle_outline_rounded, color: Colors.grey[300]),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        if (_debts.isEmpty)
          OutlinedButton(
            onPressed: () => _showNoDebtConfirmation(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: Text("I don't have any debt", style: sans(15, weight: FontWeight.w600, color: kGreen)),
          ),
      ],
      onPressed: _debts.isNotEmpty ? _next : null,
    );
  }

  Widget _buildStep9() {
    return _stepLayout(
      title: 'What is your employment status?',
      content: [
        ...EmploymentStatus.values.map((s) => _selectionTile(
          label: s.label,
          active: _employment == s,
          onTap: () => setState(() => _employment = s),
        )),
      ],
      onPressed: _next,
    );
  }

  Widget _buildStep10() {
    return _stepLayout(
      title: 'What is your gross annual household income?',
      content: [
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () => setState(() => _customIncome = true),
          child: AbsorbPointer(
            absorbing: !_customIncome,
            child: TextField(
              keyboardType: TextInputType.number,
              autofocus: _customIncome,
              decoration: InputDecoration(
                prefixText: '\$ ',
                suffixIcon: _customIncome ? IconButton(icon: const Icon(Icons.check_circle, color: kGreen), onPressed: () => setState(() => _customIncome = false)) : null,
                filled: true,
                fillColor: kMint,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
              style: serif(28),
              controller: TextEditingController(text: _grossIncome.toStringAsFixed(0))..selection = TextSelection.collapsed(offset: _grossIncome.toStringAsFixed(0).length),
              onChanged: (v) => setState(() => _grossIncome = double.tryParse(v) ?? 0),
            ),
          ),
        ),
        if (!_customIncome) ...[
          const SizedBox(height: 10),
          Slider(
            value: _grossIncome.clamp(30000, 300000),
            min: 30000,
            max: 300000,
            divisions: 54,
            activeColor: kGreen,
            onChanged: (v) => setState(() => _grossIncome = v),
          ),
          Center(child: Text('Slide to adjust or tap amount to type', style: sans(12, color: Colors.grey))),
        ],
        const SizedBox(height: 20),
        _infoBanner('Total before taxes for all applicants', Colors.grey, Colors.grey.withOpacity(0.05)),
      ],
      onPressed: _next,
    );
  }

  Widget _buildStep11() {
    return _stepLayout(
      title: 'How would you rate your credit?',
      content: [
        ...CreditScore.values.map((s) => _selectionTile(
          label: s.label,
          subtitle: s.range,
          active: _credit == s,
          onTap: () => setState(() => _credit = s),
        )),
      ],
      onPressed: _next,
    );
  }

  Widget _buildStep12() {
    return _stepLayout(
      title: 'Provide a name for your scenario',
      content: [
        const SizedBox(height: 20),
        TextField(
          decoration: InputDecoration(
            hintText: 'e.g. Dream House in MTL',
            filled: true,
            fillColor: kMint,
            errorText: _nameError,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          ),
          style: sans(16),
          onChanged: (v) => setState(() {
            _scenarioName = v;
            if (v.isNotEmpty) _nameError = null;
          }),
        ),
        if (_nameError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Scenario name is required to continue.', style: sans(12, color: Colors.red)),
          ),
      ],
      buttonLabel: 'Calculate Results',
      onPressed: () {
        if (_scenarioName.trim().isEmpty) {
          setState(() => _nameError = 'Please provide a name');
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PrequalificationResults(
              originalId: widget.initialScenario?.id,
              income: _grossIncome,
              downPayment: _downPayment,
              debts: _debts,
              city: _city,
              scenarioName: _scenarioName,
              residency: _residency,
              isFirstTimeBuyer: _isFirstTimeBuyer,
              isCondo: _isCondo,
              isNewlyBuilt: _isNewlyBuilt,
              usage: _usage,
              employment: _employment,
              credit: _credit,
            ),
          ),
        );
      },
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  Widget _stepLayout({
    required String title,
    required List<Widget> content,
    String buttonLabel = 'Next',
    VoidCallback? onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: serif(28, height: 1.2)),
          const SizedBox(height: 30),
          Expanded(child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: content))),
          Row(
            children: [
              if (_isEditing) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: _quickSave,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      side: const BorderSide(color: kGreen, width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: Text('Save & Exit', style: sans(16, weight: FontWeight.w700, color: kGreen)),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              if (onPressed != null)
                Expanded(
                  child: ElevatedButton(
                    onPressed: onPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 0,
                    ),
                    child: Text(buttonLabel, style: sans(16, weight: FontWeight.w700)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _selectionTile({required String label, String? subtitle, required bool active, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: active ? kGreen.withOpacity(0.05) : Colors.white,
          border: Border.all(color: active ? kGreen : Colors.grey[300]!, width: active ? 2 : 1),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: sans(16, weight: active ? FontWeight.w700 : FontWeight.w500)),
                  if (subtitle != null) Text(subtitle, style: sans(13, color: Colors.grey[600])),
                ],
              ),
            ),
            if (active) const Icon(Icons.check_circle, color: kGreen),
          ],
        ),
      ),
    );
  }

  Widget _infoBanner(String text, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: sans(12, color: color))),
        ],
      ),
    );
  }

  void _openDebtSheet(String type) {
    final existing = _debts.cast<DebtItem?>().firstWhere((d) => d?.type == type, orElse: () => null);
    
    final balController = TextEditingController(text: existing?.balance.toStringAsFixed(0) ?? '');
    final payController = TextEditingController(text: existing?.monthlyPayment.toStringAsFixed(0) ?? '');
    String? error;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.95,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
          padding: const EdgeInsets.all(24),
          child: StatefulBuilder(
            builder: (context, setModalState) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Details for $type', style: serif(24)),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                  ],
                ),
                const SizedBox(height: 24),
                _labeledInput('Current Balance', balController, (v) { if (error != null) setModalState(() => error = null); }),
                const SizedBox(height: 16),
                _labeledInput('Monthly Payment', payController, (v) { if (error != null) setModalState(() => error = null); }),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(error!, style: sans(13, color: Colors.red, weight: FontWeight.w600)),
                  ),
                const Spacer(),
                if (existing != null)
                  TextButton(
                    onPressed: () {
                      setState(() => _debts.removeWhere((d) => d.type == type));
                      Navigator.pop(context);
                    },
                    child: Text('Remove this debt', style: sans(14, color: Colors.red, weight: FontWeight.w600)),
                  ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    final b = double.tryParse(balController.text) ?? 0;
                    final p = double.tryParse(payController.text) ?? 0;
                    if (p <= 0) {
                      setModalState(() => error = 'Monthly payment is required to save');
                      return;
                    }
                    setState(() {
                      _debts.removeWhere((d) => d.type == type);
                      _debts.add(DebtItem(type: type, balance: b, monthlyPayment: p));
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kGreen,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text('Save Debt', style: sans(16, weight: FontWeight.w700, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _labeledInput(String label, TextEditingController controller, ValueChanged<String> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: sans(13, weight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            prefixText: '\$ ',
            filled: true,
            fillColor: kMint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  void _showNoDebtConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm', style: serif(20)),
        content: Text('Are you sure you have no monthly debt payments?', style: sans(14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: sans(14, color: Colors.grey))),
          TextButton(onPressed: () { Navigator.pop(context); _next(); }, child: Text('Yes, no debt', style: sans(14, weight: FontWeight.w600, color: kGreen))),
        ],
      ),
    );
  }
}

// ─── Results View ─────────────────────────────────────────────────────────────

class PrequalificationResults extends StatefulWidget {
  final String? originalId;
  final double income;
  final double downPayment;
  final List<DebtItem> debts;
  final String city;
  final String scenarioName;
  final ResidencyStatus residency;
  final bool isFirstTimeBuyer;
  final bool isCondo;
  final bool isNewlyBuilt;
  final PropertyUsage usage;
  final EmploymentStatus employment;
  final CreditScore credit;

  const PrequalificationResults({
    super.key,
    this.originalId,
    required this.income,
    required this.downPayment,
    required this.debts,
    required this.city,
    required this.scenarioName,
    required this.residency,
    required this.isFirstTimeBuyer,
    required this.isCondo,
    required this.isNewlyBuilt,
    required this.usage,
    required this.employment,
    required this.credit,
  });

  @override
  State<PrequalificationResults> createState() => _PrequalificationResultsState();
}

class _PrequalificationResultsState extends State<PrequalificationResults> {
  late double _income;
  late double _downPayment;
  late double _monthlyDebt;
  
  // Expenses
  double _propertyTaxRate = 0.01; // 1%
  double _heating = 150.0;
  double _monthlyCondoFee = 0.0;

  // Qualification Settings
  double _stressRate = 0.0725; // 7.25%
  int _amortization = 25;
  double _gdsLimit = 0.32;
  double _tdsLimit = 0.40;

  @override
  void initState() {
    super.initState();
    _income = widget.income;
    _downPayment = widget.downPayment;
    _monthlyDebt = widget.debts.fold(0.0, (sum, d) => sum + d.monthlyPayment);
  }

  /// Canadian minimum down payment rules (CMHC B-20).
  double _minDownPayment(double price) {
    if (price >= 1000000) return price * 0.20;
    if (price >= 500000) return 25000 + (price - 500000) * 0.10;
    return price * 0.05;
  }

  void _saveAndExit() {
    final scenario = PrequalScenario(
      id: widget.originalId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: widget.scenarioName,
      city: widget.city,
      residency: widget.residency,
      isFirstTimeBuyer: widget.isFirstTimeBuyer,
      isCondo: widget.isCondo,
      isNewlyBuilt: widget.isNewlyBuilt,
      usage: widget.usage,
      downPayment: _downPayment,
      debts: widget.debts,
      employment: widget.employment,
      grossIncome: _income,
      credit: widget.credit,
      savedAt: DateTime.now(),
    );
    
    if (widget.originalId != null) {
      ScenarioService.instance.updatePrequal(scenario);
    } else {
      ScenarioService.instance.addPrequal(scenario);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Scenario "${widget.scenarioName}" saved!', style: sans(14, weight: FontWeight.w600, color: Colors.white)),
        backgroundColor: kGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(20),
      ),
    );
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    // 1. Income limits — condo fees (50% per CMHC) count against GDS/TDS
    final monthlyIncome = _income / 12;
    final condoFeeImpact = widget.isCondo ? _monthlyCondoFee * 0.5 : 0.0;
    final maxHousingGds = monthlyIncome * _gdsLimit - condoFeeImpact;
    final maxHousingTds = (monthlyIncome * _tdsLimit) - _monthlyDebt - condoFeeImpact;
    final maxHousingPayment = min(maxHousingGds, maxHousingTds);

    // 2. Iterative solve: property tax is % of purchase price (not just down payment)
    //    maxHousingPayment = mortgagePayment + (purchasePrice × taxRate / 12) + heating
    //    purchasePrice = maxPrincipal + downPayment  →  circular, so we iterate to converge.
    double maxMortgagePaymentStress = max(0.0, maxHousingPayment - _heating);
    double maxPrincipal = 0.0;
    for (int i = 0; i < 15; i++) {
      maxPrincipal = MortgageMath.calcPrincipal(
        payment: maxMortgagePaymentStress,
        annualRate: _stressRate,
        amortizationYears: _amortization,
        frequency: PaymentFrequency.monthly,
      );
      final estimatedPrice = maxPrincipal + _downPayment;
      final monthlyTax = estimatedPrice * _propertyTaxRate / 12;
      final newPayment = max(0.0, maxHousingPayment - _heating - monthlyTax);
      if ((newPayment - maxMortgagePaymentStress).abs() < 0.50) break;
      maxMortgagePaymentStress = newPayment;
    }

    // 3. Purchase price, insurance, total mortgage
    final purchasePrice = maxPrincipal + _downPayment;
    // Properties ≥ $1M are uninsured; CMHC only applies below $1M
    final isInsurable = purchasePrice < 1000000;
    final cmhc = isInsurable ? MortgageMath.cmhcPremium(maxPrincipal, purchasePrice) : 0.0;
    final totalMortgage = maxPrincipal + cmhc;

    // 4. Contract rate: stress test = max(contract + 2%, 5.25%).
    //    Clamp to at least 1% to avoid unrealistic displayed rates.
    final contractRate = max(_stressRate - 0.02, 0.01);
    final actualMortgagePayment = MortgageMath.calcPayment(
      principal: totalMortgage,
      annualRate: contractRate,
      amortizationYears: _amortization,
      frequency: PaymentFrequency.monthly,
    );

    // 5. Monthly outflow
    final propertyTax = purchasePrice * _propertyTaxRate / 12;
    final totalMonthlyOutflow = actualMortgagePayment + propertyTax + _heating +
        (widget.isCondo ? _monthlyCondoFee : 0.0);

    // 6. Minimum down payment required for this purchase price
    final minDown = _minDownPayment(purchasePrice);
    final downShortfall = max(0.0, minDown - _downPayment);

    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return Scaffold(
      backgroundColor: kMint,
      appBar: AppBar(
        backgroundColor: kMint,
        elevation: 0,
        title: Text(widget.scenarioName, style: serif(18)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            child: Text('Exit', style: sans(14, weight: FontWeight.w700, color: kGreen)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                  children: [
                    // ── Down-payment warning ──────────────────────────────────────
                    if (downShortfall > 0) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.orange.shade300),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Your down payment of ${fmt.format(_downPayment.isNaN || _downPayment.isInfinite ? 0 : _downPayment)} is below the minimum required (${fmt.format(minDown.isNaN || minDown.isInfinite ? 0 : minDown)}) for this purchase price. '
                                'Increase your down payment by at least ${fmt.format(downShortfall.isNaN || downShortfall.isInfinite ? 0 : downShortfall)} to qualify.',
                                style: sans(12, color: Colors.orange.shade800, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    _resultCard(
                      title: 'Your estimated purchase price',
                      value: fmt.format(purchasePrice.isNaN || purchasePrice.isInfinite ? 0 : purchasePrice),
                      color: kGreen,
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Based on your income and debts, this is the maximum home price you may qualify for.',
                                  style: sans(13, color: Colors.grey[600], height: 1.4),
                                ),
                              ),
                              const SizedBox(width: 16),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.asset(
                                  'assets/images/3dhome.jpg',
                                  width: 100,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: 100,
                                    height: 80,
                                    color: kMint,
                                    child: const Icon(Icons.home_work_outlined, color: kGreen),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () => _showContactAdvisor(purchasePrice),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kGreen,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 54),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              elevation: 0,
                            ),
                            child: Text('Get Pre-approved', style: sans(15, weight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _resultCard(
                      title: 'Monthly cost breakdown',
                      value: fmt.format(totalMonthlyOutflow.isNaN || totalMonthlyOutflow.isInfinite ? 0 : totalMonthlyOutflow),
                      child: Column(
                        children: [
                          _kv('Mortgage payment', fmt.format(actualMortgagePayment.isNaN || actualMortgagePayment.isInfinite ? 0 : actualMortgagePayment)),
                          _kv('Property tax (est.)', fmt.format(propertyTax.isNaN || propertyTax.isInfinite ? 0 : propertyTax)),
                          _kv('Heating (est.)', fmt.format(_heating.isNaN || _heating.isInfinite ? 0 : _heating)),
                          if (widget.isCondo && _monthlyCondoFee > 0)
                            _kv('Condo fees', fmt.format(_monthlyCondoFee.isNaN || _monthlyCondoFee.isInfinite ? 0 : _monthlyCondoFee)),
                          const Divider(height: 24),
                          _editButton('Edit expenses', _editExpenses),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _resultCard(
                      title: 'Home price breakdown',
                      value: fmt.format(purchasePrice.isNaN || purchasePrice.isInfinite ? 0 : purchasePrice),
                      child: Column(
                        children: [
                          _kv('Down payment', fmt.format(_downPayment.isNaN || _downPayment.isInfinite ? 0 : _downPayment)),
                          _kv('Mortgage insurance', isInsurable ? fmt.format(cmhc.isNaN || cmhc.isInfinite ? 0 : cmhc) : 'N/A (≥\$1M)'),
                          _kv('Net mortgage amount', fmt.format(maxPrincipal.isNaN || maxPrincipal.isInfinite ? 0 : maxPrincipal)),
                          _kv('Est. closing costs (1.5%)', fmt.format((purchasePrice * 0.015).isNaN || (purchasePrice * 0.015).isInfinite ? 0 : purchasePrice * 0.015)),
                          const Divider(height: 24),
                          _editButton('Edit down payment', _editDownPayment),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _resultCard(
                      title: 'Mortgage Details',
                      value: '${(contractRate * 100).toStringAsFixed(2)}%',
                      child: Column(
                        children: [
                          _kv('Total amount', fmt.format(totalMortgage.isNaN || totalMortgage.isInfinite ? 0 : totalMortgage)),
                          _kv('Amortization', '$_amortization years'),
                          _kv('Stress test rate', '${(_stressRate * 100).toStringAsFixed(2)}%'),
                          _kv('Insurable?', isInsurable ? 'Yes' : 'No (≥\$1M)'),
                          _kv('Loan to value', '${(maxPrincipal / purchasePrice * 100).toStringAsFixed(1)}%'),
                          _kv('GDS limit / TDS limit', '${(_gdsLimit * 100).toStringAsFixed(1)}% / ${(_tdsLimit * 100).toStringAsFixed(1)}%'),
                          const Divider(height: 24),
                          _editButton('Edit qualification', _editQualification),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, -4))],
                ),
                padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
                child: ElevatedButton(
                  onPressed: _saveAndExit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kGreen,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 0,
                  ),
                  child: Text('Save and Exit', style: sans(16, weight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Sheet Editors ─────────────────────────────────────────────────────────

  void _editExpenses() {
    _openResizableSheet(
      title: 'Monthly Expenses',
      children: [
        _sheetInput('Heating Cost', _heating, (v) => setState(() => _heating = v)),
        const SizedBox(height: 20),
        _sheetInput('Property Tax Rate (%)', _propertyTaxRate * 100, (v) => setState(() => _propertyTaxRate = v / 100)),
        const SizedBox(height: 10),
        Text('Default is 1% of property value annually.', style: sans(12, color: Colors.grey)),
        if (widget.isCondo) ...[
          const SizedBox(height: 20),
          _sheetInput('Monthly Condo Fees', _monthlyCondoFee, (v) => setState(() => _monthlyCondoFee = v)),
          const SizedBox(height: 10),
          Text('50% of condo fees count toward GDS/TDS per CMHC guidelines.', style: sans(12, color: Colors.grey)),
        ],
      ],
    );
  }

  void _editDownPayment() {
    _openResizableSheet(
      title: 'Down Payment',
      children: [
        _sheetInput('Available Funds', _downPayment, (v) => setState(() => _downPayment = v)),
        const SizedBox(height: 10),
        Text('Higher down payments increase your purchase power and may eliminate CMHC insurance.', style: sans(12, color: Colors.grey)),
      ],
    );
  }

  void _editQualification() {
    _openResizableSheet(
      title: 'Qualification Variables',
      children: [
        _sheetInput('Annual Household Income', _income, (v) => setState(() => _income = v)),
        const SizedBox(height: 20),
        _sheetInput('Stress Test Rate (%)', _stressRate * 100, (v) => setState(() => _stressRate = v / 100)),
        const SizedBox(height: 20),
        _sheetInput('Amortization (Years)', _amortization.toDouble(), (v) => setState(() => _amortization = v.round())),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _sheetInput('GDS Limit (%)', _gdsLimit * 100, (v) => setState(() => _gdsLimit = v / 100))),
            const SizedBox(width: 16),
            Expanded(child: _sheetInput('TDS Limit (%)', _tdsLimit * 100, (v) => setState(() => _tdsLimit = v / 100))),
          ],
        ),
      ],
    );
  }

  void _openResizableSheet({required String title, required List<Widget> children}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.95, // FULL PAGE
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: serif(24)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  controller: controller,
                  children: children,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetInput(String label, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: sans(13, weight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            prefixText: '\$ ',
            filled: true,
            fillColor: kMint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          controller: TextEditingController(text: value.toStringAsFixed(0))..selection = TextSelection.collapsed(offset: value.toStringAsFixed(0).length),
          onChanged: (v) => onChanged(double.tryParse(v) ?? 0),
        ),
      ],
    );
  }

  void _showContactAdvisor(double price) {
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(28, 30, 28, MediaQuery.of(context).padding.bottom + 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contact Advisor', style: serif(28)),
            const SizedBox(height: 12),
            Text('We found a pre-qualification for approximately ${fmt.format(price.isNaN || price.isInfinite ? 0 : price)} in ${widget.city}. Send this message to an advisor to start your official pre-approval.', style: sans(14, color: Colors.grey[600], height: 1.5)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: kMint, borderRadius: BorderRadius.circular(12)),
              child: Text(
                'Hello, I am looking for a pre-approval for ${fmt.format(price.isNaN || price.isInfinite ? 0 : price)} in ${widget.city}. My household income is ${fmt.format(_income.isNaN || _income.isInfinite ? 0 : _income)} and I have a down payment of ${fmt.format(_downPayment.isNaN || _downPayment.isInfinite ? 0 : _downPayment)}.',
                style: sans(14, height: 1.4),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: kGreen, minimumSize: const Size(double.infinity, 54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              child: Text('Send Message', style: sans(16, weight: FontWeight.w700, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultCard({required String title, required String value, Color? color, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: sans(13, color: Colors.grey[600], weight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: serif(32, color: color ?? Colors.black)),
          child,
        ],
      ),
    );
  }

  Widget _kv(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: sans(13, color: Colors.grey[600])),
          Text(val, style: sans(13, weight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _editButton(String label, VoidCallback onTap) {
    return TextButton(
      onPressed: onTap,
      child: Text(label, style: sans(13, weight: FontWeight.w700, color: kGreen)),
    );
  }
}
