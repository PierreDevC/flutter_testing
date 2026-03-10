import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../core/mortgage_math.dart';
import '../models/mortgage_scenario.dart';
import '../services/scenario_service.dart';

// ─── Modes ────────────────────────────────────────────────────────────────────

enum CalcType {
  payment('Mortgage Payment', 'Calculate your periodic payments'),
  amount('Remaining Balance', 'See your balance over time'),
  rate('Interest Rate', 'Find the implied interest rate'),
  amortization('Amortization', 'Calculate years to pay off'),
  reverse('Reverse Mortgage', 'Calculate future compounding debt');

  final String label;
  final String description;
  const CalcType(this.label, this.description);

  MortgageCalcType get modelType {
    switch (this) {
      case CalcType.payment: return MortgageCalcType.payment;
      case CalcType.amount: return MortgageCalcType.remainingBalance;
      case CalcType.rate: return MortgageCalcType.rate;
      case CalcType.amortization: return MortgageCalcType.amortization;
      case CalcType.reverse: return MortgageCalcType.reverse;
    }
  }

  static CalcType fromModel(MortgageCalcType type) {
    switch (type) {
      case MortgageCalcType.payment: return CalcType.payment;
      case MortgageCalcType.remainingBalance: return CalcType.amount;
      case MortgageCalcType.rate: return CalcType.rate;
      case MortgageCalcType.amortization: return CalcType.amortization;
      case MortgageCalcType.reverse: return CalcType.reverse;
    }
  }
}

// ─── Page ─────────────────────────────────────────────────────────────────────

class MortgageCalculatorPage extends StatefulWidget {
  final MortgageScenario? initialScenario;
  const MortgageCalculatorPage({super.key, this.initialScenario});

  @override
  State<MortgageCalculatorPage> createState() => _MortgageCalculatorPageState();
}

class _MortgageCalculatorPageState extends State<MortgageCalculatorPage> {
  late CalcType _type;

  // Basic Variables
  late double _mortgage;
  late double _rate;
  late int _amortYears;
  late double _payment;
  late int _showBalanceAtYear;
  late DateTime _startDate;

  // Strategy Variables
  late PaymentFrequency _frequency;
  late double _annualLumpSum;
  late double _extraPerPayment;
  late double _paymentIncreasePct;
  late bool _doubleUp;

