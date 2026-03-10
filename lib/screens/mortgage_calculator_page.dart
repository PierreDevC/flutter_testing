import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../core/mortgage_math.dart';
import '../models/mortgage_scenario.dart';
import '../services/scenario_service.dart';

// ─── Mode ─────────────────────────────────────────────────────────────────────

enum CalcMode { payment, amount, rate, amortization }

// ─── Computed result ──────────────────────────────────────────────────────────

class _Result {
  final double payment;        // per selected frequency
  final double monthlyPayment;
  final double effectivePrincipal;
  final double cmhcPremium;
  final double loanAmount;
  final double annualRate;
  final int amortYears;
  final double ltv;
  final double firstInterest;
  final double firstPrincipal;
  final double totalInterest;
  final double totalCost;
  final double balanceAtEndOfTerm;
  final double interestDuringTerm;
  final List<YearlyRow> schedule;
  final List<YearlyRow> scheduleNoPrepay; // for comparison
  final double interestSaved;

  const _Result({
    required this.payment,
    required this.monthlyPayment,
    required this.effectivePrincipal,
    required this.cmhcPremium,
    required this.loanAmount,
    required this.annualRate,
    required this.amortYears,
    required this.ltv,
    required this.firstInterest,
    required this.firstPrincipal,
    required this.totalInterest,
    required this.totalCost,
    required this.balanceAtEndOfTerm,
    required this.interestDuringTerm,
    required this.schedule,
    required this.scheduleNoPrepay,
    required this.interestSaved,
  });
}

// ─── Formatters ───────────────────────────────────────────────────────────────

final _currencyFmt = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
final _currency2Fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
String _fmtCurrency(double v) => _currencyFmt.format(v);
String _fmtCurrency2(double v) => _currency2Fmt.format(v);
String _fmtPct(double v) => '${(v * 100).toStringAsFixed(2)}%';
String _fmtPctPct(double v) => '${v.toStringAsFixed(2)}%'; // v already in %

// ─── Page ─────────────────────────────────────────────────────────────────────

class MortgageCalculatorPage extends StatefulWidget {
  const MortgageCalculatorPage({super.key});

  @override
  State<MortgageCalculatorPage> createState() => _MortgageCalculatorPageState();
}

class _MortgageCalculatorPageState extends State<MortgageCalculatorPage> {
  // Mode
  CalcMode _mode = CalcMode.payment;

  // Core inputs
  double _loanAmount = 388000;
  double _ratePct = 5.25; // as % (e.g. 5.25)
  int _amortYears = 25;
  double _paymentInput = 2142;

  // Down payment section
  double _propertyPrice = 485000;
  double _downPaymentAbs = 97000;
  bool _downAsPct = false;

  // Additional
  PaymentFrequency _frequency = PaymentFrequency.monthly;
  int _termYears = 5;
  DateTime _firstPaymentDate = DateTime.now();
  bool _showStressTest = false;

  // Prepayments
  bool _showPrepayment = false;
  double _lumpSum = 0;
  double _extraPerPayment = 0;

  // UI
  bool _showMonthly = false;

  // ── Sync helpers ────────────────────────────────────────────────────────────

  void _onPropertyPriceChanged(double v) {
    final pct = _propertyPrice > 0 ? _downPaymentAbs / _propertyPrice : 0.20;
    setState(() {
      _propertyPrice = v;
      _downPaymentAbs = (v * pct).clamp(0, v);
      _loanAmount = (_propertyPrice - _downPaymentAbs).clamp(0, 2000000);
    });
  }

  void _onDownPaymentChanged(double v) {
    setState(() {
      _downPaymentAbs = v.clamp(0, _propertyPrice);
      _loanAmount = (_propertyPrice - _downPaymentAbs).clamp(0, 2000000);
    });
  }

  void _onLoanAmountChanged(double v) {
    setState(() {
      _loanAmount = v;
      _downPaymentAbs = (_propertyPrice - v).clamp(0, _propertyPrice);
    });
  }

  // ── Computed ────────────────────────────────────────────────────────────────

  double get _annualRate => _ratePct / 100;
  double get _downPct => _propertyPrice > 0 ? _downPaymentAbs / _propertyPrice : 0;
  double get _cmhcPremium =>
      MortgageMath.cmhcPremium(_loanAmount, _propertyPrice);
  double get _effectivePrincipal => _loanAmount + _cmhcPremium;
  double get _ltv =>
      _propertyPrice > 0 ? _loanAmount / _propertyPrice : 0;

