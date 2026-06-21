import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/info_content.dart';
import '../providers/app_provider.dart';
import '../widgets/info_document_layout.dart';

class SecurityInfoScreen extends StatelessWidget {
  const SecurityInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final t = provider.t;
    final lang = provider.language;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t('profile_security_info'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: InfoDocumentLayout(
        title: t('profile_security_info'),
        headerIcon: Icons.security_outlined,
        intro: t('security_info_intro'),
        sections: InfoContent.securitySections(lang),
      ),
    );
  }
}
