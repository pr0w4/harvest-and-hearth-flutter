import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../models/food_item.dart';
import '../screens/ai_chat_screen.dart';
import '../screens/barcode_scanner_screen.dart';
import '../screens/meal_calendar_planner_screen.dart';
import '../screens/recipes_screen.dart';
import '../widgets/add_food_modal.dart';
import '../constants/categories.dart';
import '../theme/app_theme.dart';
import '../utils/date_helper.dart';
import '../services/weather_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<WeatherSnapshot> _weatherFuture;

  @override
  void initState() {
    super.initState();
    _weatherFuture = _loadWeather();
  }

  Future<WeatherSnapshot> _loadWeather() {
    final isVn = context.read<AppProvider>().language == 'VIE';
    return WeatherService.fetchCurrentWeather(isVietnamese: isVn);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final t = provider.t;

    final expired = provider.expiredItems;
    final expiringSoon = provider.expiringSoonItems;
    final recent = provider.inventory.take(5).toList();
    final goodCount = provider.inventory
        .where((i) => !i.isExpired && !i.isExpiringSoon)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.eco_rounded,
                color: Theme.of(context).colorScheme.primary, size: 26),
            const SizedBox(width: 8),
            Text(
              'Harvest & Hearth',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(provider.isDark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined),
            tooltip: t('profile_dark_mode'),
            onPressed: () => context.read<AppProvider>().toggleTheme(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
        children: [
          _WelcomeBanner(
            provider: provider,
            weatherFuture: _weatherFuture,
            onRefreshWeather: () {
              setState(() {
                _weatherFuture = _loadWeather();
              });
            },
          ),
          const SizedBox(height: 20),
          _StatsRow(
            total: provider.inventory.length,
            expiredCount: expired.length,
            expiringCount: expiringSoon.length,
            goodCount: goodCount,
            t: t,
          ),
          const SizedBox(height: 20),
          _SectionHeader(title: t('dashboard_quick_actions')),
          const SizedBox(height: 10),
          _QuickActionGrid(provider: provider, isDemoMode: provider.isDemoMode),
          const SizedBox(height: 20),
          _AiChatPreviewCard(provider: provider),
          const SizedBox(height: 20),
          if (expired.isNotEmpty || expiringSoon.isNotEmpty) ...[
            _SectionHeader(title: t('dashboard_alerts')),
            const SizedBox(height: 10),
            _AlertsCard(
              expired: expired,
              expiringSoon: expiringSoon,
              t: t,
              language: provider.language,
            ),
            const SizedBox(height: 20),
          ],
          _SectionHeader(title: t('dashboard_realtime_recipes')),
          const SizedBox(height: 10),
          _RealtimeRecipeSuggestionsCard(provider: provider),
          if (!provider.isDemoMode) ...[
            const SizedBox(height: 20),
            _SectionHeader(title: t('dashboard_recent')),
            const SizedBox(height: 10),
            if (recent.isEmpty)
              _EmptyCard(message: t('dashboard_no_items'))
            else
              _RecentItemsList(
                items: recent,
                t: t,
                language: provider.language,
              ),
            const SizedBox(height: 20),
            _TipCard(t: t),
          ],
        ],
      ),
    );
  }
}

// ── Welcome Banner ──────────────────────────────────────────────────────────

class _WelcomeBanner extends StatefulWidget {
  final AppProvider provider;
  final Future<WeatherSnapshot> weatherFuture;
  final VoidCallback onRefreshWeather;
  const _WelcomeBanner({
    required this.provider,
    required this.weatherFuture,
    required this.onRefreshWeather,
  });

  @override
  State<_WelcomeBanner> createState() => _WelcomeBannerState();
}

class _WelcomeBannerState extends State<_WelcomeBanner> {
  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final t = provider.t;
    final name = provider.user?.name ?? '';
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? (provider.language == 'VIE' ? 'Chào buổi sáng' : 'Good morning')
        : hour < 17
            ? (provider.language == 'VIE'
                ? 'Chào buổi trưa'
                : 'Good afternoon')
            : (provider.language == 'VIE' ? 'Chào buổi tối' : 'Good evening');

