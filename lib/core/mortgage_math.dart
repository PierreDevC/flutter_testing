import 'dart:math';

// ─── Payment Frequency ────────────────────────────────────────────────────────

enum PaymentFrequency {
  monthly,
  semiMonthly,
  biweekly,
  acceleratedBiweekly,
  weekly,
  acceleratedWeekly;

  int get paymentsPerYear => switch (this) {
        PaymentFrequency.monthly => 12,
        PaymentFrequency.semiMonthly => 24,
        PaymentFrequency.biweekly => 26,
        PaymentFrequency.acceleratedBiweekly => 26,
        PaymentFrequency.weekly => 52,
        PaymentFrequency.acceleratedWeekly => 52,
      };

  bool get isAccelerated =>
      this == PaymentFrequency.acceleratedBiweekly ||
      this == PaymentFrequency.acceleratedWeekly;

  String get label => switch (this) {
        PaymentFrequency.monthly => 'Monthly',
        PaymentFrequency.semiMonthly => 'Semi-monthly',
        PaymentFrequency.biweekly => 'Bi-weekly',
        PaymentFrequency.acceleratedBiweekly => 'Accelerated bi-weekly',
        PaymentFrequency.weekly => 'Weekly',
        PaymentFrequency.acceleratedWeekly => 'Accelerated weekly',
      };

  String get shortLabel => switch (this) {
        PaymentFrequency.monthly => '/mo',
        PaymentFrequency.semiMonthly => '/semi-mo',
        PaymentFrequency.biweekly => '/biweek',
        PaymentFrequency.acceleratedBiweekly => '/biweek',
        PaymentFrequency.weekly => '/wk',
        PaymentFrequency.acceleratedWeekly => '/wk',
      };
}

// ─── Yearly Schedule Row ──────────────────────────────────────────────────────

class YearlyRow {
  final int year;
  final double principalPaid;
  final double interestPaid;
  final double balance;

  const YearlyRow({
    required this.year,
    required this.principalPaid,
    required this.interestPaid,
    required this.balance,
  });
}

// ─── Core Math ────────────────────────────────────────────────────────────────

class MortgageMath {
  // Canadian mortgage: nominal annual rate compounded semi-annually.
  // Effective monthly rate = (1 + annualRate/2)^(1/6) - 1
  static double effectiveMonthlyRate(double annualRate) {
    return pow(1 + annualRate / 2, 1 / 6).toDouble() - 1;
  }

  static double periodicRate(double annualRate, PaymentFrequency freq) {
    final m = effectiveMonthlyRate(annualRate);
    return switch (freq) {
      PaymentFrequency.monthly => m,
      PaymentFrequency.semiMonthly => pow(1 + m, 0.5).toDouble() - 1,
      PaymentFrequency.biweekly ||
      PaymentFrequency.acceleratedBiweekly =>
        pow(1 + m, 12 / 26).toDouble() - 1,
      PaymentFrequency.weekly ||
      PaymentFrequency.acceleratedWeekly =>
        pow(1 + m, 12 / 52).toDouble() - 1,
    };
  }

  static double calcPayment({
    required double principal,
    required double annualRate,
    required int amortizationYears,
    PaymentFrequency frequency = PaymentFrequency.monthly,
  }) {
    if (principal <= 0) return 0;
    if (annualRate <= 0) {
      return principal / (amortizationYears * frequency.paymentsPerYear);
    }
    if (frequency.isAccelerated) {
      final monthlyPmt = _standardPayment(
          principal, annualRate, amortizationYears, PaymentFrequency.monthly);
      return frequency == PaymentFrequency.acceleratedBiweekly
          ? monthlyPmt / 2
          : monthlyPmt / 4;
    }
    return _standardPayment(principal, annualRate, amortizationYears, frequency);
  }

  static double _standardPayment(double p, double r, int years, PaymentFrequency freq) {
    final rate = periodicRate(r, freq);
    final n = years * freq.paymentsPerYear;
    if (rate == 0) return p / n;
    return p * rate * pow(1 + rate, n) / (pow(1 + rate, n) - 1);
  }

  // Solve for max loan given periodic payment, rate, amortization
  static double calcPrincipal({
    required double payment,
    required double annualRate,
    required int amortizationYears,
    PaymentFrequency frequency = PaymentFrequency.monthly,
  }) {
    if (payment <= 0) return 0;
    // For accelerated, treat as monthly equivalent
    final double effectivePmt;
    final PaymentFrequency effectiveFreq;
    if (frequency.isAccelerated) {
      effectivePmt = payment *
          (frequency == PaymentFrequency.acceleratedBiweekly ? 2 : 4);
      effectiveFreq = PaymentFrequency.monthly;
    } else {
      effectivePmt = payment;
      effectiveFreq = frequency;
    }
    if (annualRate <= 0) {
      return effectivePmt * amortizationYears * effectiveFreq.paymentsPerYear;
    }
    final r = periodicRate(annualRate, effectiveFreq);
    final n = amortizationYears * effectiveFreq.paymentsPerYear;
    if (r == 0) return effectivePmt * n;
    return effectivePmt * (pow(1 + r, n) - 1) / (r * pow(1 + r, n));
  }

