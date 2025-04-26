import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ContributorsScreen extends StatelessWidget {
  const ContributorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsContributors),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          // TODO: Replace with actual contributor list/info
          child: Text('Contributor information will be shown here.'), 
        ),
      ),
    );
  }
} 