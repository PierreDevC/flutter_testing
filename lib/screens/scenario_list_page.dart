import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../services/scenario_service.dart';
import 'mortgage_calculator_page.dart';
import 'prequalification_page.dart';

enum ScenarioToolType { mortgage, prequal }

class ScenarioListPage extends StatelessWidget {
  final ScenarioToolType type;

  const ScenarioListPage({super.key, required this.type});

  String get _title => type == ScenarioToolType.mortgage ? 'Mortgage Scenarios' : 'Pre-qualification Scenarios';

  @override
  Widget build(BuildContext context) {
    final service = ScenarioService.instance;
    final notifier = type == ScenarioToolType.mortgage ? service.mortgageScenarios : service.prequalScenarios;

    return Scaffold(
      backgroundColor: kMint,
      appBar: AppBar(
        backgroundColor: kMint,
        elevation: 0,
        title: Text(_title, style: serif(20)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ResponsiveMaxWidth(
        child: ValueListenableBuilder<String?>(
          valueListenable: service.pinnedScenarioId,
          builder: (context, pinnedId, _) {
            return ValueListenableBuilder<List<dynamic>>(
              valueListenable: notifier,
              builder: (context, scenarios, _) {
                if (scenarios.isEmpty) {
                  return _buildEmptyState(context);
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                  itemCount: scenarios.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final s = scenarios[index];
                    final isPinned = pinnedId == s.id;
                    return _ScenarioCard(
                      name: s.name,
                      date: s.savedAt,
                      isPinned: isPinned,
                      onTap: () => _openScenario(context, s),
                      onPin: () => service.togglePin(s.id, type == ScenarioToolType.mortgage ? ScenarioType.mortgage : ScenarioType.prequal),
                      onEdit: () => _editScenario(context, s),
                      onRename: () => _renameScenario(context, s.id, s.name),
                      onDelete: () => _deleteScenario(context, s.id),
                    );
                  },
                );
              },
            );
          }
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createNew(context),
        backgroundColor: kGreen,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('New Scenario', style: sans(14, weight: FontWeight.w700, color: Colors.white)),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Icon(
              type == ScenarioToolType.mortgage ? Icons.calculate_outlined : Icons.how_to_reg_outlined, 
              size: 40, 
              color: const Color(0xFFE0E0E0),
            ),
          ),
          const SizedBox(height: 20),
          Text('No scenarios yet', style: serif(20, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text('Save your calculations to compare them later.', style: sans(14, color: Colors.grey[500])),
        ],
      ),
    );
  }

  void _openScenario(BuildContext context, dynamic scenario) {
    if (type == ScenarioToolType.mortgage) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MortgageCalculatorPage(initialScenario: scenario)),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PrequalificationResults(
            originalId: scenario.id,
            income: scenario.grossIncome,
            downPayment: scenario.downPayment,
            debts: scenario.debts,
            city: scenario.city,
            scenarioName: scenario.name,
            residency: scenario.residency,
            isFirstTimeBuyer: scenario.isFirstTimeBuyer,
            isCondo: scenario.isCondo,
            isNewlyBuilt: scenario.isNewlyBuilt,
            usage: scenario.usage,
            employment: scenario.employment,
            credit: scenario.credit,
          ),
        ),
      );
    }
  }

  void _editScenario(BuildContext context, dynamic scenario) {
    if (type == ScenarioToolType.mortgage) {
      _openScenario(context, scenario);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PrequalificationPage(initialScenario: scenario)),
      );
    }
  }

  void _createNew(BuildContext context) {
    if (type == ScenarioToolType.mortgage) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const MortgageCalculatorPage()));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const PrequalificationPage()));
    }
  }

  void _renameScenario(BuildContext context, String id, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rename Scenario', style: serif(20)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'New name...',
            filled: true,
            fillColor: kMint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: sans(14, color: Colors.grey))),
          TextButton(
            onPressed: () {
              if (type == ScenarioToolType.mortgage) {
                ScenarioService.instance.renameMortgage(id, controller.text);
              } else {
                ScenarioService.instance.renamePrequal(id, controller.text);
              }
              Navigator.pop(context);
            },
            child: Text('Rename', style: sans(14, weight: FontWeight.w600, color: kGreen)),
          ),
        ],
      ),
    );
  }

  void _deleteScenario(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Scenario', style: serif(20)),
        content: Text('Are you sure you want to delete this scenario? This action cannot be undone.', style: sans(14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: sans(14, color: Colors.grey))),
          TextButton(
            onPressed: () {
              if (type == ScenarioToolType.mortgage) {
                ScenarioService.instance.removeMortgage(id);
              } else {
                ScenarioService.instance.removePrequal(id);
              }
              Navigator.pop(context);
            },
            child: Text('Delete', style: sans(14, weight: FontWeight.w600, color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  final String name;
  final DateTime date;
  final bool isPinned;
  final VoidCallback onTap;
  final VoidCallback onPin;
  final VoidCallback onEdit;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _ScenarioCard({
    required this.name,
    required this.date,
    required this.isPinned,
    required this.onTap,
    required this.onPin,
    required this.onEdit,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(name, style: serif(18)),
                      if (isPinned) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.push_pin_rounded, size: 14, color: kGreen),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(DateFormat('MMM d, yyyy').format(date), style: sans(12, color: Colors.grey[500])),
                ],
              ),
            ),
            IconButton(
              icon: Icon(isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined, size: 20, color: isPinned ? kGreen : Colors.grey[300]),
              onPressed: onPin,
            ),
            PopupMenuButton(
              icon: Icon(Icons.more_vert_rounded, color: Colors.grey[400]),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              itemBuilder: (context) => [
                PopupMenuItem(
                  onTap: onEdit,
                  child: Row(children: [
                    const Icon(Icons.edit_note_rounded, size: 18, color: kGreen), 
                    const SizedBox(width: 10), 
                    Text('Edit Survey', style: sans(14, weight: FontWeight.w600, color: kGreen))
                  ]),
                ),
                PopupMenuItem(
                  onTap: onRename,
                  child: Row(children: [
                    Icon(Icons.drive_file_rename_outline_rounded, size: 18, color: Colors.grey[700]), 
                    const SizedBox(width: 10), 
                    Text('Rename', style: sans(14))
                  ]),
                ),
                PopupMenuItem(
                  onTap: onDelete,
                  child: Row(children: [
                    Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red.shade600), 
                    const SizedBox(width: 10), 
                    Text('Delete', style: sans(14, color: Colors.red.shade600))
                  ]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
