import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/categories.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'help_center_screen.dart';
import 'notifications_screen.dart';
import 'security_info_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final t = provider.t;
    final user = provider.user!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(t('profile_title'),
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          // Avatar card
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: BorderSide(color: cs.primary.withAlpha(85)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: cs.primaryContainer,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t('dashboard_welcome'),
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: TextStyle(
                              color: cs.onSurfaceVariant, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Preferences section
          _SectionLabel(title: t('profile_preferences')),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                // Language
                ListTile(
                  leading: const Icon(Icons.language_rounded),
                  title: Text(t('profile_language')),
                  trailing: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'VIE', label: Text('VIE')),
                      ButtonSegment(value: 'ENG', label: Text('ENG')),
                    ],
                    selected: {provider.language},
                    onSelectionChanged: (s) => provider.setLanguage(s.first),
                    style: ButtonStyle(
                      padding: const WidgetStatePropertyAll(
                        EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      side: WidgetStatePropertyAll(
                        BorderSide(color: cs.outlineVariant.withAlpha(120)),
                      ),
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                // Dark mode
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode_outlined),
                  title: Text(t('profile_dark_mode')),
                  value: provider.isDark,
                  onChanged: (_) => provider.toggleTheme(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Settings section
          _SectionLabel(title: t('profile_settings')),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_active_outlined),
                  title: Text(t('profile_expiry_reminders')),
                  subtitle: Text(
                    t('profile_expiry_reminders_sub'),
                    style: const TextStyle(fontSize: 12),
                  ),
                  value: provider.expiryRemindersEnabled,
                  onChanged: (v) => provider.setExpiryRemindersEnabled(v),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.notifications_none_rounded),
                  title: Text(t('profile_notifications_center')),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    context.read<AppProvider>().refreshNotificationLogs();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.tune_rounded),
                  title: Text(t('food_expiry_default_settings')),
                  subtitle: Text(
                    t('food_expiry_default_settings_sub'),
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const _InventoryDefaultsScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.security_outlined),
                  title: Text(t('profile_security_info')),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SecurityInfoScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.help_outline_rounded),
                  title: Text(t('profile_help_info')),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HelpCenterScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Inventory stats
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: _StatItem(
                      value: '${provider.inventory.length}',
                      label: t('dashboard_items'),
                      icon: Icons.kitchen_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatItem(
                      value: '${provider.savedRecipes.length}',
                      label: t('recipes_saved'),
                      icon: Icons.bookmark_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatItem(
                      value: '${provider.expiredItems.length}',
                      label: t('dashboard_expired'),
                      icon: Icons.warning_amber_rounded,
                      isAlert: provider.expiredItems.isNotEmpty,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          _SectionLabel(title: t('profile_hearthie_about')),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.hearthieSky.withAlpha(28),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.hearthieGold.withAlpha(140),
                          ),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: AppColors.hearthieGold,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Hearthie',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _AboutRow(
                    title: t('profile_hearthie_mission'),
                    content: provider.language == 'VIE'
                        ? 'Giúp nấu ăn thực tế, giảm lãng phí thực phẩm và ra quyết định nhanh trong gian bếp.'
                        : 'Help users cook practically, reduce food waste, and make faster kitchen decisions.',
                  ),
                  _AboutRow(
                    title: t('profile_hearthie_capabilities'),
                    content: provider.language == 'VIE'
                        ? 'Gợi ý công thức theo kho hiện tại, meal plan 7 ngày, budget mode, leftovers mode, shopping list thiếu nguyên liệu.'
                        : 'Inventory-based recipes, 7-day meal plans, budget mode, leftovers mode, and missing-ingredient shopping lists.',
                  ),
                  _AboutRow(
                    title: t('profile_hearthie_limits'),
                    content: provider.language == 'VIE'
                        ? 'Không thay thế tư vấn y tế/dinh dưỡng chuyên sâu; luôn cần người dùng kiểm tra dị ứng và độ an toàn thực phẩm.'
                        : 'Not a substitute for medical/professional nutrition advice; users should verify allergies and food safety.',
                  ),
                  _AboutRow(
                    title: t('profile_hearthie_powered'),
                    content: 'Groq Cloud',
                  ),
                  _AboutRow(
                    title: t('profile_hearthie_creator'),
                    content: 'pr0w4 - pr0w4.dev',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Logout
          OutlinedButton.icon(
            onPressed: () => _confirmLogout(context, provider),
            icon: const Icon(Icons.logout_rounded, color: Colors.red),
            label: Text(t('profile_logout'),
                style: const TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.red.withAlpha(180), width: 1.4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, AppProvider provider) {
    final t = provider.t;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t('profile_logout')),
        content: Text(t('profile_logout_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('common_cancel')),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final auth = ClerkAuth.of(context, listen: false);
              await provider.logout(auth);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(t('profile_logout')),
          ),
        ],
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({
    required this.title,
    required this.content,
  });

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              '$title:',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              content,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryDefaultsScreen extends StatelessWidget {
  const _InventoryDefaultsScreen();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final t = provider.t;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          t('food_expiry_default_settings'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: AppCategories.all.map((info) {
          final value = provider.defaultExpiryDaysFor(info.category);
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(info.icon, color: info.color),
              title: Text(t(info.translationKey)),
              subtitle: Text('${t('food_expiry_default_days')}: $value'),
              trailing: SizedBox(
                width: 110,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: () => provider.setDefaultExpiryDaysFor(
                        info.category,
                        value - 1,
                      ),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text('$value'),
                    IconButton(
                      onPressed: () => provider.setDefaultExpiryDaysFor(
                        info.category,
                        value + 1,
                      ),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final bool isAlert;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isAlert ? Colors.red : Theme.of(context).colorScheme.primary;
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (isAlert ? Colors.red : cs.primary).withAlpha(90),
        ),
        color: (isAlert ? Colors.red : cs.primary).withAlpha(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
