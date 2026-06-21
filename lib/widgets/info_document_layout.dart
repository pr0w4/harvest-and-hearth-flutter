import 'package:flutter/material.dart';

import '../constants/info_content.dart';
import '../theme/app_theme.dart';

class InfoDocumentLayout extends StatelessWidget {
  const InfoDocumentLayout({
    super.key,
    required this.title,
    required this.headerIcon,
    required this.sections,
    this.intro,
  });

  final String title;
  final IconData headerIcon;
  final List<InfoSectionData> sections;
  final String? intro;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
      children: [
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            side: BorderSide(color: cs.primary.withAlpha(70)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withAlpha(120),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.primary.withAlpha(90)),
                  ),
                  child: Icon(headerIcon, color: cs.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (intro != null && intro!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            intro!,
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
        const SizedBox(height: 16),
        ...sections.map(
          (section) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _InfoSectionCard(section: section),
          ),
        ),
        const SizedBox(height: 8),
        _SamsungFooter(cs: cs),
      ],
    );
  }
}

class _InfoSectionCard extends StatelessWidget {
  const _InfoSectionCard({required this.section});

  final InfoSectionData section;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(section.icon, size: 20, color: cs.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    section.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            if (section.body.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                section.body,
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ],
            if (section.bullets.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...section.bullets.map(
                (b) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: cs.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          b,
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SamsungFooter extends StatelessWidget {
  const _SamsungFooter({required this.cs});

  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withAlpha(120)),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.apartment_rounded,
            size: 22,
            color: cs.onSurfaceVariant.withAlpha(180),
          ),
          const SizedBox(height: 8),
          Text(
            InfoContent.footer,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
