import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/food_item.dart';
import '../models/recipe.dart';
import '../providers/app_provider.dart';
import '../utils/recipe_cook_dialog.dart';

enum _IngredientStockStatus { ready, low, unlinked, missing }

class _IngredientStockInfo {
  const _IngredientStockInfo({
    required this.status,
    this.foodItem,
  });

  final _IngredientStockStatus status;
  final FoodItem? foodItem;
}

_IngredientStockInfo _stockInfo(List<FoodItem> inventory, RecipeIngredient ing) {
  if (ing.foodItemId.isEmpty) {
    return const _IngredientStockInfo(status: _IngredientStockStatus.unlinked);
  }
  for (final item in inventory) {
    if (item.id == ing.foodItemId) {
      if (item.quantity >= ing.quantityNeeded) {
        return _IngredientStockInfo(
          status: _IngredientStockStatus.ready,
          foodItem: item,
        );
      }
      return _IngredientStockInfo(
        status: _IngredientStockStatus.low,
        foodItem: item,
      );
    }
  }
  return const _IngredientStockInfo(status: _IngredientStockStatus.missing);
}

(int ready, int total) _recipeStockSummary(
  List<FoodItem> inventory,
  List<RecipeIngredient> ingredients,
) {
  if (ingredients.isEmpty) return (0, 0);
  var ready = 0;
  for (final ing in ingredients) {
    final info = _stockInfo(inventory, ing);
    if (info.status == _IngredientStockStatus.ready) ready++;
  }
  return (ready, ingredients.length);
}

String _difficultyLabel(AppProvider provider, RecipeDifficulty d) {
  switch (d) {
    case RecipeDifficulty.easy:
      return provider.t('recipes_difficulty_easy');
    case RecipeDifficulty.medium:
      return provider.t('recipes_difficulty_medium');
    case RecipeDifficulty.hard:
      return provider.t('recipes_difficulty_hard');
  }
}

class CustomRecipesTab extends StatelessWidget {
  const CustomRecipesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        if (provider.isCustomRecipesLoading && provider.customRecipes.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return _CustomRecipesBody(provider: provider);
      },
    );
  }
}

class _CustomRecipesBody extends StatefulWidget {
  const _CustomRecipesBody({required this.provider});

  final AppProvider provider;

  @override
  State<_CustomRecipesBody> createState() => _CustomRecipesBodyState();
}

class _CustomRecipesBodyState extends State<_CustomRecipesBody> {
  AppProvider get provider => widget.provider;

  String t(String key) => provider.t(key);

