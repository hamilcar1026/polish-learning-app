import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../data/numeral_declensions.dart';

/// NumeralDeclensionTable
/// 숫자(1~100) 격변화 표를 표시하는 위젯. 헤더는 i18n 적용.
class NumeralDeclensionTable extends StatelessWidget {
  final int number;

  const NumeralDeclensionTable({super.key, required this.number});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final data = numeralDeclensions[number];

    if (data == null) {
      return Center(child: Text('${loc.noDeclensionData} ($number)'));
    }

    // i18n 케이스 라벨 매핑
    final caseLabels = {
      'caseNominative': loc.caseNominative,
      'caseGenitive': loc.caseGenitive,
      'caseDative': loc.caseDative,
      'caseAccusative': loc.caseAccusative,
      'caseInstrumental': loc.caseInstrumental,
      'caseLocative': loc.caseLocative,
      'caseVocative': loc.caseVocative,
    };

    // 폴란드어 격 순서 (numeral_declensions.dart의 키와 일치)
    final polishCases = [
      'caseNominative',
      'caseGenitive',
      'caseDative',
      'caseAccusative',
      'caseInstrumental',
      'caseLocative',
      'caseVocative',
    ];

    return DataTable(
      columns: [
        DataColumn(label: Text(loc.tableHeaderCase)),
        DataColumn(label: Text(loc.tableHeaderSingular)),
      ],
      rows: polishCases.map((caseKey) {
        return DataRow(
          cells: [
            DataCell(Text(caseLabels[caseKey] ?? caseKey)),
            DataCell(Text(data[caseKey] ?? '-')),
          ],
        );
      }).toList(),
    );
  }
}