  // Solve for annual rate via binary search
  static double calcRate({
    required double payment,
    required double principal,
    required int amortizationYears,
    PaymentFrequency frequency = PaymentFrequency.monthly,
  }) {
    if (principal <= 0 || payment <= 0) return 0;
    double lo = 0.0001, hi = 0.30;
    for (int i = 0; i < 200; i++) {
      final mid = (lo + hi) / 2;
      final calc = calcPayment(
        principal: principal,
        annualRate: mid,
        amortizationYears: amortizationYears,
        frequency: frequency,
      );
      if ((calc - payment).abs() < 0.01) return mid;
      if (calc > payment) { hi = mid; } else { lo = mid; }
    }
    return (lo + hi) / 2;
  }

  // Solve for amortization years
  static int calcAmortization({
    required double payment,
    required double principal,
    required double annualRate,
    PaymentFrequency frequency = PaymentFrequency.monthly,
  }) {
    if (principal <= 0 || payment <= 0) return 25;
    for (int years = 1; years <= 30; years++) {
      final calc = calcPayment(
        principal: principal,
        annualRate: annualRate,
        amortizationYears: years,
        frequency: frequency,
      );
      if (calc <= payment) return years;
    }
    return 30;
  }

  // Balance remaining after a given number of payments
  static double balanceAfter({
    required double principal,
    required double annualRate,
    required int amortizationYears,
    required int paymentsMade,
    PaymentFrequency frequency = PaymentFrequency.monthly,
  }) {
    if (principal <= 0) return 0;
    if (annualRate <= 0) {
      final pmt = principal / (amortizationYears * frequency.paymentsPerYear);
      return max(0.0, principal - pmt * paymentsMade);
    }
    final r = periodicRate(annualRate, frequency);
    final pmt = calcPayment(
        principal: principal,
        annualRate: annualRate,
        amortizationYears: amortizationYears,
        frequency: frequency);
    if (frequency.isAccelerated) {
      // Step through schedule for accuracy
      double balance = principal;
      for (int i = 0; i < paymentsMade && balance > 0; i++) {
        final interest = balance * r;
        balance = max(0, balance - (pmt - interest));
      }
      return balance;
    }
    final val = principal * pow(1 + r, paymentsMade) -
        pmt * (pow(1 + r, paymentsMade) - 1) / r;
    return max(0.0, val);
  }

  // CMHC insurance premium rate by LTV
  static double cmhcRate(double ltv) {
    if (ltv <= 0.80) return 0.0;
    if (ltv <= 0.85) return 0.028;
    if (ltv <= 0.90) return 0.031;
    return 0.040;
  }

  static double cmhcPremium(double loanAmount, double propertyPrice) {
    if (propertyPrice <= 0) return 0;
    final ltv = loanAmount / propertyPrice;
    return loanAmount * cmhcRate(ltv);
  }

  // Stress test qualifying rate
  static double stressTestRate(double contractRate) {
    return max(contractRate + 0.02, 0.0525);
  }

  // Yearly amortization schedule with optional prepayments
  static List<YearlyRow> yearlySchedule({
    required double principal,
    required double annualRate,
    required int amortizationYears,
    PaymentFrequency frequency = PaymentFrequency.monthly,
    double extraPerPayment = 0,
    double annualLumpSum = 0,
    double paymentIncreasePct = 0, // 0.15 for 15%
    bool doubleUp = false,
  }) {
    if (principal <= 0 || amortizationYears <= 0) return [];
    final r = periodicRate(annualRate, frequency);
    final initialBasePmt = calcPayment(
      principal: principal,
      annualRate: annualRate,
      amortizationYears: amortizationYears,
      frequency: frequency,
    );
    final paymentsPerYear = frequency.paymentsPerYear;

    double balance = principal;
    final rows = <YearlyRow>[];
    double currentBasePmt = initialBasePmt;

    for (int year = 1; year <= amortizationYears + 30 && balance > 0.01; year++) {
      double yearPrincipal = 0, yearInterest = 0;
      
      // Calculate current periodic payment for this year
      // Increase payment annually if specified
      if (year > 1) {
        currentBasePmt *= (1 + paymentIncreasePct);
      }

      final pmt = currentBasePmt + extraPerPayment + (doubleUp ? currentBasePmt : 0);

      for (int p = 0; p < paymentsPerYear && balance > 0.01; p++) {
        final interest = balance * r;
        final prin = min(pmt - interest, balance);
        if (prin < 0) {
          // Interest exceeds payment, which shouldn't happen with standard amort
          // but could with extra small payments. In that case, add interest to balance.
          balance += (interest - pmt);
          yearInterest += interest;
          yearPrincipal -= (interest - pmt); // Negative principal
        } else {
          yearInterest += interest;
          yearPrincipal += prin;
          balance -= prin;
        }
        if (balance < 0.01) balance = 0;
      }
      
      // Annual Lump Sum at end of year
      if (annualLumpSum > 0 && balance > 0) {
        final extra = min(annualLumpSum, balance);
        yearPrincipal += extra;
        balance -= extra;
        if (balance < 0.01) balance = 0;
      }

      rows.add(YearlyRow(
        year: year,
        principalPaid: yearPrincipal,
        interestPaid: yearInterest,
        balance: balance,
      ));
      if (balance <= 0.01) break;
    }
    return rows;
  }
}
