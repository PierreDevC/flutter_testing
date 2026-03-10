import '../core/prequal_models.dart';

class PrequalScenario {
  final String id;
  final String name;
  
  // Input Data
  final String city;
  final ResidencyStatus residency;
  final bool isFirstTimeBuyer;
  final bool isCondo;
  final bool isNewlyBuilt;
  final PropertyUsage usage;
  final double downPayment;
  final List<DebtItem> debts;
  final EmploymentStatus employment;
  final double grossIncome;
  final CreditScore credit;
  
  final DateTime savedAt;

  PrequalScenario({
    required this.id,
    required this.name,
    required this.city,
    required this.residency,
    required this.isFirstTimeBuyer,
    required this.isCondo,
    required this.isNewlyBuilt,
    required this.usage,
    required this.downPayment,
    required this.debts,
    required this.employment,
    required this.grossIncome,
    required this.credit,
    required this.savedAt,
  });
}
