import '../core/mortgage_math.dart';

enum MortgageCalcType { payment, remainingBalance, rate, amortization, reverse }

class MortgageScenario {
  final String id;
  final String name;
  final MortgageCalcType calcType;

  // Basic Variables
  final double mortgageAmount;
  final double annualRatePct;
  final int amortizationYears;
  final double monthlyPayment;
  final int showBalanceAtYear;
  final DateTime startDate;
  
  // Strategy Variables
  final PaymentFrequency frequency;
  final double annualLumpSum;
  final double extraPerPayment;
  final double paymentIncreasePct;
  final bool doubleUp;

  final DateTime savedAt;

  MortgageScenario({
    required this.id,
    required this.name,
    required this.calcType,
    required this.mortgageAmount,
    required this.annualRatePct,
    required this.amortizationYears,
    required this.monthlyPayment,
    required this.showBalanceAtYear,
    required this.startDate,
    required this.savedAt,
    this.frequency = PaymentFrequency.monthly,
    this.annualLumpSum = 0,
    this.extraPerPayment = 0,
    this.paymentIncreasePct = 0,
    this.doubleUp = false,
  });
}
