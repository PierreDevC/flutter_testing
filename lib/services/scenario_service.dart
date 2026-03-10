import 'package:flutter/foundation.dart';
import '../models/mortgage_scenario.dart';

class ScenarioService {
  ScenarioService._();
  static final ScenarioService instance = ScenarioService._();

  final ValueNotifier<List<MortgageScenario>> scenarios =
      ValueNotifier<List<MortgageScenario>>([]);

  void add(MortgageScenario scenario) {
    scenarios.value = [...scenarios.value, scenario];
  }

  void remove(String id) {
    scenarios.value = scenarios.value.where((s) => s.id != id).toList();
  }

  MortgageScenario? get latest =>
      scenarios.value.isEmpty ? null : scenarios.value.last;
}
