import 'package:flutter/foundation.dart';
import '../models/mortgage_scenario.dart';
import '../models/prequalification_scenario.dart';

enum ScenarioType { mortgage, prequal }

class ScenarioService {
  ScenarioService._();
  static final ScenarioService instance = ScenarioService._();

  final ValueNotifier<List<MortgageScenario>> mortgageScenarios =
      ValueNotifier<List<MortgageScenario>>([]);

  final ValueNotifier<List<PrequalScenario>> prequalScenarios =
      ValueNotifier<List<PrequalScenario>>([]);

  final ValueNotifier<String?> pinnedScenarioId = ValueNotifier<String?>(null);
  final ValueNotifier<ScenarioType?> pinnedScenarioType = ValueNotifier<ScenarioType?>(null);

  // Mortgage Scenarios
  void addMortgage(MortgageScenario scenario) {
    mortgageScenarios.value = [...mortgageScenarios.value, scenario];
  }

  void removeMortgage(String id) {
    if (pinnedScenarioId.value == id) {
      pinnedScenarioId.value = null;
      pinnedScenarioType.value = null;
    }
    mortgageScenarios.value = mortgageScenarios.value.where((s) => s.id != id).toList();
  }

  void renameMortgage(String id, String newName) {
    mortgageScenarios.value = mortgageScenarios.value.map((s) {
      if (s.id == id) {
        return MortgageScenario(
          id: s.id,
          name: newName,
          calcType: s.calcType,
          mortgageAmount: s.mortgageAmount,
          annualRatePct: s.annualRatePct,
          amortizationYears: s.amortizationYears,
          monthlyPayment: s.monthlyPayment,
          showBalanceAtYear: s.showBalanceAtYear,
          startDate: s.startDate,
          savedAt: s.savedAt,
          frequency: s.frequency,
          annualLumpSum: s.annualLumpSum,
          extraPerPayment: s.extraPerPayment,
          paymentIncreasePct: s.paymentIncreasePct,
          doubleUp: s.doubleUp,
        );
      }
      return s;
    }).toList();
  }

  void updateMortgage(MortgageScenario scenario) {
    mortgageScenarios.value = mortgageScenarios.value.map((s) => s.id == scenario.id ? scenario : s).toList();
  }

  // Prequal Scenarios
  void addPrequal(PrequalScenario scenario) {
    prequalScenarios.value = [...prequalScenarios.value, scenario];
  }

  void removePrequal(String id) {
    if (pinnedScenarioId.value == id) {
      pinnedScenarioId.value = null;
      pinnedScenarioType.value = null;
    }
    prequalScenarios.value = prequalScenarios.value.where((s) => s.id != id).toList();
  }

  void renamePrequal(String id, String newName) {
    prequalScenarios.value = prequalScenarios.value.map((s) {
      if (s.id == id) {
        return PrequalScenario(
          id: s.id,
          name: newName,
          city: s.city,
          residency: s.residency,
          isFirstTimeBuyer: s.isFirstTimeBuyer,
          isCondo: s.isCondo,
          isNewlyBuilt: s.isNewlyBuilt,
          usage: s.usage,
          downPayment: s.downPayment,
          debts: s.debts,
          employment: s.employment,
          grossIncome: s.grossIncome,
          credit: s.credit,
          savedAt: s.savedAt,
        );
      }
      return s;
    }).toList();
  }

  void updatePrequal(PrequalScenario scenario) {
    prequalScenarios.value = prequalScenarios.value.map((s) => s.id == scenario.id ? scenario : s).toList();
  }

  void togglePin(String id, ScenarioType type) {
    if (pinnedScenarioId.value == id) {
      pinnedScenarioId.value = null;
      pinnedScenarioType.value = null;
    } else {
      pinnedScenarioId.value = id;
      pinnedScenarioType.value = type;
    }
  }

  dynamic get activeScenario {
    if (pinnedScenarioId.value != null) {
      if (pinnedScenarioType.value == ScenarioType.mortgage) {
        final list = mortgageScenarios.value.where((s) => s.id == pinnedScenarioId.value);
        if (list.isNotEmpty) return list.first;
      } else {
        final list = prequalScenarios.value.where((s) => s.id == pinnedScenarioId.value);
        if (list.isNotEmpty) return list.first;
      }
    }

    MortgageScenario? latestMortgage;
    if (mortgageScenarios.value.isNotEmpty) {
      latestMortgage = mortgageScenarios.value.reduce((a, b) => a.savedAt.isAfter(b.savedAt) ? a : b);
    }

    PrequalScenario? latestPrequal;
    if (prequalScenarios.value.isNotEmpty) {
      latestPrequal = prequalScenarios.value.reduce((a, b) => a.savedAt.isAfter(b.savedAt) ? a : b);
    }

    if (latestMortgage != null && latestPrequal != null) {
      return latestMortgage.savedAt.isAfter(latestPrequal.savedAt) ? latestMortgage : latestPrequal;
    }
    return latestMortgage ?? latestPrequal;
  }
}
