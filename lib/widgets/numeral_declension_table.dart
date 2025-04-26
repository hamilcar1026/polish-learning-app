import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Basic numeral declension table for Polish numerals 1-100.
/// [forms] is a map of case code (e.g. 'nom', 'gen', etc.) to the declension form.
class NumeralDeclensionTable extends StatelessWidget {
  final String lemma; // e.g. "pięć"
  final Map<String, String> forms;

  const NumeralDeclensionTable({
    Key? key,
    required this.lemma,
    required this.forms,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final caseOrder = [
      'nom', 'gen', 'dat', 'acc', 'inst', 'loc', 'voc'
    ];
    final caseNames = [
      l10n.caseNominative,
      l10n.caseGenitive,
      l10n.caseDative,
      l10n.caseAccusative,
      l10n.caseInstrumental,
      l10n.caseLocative,
      l10n.caseVocative,
    ];
    return Card(
      color: Theme.of(context).colorScheme.surface,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Table(
          border: TableBorder.all(color: Theme.of(context).dividerColor),
          columnWidths: const {
            0: IntrinsicColumnWidth(),
            1: FlexColumnWidth(),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.08)),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(l10n.tableHeaderCase, style: Theme.of(context).textTheme.labelLarge),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    lemma,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            ...List.generate(caseOrder.length, (i) {
              final code = caseOrder[i];
              return TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Text(caseNames[i]),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Text(forms[code] ?? '-'),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
