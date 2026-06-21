import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/daily_meal_plan.dart';
import '../models/recipe.dart';
import '../providers/app_provider.dart';
import '../services/recipe_search_service.dart';
import '../theme/app_theme.dart';
import '../utils/recipe_cook_dialog.dart';

class MealCalendarPlannerScreen extends StatefulWidget {
  const MealCalendarPlannerScreen({super.key});

  @override
  State<MealCalendarPlannerScreen> createState() =>
      _MealCalendarPlannerScreenState();
}

class _MealCalendarPlannerScreenState extends State<MealCalendarPlannerScreen> {
  late DateTime _selectedDate;
  late DateTime _focusedMonth;
  bool _shoppingWeekly = false;
  bool _deductInventory = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _focusedMonth = DateTime(now.year, now.month, 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AppProvider>().loadCustomRecipes(silent: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final t = provider.t;
    final cs = Theme.of(context).colorScheme;
    final plansByDate = provider.dailyPlansByDate;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _title(provider.language),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: _shoppingTooltip(provider.language),
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () {
              _openShoppingSheet(context);
            },
          ),
          IconButton(
            tooltip: _todayLabel(provider.language),
            icon: const Icon(Icons.today_rounded),
            onPressed: () {
              final now = DateTime.now();
              setState(() {
                _selectedDate = DateTime(now.year, now.month, now.day);
                _focusedMonth = DateTime(now.year, now.month, 1);
              });
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddMealSheet(context, provider),
        icon: const Icon(Icons.add_rounded),
        label: Text(_addMealCta(provider.language)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: _CalendarCard(
              focusedMonth: _focusedMonth,
              selectedDate: _selectedDate,
              plansByDate: plansByDate,
              language: provider.language,
              onPrevMonth: () => setState(() {
                _focusedMonth =
                    DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
              }),
              onNextMonth: () => setState(() {
                _focusedMonth =
                    DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
              }),
              onSelectDate: (d) => setState(() {
                _selectedDate = DateTime(d.year, d.month, d.day);
                _focusedMonth = DateTime(d.year, d.month, 1);
              }),
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withAlpha(58),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(22),
                ),
              ),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 120),
                children: [
                  Text(
                    _dateHeadline(_selectedDate, provider.language),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _agendaSubtitle(provider.language),
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _AgendaTimeline(
                    plans: provider.dailyPlansForDate(_selectedDate),
                    language: provider.language,
                    provider: provider,
                    onRemove: (id) => provider.removeDailyMealPlan(id),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(
                        value: false,
                        label: Text(provider.language == 'VIE' ? 'Ngày' : 'Day'),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text(provider.language == 'VIE' ? 'Tuần' : 'Week'),
                      ),
                    ],
                    selected: {_shoppingWeekly},
                    onSelectionChanged: (s) {
                      setState(() {
                        _shoppingWeekly = s.first;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: () async {
                      await provider.generateShoppingFromDailyMealPlans(
                        anchorDate: _selectedDate,
                        weekly: _shoppingWeekly,
                        deductInventory: _deductInventory,
                      );
                      if (!context.mounted) return;
                      await _openShoppingSheet(context);
                    },
                    icon: const Icon(Icons.shopping_cart_checkout_rounded),
                    label: Text(
                      provider.language == 'VIE'
                          ? (_shoppingWeekly
                              ? 'Tạo danh sách mua cho 1 tuần'
                              : 'Tạo danh sách mua cho ngày này')
                          : (_shoppingWeekly
                              ? 'Create 7-day shopping list'
                              : 'Create 1-day shopping list'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _openShoppingSheet(context),
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: Text(
                      provider.language == 'VIE'
                          ? 'Mở lại list mua nguyên liệu'
                          : 'Open current ingredient list',
                    ),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () =>
                        provider.clearDailyPlansForDate(_selectedDate),
                    icon: const Icon(Icons.delete_sweep_rounded),
                    label: Text(_clearDayLabel(provider.language)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAddMealSheet(
    BuildContext context,
    AppProvider provider,
  ) async {
    await provider.loadCustomRecipes(silent: true);
    if (!context.mounted) return;
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _AddMealSheet(
        selectedDate: _selectedDate,
        provider: provider,
      ),
    );
    if (added != true || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          provider.language == 'VIE'
              ? 'Đã thêm vào lịch. Bạn có thể tạo danh sách mua nguyên liệu ngay.'
              : 'Added to calendar. You can create an ingredient list now.',
        ),
        action: SnackBarAction(
          label: provider.language == 'VIE' ? 'Mở list' : 'Open list',
          onPressed: () => _openShoppingSheet(context),
        ),
      ),
    );
  }

  Future<void> _openShoppingSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ShoppingFromCalendarSheet(
        anchorDate: _selectedDate,
        initialWeekly: _shoppingWeekly,
        initialDeductInventory: _deductInventory,
        onWeeklyChanged: (v) => _shoppingWeekly = v,
        onDeductInventoryChanged: (v) => _deductInventory = v,
      ),
    );
  }

  String _title(String lang) =>
      lang == 'VIE' ? 'Lịch Thực Đơn' : 'Meal Calendar';
  String _todayLabel(String lang) => lang == 'VIE' ? 'Hôm nay' : 'Today';
  String _shoppingTooltip(String lang) =>
      lang == 'VIE' ? 'Danh sách mua sắm' : 'Shopping list';
  String _addMealCta(String lang) =>
      lang == 'VIE' ? 'Thêm bữa ăn' : 'Add meal';
  String _agendaSubtitle(String lang) => lang == 'VIE'
      ? 'Hiển thị theo timeline giống lịch Google trong ngày đã chọn.'
      : 'Timeline view similar to Google Calendar for the selected day.';
  String _clearDayLabel(String lang) => lang == 'VIE'
      ? 'Xóa thực đơn của ngày này'
      : 'Clear this day menu';

  String _dateHeadline(DateTime date, String lang) {
    final weekday = [
      '',
      lang == 'VIE' ? 'Thứ Hai' : 'Monday',
      lang == 'VIE' ? 'Thứ Ba' : 'Tuesday',
      lang == 'VIE' ? 'Thứ Tư' : 'Wednesday',
      lang == 'VIE' ? 'Thứ Năm' : 'Thursday',
      lang == 'VIE' ? 'Thứ Sáu' : 'Friday',
      lang == 'VIE' ? 'Thứ Bảy' : 'Saturday',
      lang == 'VIE' ? 'Chủ Nhật' : 'Sunday',
    ][date.weekday];
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    return '$weekday, $dd/$mm/${date.year}';
  }
}

class _ShoppingFromCalendarSheet extends StatefulWidget {
  const _ShoppingFromCalendarSheet({
    required this.anchorDate,
    required this.initialWeekly,
    required this.initialDeductInventory,
    required this.onWeeklyChanged,
    required this.onDeductInventoryChanged,
  });

  final DateTime anchorDate;
  final bool initialWeekly;
  final bool initialDeductInventory;
  final ValueChanged<bool> onWeeklyChanged;
  final ValueChanged<bool> onDeductInventoryChanged;

  @override
  State<_ShoppingFromCalendarSheet> createState() =>
      _ShoppingFromCalendarSheetState();
}

class _ShoppingFromCalendarSheetState
    extends State<_ShoppingFromCalendarSheet> {
  late bool _weekly;
  late bool _deductInventory;
  bool _generating = false;
  bool _addingToInventory = false;
  bool _autoAddPurchased = true;
  bool _useHearthieClassification = true;

  @override
  void initState() {
    super.initState();
    _weekly = widget.initialWeekly;
    _deductInventory = widget.initialDeductInventory;
  }

  Future<void> _buildList(AppProvider provider) async {
    setState(() => _generating = true);
    await provider.generateShoppingFromDailyMealPlans(
      anchorDate: widget.anchorDate,
      weekly: _weekly,
      deductInventory: _deductInventory,
    );
    if (!mounted) return;
    setState(() => _generating = false);
  }

  Future<void> _markAllPurchased(AppProvider provider) async {
    for (final item in provider.shoppingPlanItems) {
      await provider.setShoppingPurchased(item.id, true);
    }
    if (_autoAddPurchased) {
      await _movePurchasedToInventory(provider);
    }
  }

  Future<void> _movePurchasedToInventory(AppProvider provider) async {
    if (_addingToInventory) return;
    setState(() => _addingToInventory = true);
    final result = await provider.addPurchasedItemsToInventory(
      useHearthieClassification: _useHearthieClassification,
    );
    if (!mounted) return;
    setState(() => _addingToInventory = false);
    final lang = provider.language;
    if (result.addedCount <= 0) return;
    final msg = lang == 'VIE'
        ? 'Đã nhập ${result.addedCount} món vào kho. '
            'Hearthie: ${result.aiClassifiedCount}, '
            'Phân loại phụ: ${result.fallbackClassifiedCount}.'
        : 'Added ${result.addedCount} items to inventory. '
            'Hearthie: ${result.aiClassifiedCount}, '
            'Fallback: ${result.fallbackClassifiedCount}.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _togglePurchased(
    AppProvider provider,
    String id,
    bool purchased,
  ) async {
    await provider.setShoppingPurchased(id, purchased);
    if (!_autoAddPurchased || !purchased) return;
    await _movePurchasedToInventory(provider);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final lang = provider.language;
        final cs = Theme.of(context).colorScheme;
        final items = provider.shoppingPlanItems;
        final purchasedCount = items.where((e) => e.isPurchased).length;
        final savedAt = provider.shoppingPlanSavedAt;
        final d = widget.anchorDate;
        final dd = d.day.toString().padLeft(2, '0');
        final mm = d.month.toString().padLeft(2, '0');
        final dateLabel = '$dd/$mm/${d.year}';

        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                lang == 'VIE' ? 'Danh sách mua sắm' : 'Shopping list',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                lang == 'VIE'
                    ? 'Được tạo từ thực đơn ngày $dateLabel'
                    : 'Built from menu on $dateLabel',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
              ),
              const SizedBox(height: 10),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(
                    value: false,
                    label: Text(lang == 'VIE' ? 'Ngày' : 'Day'),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text(lang == 'VIE' ? 'Tuần' : 'Week'),
                  ),
                ],
                selected: {_weekly},
                onSelectionChanged: (s) {
                  final next = s.first;
                  setState(() => _weekly = next);
                  widget.onWeeklyChanged(next);
                },
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: _generating ? null : () => _buildList(provider),
                icon: _generating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome_rounded),
                label: Text(
                  lang == 'VIE'
                      ? (_weekly
                          ? 'Tạo danh sách mua cho 1 tuần'
                          : 'Tạo danh sách mua cho ngày này')
                      : (_weekly
                          ? 'Build 7-day shopping list'
                          : 'Build shopping list for this day'),
                ),
              ),
              if (savedAt != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${lang == 'VIE' ? 'Cập nhật' : 'Updated'}: ${savedAt.toLocal()}',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      lang == 'VIE'
                          ? 'Đã mua: $purchasedCount/${items.length}'
                          : 'Purchased: $purchasedCount/${items.length}',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ),
                  TextButton(
                    onPressed: items.isEmpty
                        ? null
                        : () => _markAllPurchased(provider),
                    child: Text(lang == 'VIE' ? 'Đánh dấu hết' : 'Mark all'),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              SwitchListTile(
                value: _autoAddPurchased,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  lang == 'VIE'
                      ? 'Tự động nhập kho khi đánh dấu đã mua'
                      : 'Auto add to inventory when purchased',
                ),
                onChanged: (v) => setState(() => _autoAddPurchased = v),
              ),
              SwitchListTile(
                value: _useHearthieClassification,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  lang == 'VIE'
                      ? 'Dùng Hearthie để phân loại danh mục'
                      : 'Use Hearthie to classify category',
                ),
                subtitle: Text(
                  lang == 'VIE'
                      ? 'Tắt đi sẽ dùng phân loại mặc định trong app.'
                      : 'If off, app uses built-in fallback rules.',
                ),
                onChanged: (v) =>
                    setState(() => _useHearthieClassification = v),
              ),
              SwitchListTile(
                value: _deductInventory,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  lang == 'VIE'
                      ? 'Trừ nguyên liệu sẵn có trong tủ'
                      : 'Deduct ingredients available in inventory',
                ),
                subtitle: Text(
                  lang == 'VIE'
                      ? 'Chỉ mua những nguyên liệu còn thiếu.'
                      : 'Only buy missing ingredients.',
                ),
                onChanged: (v) {
                  setState(() => _deductInventory = v);
                  widget.onDeductInventoryChanged(v);
                },
              ),
              Flexible(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(color: cs.outlineVariant.withAlpha(110)),
                  ),
                  child: items.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Text(
                              lang == 'VIE'
                                  ? 'Chưa có danh sách. Hãy tạo từ thực đơn.'
                                  : 'No list yet. Build from meal plan.',
                              style: TextStyle(color: cs.onSurfaceVariant),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: items.length,
                          itemBuilder: (_, i) {
                            final e = items[i];
                            return ListTile(
                              leading: Checkbox(
                                value: e.isPurchased,
                                onChanged: (v) => _togglePurchased(
                                    provider, e.id, v ?? false),
                              ),
                              title: Text(
                                e.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700),
                              ),
                              subtitle: e.planMealRefs.isEmpty
                                  ? null
                                  : Text(
                                      e.planMealRefs.take(2).join(' • '),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () =>
                                        provider.setShoppingConfirmedQty(
                                      e.id,
                                      (e.confirmedQty - 0.5)
                                          .clamp(0, 9999)
                                          .toDouble(),
                                    ),
                                    icon: const Icon(
                                        Icons.remove_circle_outline_rounded),
                                  ),
                                  Text('${e.confirmedQty} ${e.unit}'),
                                  IconButton(
                                    onPressed: () =>
                                        provider.setShoppingConfirmedQty(
                                      e.id,
                                      e.confirmedQty + 0.5,
                                    ),
                                    icon: const Icon(
                                        Icons.add_circle_outline_rounded),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          items.isEmpty ? null : provider.clearShoppingPlan,
                      icon: const Icon(Icons.delete_outline_rounded),
                      label:
                          Text(lang == 'VIE' ? 'Xóa danh sách' : 'Clear list'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: (purchasedCount == 0 || _addingToInventory)
                          ? null
                          : () => _movePurchasedToInventory(provider),
                      icon: _addingToInventory
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.inventory_2_outlined),
                      label: Text(
                        lang == 'VIE' ? 'Nhập vào kho' : 'Add to inventory',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({
    required this.focusedMonth,
    required this.selectedDate,
    required this.plansByDate,
    required this.language,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.onSelectDate,
  });

  final DateTime focusedMonth;
  final DateTime selectedDate;
  final Map<String, List<DailyMealPlan>> plansByDate;
  final String language;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final monthTitle = _monthLabel(focusedMonth, language);
    final days = _daysForMonthGrid(focusedMonth);
    final today = DateTime.now();
    final todayKey = mealDateKey(today);
    final selectedKey = mealDateKey(selectedDate);

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withAlpha(110)),
      ),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onPrevMonth,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Text(
                  monthTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              IconButton(
                onPressed: onNextMonth,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: _weekLabels(language)
                .map(
                  (label) => Expanded(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 6),
          GridView.builder(
            itemCount: days.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.76,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemBuilder: (_, i) {
              final day = days[i];
              final key = mealDateKey(day);
              final dayPlans = plansByDate[key] ?? const <DailyMealPlan>[];
              final inCurrentMonth = day.month == focusedMonth.month;
              final isSelected = key == selectedKey;
              final isToday = key == todayKey;

              return InkWell(
                onTap: () => onSelectDate(day),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? cs.primary.withAlpha(22)
                        : cs.surfaceContainerHighest.withAlpha(46),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? cs.primary
                          : isToday
                              ? cs.secondary
                              : cs.outlineVariant.withAlpha(90),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: inCurrentMonth
                                ? cs.onSurface
                                : cs.onSurfaceVariant.withAlpha(140),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      ...dayPlans.take(3).map(
                            (e) => Container(
                              margin: const EdgeInsets.only(bottom: 2),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: _slotColor(e.mealSlot).withAlpha(34),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                _slotShort(e.mealSlot, language),
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: _slotColor(e.mealSlot),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  static List<DateTime> _daysForMonthGrid(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final leadingDays = first.weekday - DateTime.monday;
    final gridStart = first.subtract(Duration(days: leadingDays));
    return List.generate(
      42,
      (i) => DateTime(
        gridStart.year,
        gridStart.month,
        gridStart.day + i,
      ),
    );
  }

  static List<String> _weekLabels(String lang) {
    if (lang == 'VIE') return const ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  }

  static String _monthLabel(DateTime date, String lang) {
    const en = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    const vi = [
      '',
      'Tháng 1',
      'Tháng 2',
      'Tháng 3',
      'Tháng 4',
      'Tháng 5',
      'Tháng 6',
      'Tháng 7',
      'Tháng 8',
      'Tháng 9',
      'Tháng 10',
      'Tháng 11',
      'Tháng 12'
    ];
    final label = lang == 'VIE' ? vi[date.month] : en[date.month];
    return '$label ${date.year}';
  }
}

class _AgendaTimeline extends StatelessWidget {
  const _AgendaTimeline({
    required this.plans,
    required this.language,
    required this.provider,
    required this.onRemove,
  });

  final List<DailyMealPlan> plans;
  final String language;
  final AppProvider provider;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (plans.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant.withAlpha(110)),
        ),
        child: Text(
          language == 'VIE'
              ? 'Chưa có thực đơn cho ngày này. Chạm "Thêm bữa ăn" để bắt đầu.'
              : 'No meals for this day yet. Tap "Add meal" to start.',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
      );
    }

    return Column(
      children: plans
          .map(
            (e) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _slotColor(e.mealSlot).withAlpha(140),
                ),
              ),
              child: ListTile(
                leading: Container(
                  width: 8,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: _slotColor(e.mealSlot),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                title: Text(
                  e.recipeName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${_slotLabel(e.mealSlot, language)} • ${_slotTime(e.mealSlot)} • ${e.sourceName}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (e.sourceName == 'Custom' && e.recipeId.isNotEmpty)
                      IconButton(
                        tooltip: provider.t('recipes_custom_cook'),
                        icon: const Icon(Icons.restaurant_rounded),
                        onPressed: () {
                          final recipe = provider.findRecipeById(e.recipeId);
                          if (recipe == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  language == 'VIE'
                                      ? 'Không tìm thấy công thức. Hãy mở tab Công thức → Của tôi để tải lại.'
                                      : 'Recipe not found. Open Recipes → My recipes to refresh.',
                                ),
                              ),
                            );
                            return;
                          }
                          showCookRecipeDialog(context, provider, recipe);
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () => onRemove(e.id),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _AddMealSheet extends StatefulWidget {
  const _AddMealSheet({
    required this.selectedDate,
    required this.provider,
  });

  final DateTime selectedDate;
  final AppProvider provider;

  @override
  State<_AddMealSheet> createState() => _AddMealSheetState();
}

class _AddMealSheetState extends State<_AddMealSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  final List<Recipe> _remote = [];
  bool _loadingRemote = false;
  String _slot = 'breakfast';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Recipe> get _customCandidates => widget.provider.customRecipes;

  List<Recipe> get _otherLocalCandidates {
    final map = <String, Recipe>{};
    for (final r in [
      ...widget.provider.savedRecipes,
      ...widget.provider.recipeCache,
    ]) {
      map.putIfAbsent(r.id, () => r);
    }
    return map.values.toList(growable: false);
  }

  List<Recipe> get _localCandidates {
    final map = <String, Recipe>{};
    for (final r in [..._customCandidates, ..._otherLocalCandidates]) {
      map.putIfAbsent(r.id, () => r);
    }
    return map.values.toList(growable: false);
  }

  Future<void> _searchRemote() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;
    setState(() => _loadingRemote = true);
    final result = await Future.wait<List<Recipe>>([
      RecipeSearchService.instance
          .searchMealDB(q)
          .catchError((_) => <Recipe>[]),
      RecipeSearchService.instance
          .searchDummyJson(q)
          .catchError((_) => <Recipe>[]),
    ]);
    if (!mounted) return;
    final map = <String, Recipe>{};
    for (final r in [...result[0], ...result[1]]) {
      map.putIfAbsent('${r.sourceName}_${r.name.toLowerCase()}', () => r);
    }
    _remote
      ..clear()
      ..addAll(map.values.take(20));
    setState(() => _loadingRemote = false);
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.provider.language;
    final cs = Theme.of(context).colorScheme;
    final q = _searchCtrl.text.trim().toLowerCase();

    final localFiltered = _localCandidates
        .where((e) => q.isEmpty || e.name.toLowerCase().contains(q))
        .toList(growable: false);
    final customFiltered = _customCandidates
        .where((e) => q.isEmpty || e.name.toLowerCase().contains(q))
        .toList(growable: false);
    final otherFiltered = _otherLocalCandidates
        .where((e) => q.isEmpty || e.name.toLowerCase().contains(q))
        .toList(growable: false);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            lang == 'VIE' ? 'Thêm vào thực đơn' : 'Add to daily menu',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: ['breakfast', 'lunch', 'dinner']
                .map(
                  (s) => ChoiceChip(
                    label: Text(_slotLabel(s, lang)),
                    selected: _slot == s,
                    onSelected: (_) => setState(() => _slot = s),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: lang == 'VIE'
                        ? 'Tìm món ăn...'
                        : 'Search recipes...',
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _searchRemote(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: _loadingRemote ? null : _searchRemote,
                icon: _loadingRemote
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.travel_explore_rounded),
                label: Text(lang == 'VIE' ? 'Web' : 'Web'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Flexible(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(color: cs.outlineVariant.withAlpha(110)),
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  if (customFiltered.isNotEmpty)
                    _SectionTitle(
                      title: widget.provider.t('recipes_custom_meal_section'),
                    ),
                  ...customFiltered.take(12).map(
                        (r) => _RecipePickTile(
                          recipe: r,
                          subtitle: widget.provider.t('recipes_custom'),
                          onTap: () async {
                            await widget.provider.upsertDailyMealPlan(
                              date: widget.selectedDate,
                              mealSlot: _slot,
                              recipe: r,
                            );
                            if (!context.mounted) return;
                            Navigator.pop(context, true);
                          },
                        ),
                      ),
                  if (otherFiltered.isNotEmpty)
                    _SectionTitle(
                      title: lang == 'VIE'
                          ? 'Món có sẵn trong app'
                          : 'Available in app',
                    ),
                  ...otherFiltered.take(12).map(
                        (r) => _RecipePickTile(
                          recipe: r,
                          onTap: () async {
                            await widget.provider.upsertDailyMealPlan(
                              date: widget.selectedDate,
                              mealSlot: _slot,
                              recipe: r,
                            );
                            if (!context.mounted) return;
                            Navigator.pop(context, true);
                          },
                        ),
                      ),
                  if (_remote.isNotEmpty)
                    _SectionTitle(
                      title: lang == 'VIE'
                          ? 'Kết quả từ internet'
                          : 'Internet results',
                    ),
                  ..._remote.map(
                    (r) => _RecipePickTile(
                      recipe: r,
                      onTap: () async {
                        await widget.provider.upsertDailyMealPlan(
                          date: widget.selectedDate,
                          mealSlot: _slot,
                          recipe: r,
                        );
                        if (!context.mounted) return;
                        Navigator.pop(context, true);
                      },
                    ),
                  ),
                  if (localFiltered.isEmpty &&
                      _remote.isEmpty &&
                      !_loadingRemote)
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(
                        lang == 'VIE'
                            ? 'Chưa có kết quả. Hãy nhập từ khóa để tìm món.'
                            : 'No results yet. Enter a keyword to search.',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _RecipePickTile extends StatelessWidget {
  const _RecipePickTile({
    required this.recipe,
    required this.onTap,
    this.subtitle,
  });

  final Recipe recipe;
  final VoidCallback onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(
        recipe.isCustom ? Icons.edit_note_rounded : Icons.restaurant_menu_rounded,
      ),
      title: Text(
        recipe.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        subtitle ?? recipe.sourceName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: onTap,
    );
  }
}

Color _slotColor(String slot) {
  switch (slot) {
    case 'breakfast':
      return const Color(0xFFE67E22);
    case 'lunch':
      return const Color(0xFF2E86DE);
    case 'dinner':
      return const Color(0xFF8E44AD);
    default:
      return const Color(0xFF16A085);
  }
}

String _slotLabel(String slot, String lang) {
  if (lang == 'VIE') {
    switch (slot) {
      case 'breakfast':
        return 'Bữa sáng';
      case 'lunch':
        return 'Bữa trưa';
      case 'dinner':
        return 'Bữa tối';
      default:
        return 'Bữa ăn';
    }
  }
  switch (slot) {
    case 'breakfast':
      return 'Breakfast';
    case 'lunch':
      return 'Lunch';
    case 'dinner':
      return 'Dinner';
    default:
      return 'Meal';
  }
}

String _slotShort(String slot, String lang) {
  if (lang == 'VIE') {
    switch (slot) {
      case 'breakfast':
        return 'Sáng';
      case 'lunch':
        return 'Trưa';
      case 'dinner':
        return 'Tối';
      default:
        return 'Bữa';
    }
  }
  switch (slot) {
    case 'breakfast':
      return 'AM';
    case 'lunch':
      return 'Noon';
    case 'dinner':
      return 'PM';
    default:
      return 'Meal';
  }
}

String _slotTime(String slot) {
  switch (slot) {
    case 'breakfast':
      return '08:00';
    case 'lunch':
      return '12:30';
    case 'dinner':
      return '18:30';
    default:
      return '--:--';
  }
}
