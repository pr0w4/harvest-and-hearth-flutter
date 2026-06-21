import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/info_content.dart';
import '../providers/app_provider.dart';
import '../widgets/info_document_layout.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final t = provider.t;
    final lang = provider.language;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t('profile_help_info'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: InfoDocumentLayout(
        title: t('profile_help_info'),
        headerIcon: Icons.help_outline_rounded,
        intro: t('help_center_intro'),
        sections: InfoContent.helpSections(lang),
      ),
    );
  }
}