    return FutureBuilder<WeatherSnapshot>(
      future: widget.weatherFuture,
      builder: (context, snapshot) {
        final weather = snapshot.data;
        final scene = _resolveSkyScene(hour, weather?.weatherCode);
        final gradient = _gradientForScene(scene);
        final symbol = _symbolForScene(scene, hour);

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: const [0.0, 0.65, 1.0],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withAlpha(70),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(38),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.waving_hand_rounded,
                  color: Colors.amberAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting, $name',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      t('dashboard_subtitle'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _WeatherMiniInfo(
                provider: provider,
                weather: weather,
                symbol: symbol,
                onRefresh: widget.onRefreshWeather,
              ),
            ],
          ),
        );
      },
    );
  }

  List<Color> _gradientForScene(_SkyScene scene) {
    switch (scene) {
      case _SkyScene.daySunny:
        return const [Color(0xFF2F80ED), Color(0xFF56CCF2), Color(0xFFFFD166)];
      case _SkyScene.dayRainy:
        return const [Color(0xFF314755), Color(0xFF4B6B7C), Color(0xFF1F2F3A)];
      case _SkyScene.noon:
        return const [Color(0xFF1890FF), Color(0xFF6AD0FF), Color(0xFFFFA940)];
      case _SkyScene.nightClear:
        return const [Color(0xFF0B1D3A), Color(0xFF152A52), Color(0xFF050A17)];
    }
  }

  _SkyScene _resolveSkyScene(int hour, int? weatherCode) {
    final rainyCodes = <int>{
      51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82, 95, 96, 99
    };
    if (hour >= 19 || hour < 5) return _SkyScene.nightClear;
    if (hour >= 11 && hour < 14) return _SkyScene.noon;
    if (weatherCode != null && rainyCodes.contains(weatherCode)) {
      return _SkyScene.dayRainy;
    }
    return _SkyScene.daySunny;
  }

  _WeatherSymbol _symbolForScene(_SkyScene scene, int hour) {
    switch (scene) {
      case _SkyScene.daySunny:
        return hour >= 15 ? _WeatherSymbol.evening : _WeatherSymbol.morning;
      case _SkyScene.noon:
        return _WeatherSymbol.noon;
      case _SkyScene.nightClear:
        return _WeatherSymbol.night;
      case _SkyScene.dayRainy:
        return _WeatherSymbol.rain;
    }
  }
}

class _WeatherMiniInfo extends StatelessWidget {
  const _WeatherMiniInfo({
    required this.provider,
    required this.weather,
    required this.symbol,
    required this.onRefresh,
  });