  Future<void> _refresh() => provider.loadCustomRecipes();

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  void _showForm({Recipe? recipe}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _CustomRecipeForm(
        provider: provider,
        existing: recipe,
        onSaved: (created) {
          _showSnack(
            created ? t('recipes_custom_saved') : t('recipes_custom_updated'),
          );
        },
        onFailed: () => _showSnack(t('recipes_custom_save_failed'), isError: true),
      ),
    );
  }

  Future<void> _confirmDelete(Recipe recipe) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t('recipes_custom_delete_title')),
        content: Text(
          t('recipes_custom_delete_body').replaceAll('{name}', recipe.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t('common_cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t('common_delete')),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final ok = await provider.deleteCustomRecipe(recipe.id);
    if (!mounted) return;
    _showSnack(
      ok ? t('recipes_custom_deleted') : t('recipes_custom_delete_failed'),
      isError: !ok,
    );
  }

  void _showDetailSheet(Recipe recipe) {
    final cs = Theme.of(context).colorScheme;
    final inventory = provider.inventory;
    final (ready, total) =
        _recipeStockSummary(inventory, recipe.customIngredients);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize: 0.5,
        maxChildSize: 1.0,
        expand: false,
        builder: (_, ctrl) => ListView(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            _sheetHandle(cs),
            const SizedBox(height: 16),
            Text(
              recipe.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            if (recipe.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(recipe.description, style: TextStyle(color: cs.onSurfaceVariant)),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('${recipe.totalTime} ${t('recipes_mins')}')),
                Chip(label: Text('${recipe.servings} ${t('recipes_people')}')),
                Chip(label: Text('${recipe.calories} ${t('recipes_kcal')}')),
                Chip(label: Text(_difficultyLabel(provider, recipe.difficulty))),
                if (total > 0)
                  Chip(
                    avatar: Icon(
                      ready == total
                          ? Icons.check_circle_rounded
                          : Icons.inventory_2_outlined,
                      size: 16,
                      color: ready == total ? Colors.green : cs.primary,
                    ),
                    label: Text(
                      t('recipes_custom_stock_ready')
                          .replaceAll('{ready}', '$ready')
                          .replaceAll('{total}', '$total'),
                    ),
                  ),
              ],
            ),
            const Divider(height: 28),
            Text(
              t('recipes_ingredients'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (recipe.customIngredients.isEmpty)
              Text(
                recipe.ingredientsNeeded.join('\n'),
                style: TextStyle(color: cs.onSurfaceVariant),
              )
            else
              ...recipe.customIngredients.map(
                (ing) => _IngredientTile(
                  provider: provider,
                  ingredient: ing,
                  inventory: inventory,
                ),
              ),
            const SizedBox(height: 16),
            Text(
              t('recipes_steps'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...recipe.instructions.asMap().entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: cs.primaryContainer,
                          child: Text(
                            '${e.key + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: cs.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(e.value)),
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: 20),
            if (recipe.isCustom && recipe.customIngredients.isNotEmpty)
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  showCookRecipeDialog(context, provider, recipe);
                },
                icon: const Icon(Icons.restaurant_rounded),
                label: Text(provider.t('recipes_custom_cook')),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recipes = provider.customRecipes;
    final cs = Theme.of(context).colorScheme;
    final inventory = provider.inventory;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: recipes.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.sizeOf(context).height * 0.22),
                  Icon(Icons.edit_note_rounded, size: 64, color: cs.outlineVariant),
                  const SizedBox(height: 16),
                  Text(
                    t('recipes_custom_empty'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      t('recipes_custom_empty_sub'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: FilledButton.icon(
                      onPressed: () => _showForm(),
                      icon: const Icon(Icons.add_rounded),
                      label: Text(t('recipes_custom_create')),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: recipes.length,
                itemBuilder: (context, i) {
                  final recipe = recipes[i];
                  final (ready, total) =
                      _recipeStockSummary(inventory, recipe.customIngredients);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _showDetailSheet(recipe),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    recipe.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${recipe.totalTime} ${t('recipes_mins')} • '
                                    '${recipe.servings} ${t('recipes_people')} • '
                                    '${recipe.calories} ${t('recipes_kcal')}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                  if (total > 0) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          ready == total
                                              ? Icons.check_circle_rounded
                                              : Icons.warning_amber_rounded,
                                          size: 14,
                                          color: ready == total
                                              ? Colors.green
                                              : Colors.orange,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          t('recipes_custom_stock_ready')
                                              .replaceAll('{ready}', '$ready')
                                              .replaceAll('{total}', '$total'),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: ready == total
                                                ? Colors.green
                                                : Colors.orange,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: t('recipes_custom_edit'),
                              icon: const Icon(Icons.edit_rounded),
                              onPressed: () => _showForm(recipe: recipe),
                            ),
                            IconButton(
                              tooltip: t('common_delete'),
                              icon: Icon(Icons.delete_rounded, color: cs.error),
                              onPressed: () => _confirmDelete(recipe),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: recipes.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showForm(),
              icon: const Icon(Icons.add_rounded),
              label: Text(t('recipes_custom_create')),
            ),
    );
  }
}

class _IngredientTile extends StatelessWidget {
  const _IngredientTile({
    required this.provider,
    required this.ingredient,
    required this.inventory,
  });

  final AppProvider provider;
  final RecipeIngredient ingredient;
  final List<FoodItem> inventory;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final info = _stockInfo(inventory, ingredient);
    final subtitle = switch (info.status) {
      _IngredientStockStatus.unlinked =>
        '${ingredient.quantityNeeded} ${ingredient.unit} • ${provider.t('recipes_custom_not_in_stock')}',
      _IngredientStockStatus.missing =>
        '${ingredient.quantityNeeded} ${ingredient.unit} • ${provider.t('recipes_custom_not_in_stock')}',
      _IngredientStockStatus.ready || _IngredientStockStatus.low =>
        '${ingredient.quantityNeeded} ${ingredient.unit} • ${provider.t('recipes_custom_stock_line').replaceAll('{qty}', '${info.foodItem!.quantity}').replaceAll('{unit}', info.foodItem!.unit)}',
    };
    final icon = switch (info.status) {
      _IngredientStockStatus.ready => Icons.check_circle_rounded,
      _IngredientStockStatus.low => Icons.remove_circle_outline,
      _IngredientStockStatus.unlinked => Icons.link_off_rounded,
      _IngredientStockStatus.missing => Icons.warning_amber_rounded,
    };
    final color = switch (info.status) {
      _IngredientStockStatus.ready => Colors.green,
      _IngredientStockStatus.low => cs.error,
      _IngredientStockStatus.unlinked => Colors.orange,
      _IngredientStockStatus.missing => Colors.orange,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(ingredient.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        trailing: Icon(icon, color: color),
      ),
    );
  }
}

class _CustomRecipeForm extends StatefulWidget {
  const _CustomRecipeForm({
    required this.provider,
    this.existing,
    required this.onSaved,
    required this.onFailed,
  });

  final AppProvider provider;
  final Recipe? existing;
  final void Function(bool created) onSaved;
  final VoidCallback onFailed;

  @override
  State<_CustomRecipeForm> createState() => _CustomRecipeFormState();
}

class _CustomRecipeFormState extends State<_CustomRecipeForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _prepCtrl;
  late final TextEditingController _cookCtrl;
  late final TextEditingController _servingsCtrl;
  late final TextEditingController _caloriesCtrl;
  late final TextEditingController _instructionsCtrl;
  RecipeDifficulty _difficulty = RecipeDifficulty.easy;
  bool _saving = false;
  List<RecipeIngredient> _selectedIngredients = [];

  String t(String key) => widget.provider.t(key);

  @override
  void initState() {
    super.initState();
    final r = widget.existing;
    _nameCtrl = TextEditingController(text: r?.name ?? '');
    _descCtrl = TextEditingController(text: r?.description ?? '');
    _prepCtrl = TextEditingController(text: (r?.prepTime ?? 0).toString());
    _cookCtrl = TextEditingController(text: (r?.cookTime ?? 0).toString());
    _servingsCtrl = TextEditingController(text: (r?.servings ?? 2).toString());
    _caloriesCtrl = TextEditingController(text: (r?.calories ?? 0).toString());
    _instructionsCtrl =
        TextEditingController(text: r?.instructions.join('\n') ?? '');
    _difficulty = r?.difficulty ?? RecipeDifficulty.easy;
    _selectedIngredients = List.from(r?.customIngredients ?? []);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _prepCtrl.dispose();
    _cookCtrl.dispose();
    _servingsCtrl.dispose();
    _caloriesCtrl.dispose();
    _instructionsCtrl.dispose();
    super.dispose();
  }

  List<String> _parseLines(String raw) =>
      raw.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedIngredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('recipes_custom_ingredients_required'))),
      );
      return;
    }

    setState(() => _saving = true);

    final ingredientLines = _selectedIngredients
        .map((e) => '${e.name} (${e.quantityNeeded} ${e.unit})')
        .toList();

    final recipe = Recipe(
      id: widget.existing?.id ?? const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      difficulty: _difficulty,
      prepTime: int.tryParse(_prepCtrl.text) ?? 0,
      cookTime: int.tryParse(_cookCtrl.text) ?? 0,
      servings: int.tryParse(_servingsCtrl.text) ?? 2,
      calories: int.tryParse(_caloriesCtrl.text) ?? 0,
      ingredientsNeeded: ingredientLines,
      instructions: normalizeRecipeInstructions(_parseLines(_instructionsCtrl.text)),
      sourceName: 'Custom',
      sourceUrl: '',
      imageKeyword: _nameCtrl.text.trim().toLowerCase(),
      customIngredients: _selectedIngredients,
    );

    final created = widget.existing == null;
    final ok = created
        ? await widget.provider.addCustomRecipe(recipe)
        : await widget.provider.updateCustomRecipe(recipe);

    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      widget.onSaved(created);
      Navigator.pop(context);
    } else {
      widget.onFailed();
    }
  }

  void _showEditIngredientDialog(int index, RecipeIngredient ing) {
    final qtyCtrl = TextEditingController(text: ing.quantityNeeded.toString());
    final nameCtrl = TextEditingController(text: ing.name);
    final unitCtrl = TextEditingController(text: ing.unit);

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('recipes_custom_edit_ingredient')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: t('recipes_custom_ingredient_name'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: qtyCtrl,
                decoration: InputDecoration(
                  labelText: t('recipes_custom_ingredient_qty'),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: unitCtrl,
                decoration: InputDecoration(
                  labelText: t('recipes_custom_ingredient_unit'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('common_cancel'))),
          FilledButton(
            onPressed: () {
              setState(() {
                _selectedIngredients[index] = ing.copyWith(
                  name: nameCtrl.text.trim(),
                  quantityNeeded: double.tryParse(qtyCtrl.text) ?? ing.quantityNeeded,
                  unit: unitCtrl.text.trim(),
                );
              });
              Navigator.pop(ctx);
            },
            child: Text(t('common_save')),
          ),
        ],
      ),
    );
  }

  void _showAddIngredientDialog() {
    final inventory = widget.provider.inventory;
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final unitCtrl = TextEditingController();
    FoodItem? matchedItem;
    List<FoodItem> suggestions = [];

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final cs = Theme.of(ctx).colorScheme;
          return AlertDialog(
            title: Text(t('recipes_custom_add_ingredient')),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: t('recipes_custom_ingredient_name'),
                      hintText: t('recipes_custom_ingredient_hint'),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      final q = val.trim().toLowerCase();
                      setDialogState(() {
                        matchedItem = null;
                        suggestions = q.isEmpty
                            ? []
                            : inventory
                                .where((f) => f.name.toLowerCase().contains(q))
                                .take(6)
                                .toList();
                      });
                    },
                  ),
                  if (suggestions.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      t('recipes_custom_in_stock'),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    ...suggestions.map((f) {
                      final selected = matchedItem?.id == f.id;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Material(
                          color: selected
                              ? cs.primaryContainer.withAlpha(120)
                              : cs.surfaceContainerHighest.withAlpha(80),
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => setDialogState(() {
                              matchedItem = f;
                              nameCtrl.text = f.name;
                              unitCtrl.text = f.unit;
                              suggestions = [];
                            }),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.inventory_2_outlined,
                                    size: 16,
                                    color: selected ? cs.primary : cs.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${f.name} — ${f.quantity} ${f.unit}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                  if (matchedItem != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      t('recipes_custom_linked')
                          .replaceAll('{name}', matchedItem!.name)
                          .replaceAll('{qty}', '${matchedItem!.quantity}')
                          .replaceAll('{unit}', matchedItem!.unit),
                      style: TextStyle(fontSize: 12, color: cs.primary),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: qtyCtrl,
                          decoration: InputDecoration(
                            labelText: t('recipes_custom_ingredient_qty'),
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: unitCtrl,
                          decoration: InputDecoration(
                            labelText: t('recipes_custom_ingredient_unit'),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('common_cancel'))),
              FilledButton(
                onPressed: () {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(t('recipes_custom_ingredient_name_required'))),
                    );
                    return;
                  }
                  final linkedId = matchedItem?.id ?? '';
                  if (linkedId.isNotEmpty &&
                      _selectedIngredients.any((e) => e.foodItemId == linkedId)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(t('recipes_custom_ingredient_duplicate'))),
                    );
                    return;
                  }
                  setState(() {
                    _selectedIngredients.add(
                      RecipeIngredient(
                        foodItemId: linkedId,
                        name: name,
                        quantityNeeded: double.tryParse(qtyCtrl.text) ?? 1,
                        unit: unitCtrl.text.trim(),
                      ),
                    );
                  });
                  Navigator.pop(ctx);
                },
                child: Text(t('recipes_custom_add_ingredient')),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final cs = Theme.of(context).colorScheme;
    final inventory = widget.provider.inventory;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 1.0,
        expand: false,
        builder: (_, ctrl) => Form(
          key: _formKey,
          child: ListView(
            controller: ctrl,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              _sheetHandle(cs),
              const SizedBox(height: 16),
              Text(
                isEdit ? t('recipes_custom_edit') : t('recipes_custom_create'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: t('recipes_custom_name_label'),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? t('recipes_custom_required')
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: InputDecoration(
                  labelText: t('recipes_custom_desc_label'),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<RecipeDifficulty>(
                initialValue: _difficulty,
                decoration: InputDecoration(
                  labelText: t('recipes_difficulty'),
                  border: const OutlineInputBorder(),
                ),
                items: RecipeDifficulty.values
                    .map(
                      (d) => DropdownMenuItem(
                        value: d,
                        child: Text(_difficultyLabel(widget.provider, d)),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _difficulty = v);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _prepCtrl,
                      decoration: InputDecoration(
                        labelText: t('recipes_custom_prep_label'),
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _cookCtrl,
                      decoration: InputDecoration(
                        labelText: t('recipes_custom_cook_label'),
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _servingsCtrl,
                      decoration: InputDecoration(
                        labelText: t('recipes_custom_servings_label'),
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _caloriesCtrl,
                      decoration: InputDecoration(
                        labelText: t('recipes_custom_calories_label'),
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                t('recipes_ingredients'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._selectedIngredients.asMap().entries.map((entry) {
                final ing = entry.value;
                final info = _stockInfo(inventory, ing);
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(ing.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      info.foodItem != null
                          ? t('recipes_custom_stock_line')
                              .replaceAll('{qty}', '${info.foodItem!.quantity}')
                              .replaceAll('{unit}', info.foodItem!.unit)
                          : t('recipes_custom_not_in_stock'),
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          switch (info.status) {
                            _IngredientStockStatus.ready => Icons.check_circle_rounded,
                            _IngredientStockStatus.low => Icons.cancel_rounded,
                            _ => Icons.warning_amber_rounded,
                          },
                          color: switch (info.status) {
                            _IngredientStockStatus.ready => Colors.green,
                            _IngredientStockStatus.low => cs.error,
                            _ => Colors.orange,
                          },
                          size: 20,
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_rounded),
                          onPressed: () =>
                              _showEditIngredientDialog(entry.key, ing),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_rounded, color: cs.error),
                          onPressed: () =>
                              setState(() => _selectedIngredients.removeAt(entry.key)),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              OutlinedButton.icon(
                onPressed: _showAddIngredientDialog,
                icon: const Icon(Icons.add_rounded),
                label: Text(t('recipes_custom_from_inventory')),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _instructionsCtrl,
                decoration: InputDecoration(
                  labelText: t('recipes_custom_steps_hint'),
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                validator: (v) => v == null || v.trim().isEmpty
                    ? t('recipes_custom_steps_required')
                    : null,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEdit ? t('recipes_custom_update') : t('recipes_custom_save')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _sheetHandle(ColorScheme cs) {
  return Center(
    child: Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: cs.outlineVariant,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}
