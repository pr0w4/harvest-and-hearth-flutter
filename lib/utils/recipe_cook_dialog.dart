import 'package:flutter/material.dart';

import '../models/recipe.dart';
import '../providers/app_provider.dart';

Future<void> showCookRecipeDialog(
  BuildContext context,
  AppProvider provider,
  Recipe recipe,
) async {
  if (!recipe.isCustom || recipe.customIngredients.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(provider.t('recipes_custom_cook_no_ingredients'))),
    );
    return;
  }

  final preview = provider.previewCookCustomRecipe(recipe);
  if (!preview.success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${provider.t('recipes_custom_cook_failed')}: ${preview.insufficient.join(', ')}',
        ),
      ),
    );
    return;
  }

  final linked = recipe.customIngredients
      .where((e) => e.foodItemId.isNotEmpty)
      .toList(growable: false);
  if (linked.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(provider.t('recipes_custom_cook_no_ingredients'))),
    );
    return;
  }

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(provider.t('recipes_custom_cook_title')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(provider.t('recipes_custom_cook_body')),
            const SizedBox(height: 10),
            ...linked.map(
              (ing) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.remove_circle_outline, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('${ing.name}: ${ing.quantityNeeded} ${ing.unit}'),
                    ),
                  ],
                ),
              ),
            ),
            if (preview.unlinked.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                provider
                    .t('recipes_custom_cook_unlinked')
                    .replaceAll('{items}', preview.unlinked.join(', ')),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(provider.t('common_cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(provider.t('recipes_custom_cook_confirm')),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return;

  final result = await provider.cookCustomRecipe(recipe);
  if (!context.mounted) return;

  if (result.success) {
    var msg = provider.t('recipes_custom_cook_success');
    if (result.unlinked.isNotEmpty) {
      msg +=
          ' (${provider.t('recipes_custom_cook_unlinked').replaceAll('{items}', result.unlinked.join(', '))})';
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${provider.t('recipes_custom_cook_failed')}: ${result.insufficient.join(', ')}',
        ),
      ),
    );
  }
}
