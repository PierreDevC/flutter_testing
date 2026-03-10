enum ResidencyStatus {
  citizen('Canadian Citizen'),
  permanentResident('Permanent Resident'),
  nonResident('Non-Resident');

  final String label;
  const ResidencyStatus(this.label);
}

enum PropertyUsage {
  reside('I plan to reside there'),
  resideAndRent('I will reside but rent out parts'),
  fullyRent('I will fully rent it out');

  final String label;
  const PropertyUsage(this.label);
}

enum EmploymentStatus {
  employed('Employed'),
  selfEmployed('Self-Employed'),
  pension('Pension');

  final String label;
  const EmploymentStatus(this.label);
}

enum CreditScore {
  excellent('Excellent', '800 - 900'),
  veryGood('Very Good', '680 - 799'),
  good('Good', '600 - 679'),
  needsWork('Needs some work', '300 - 559');

  final String label;
  final String range;
  const CreditScore(this.label, this.range);
}

class DebtItem {
  final String type;
  double balance;
  double monthlyPayment;

  DebtItem({required this.type, this.balance = 0, this.monthlyPayment = 0});
}
