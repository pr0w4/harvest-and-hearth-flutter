class RecipeIngredient {
  final String foodItemId;
  final String name;
  final double quantityNeeded;
  final String unit;

  const RecipeIngredient({
    required this.foodItemId,
    required this.name,
    required this.quantityNeeded,
    required this.unit,
  });

  Map<String, dynamic> toJson() => {
        'foodItemId': foodItemId,
        'name': name,
        'quantityNeeded': quantityNeeded,
        'unit': unit,
      };

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) =>
      RecipeIngredient(
        foodItemId: json['foodItemId'] as String? ?? '',
        name: json['name'] as String,
        quantityNeeded: (json['quantityNeeded'] as num).toDouble(),
        unit: json['unit'] as String,
      );

  RecipeIngredient copyWith({
    String? foodItemId,
    String? name,
    double? quantityNeeded,
    String? unit,
  }) =>
      RecipeIngredient(
        foodItemId: foodItemId ?? this.foodItemId,
        name: name ?? this.name,
        quantityNeeded: quantityNeeded ?? this.quantityNeeded,
        unit: unit ?? this.unit,
      );
}

enum RecipeDifficulty { easy, medium, hard }

List<String> normalizeRecipeInstructions(List<String> raw) {
  final out = <String>[];
  final seen = <String>{};

  for (final row in raw) {
    var s = row.trim();
    if (s.isEmpty) continue;

    // Drop standalone "step 1", "bước 2", "2.", "(3)" lines.
    final lower = s.toLowerCase();
    if (RegExp(r'^(step|bước)\s*\d+[:.)-]?\s*$').hasMatch(lower) ||
        RegExp(r'^\(?\d+\)?[.)-]?\s*$').hasMatch(lower)) {
      continue;
    }

    // Remove step prefixes inside a real sentence.
    s = s.replaceFirst(
      RegExp(r'^\s*(step|bước)\s*\d+\s*[:.)-]?\s*', caseSensitive: false),
      '',
    );
    s = s.replaceFirst(RegExp(r'^\s*\(?\d+\)?[.)-]\s*'), '');
    s = s.trim();
    if (s.isEmpty) continue;

    final key = s.toLowerCase();
    if (seen.add(key)) {
      out.add(s);
    }
  }
  return out;
}

extension RecipeDifficultyX on RecipeDifficulty {
  String get value => name;

  static RecipeDifficulty fromString(String v) {
    switch (v.toLowerCase()) {
      case 'easy':
      case 'dễ':
        return RecipeDifficulty.easy;
      case 'medium':
      case 'trung bình':
        return RecipeDifficulty.medium;
      case 'hard':
      case 'khó':
        return RecipeDifficulty.hard;
      default:
        return RecipeDifficulty.easy;
    }
  }
}

class Recipe {
  final String id;
  final String name;
  final String description;
  final RecipeDifficulty difficulty;
  final int prepTime;
  final int cookTime;
  final int servings;
  final int calories;
  final List<String> ingredientsNeeded;
  final List<String> instructions;
  final String sourceName;
  final String sourceUrl;
  final String imageKeyword;
  bool isSaved;
  List<RecipeIngredient> customIngredients;

  bool get isCustom => sourceName == 'Custom';

  int get totalTime => prepTime + cookTime;

  Recipe({
    required this.id,
    required this.name,
    required this.description,
    required this.difficulty,
    required this.prepTime,
    required this.cookTime,
    required this.servings,
    required this.calories,
    required this.ingredientsNeeded,
    required this.instructions,
    required this.sourceName,
    required this.sourceUrl,
    required this.imageKeyword,
    this.isSaved = false,
    this.customIngredients = const [],
  });

  Recipe copyWith({
    String? id,
    String? name,
    String? description,
    RecipeDifficulty? difficulty,
    int? prepTime,
    int? cookTime,
    int? servings,
    int? calories,
    List<String>? ingredientsNeeded,
    List<String>? instructions,
    String? sourceName,
    String? sourceUrl,
    String? imageKeyword,
    bool? isSaved,
    List<RecipeIngredient>? customIngredients,
  }) {
    return Recipe(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      prepTime: prepTime ?? this.prepTime,
      cookTime: cookTime ?? this.cookTime,
      servings: servings ?? this.servings,
      calories: calories ?? this.calories,
      ingredientsNeeded: ingredientsNeeded ?? this.ingredientsNeeded,
      instructions: instructions ?? this.instructions,
      sourceName: sourceName ?? this.sourceName,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      imageKeyword: imageKeyword ?? this.imageKeyword,
      isSaved: isSaved ?? this.isSaved,
      customIngredients: customIngredients ?? this.customIngredients,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'difficulty': difficulty.value,
        'prepTime': prepTime,
        'cookTime': cookTime,
        'servings': servings,
        'calories': calories,
        'ingredientsNeeded': ingredientsNeeded,
        'instructions': instructions,
        'sourceName': sourceName,
        'sourceUrl': sourceUrl,
        'imageKeyword': imageKeyword,
        'isSaved': isSaved,
        'customIngredients': customIngredients.map((e) => e.toJson()).toList(),
      };

  factory Recipe.fromJson(Map<String, dynamic> json) => Recipe(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        difficulty: RecipeDifficultyX.fromString(json['difficulty'] as String),
        prepTime: (json['prepTime'] as num).toInt(),
        cookTime: (json['cookTime'] as num).toInt(),
        servings: (json['servings'] as num).toInt(),
        calories: (json['calories'] as num).toInt(),
        ingredientsNeeded: List<String>.from(json['ingredientsNeeded'] as List),
        instructions: normalizeRecipeInstructions(
          List<String>.from(json['instructions'] as List),
        ),
        sourceName: json['sourceName'] as String,
        sourceUrl: json['sourceUrl'] as String? ?? '',
        imageKeyword: json['imageKeyword'] as String? ?? '',
        isSaved: json['isSaved'] as bool? ?? false,
        customIngredients: (json['customIngredients'] as List<dynamic>? ?? [])
            .map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Result of attempting to cook a custom recipe (deduct linked inventory).
class CookRecipeResult {
  const CookRecipeResult({
    required this.success,
    this.insufficient = const [],
    this.deducted = const [],
    this.unlinked = const [],
  });

  final bool success;
  final List<String> insufficient;
  final List<String> deducted;
  final List<String> unlinked;
}