  _Result _compute() {
    // 1. Determine the "Final" inputs for this calculation cycle
    double finalPrincipal = _effectivePrincipal;
    double finalAnnualRate = _annualRate;
    int finalAmortYears = _amortYears;
    double finalPayment = 0;
    double finalMonthlyPayment = 0;
    double finalCmhc = _cmhcPremium;
    double finalLoanAmount = _loanAmount;

    switch (_mode) {
      case CalcMode.payment:
        finalPayment = MortgageMath.calcPayment(
          principal: finalPrincipal,
          annualRate: finalAnnualRate,
          amortizationYears: finalAmortYears,
          frequency: _frequency,
        );
        finalMonthlyPayment = MortgageMath.calcPayment(
          principal: finalPrincipal,
          annualRate: finalAnnualRate,
          amortizationYears: finalAmortYears,
          frequency: PaymentFrequency.monthly,
        );

      case CalcMode.amount:
        // Input is _paymentInput (periodic payment)
        // MortgageMath.calcPrincipal gives total effective principal (Loan + CMHC)
        finalPrincipal = MortgageMath.calcPrincipal(
          payment: _paymentInput,
          annualRate: finalAnnualRate,
          amortizationYears: finalAmortYears,
          frequency: _frequency,
        );
        finalPayment = _paymentInput;
        
        // Solve for base loan amount (back out CMHC)
        // Since CMHC is a % of loan amount based on LTV, and LTV = loan / price
        // This is tricky if price isn't fixed. We assume the current _propertyPrice
        // or a fixed down payment. Let's assume the user wants the max loan 
        // given the current _downPaymentAbs or a target LTV.
        // For simplicity in a calculator: Principal = Loan + CMHC(Loan, Price)
        // We'll approximate the base loan by iterating or using the math:
        // Loan = Principal / (1 + CMHC_Rate)
        final ltv = _propertyPrice > 0 ? (finalPrincipal - _downPaymentAbs) / _propertyPrice : 0.80;
        final cRate = MortgageMath.cmhcRate(ltv);
        finalLoanAmount = finalPrincipal / (1 + cRate);
        finalCmhc = finalPrincipal - finalLoanAmount;

        finalMonthlyPayment = MortgageMath.calcPayment(
          principal: finalPrincipal,
          annualRate: finalAnnualRate,
          amortizationYears: finalAmortYears,
          frequency: PaymentFrequency.monthly,
        );

      case CalcMode.rate:
        finalAnnualRate = MortgageMath.calcRate(
          payment: _paymentInput,
          principal: finalPrincipal,
          amortizationYears: finalAmortYears,
          frequency: _frequency,
        );
        finalPayment = _paymentInput;
        finalMonthlyPayment = MortgageMath.calcPayment(
          principal: finalPrincipal,
          annualRate: finalAnnualRate,
          amortizationYears: finalAmortYears,
          frequency: PaymentFrequency.monthly,
        );

      case CalcMode.amortization:
        finalAmortYears = MortgageMath.calcAmortization(
          payment: _paymentInput,
          principal: finalPrincipal,
          annualRate: finalAnnualRate,
          frequency: _frequency,
        );
        finalPayment = _paymentInput;
        finalMonthlyPayment = MortgageMath.calcPayment(
          principal: finalPrincipal,
          annualRate: finalAnnualRate,
          amortizationYears: finalAmortYears,
          frequency: PaymentFrequency.monthly,
        );
    }

    // 2. Calculate derived outputs using the "Final" values
    final r = MortgageMath.periodicRate(finalAnnualRate, _frequency);
    final firstInterest = finalPrincipal * r;
    final firstPrincipal = finalPayment - firstInterest;

    // Schedule with prepayments
    final schedule = MortgageMath.yearlySchedule(
      principal: finalPrincipal,
      annualRate: finalAnnualRate,
      amortizationYears: finalAmortYears,
      frequency: _frequency,
      extraPerPayment: _extraPerPayment,
      annualLumpSum: _lumpSum,
    );

    // Baseline schedule (no prepayments) for comparison
    final scheduleNoPrepay = (_lumpSum > 0 || _extraPerPayment > 0)
        ? MortgageMath.yearlySchedule(
            principal: finalPrincipal,
            annualRate: finalAnnualRate,
            amortizationYears: finalAmortYears,
            frequency: _frequency,
          )
        : schedule;

    final totalInterest = schedule.fold(0.0, (sum, row) => sum + row.interestPaid);
    final totalInterestNoPrepay = scheduleNoPrepay.fold(0.0, (sum, row) => sum + row.interestPaid);
    final totalCost = finalPrincipal + totalInterest;

    final termPayments = _termYears * _frequency.paymentsPerYear;
    final balanceAtEndOfTerm = MortgageMath.balanceAfter(
      principal: finalPrincipal,
      annualRate: finalAnnualRate,
      amortizationYears: finalAmortYears,
      paymentsMade: termPayments,
      frequency: _frequency,
    );

    double interestDuringTerm = 0;
    double bal = finalPrincipal;
    for (int i = 0; i < termPayments && bal > 0.01; i++) {
      final interest = bal * r;
      interestDuringTerm += interest;
      bal = max(0, bal - (finalPayment - interest));
    }

    return _Result(
      payment: finalPayment,
      monthlyPayment: finalMonthlyPayment,
      effectivePrincipal: finalPrincipal,
      cmhcPremium: finalCmhc,
      loanAmount: finalLoanAmount,
      annualRate: finalAnnualRate,
      amortYears: finalAmortYears,
      ltv: _propertyPrice > 0 ? finalLoanAmount / _propertyPrice : 0,
      firstInterest: firstInterest,
      firstPrincipal: firstPrincipal,
      totalInterest: totalInterest,
      totalCost: totalCost,
      balanceAtEndOfTerm: balanceAtEndOfTerm,
      interestDuringTerm: interestDuringTerm,
      schedule: schedule,
      scheduleNoPrepay: scheduleNoPrepay,
      interestSaved: max(0, totalInterestNoPrepay - totalInterest),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final result = _compute();

    return Scaffold(
      backgroundColor: kMint,
      appBar: AppBar(
        backgroundColor: kMint,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Mortgage Calculator', style: serif(18)),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
        children: [
          _buildModeToggle(),
          const SizedBox(height: 16),
          _buildInputCard(result),
          const SizedBox(height: 12),
          _buildDownPaymentCard(),
          const SizedBox(height: 12),
          _buildSettingsCard(),
          const SizedBox(height: 12),
          _buildPrepaymentCard(),
          const SizedBox(height: 20),
          _buildPrimaryResult(result),
          const SizedBox(height: 12),
          _buildBreakdownCard(result),
          const SizedBox(height: 12),
          _buildCostSummaryCard(result),
          const SizedBox(height: 12),
          _buildAmortizationCard(result),
        ],
      ),
      bottomNavigationBar: _buildSaveBar(result),
    );
  }

  // ── Mode Toggle ─────────────────────────────────────────────────────────────

  Widget _buildModeToggle() {
    const modes = [
      (CalcMode.payment, 'Monthly Payment', Icons.payments_outlined),
      (CalcMode.amount, 'Mortgage Amount', Icons.account_balance_outlined),
      (CalcMode.rate, 'Interest Rate', Icons.percent_rounded),
      (CalcMode.amortization, 'Amortization', Icons.hourglass_bottom_rounded),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Calculate my…',
            style: sans(12, weight: FontWeight.w600, color: Colors.grey[500])
                .copyWith(letterSpacing: 0.8)),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 3.2,
          children: modes.map((m) {
            final active = _mode == m.$1;
            return GestureDetector(
              onTap: () => setState(() => _mode = m.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: active ? kGreen : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(m.$3,
                        size: 16,
                        color: active ? Colors.white : Colors.grey[400]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        m.$2,
                        style: sans(12,
                            weight: FontWeight.w600,
                            color: active ? Colors.white : Colors.grey[700]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Input Card (3 sliders based on mode) ────────────────────────────────────

  Widget _buildInputCard(_Result result) {
    final rate = _annualRate;
    final stressRate = MortgageMath.stressTestRate(rate);
    final impliedRate = result.annualRate;
    final impliedAmort = result.amortYears;
    final impliedAmount = result.loanAmount;

    return _card(
      children: [
        // Mortgage Amount slider (shown for payment, rate, amortization modes)
        if (_mode != CalcMode.amount) ...[
          _SliderField(
            label: 'Mortgage Amount',
            value: _loanAmount,
            min: 50000,
            max: 2000000,
            step: 5000,
            prefix: '\$',
            displayValue: _fmtCurrency(_loanAmount),
            onChanged: _onLoanAmountChanged,
            onTyped: (v) => _onLoanAmountChanged(v.clamp(0, 2000000)),
          ),
          const SizedBox(height: 16),
        ],

        // Monthly Payment slider (shown for amount, rate, amortization modes)
        if (_mode != CalcMode.payment) ...[
          _SliderField(
            label: 'Monthly Payment',
            value: _paymentInput,
            min: 500,
            max: 15000,
            step: 50,
            prefix: '\$',
            displayValue: _fmtCurrency(_paymentInput),
            onChanged: (v) => setState(() => _paymentInput = v),
            onTyped: (v) => setState(() => _paymentInput = v.clamp(500, 15000)),
          ),
          const SizedBox(height: 16),
        ],

        // Interest Rate slider (shown for all except rate mode)
        if (_mode != CalcMode.rate) ...[
          _SliderField(
            label: 'Interest Rate',
            value: _ratePct,
            min: 0.5,
            max: 12,
            step: 0.05,
            suffix: '%',
            displayValue: '${_ratePct.toStringAsFixed(2)}%',
            onChanged: (v) => setState(() => _ratePct = v),
            onTyped: (v) => setState(() => _ratePct = v.clamp(0.5, 12)),
          ),
          Row(
            children: [
              const Spacer(),
              Text('Show stress test rate',
                  style: sans(12, color: Colors.grey[600])),
              const SizedBox(width: 6),
              Switch.adaptive(
                value: _showStressTest,
                onChanged: (v) => setState(() => _showStressTest = v),
                activeTrackColor: kAccent,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
          if (_showStressTest) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 14, color: Color(0xFFD07A2B)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: sans(12, color: Colors.grey[700]),
                        children: [
                          const TextSpan(text: 'Contract rate: '),
                          TextSpan(
                              text: _fmtPctPct(_ratePct),
                              style: sans(12, weight: FontWeight.w700)),
                          const TextSpan(text: '   Qualifying rate: '),
                          TextSpan(
                              text: _fmtPct(stressRate),
                              style: sans(12,
                                  weight: FontWeight.w700,
                                  color: const Color(0xFFD07A2B))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ] else
            const SizedBox(height: 8),
        ],

        // Amortization slider (shown for all except amortization mode)
        if (_mode != CalcMode.amortization) ...[
          _SliderField(
            label: 'Amortization',
            value: _amortYears.toDouble(),
            min: 5,
            max: 30,
            step: 1,
            suffix: ' yrs',
            displayValue: '$_amortYears yrs',
            onChanged: (v) => setState(() => _amortYears = v.round()),
            onTyped: (v) =>
                setState(() => _amortYears = v.round().clamp(5, 30)),
          ),
          if (_amortYears > 25) ...[
            const SizedBox(height: 8),
            _infoBanner(
              '30-year amortization requires ≥ 20% down payment (uninsured mortgage).',
              const Color(0xFF2B82D0),
              const Color(0xFFDCEEF9),
            ),
          ],
        ],

        // Shown output for derived modes
        if (_mode == CalcMode.rate) ...[
          _outputRow('Implied rate', _fmtPct(impliedRate)),
          if (_showStressTest)
            _outputRow('Qualifying rate',
                _fmtPct(MortgageMath.stressTestRate(impliedRate)),
                color: const Color(0xFFD07A2B)),
        ],
        if (_mode == CalcMode.amortization)
          _outputRow('Years to pay off', '$impliedAmort yrs'),
        if (_mode == CalcMode.amount)
          _outputRow('Max loan amount', _fmtCurrency(impliedAmount)),
      ],
    );
  }

  // ── Down Payment Card ───────────────────────────────────────────────────────

  Widget _buildDownPaymentCard() {
    final pct = _downPct * 100;
    final hasCmhc = _ltv > 0.80;
    final insufficientDown = _ltv > 0.95;

    return _card(
      children: [
        Row(
          children: [
            Text('Down Payment',
                style: sans(14, weight: FontWeight.w600)),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _downAsPct = !_downAsPct),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: kMint, borderRadius: BorderRadius.circular(20)),
                child: Text(
                  _downAsPct ? 'Switch to \$' : 'Switch to %',
                  style: sans(11,
                      weight: FontWeight.w600, color: kGreen),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _SliderField(
          label: 'Property Price',
          value: _propertyPrice,
          min: 100000,
          max: 3000000,
          step: 5000,
          prefix: '\$',
          displayValue: _fmtCurrency(_propertyPrice),
          onChanged: _onPropertyPriceChanged,
          onTyped: (v) => _onPropertyPriceChanged(v.clamp(100000, 3000000)),
        ),
        const SizedBox(height: 14),
        if (_downAsPct)
          _SliderField(
            label: 'Down Payment',
            value: pct,
            min: 0,
            max: 100,
            step: 0.5,
            suffix: '%',
            displayValue: '${pct.toStringAsFixed(1)}%',
            onChanged: (v) =>
                _onDownPaymentChanged(_propertyPrice * v / 100),
            onTyped: (v) =>
                _onDownPaymentChanged(_propertyPrice * v.clamp(0, 100) / 100),
          )
        else
          _SliderField(
            label: 'Down Payment',
            value: _downPaymentAbs,
            min: 0,
            max: _propertyPrice,
            step: 5000,
            prefix: '\$',
            displayValue: _fmtCurrency(_downPaymentAbs),
            onChanged: _onDownPaymentChanged,
            onTyped: (v) => _onDownPaymentChanged(v.clamp(0, _propertyPrice)),
          ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _kvSmall('Down payment', '${pct.toStringAsFixed(1)}%'),
            _kvSmall('Mortgage amount', _fmtCurrency(_loanAmount)),
            if (hasCmhc)
              _kvSmall('CMHC insurance', _fmtCurrency(_cmhcPremium),
                  color: const Color(0xFFD07A2B)),
          ],
        ),
        if (hasCmhc) ...[
          const SizedBox(height: 10),
          _infoBanner(
            'Mortgage insurance (CMHC) will be added to your loan amount.',
            const Color(0xFFD07A2B),
            const Color(0xFFFFF3E0),
          ),
        ],
        if (insufficientDown) ...[
          const SizedBox(height: 6),
          _infoBanner(
            'Minimum down payment is 5% for properties up to \$500,000.',
            const Color(0xFFD32F2F),
            const Color(0xFFFFF0F0),
          ),
        ],
      ],
    );
  }

  // ── Settings Card ───────────────────────────────────────────────────────────

  Widget _buildSettingsCard() {
    return _card(
      children: [
        Text('Loan Settings', style: sans(14, weight: FontWeight.w600)),
        const SizedBox(height: 14),
        _dropdownRow<PaymentFrequency>(
          label: 'Payment Frequency',
          value: _frequency,
          items: PaymentFrequency.values,
          itemLabel: (f) => f.label,
          onChanged: (v) => setState(() => _frequency = v),
        ),
        const Divider(height: 24, color: Color(0xFFF0F0F0)),
        _dropdownRow<int>(
          label: 'Mortgage Term',
          value: _termYears,
          items: const [1, 2, 3, 4, 5, 7, 10],
          itemLabel: (v) => '$v ${v == 1 ? 'year' : 'years'}',
          onChanged: (v) => setState(() => _termYears = v),
        ),
        const Divider(height: 24, color: Color(0xFFF0F0F0)),
        Row(
          children: [
            Text('First Payment Date',
                style: sans(13, weight: FontWeight.w500)),
            const Spacer(),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _firstPaymentDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() => _firstPaymentDate = picked);
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: kMint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  DateFormat('MMM d, yyyy').format(_firstPaymentDate),
                  style: sans(13, weight: FontWeight.w600, color: kGreen),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Prepayment Card ─────────────────────────────────────────────────────────

  Widget _buildPrepaymentCard() {
    return _card(
      children: [
        GestureDetector(
          onTap: () => setState(() => _showPrepayment = !_showPrepayment),
          child: Row(
            children: [
              const Icon(Icons.add_circle_outline_rounded,
                  size: 18, color: kAccent),
              const SizedBox(width: 8),
              Text('Extra Payments',
                  style: sans(14, weight: FontWeight.w600, color: kAccent)),
              const Spacer(),
              Icon(
                _showPrepayment
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
        if (_showPrepayment) ...[
          const SizedBox(height: 14),
          _labeledTextField(
            label: 'Lump sum per year',
            value: _lumpSum,
            prefix: '\$',
            onChanged: (v) => setState(() => _lumpSum = v),
          ),
          const SizedBox(height: 12),
          _labeledTextField(
            label: 'Extra amount per payment',
            value: _extraPerPayment,
            prefix: '\$',
            onChanged: (v) => setState(() => _extraPerPayment = v),
          ),
          const SizedBox(height: 10),
          _infoBanner(
            'Most Canadian lenders allow 10–20% of the original principal as prepayment without penalty.',
            Colors.grey,
            const Color(0xFFF5F5F5),
          ),
        ],
      ],
    );
  }

  // ── Primary Result ──────────────────────────────────────────────────────────

  Widget _buildPrimaryResult(_Result result) {
    final String label;
    final String value;
    final String sublabel;

    switch (_mode) {
      case CalcMode.payment:
        label = 'Estimated ${_frequency.label.toLowerCase()} payment';
        value = _fmtCurrency(result.payment);
        sublabel = _frequency == PaymentFrequency.monthly
            ? ''
            : 'Monthly equivalent: ${_fmtCurrency(result.monthlyPayment)}';
      case CalcMode.amount:
        label = 'Maximum mortgage amount';
        value = _fmtCurrency(result.loanAmount);
        sublabel =
            'Property up to ${_fmtCurrency(result.loanAmount + _downPaymentAbs)}';
      case CalcMode.rate:
        label = 'Implied interest rate';
        value = _fmtPct(result.annualRate);
        sublabel = _showStressTest
            ? 'Qualifying rate: ${_fmtPct(MortgageMath.stressTestRate(result.annualRate))}'
            : '';
      case CalcMode.amortization:
        label = "You'll be mortgage-free in";
        value = '${result.amortYears} years';
        sublabel = '';
    }

    final effectiveAmort = result.schedule.isEmpty ? 0 : result.schedule.last.year;
    final hasPrepay = _lumpSum > 0 || _extraPerPayment > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kGreen, Color(0xFF1E4D38)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kGreen.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: sans(13, color: Colors.white.withValues(alpha: 0.7))),
          const SizedBox(height: 6),
          Text(value,
              style: serif(40, color: Colors.white)
                  .copyWith(letterSpacing: -1, height: 1.1)),
          if (sublabel.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(sublabel,
                style: sans(12, color: Colors.white.withValues(alpha: 0.6))),
          ],
          if (hasPrepay && effectiveAmort < _amortYears) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: kAccent.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Paid off in $effectiveAmort yrs  ·  Save ${_fmtCurrency(result.interestSaved)} interest',
                style: sans(11,
                    weight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Breakdown Card (donut chart) ────────────────────────────────────────────

  Widget _buildBreakdownCard(_Result result) {
    final p = result.firstPrincipal.clamp(0.0, double.infinity);
    final i = result.firstInterest.clamp(0.0, double.infinity);
    final ins = result.cmhcPremium;
    final total = p + i + (ins > 0 ? ins / _amortYears / 12 : 0);

    return _card(
      children: [
        Text('Payment Breakdown',
            style: sans(14, weight: FontWeight.w600)),
        Text('First payment split',
            style: sans(12, color: Colors.grey[500])),
        const SizedBox(height: 16),
        Row(
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: CustomPaint(
                painter: _DonutPainter(
                  principal: p,
                  interest: i,
                  insurance: ins > 0 ? ins / _amortYears / 12 : 0,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _legendRow(kAccent, 'Principal',
                      total > 0 ? '${(p / total * 100).toStringAsFixed(1)}%' : '—'),
                  const SizedBox(height: 8),
                  _legendRow(const Color(0xFF2B82D0), 'Interest',
                      total > 0 ? '${(i / total * 100).toStringAsFixed(1)}%' : '—'),
                  if (ins > 0) ...[
                    const SizedBox(height: 8),
                    _legendRow(const Color(0xFFD07A2B), 'CMHC insurance',
                        '${((ins / _amortYears / 12) / total * 100).toStringAsFixed(1)}%'),
                  ],
                ],
              ),
            ),
          ],
        ),
        const Divider(height: 24, color: Color(0xFFF0F0F0)),
        _kvRow('Payment amount',
            '${_fmtCurrency(result.payment)}${_frequency.shortLabel}'),
        _kvRow('Principal (first payment)', _fmtCurrency2(p)),
        _kvRow('Interest (first payment)', _fmtCurrency2(i)),
        if (ins > 0)
          _kvRow('CMHC premium (total)', _fmtCurrency(ins)),
      ],
    );
  }

  // ── Cost Summary Card ───────────────────────────────────────────────────────

  Widget _buildCostSummaryCard(_Result result) {
    final effectiveAmort =
        result.schedule.isEmpty ? _amortYears : result.schedule.last.year;
    final hasPrepay = _lumpSum > 0 || _extraPerPayment > 0;

    return _card(
      children: [
        Text('Cost Summary', style: sans(14, weight: FontWeight.w600)),
        const SizedBox(height: 14),
        _kvRow('Total cost (full amortization)', _fmtCurrency(result.totalCost)),
        _kvRow('Total interest paid', _fmtCurrency(result.totalInterest)),
        _kvRow('Interest during term ($_termYears yrs)',
            _fmtCurrency(result.interestDuringTerm)),
        _kvRow('Balance at end of term',
            _fmtCurrency(result.balanceAtEndOfTerm)),
        _kvRow('Effective amortization', '$effectiveAmort years'),
        if (hasPrepay && result.interestSaved > 0)
          _kvRow('Interest saved from prepayments',
              _fmtCurrency(result.interestSaved),
              color: kAccent),
      ],
    );
  }

  // ── Amortization Schedule Card ──────────────────────────────────────────────

  Widget _buildAmortizationCard(_Result result) {
    final maxBar = result.schedule.isEmpty
        ? 1.0
        : result.schedule
            .map((r) => r.principalPaid + r.interestPaid)
            .reduce(max);

    return _card(
      children: [
        Row(
          children: [
            Text('Amortization Schedule',
                style: sans(14, weight: FontWeight.w600)),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _showMonthly = !_showMonthly),
              child: Text(
                _showMonthly ? 'Show yearly' : 'Show monthly',
                style: sans(12, color: kAccent, weight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Stacked bar chart (simplified)
        SizedBox(
          height: 80,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: result.schedule.take(30).map((row) {
              final total = row.principalPaid + row.interestPaid;
              final frac = maxBar > 0 ? total / maxBar : 0.0;
              final pFrac = total > 0 ? row.principalPaid / total : 0.0;
              final isMilestone = row.year == _termYears;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0.5),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (isMilestone)
                        Container(width: 2, height: 4, color: kAccent),
                      SizedBox(
                        height: 72 * frac,
                        child: Column(
                          children: [
                            Expanded(
                              flex: ((1 - pFrac) * 100).round(),
                              child: Container(
                                  color: const Color(0xFF2B82D0)
                                      .withValues(alpha: 0.7)),
                            ),
                            Expanded(
                              flex: (pFrac * 100).round().clamp(1, 100),
                              child: Container(color: kAccent.withValues(alpha: 0.7)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              _legendDot(kAccent, 'Principal'),
              const SizedBox(width: 16),
              _legendDot(const Color(0xFF2B82D0), 'Interest'),
              const SizedBox(width: 16),
              _legendDot(kAccent, 'Term end ($_termYears yr)', isLine: true),
            ],
          ),
        ),
        const Divider(height: 16, color: Color(0xFFF0F0F0)),
        // Table header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              SizedBox(width: 40, child: Text('Year', style: sans(11, weight: FontWeight.w600, color: Colors.grey[500]))),
              Expanded(child: Text('Principal', style: sans(11, weight: FontWeight.w600, color: Colors.grey[500]), textAlign: TextAlign.right)),
              Expanded(child: Text('Interest', style: sans(11, weight: FontWeight.w600, color: Colors.grey[500]), textAlign: TextAlign.right)),
              Expanded(child: Text('Balance', style: sans(11, weight: FontWeight.w600, color: Colors.grey[500]), textAlign: TextAlign.right)),
            ],
          ),
        ),
        ...result.schedule.take(_showMonthly ? 360 : 30).map((row) {
          final isEven = row.year % 2 == 0;
          final isTerm = row.year == _termYears;
          return Container(
            color: isTerm
                ? kAccent.withValues(alpha: 0.07)
                : isEven
                    ? Colors.grey.withValues(alpha: 0.04)
                    : Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Text(
                    '${row.year}',
                    style: sans(12,
                        weight:
                            isTerm ? FontWeight.w700 : FontWeight.w400,
                        color: isTerm ? kAccent : null),
                  ),
                ),
                Expanded(
                    child: Text(_fmtCurrency(row.principalPaid),
                        style: sans(12), textAlign: TextAlign.right)),
                Expanded(
                    child: Text(_fmtCurrency(row.interestPaid),
                        style: sans(12), textAlign: TextAlign.right)),
                Expanded(
                    child: Text(_fmtCurrency(row.balance),
                        style: sans(12), textAlign: TextAlign.right)),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── Save Bar ────────────────────────────────────────────────────────────────

  Widget _buildSaveBar(_Result result) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Color(0x10000000), blurRadius: 12, offset: Offset(0, -4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Scenario name…',
                hintStyle: sans(13, color: Colors.grey[400]),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                filled: true,
                fillColor: kMint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: sans(13),
              onChanged: (v) => setState(() {}), // triggers rebuild for button
              onSubmitted: (_) {},
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: () => _saveScenario(result),
            style: ElevatedButton.styleFrom(
              backgroundColor: kGreen,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            icon: const Icon(Icons.bookmark_add_outlined, size: 18),
            label: Text('Save', style: sans(13, weight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _saveScenario(_Result result) {
    final name = 'Scenario ${ScenarioService.instance.scenarios.value.length + 1}';
    final scenario = MortgageScenario(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      propertyPrice: _propertyPrice,
      downPayment: _downPaymentAbs,
      loanAmount: result.loanAmount,
      effectivePrincipal: result.effectivePrincipal,
      cmhcPremium: result.cmhcPremium,
      annualRatePct: result.annualRate * 100,
      amortizationYears: result.amortYears,
      termYears: _termYears,
      frequency: _frequency,
      payment: result.payment,
      monthlyPayment: result.monthlyPayment,
      savedAt: DateTime.now(),
    );
    ScenarioService.instance.add(scenario);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"$name" saved!', style: sans(13, color: Colors.white)),
        backgroundColor: kGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Shared helpers ──────────────────────────────────────────────────────────

  Widget _card({required List<Widget> children}) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _outputRow(String label, String value, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: (color ?? kAccent).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: sans(13, color: Colors.grey[600])),
          Text(value,
              style: sans(14,
                  weight: FontWeight.w700, color: color ?? kAccent)),
        ],
      ),
    );
  }

  Widget _kvRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
              child: Text(label, style: sans(13, color: Colors.grey[600]))),
          Text(value,
              style: sans(13,
                  weight: FontWeight.w600, color: color ?? const Color(0xFF1A1A1A))),
        ],
      ),
    );
  }

  Widget _kvSmall(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: sans(11, color: Colors.grey[500])),
        const SizedBox(height: 2),
        Text(value,
            style: sans(13,
                weight: FontWeight.w700,
                color: color ?? const Color(0xFF1A1A1A))),
      ],
    );
  }

  Widget _legendRow(Color color, String label, String pct) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Expanded(child: Text(label, style: sans(12, color: Colors.grey[700]))),
        Text(pct, style: sans(12, weight: FontWeight.w600)),
      ],
    );
  }

  Widget _legendDot(Color color, String label, {bool isLine = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        isLine
            ? Container(
                width: 12,
                height: 2,
                decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(1)))
            : Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                    color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: sans(10, color: Colors.grey[600])),
      ],
    );
  }

  Widget _infoBanner(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: bgColor, borderRadius: BorderRadius.circular(10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 14, color: textColor),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text, style: sans(12, color: textColor))),
        ],
      ),
    );
  }

  Widget _labeledTextField({
    required String label,
    required double value,
    String prefix = '',
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        Expanded(child: Text(label, style: sans(13, weight: FontWeight.w500))),
        SizedBox(
          width: 110,
          child: TextField(
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
            ],
            controller: TextEditingController(
                text: value > 0 ? value.toStringAsFixed(0) : '0'),
            decoration: InputDecoration(
              prefixText: prefix,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              filled: true,
              fillColor: kMint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            style: sans(13),
            onSubmitted: (v) {
              final parsed = double.tryParse(v);
              if (parsed != null) onChanged(parsed);
            },
          ),
        ),
      ],
    );
  }

  Widget _dropdownRow<T>({
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T> onChanged,
  }) {
    return Row(
      children: [
        Text(label, style: sans(13, weight: FontWeight.w500)),
        const Spacer(),
        DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            isDense: true,
            style: sans(13, weight: FontWeight.w600),
            items: items
                .map((i) => DropdownMenuItem<T>(
                    value: i, child: Text(itemLabel(i))))
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
      ],
    );
  }
}

// ─── Donut Chart Painter ──────────────────────────────────────────────────────

class _DonutPainter extends CustomPainter {
  final double principal;
  final double interest;
  final double insurance;

  const _DonutPainter({
    required this.principal,
    required this.interest,
    required this.insurance,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = principal + interest + insurance;
    if (total <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    void drawArc(double value, Color color, double startAngle) {
      final sweep = 2 * pi * value / total;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep - 0.04,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 18
          ..strokeCap = StrokeCap.butt,
      );
    }

    double angle = -pi / 2;
    drawArc(principal, kAccent, angle);
    angle += 2 * pi * principal / total;
    drawArc(interest, const Color(0xFF2B82D0), angle);
    angle += 2 * pi * interest / total;
    if (insurance > 0) drawArc(insurance, const Color(0xFFD07A2B), angle);
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.principal != principal ||
      old.interest != interest ||
      old.insurance != insurance;
}

// ─── Slider + Text Field Widget ───────────────────────────────────────────────

class _SliderField extends StatefulWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final double step;
  final String prefix;
  final String suffix;
  final String displayValue;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onTyped;

  const _SliderField({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    this.prefix = '',
    this.suffix = '',
    required this.displayValue,
    required this.onChanged,
    required this.onTyped,
  });

  @override
  State<_SliderField> createState() => _SliderFieldState();
}

class _SliderFieldState extends State<_SliderField> {
  late TextEditingController _controller;
  late FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.displayValue);
    _focus = FocusNode();
    _focus.addListener(() {
      if (!_focus.hasFocus) _submit();
    });
  }

  @override
  void didUpdateWidget(_SliderField old) {
    super.didUpdateWidget(old);
    if (!_focus.hasFocus && old.displayValue != widget.displayValue) {
      _controller.text = widget.displayValue;
    }
  }

  void _submit() {
    final raw = _controller.text.replaceAll(RegExp(r'[^\d.]'), '');
    final parsed = double.tryParse(raw);
    if (parsed != null) widget.onTyped(parsed);
    _controller.text = widget.displayValue;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final divisions = ((widget.max - widget.min) / widget.step).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(widget.label,
                style: sans(13, weight: FontWeight.w500)),
            const Spacer(),
            SizedBox(
              width: 110,
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                ],
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  prefixText: widget.prefix,
                  suffixText: widget.suffix,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  filled: true,
                  fillColor: kMint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: sans(13, weight: FontWeight.w600),
                onSubmitted: (_) => _submit(),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: kAccent,
            inactiveTrackColor: kAccent.withValues(alpha: 0.15),
            thumbColor: kAccent,
            overlayColor: kAccent.withValues(alpha: 0.15),
            trackHeight: 3,
            thumbShape:
                const RoundSliderThumbShape(enabledThumbRadius: 7),
          ),
          child: Slider(
            value: widget.value.clamp(widget.min, widget.max),
            min: widget.min,
            max: widget.max,
            divisions: divisions,
            onChanged: widget.onChanged,
          ),
        ),
      ],
    );
  }
}