  final AppProvider provider;
  final WeatherSnapshot? weather;
  final _WeatherSymbol symbol;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    if (weather == null) {
      return InkWell(
        onTap: onRefresh,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(28),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withAlpha(42)),
          ),
          child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
        ),
      );
    }
    return InkWell(
      onTap: onRefresh,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minWidth: 134),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(26),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withAlpha(42)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${weather!.temperatureC.toStringAsFixed(0)}°C',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(width: 8),
                _WeatherSymbolIcon(symbol: symbol),
              ],
            ),
            Text(
              weather!.city,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _WeatherSymbolIcon extends StatelessWidget {
  const _WeatherSymbolIcon({required this.symbol});

  final _WeatherSymbol symbol;

  @override
  Widget build(BuildContext context) {
    switch (symbol) {
      case _WeatherSymbol.morning:
        return const Icon(Icons.wb_sunny_rounded, color: Color(0xFFFFD54F), size: 20);
      case _WeatherSymbol.noon:
        return const Icon(Icons.sunny, color: Color(0xFFFFD54F), size: 20);
      case _WeatherSymbol.evening:
        return const Icon(Icons.wb_twilight_rounded, color: Color(0xFFFFD54F), size: 20);
      case _WeatherSymbol.night:
        return const Icon(Icons.nights_stay_rounded, color: Color(0xFFFFF3B0), size: 20);
      case _WeatherSymbol.rain:
        return const Icon(Icons.thunderstorm_rounded, color: Color(0xFFE3F2FD), size: 20);
    }
  }
}

class _HearthieLogo extends StatelessWidget {
  const _HearthieLogo({
    required this.size,
    required this.tint,
  });

  final double size;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        tint.withAlpha(235),
        BlendMode.srcATop,
      ),
      child: Image.asset(
        'public/hearthie/hearthie.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

enum _SkyScene { daySunny, dayRainy, noon, nightClear }

enum _WeatherSymbol { morning, noon, evening, night, rain }

// ── Stats Row ───────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final int total;
  final int expiredCount;
  final int expiringCount;
  final int goodCount;
  final String Function(String) t;

  const _StatsRow({
    required this.total,
    required this.expiredCount,
    required this.expiringCount,
    required this.goodCount,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.inventory_2_rounded,
            value: '$total',
            label: t('dashboard_stats_total'),
            color: cs.primary,
            cs: cs,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.check_circle_rounded,
            value: '$goodCount',
            label: t('dashboard_stats_good'),
            color: Colors.green,
            cs: cs,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: expiredCount > 0
                ? Icons.dangerous_rounded
                : Icons.warning_amber_rounded,
            value: '${expiredCount + expiringCount}',
            label: t('dashboard_stats_attention'),
            color: expiredCount > 0 ? Colors.red : Colors.orange,
            cs: cs,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final ColorScheme cs;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(38)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── Quick Action Grid ───────────────────────────────────────────────────────

class _QuickActionGrid extends StatelessWidget {
  final AppProvider provider;
  final bool isDemoMode;
  const _QuickActionGrid({required this.provider, required this.isDemoMode});

  @override
  Widget build(BuildContext context) {
    final t = provider.t;
    final cs = Theme.of(context).colorScheme;
    final calendarLabel =
        provider.language == 'VIE' ? 'Lịch thực đơn' : 'Meal Calendar';

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            SizedBox(
              width: itemWidth,
              child: _QuickActionButton(
                icon: Icons.add_circle_outline_rounded,
                label: t('dashboard_quick_add'),
                color: cs.primary,
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (_) => const AddFoodModal(),
                  );
                },
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _QuickActionButton(
                icon: Icons.qr_code_scanner_rounded,
                label: t('food_barcode'),
                color: cs.secondary,
                onTap: () async {
                  final scanned =
                      await Navigator.of(context, rootNavigator: true)
                          .push<String>(
                    MaterialPageRoute(
                      fullscreenDialog: true,
                      builder: (_) => BarcodeScannerScreen(t: t),
                    ),
                  );
                  if (!context.mounted) return;
                  if (scanned == null || scanned.isEmpty) return;
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (_) => AddFoodModal(initialScannedName: scanned),
                  );
                },
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _QuickActionButton(
                icon: Icons.restaurant_menu_rounded,
                label: t('dashboard_ai_suggestion'),
                color: cs.primary,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RecipesScreen()),
                  );
                },
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _QuickActionButton(
                icon: Icons.calendar_month_outlined,
                label: calendarLabel,
                color: cs.secondary,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MealCalendarPlannerScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            color: color.withAlpha(10),
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: color.withAlpha(64),
              width: 1.2,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── AI Chat Preview Card ────────────────────────────────────────────────────

class _AiChatPreviewCard extends StatelessWidget {
  final AppProvider provider;
  const _AiChatPreviewCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final t = provider.t;
    final cs = Theme.of(context).colorScheme;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: cs.secondary.withAlpha(51)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AiChatScreen()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.hearthieSky, AppColors.hearthieGold],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _HearthieLogo(
                  size: 24,
                  tint: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('chat_title'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t('chat_subtitle'),
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 16, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Alerts Card ─────────────────────────────────────────────────────────────

class _AlertsCard extends StatelessWidget {
  final List<FoodItem> expired;
  final List<FoodItem> expiringSoon;
  final String Function(String) t;
  final String language;

  const _AlertsCard({
    required this.expired,
    required this.expiringSoon,
    required this.t,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ...expired.map((item) => _AlertRow(
                item: item,
                isExpired: true,
                t: t,
                language: language,
              )),
          if (expired.isNotEmpty && expiringSoon.isNotEmpty)
            const Divider(height: 1, indent: 16, endIndent: 16),
          ...expiringSoon.take(3).map((item) => _AlertRow(
                item: item,
                isExpired: false,
                t: t,
                language: language,
              )),
        ],
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  final FoodItem item;
  final bool isExpired;
  final String Function(String) t;
  final String language;

  const _AlertRow({
    required this.item,
    required this.isExpired,
    required this.t,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = isExpired
        ? cs.error
        : (cs.brightness == Brightness.dark
            ? const Color(0xFFFFC46B)
            : const Color(0xFFB76A00));
    final bg = isExpired
        ? cs.errorContainer.withAlpha(120)
        : (cs.brightness == Brightness.dark
            ? const Color(0xFF4A3200).withAlpha(120)
            : const Color(0xFFFFF1D8));
    final info = AppCategories.forCategory(item.category);
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(info.icon, color: color, size: 20),
      ),
      title:
          Text(item.name, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(
        DateHelper.relativeLabel(item.daysUntilExpiry, language),
        style: TextStyle(color: color, fontSize: 12),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          isExpired
              ? t('inventory_expired_badge')
              : t('inventory_expiring_badge'),
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _RealtimeRecipeSuggestionsCard extends StatelessWidget {
  const _RealtimeRecipeSuggestionsCard({required this.provider});

  final AppProvider provider;

  @override
  Widget build(BuildContext context) {
    final suggestions = _buildSuggestions(provider);
    if (suggestions.isEmpty) {
      return _EmptyCard(message: provider.t('dashboard_recipe_suggest_empty'));
    }

    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
        child: Column(
          children: [
            ...suggestions.map(
              (s) => ListTile(
                dense: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AiChatScreen(initialPrompt: s.prompt),
                    ),
                  );
                },
                leading: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(s.icon, size: 18, color: cs.onPrimaryContainer),
                ),
                title: Text(
                  s.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(s.subtitle),
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RecipesScreen()),
                      );
                    },
                    icon: const Icon(Icons.restaurant_menu_rounded, size: 18),
                    label: Text(provider.t('dashboard_recipe_open_recipes')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AiChatScreen()),
                      );
                    },
                    icon: _HearthieLogo(
                      size: 18,
                      tint: cs.onSecondaryContainer,
                    ),
                    label: Text(provider.t('dashboard_recipe_open_ai')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<_RecipeSuggestion> _buildSuggestions(AppProvider provider) {
    final inventory = provider.inventory;
    final lang = provider.language;
    final expiring = provider.expiringSoonItems;
    final hour = DateTime.now().hour;
    final isVn = lang == 'VIE';

    final list = <_RecipeSuggestion>[];

    if (expiring.isNotEmpty) {
      final item = expiring.first;
      list.add(
        _RecipeSuggestion(
          icon: Icons.schedule_rounded,
          title: isVn
              ? 'Ưu tiên hôm nay: ${item.name}'
              : 'Priority today: ${item.name}',
          subtitle: isVn
              ? 'Nên ưu tiên ${item.name} trước để hạn chế lãng phí thực phẩm.'
              : 'Cook with ${item.name} first to reduce waste.',
          prompt: isVn
              ? 'Gợi ý 2 món Việt đơn giản để xử lý ${item.name} trước hôm nay, kèm thời gian nấu ngắn.'
              : 'Suggest 2 quick meals to use ${item.name} first today with short cooking time.',
        ),
      );
    }

    if (hour < 10) {
      list.add(
        _RecipeSuggestion(
          icon: Icons.wb_sunny_outlined,
          title: isVn ? 'Gợi ý bữa sáng nhanh, dễ làm' : 'Light breakfast idea',
          subtitle: isVn
              ? 'Ưu tiên món 10-15 phút từ nguyên liệu đang có trong kho.'
              : 'Prioritize quick 10-15 minute meals from your inventory.',
          prompt: isVn
              ? 'Gợi ý thực đơn bữa sáng nhanh 10-15 phút từ các nguyên liệu hiện có trong kho.'
              : 'Suggest a quick 10-15 minute breakfast plan from my current inventory.',
        ),
      );
    } else if (hour < 16) {
      list.add(
        _RecipeSuggestion(
          icon: Icons.lunch_dining_outlined,
          title: isVn
              ? 'Gợi ý bữa trưa cân bằng dinh dưỡng'
              : 'Balanced lunch idea',
          subtitle: isVn
              ? 'Kết hợp đạm và rau để đủ năng lượng cho cả buổi chiều.'
              : 'Combine protein + vegetables for steady afternoon energy.',
          prompt: isVn
              ? 'Gợi ý bữa trưa cân bằng dinh dưỡng từ nguyên liệu trong kho, ưu tiên món Việt dễ nấu.'
              : 'Suggest a balanced lunch from my inventory with easy-to-cook meals.',
        ),
      );
    } else {
      list.add(
        _RecipeSuggestion(
          icon: Icons.dinner_dining_outlined,
          title: isVn
              ? 'Gợi ý bữa tối gọn nhẹ sau giờ làm'
              : 'Time-saving dinner idea',
          subtitle: isVn
              ? 'Ưu tiên món một chảo hoặc một nồi để nấu và dọn nhanh.'
              : 'Try one-pan or one-pot dishes for faster cleanup.',
          prompt: isVn
              ? 'Gợi ý bữa tối gọn nhẹ kiểu một chảo hoặc một nồi từ nguyên liệu hiện có.'
              : 'Suggest a quick one-pan or one-pot dinner from my current ingredients.',
        ),
      );
    }

    if (inventory.length >= 3) {
      list.add(
        _RecipeSuggestion(
          icon: Icons.auto_awesome_rounded,
          title: isVn
              ? 'Menu tức thì từ kho hiện tại'
              : 'Instant menu from current inventory',
          subtitle: isVn
              ? 'AI có thể dựng thực đơn theo đúng nguyên liệu bạn đang có ngay lúc này.'
              : 'AI can build a menu directly from what you have now.',
          prompt: isVn
              ? 'Lập thực đơn 1 ngày (sáng-trưa-tối) theo nguyên liệu hiện có trong kho của tôi.'
              : 'Build a 1-day meal plan (breakfast-lunch-dinner) from my current inventory.',
        ),
      );
    }

    return list.take(3).toList(growable: false);
  }
}

class _RecipeSuggestion {
  const _RecipeSuggestion({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.prompt,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String prompt;
}

// ── Recent Items List ───────────────────────────────────────────────────────

class _RecentItemsList extends StatelessWidget {
  final List<FoodItem> items;
  final String Function(String) t;
  final String language;

  const _RecentItemsList({
    required this.items,
    required this.t,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: items.map((item) {
        final info = AppCategories.forCategory(item.category);
        final daysLeft = item.daysUntilExpiry;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: info.color.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(info.icon, color: info.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text('${item.quantity} ${item.unit}',
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
                if (daysLeft != null)
                  _ExpiryBadge(
                    daysLeft: daysLeft,
                    isExpired: item.isExpired,
                    isExpiringSoon: item.isExpiringSoon,
                    language: language,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ExpiryBadge extends StatelessWidget {
  final int daysLeft;
  final bool isExpired;
  final bool isExpiringSoon;
  final String language;

  const _ExpiryBadge({
    required this.daysLeft,
    required this.isExpired,
    required this.isExpiringSoon,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = isExpired
        ? cs.error
        : (isExpiringSoon
            ? (cs.brightness == Brightness.dark
                ? const Color(0xFFFFC46B)
                : const Color(0xFFB76A00))
            : const Color(0xFF2E7D32));
    final bg = isExpired
        ? cs.errorContainer.withAlpha(120)
        : (isExpiringSoon
            ? (cs.brightness == Brightness.dark
                ? const Color(0xFF4A3200).withAlpha(110)
                : const Color(0xFFFFF1D8))
            : const Color(0xFFE6F4EA));
    final icon = isExpired
        ? Icons.dangerous_rounded
        : (isExpiringSoon
            ? Icons.warning_amber_rounded
            : Icons.check_circle_outline_rounded);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            DateHelper.relativeLabel(daysLeft, language),
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

// ── Tip Card ────────────────────────────────────────────────────────────────

class _TipCard extends StatelessWidget {
  final String Function(String) t;
  const _TipCard({required this.t});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.secondaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.onSecondaryContainer.withAlpha(20),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.lightbulb_rounded,
                  color: cs.onSecondaryContainer, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t('dashboard_tip'),
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: cs.onSecondaryContainer)),
                  const SizedBox(height: 4),
                  Text(t('dashboard_tip_text'),
                      style: TextStyle(
                          color: cs.onSecondaryContainer, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section Header ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

// ── Empty Card ──────────────────────────────────────────────────────────────

class _EmptyCard extends StatelessWidget {
  final String message;
  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 40, color: cs.onSurfaceVariant.withAlpha(77)),
            const SizedBox(height: 12),
            Text(message,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
