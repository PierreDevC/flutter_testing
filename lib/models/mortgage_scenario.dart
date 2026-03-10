import '../core/mortgage_math.dart';

class MortgageScenario {
  final String id;
  final String name;

  // Property & down payment
  final double propertyPrice;
  final double downPayment;

  // Loan
  final double loanAmount;        // before CMHC
  final double effectivePrincipal; // loanAmount + cmhcPremium
  final double cmhcPremium;

  // Rate & term
  final double annualRatePct; // e.g. 5.25
  final int amortizationYears;
  final int termYears;

  // Payment
  final PaymentFrequency frequency;
  final double payment;       // per selected frequency
  final double monthlyPayment;

  final DateTime savedAt;

  const MortgageScenario({
    required this.id,
    required this.name,
    required this.propertyPrice,
    required this.downPayment,
    required this.loanAmount,
    required this.effectivePrincipal,
    required this.cmhcPremium,
    required this.annualRatePct,
    required this.amortizationYears,
    required this.termYears,
    required this.frequency,
    required this.payment,
    required this.monthlyPayment,
    required this.savedAt,
  });
}