  final _fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    final s = widget.initialScenario;
    if (s != null) {
      _type = CalcType.fromModel(s.calcType);
      _mortgage = s.mortgageAmount;
      _rate = s.annualRatePct;
      _amortYears = s.amortizationYears;
      _payment = s.monthlyPayment;
      _showBalanceAtYear = s.showBalanceAtYear;
      _startDate = s.startDate;
      _frequency = s.frequency;
      _annualLumpSum = s.annualLumpSum;
      _extraPerPayment = s.extraPerPayment;
      _paymentIncreasePct = s.paymentIncreasePct;
      _doubleUp = s.doubleUp;
    } else {
      _type = CalcType.payment;
      _mortgage = 450000;
      _rate = 5.25;
      _amortYears = 25;
      _payment = 2500;
      _showBalanceAtYear = 5;
      _startDate = DateTime.now();
      _frequency = PaymentFrequency.monthly;
      _annualLumpSum = 0;
      _extraPerPayment = 0;
      _paymentIncreasePct = 0;
      _doubleUp = false;
    }
  }

  void _openTypeSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TypeSelectorSheet(
        initialType: _type,
        onSelected: (t) => setState(() => _type = t),
      ),
    );
  }

  void _saveAndExit() {
    if (widget.initialScenario == null) {
      _showNameEntryModal();
    } else {
      _performSave(widget.initialScenario!.name, widget.initialScenario!.id);
    }
  }

  void _showNameEntryModal() {
    final controller = TextEditingController();
    String? error;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text('Save Scenario', style: serif(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'e.g. Dream House',
                  filled: true,
                  fillColor: kMint,
                  errorText: error,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                autofocus: true,
                onChanged: (_) { if (error != null) setModalState(() => error = null); },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: sans(14, color: Colors.grey))),
            TextButton(
              onPressed: () {
                if (controller.text.trim().isEmpty) {
                  setModalState(() => error = 'Name is required');
                  return;
                }
                Navigator.pop(context);
                _performSave(controller.text.trim(), DateTime.now().millisecondsSinceEpoch.toString());
              },
              child: Text('Save', style: sans(14, weight: FontWeight.w600, color: kGreen)),
            ),
          ],
        ),
      ),
    );
  }

  void _performSave(String name, String id) {
    final scenario = MortgageScenario(
      id: id,
      name: name,
      calcType: _type.modelType,
      mortgageAmount: _mortgage,
      annualRatePct: _rate,
      amortizationYears: _amortYears,
      monthlyPayment: _payment,
      showBalanceAtYear: _showBalanceAtYear,
      startDate: _startDate,
      savedAt: DateTime.now(),
      frequency: _frequency,
      annualLumpSum: _annualLumpSum,
      extraPerPayment: _extraPerPayment,
      paymentIncreasePct: _paymentIncreasePct,
      doubleUp: _doubleUp,
    );

    if (widget.initialScenario != null) {
      ScenarioService.instance.updateMortgage(scenario);
    } else {
      ScenarioService.instance.addMortgage(scenario);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Scenario "$name" saved!', style: sans(14, weight: FontWeight.w600, color: Colors.white)),
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
    final results = _calculate();

    return Scaffold(
      backgroundColor: kMint,
      appBar: AppBar(
        backgroundColor: kMint,
        elevation: 0,
        title: Text('Calculator', style: serif(20)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _saveAndExit,
              child: Text('Save & Exit', style: sans(14, weight: FontWeight.w700, color: kGreen)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
        children: [
          _buildTypeCard(),
          const SizedBox(height: 20),
          _buildFrequencySwitcher(),
          const SizedBox(height: 12),
          _buildInputSection(),
          const SizedBox(height: 12),
          _buildStrategySection(),
          const SizedBox(height: 24),
          _buildChartSection(results),
          const SizedBox(height: 20),
          _buildInfoSection(results),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, -4))],
        ),
        child: _buildResultDisplay(results),
      ),
    );
  }

  // ─── Shared UI Helpers ──────────────────────────────────────────────────────

  Widget _buildTypeCard() {
    return GestureDetector(
      onTap: _openTypeSelector,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: kGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.swap_vert_rounded, color: kGreen),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Calculating', style: sans(12, color: Colors.grey[500], weight: FontWeight.w600)),
                  Text(_type.label, style: serif(18)),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencySwitcher() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text('Payment Frequency', style: sans(12, weight: FontWeight.w600, color: Colors.grey[500])),
        ),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: PaymentFrequency.values.length,
            itemBuilder: (context, index) {
              final f = PaymentFrequency.values[index];
              final active = _frequency == f;
              return GestureDetector(
                onTap: () => setState(() => _frequency = f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: active ? kGreen : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: active ? kGreen : Colors.grey[200]!),
                    boxShadow: active ? [BoxShadow(color: kGreen.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))] : null,
                  ),
                  child: Center(
                    child: Text(
                      f.label,
                      style: sans(13, weight: active ? FontWeight.w700 : FontWeight.w500, color: active ? Colors.white : Colors.grey[600]),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          if (_type == CalcType.payment) ...[
            _slider('Mortgage Amount', _mortgage, 50000, 2000000, 5000, (v) => setState(() => _mortgage = v)),
            _slider('Interest Rate', _rate, 0.5, 12, 0.05, (v) => setState(() => _rate = v), isPct: true),
            _slider('Amortization', _amortYears.toDouble(), 1, 30, 1, (v) => setState(() => _amortYears = v.round()), isYrs: true),
            _datePicker('First Payment Date', _startDate, (d) => setState(() => _startDate = d)),
          ],
          if (_type == CalcType.amount) ...[
            _slider('Initial Mortgage', _mortgage, 50000, 2000000, 5000, (v) => setState(() => _mortgage = v)),
            _slider('Interest Rate', _rate, 0.5, 12, 0.05, (v) => setState(() => _rate = v), isPct: true),
            _slider('Amortization', _amortYears.toDouble(), 1, 30, 1, (v) => setState(() => _amortYears = v.round()), isYrs: true),
            _slider('Show balance at', _showBalanceAtYear.toDouble(), 1, 30, 1, (v) => setState(() => _showBalanceAtYear = v.round()), isYrs: true),
            _datePicker('Start Date', _startDate, (d) => setState(() => _startDate = d)),
          ],
          if (_type == CalcType.rate) ...[
            _slider('Mortgage Amount', _mortgage, 50000, 2000000, 5000, (v) => setState(() => _mortgage = v)),
            _slider('${_frequency.label} Payment', _payment, 100, 15000, 10, (v) => setState(() => _payment = v)),
            _slider('Amortization', _amortYears.toDouble(), 1, 30, 1, (v) => setState(() => _amortYears = v.round()), isYrs: true),
            _datePicker('First Payment Date', _startDate, (d) => setState(() => _startDate = d)),
          ],
          if (_type == CalcType.amortization) ...[
            _slider('Mortgage Amount', _mortgage, 50000, 2000000, 5000, (v) => setState(() => _mortgage = v)),
            _slider('${_frequency.label} Payment', _payment, 100, 15000, 10, (v) => setState(() => _payment = v)),
            _slider('Interest Rate', _rate, 0.5, 12, 0.05, (v) => setState(() => _rate = v), isPct: true),
            _datePicker('First Payment Date', _startDate, (d) => setState(() => _startDate = d)),
          ],
          if (_type == CalcType.reverse) ...[
            _slider('Initial Mortgage', _mortgage, 50000, 2000000, 5000, (v) => setState(() => _mortgage = v)),
            _slider('Interest Rate', _rate, 0.5, 12, 0.05, (v) => setState(() => _rate = v), isPct: true),
            _slider('Show balance at', _showBalanceAtYear.toDouble(), 1, 50, 1, (v) => setState(() => _showBalanceAtYear = v.round()), isYrs: true),
            _datePicker('Start Date', _startDate, (d) => setState(() => _startDate = d)),
          ],
        ],
      ),
    );
  }

  Widget _buildStrategySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded, color: kAccent, size: 20),
              const SizedBox(width: 8),
              Text('Optimize My Mortgage', style: serif(16, color: kAccent)),
            ],
          ),
          const SizedBox(height: 20),
          _slider('Annual Lump Sum', _annualLumpSum, 0, 50000, 500, (v) => setState(() => _annualLumpSum = v)),
          _slider('Extra Per Payment', _extraPerPayment, 0, 2000, 10, (v) => setState(() => _extraPerPayment = v)),
          _slider('Annual Payment Increase', _paymentIncreasePct * 100, 0, 20, 1, (v) => setState(() => _paymentIncreasePct = v / 100), isPct: true),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Double-Up Payments', style: sans(13, weight: FontWeight.w600, color: Colors.grey[700])),
              Switch.adaptive(
                value: _doubleUp,
                activeColor: kGreen,
                onChanged: (v) => setState(() => _doubleUp = v),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Results Logic ──────────────────────────────────────────────────────────

  _CalcResult _calculate() {
    double principal = _mortgage;
    double rate = _rate / 100;
    int years = _amortYears;
    
    // 1. Baseline: same frequency as selected, non-accelerated, no prepayments.
    //    Accelerated variants compare against their non-accelerated counterpart so
    //    the savings banner reflects only the benefit of acceleration (and any
    //    prepayment strategies), not an arbitrary monthly-vs-biweekly timing gap.
    final baselineFreq = switch (_frequency) {
      PaymentFrequency.acceleratedBiweekly => PaymentFrequency.biweekly,
      PaymentFrequency.acceleratedWeekly   => PaymentFrequency.weekly,
      _                                    => _frequency,
    };
    final baselineSchedule = MortgageMath.yearlySchedule(
        principal: principal, annualRate: rate, amortizationYears: years, frequency: baselineFreq);
    final baselineInterest = baselineSchedule.fold(0.0, (sum, r) => sum + r.interestPaid);

    // 2. Calculate Active Strategy
    double primary = 0;
    final activeSchedule = MortgageMath.yearlySchedule(
      principal: principal,
      annualRate: rate,
      amortizationYears: years,
      frequency: _frequency,
      extraPerPayment: _extraPerPayment,
      annualLumpSum: _annualLumpSum,
      paymentIncreasePct: _paymentIncreasePct,
      doubleUp: _doubleUp,
    );

    switch (_type) {
      case CalcType.payment:
        primary = MortgageMath.calcPayment(principal: principal, annualRate: rate, amortizationYears: years, frequency: _frequency);
      case CalcType.amount:
        primary = MortgageMath.balanceAfter(principal: principal, annualRate: rate, amortizationYears: years, paymentsMade: _showBalanceAtYear * _frequency.paymentsPerYear, frequency: _frequency);
      case CalcType.rate:
        final r = MortgageMath.calcRate(payment: _payment, principal: principal, amortizationYears: years, frequency: _frequency);
        primary = r * 100;
      case CalcType.amortization:
        primary = activeSchedule.isEmpty ? 0 : activeSchedule.last.year.toDouble();
      case CalcType.reverse:
        final effectiveMonthlyRate = pow(1 + rate / 2, 2 / 12) - 1;
        primary = principal * pow(1 + effectiveMonthlyRate, _showBalanceAtYear * 12);
    }

    final totalInterest = activeSchedule.fold(0.0, (sum, r) => sum + r.interestPaid);
    final interestSaved = max(0.0, baselineInterest - totalInterest);
    final yearsSaved = max(0, years - (activeSchedule.isEmpty ? 0 : activeSchedule.last.year));

    return _CalcResult(
      primaryValue: primary,
      totalInterest: totalInterest,
      principal: principal,
      totalCost: principal + max(0, totalInterest),
      interestSaved: interestSaved,
      yearsSaved: yearsSaved,
    );
  }

  Widget _buildResultDisplay(_CalcResult res) {
    String label = '';
    String value = '';
    switch (_type) {
      case CalcType.payment: label = '${_frequency.label} Payment'; value = _fmt.format(res.primaryValue);
      case CalcType.amount: label = 'Balance in $_showBalanceAtYear Years'; value = _fmt.format(res.primaryValue);
      case CalcType.rate: label = 'Implied Interest Rate'; value = '${res.primaryValue.toStringAsFixed(2)}%';
      case CalcType.amortization: label = 'Amortization Period'; value = '${res.primaryValue.toInt()} Years';
      case CalcType.reverse: label = 'Future Balance'; value = _fmt.format(res.primaryValue);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [kGreen, Color(0xFF1E4D38)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: kGreen.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: sans(12, color: Colors.white.withValues(alpha: 0.7), weight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: serif(32, color: Colors.white)),
          if (res.interestSaved > 100) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: kAccent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16)),
              child: Text(
                'Saving ${_fmt.format(res.interestSaved)} in interest',
                style: sans(11, weight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Chart & Info ───────────────────────────────────────────────────────────

  Widget _buildChartSection(_CalcResult res) {
    final total = res.totalCost;
    final pPct = res.principal / total;
    final iPct = res.totalInterest / total;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          Text('Cost Breakdown', style: serif(18)),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            width: 160,
            child: CustomPaint(
              painter: _PiePainter(principalPct: pPct, interestPct: iPct),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _legend(kAccent, 'Principal', '${(pPct * 100).toStringAsFixed(0)}%'),
              _legend(const Color(0xFF2B82D0), 'Interest', '${(iPct * 100).toStringAsFixed(0)}%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(_CalcResult res) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          _kvRow('Total Principal', _fmt.format(res.principal)),
          _kvRow('Total Interest', _fmt.format(res.totalInterest)),
          const Divider(height: 24),
          _kvRow('Total Cost of Borrowing', _fmt.format(res.totalCost), isBold: true),
        ],
      ),
    );
  }

  Widget _slider(String label, double value, double min, double max, double step, ValueChanged<double> onChanged, {bool isPct = false, bool isYrs = false}) {
    String display = isPct ? '${value.toStringAsFixed(2)}%' : isYrs ? '${value.toInt()} yrs' : _fmt.format(value);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: sans(13, weight: FontWeight.w600, color: Colors.grey[700])),
              Text(display, style: sans(14, weight: FontWeight.w700, color: kGreen)),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: kGreen,
              inactiveTrackColor: kMint,
              thumbColor: kGreen,
              overlayColor: kGreen.withValues(alpha: 0.1),
              trackHeight: 4,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: max > min ? ((max - min) / step).round() : 1,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _datePicker(String label, DateTime date, ValueChanged<DateTime> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: sans(13, weight: FontWeight.w600, color: Colors.grey[700])),
        TextButton(
          onPressed: () async {
            final picked = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(2000), lastDate: DateTime(2100));
            if (picked != null) onChanged(picked);
          },
          child: Text(DateFormat('MMM d, yyyy').format(date), style: sans(14, weight: FontWeight.w700, color: kGreen)),
        ),
      ],
    );
  }

  Widget _kvRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: sans(13, color: Colors.grey[600])),
          Text(value, style: sans(14, weight: isBold ? FontWeight.w800 : FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label, String pct) {
    return Column(
      children: [
        Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 6), Text(label, style: sans(12, color: Colors.grey))]),
        Text(pct, style: sans(16, weight: FontWeight.w700)),
      ],
    );
  }
}

// ─── Logic Classes ────────────────────────────────────────────────────────────

class _CalcResult {
  final double primaryValue;
  final double totalInterest;
  final double principal;
  final double totalCost;
  final double interestSaved;
  final int yearsSaved;
  _CalcResult({required this.primaryValue, required this.totalInterest, required this.principal, required this.totalCost, required this.interestSaved, required this.yearsSaved});
}

// ─── Type Selector Sheet ─────────────────────────────────────────────────────

class _TypeSelectorSheet extends StatefulWidget {
  final CalcType initialType;
  final ValueChanged<CalcType> onSelected;

  const _TypeSelectorSheet({required this.initialType, required this.onSelected});

  @override
  State<_TypeSelectorSheet> createState() => _TypeSelectorSheetState();
}

class _TypeSelectorSheetState extends State<_TypeSelectorSheet> {
  late CalcType _tempType;

  @override
  void initState() {
    super.initState();
    _tempType = widget.initialType;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            Text('What would you like to calculate?', style: serif(24)),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                controller: controller,
                children: CalcType.values.map((t) {
                  final active = _tempType == t;
                  return GestureDetector(
                    onTap: () => setState(() => _tempType = t),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: active ? kGreen.withValues(alpha: 0.05) : Colors.white,
                        border: Border.all(color: active ? kGreen : Colors.grey[200]!, width: active ? 2 : 1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.label, style: sans(16, weight: FontWeight.w700)),
                                Text(t.description, style: sans(13, color: Colors.grey[500])),
                              ],
                            ),
                          ),
                          Radio<CalcType>(
                            value: t,
                            groupValue: _tempType,
                            activeColor: kGreen,
                            onChanged: (v) => setState(() => _tempType = v!),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                widget.onSelected(_tempType);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: kGreen, minimumSize: const Size(double.infinity, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: Text('Select Calculator', style: sans(16, weight: FontWeight.w700, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Pie Painter ─────────────────────────────────────────────────────────────

class _PiePainter extends CustomPainter {
  final double principalPct;
  final double interestPct;

  _PiePainter({required this.principalPct, required this.interestPct});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 24..strokeCap = StrokeCap.round;

    double startAngle = -pi / 2;
    
    // Principal
    paint.color = kAccent;
    canvas.drawArc(rect, startAngle, (2 * pi * principalPct).clamp(0.0, 2 * pi), false, paint);
    
    // Interest
    startAngle += 2 * pi * principalPct;
    paint.color = const Color(0xFF2B82D0);
    canvas.drawArc(rect, startAngle, (2 * pi * interestPct).clamp(0.0, 2 * pi), false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
