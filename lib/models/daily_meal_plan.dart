class DailyMealPlan {
  const DailyMealPlan({
    required this.id,
    required this.dateKey,
    required this.mealSlot,
    required this.recipeId,
    required this.recipeName,
    required this.sourceName,
    this.ingredients = const [],
    this.createdAtIso,
  });

  final String id;
  final String dateKey; // yyyy-MM-dd
  final String mealSlot; // breakfast | lunch | dinner
  final String recipeId;
  final String recipeName;
  final String sourceName;
  final List<String> ingredients;
  final String? createdAtIso;

  DailyMealPlan copyWith({
    String? id,
    String? dateKey,
    String? mealSlot,
    String? recipeId,
    String? recipeName,
    String? sourceName,
    List<String>? ingredients,
    String? createdAtIso,
  }) {
    return DailyMealPlan(
      id: id ?? this.id,
      dateKey: dateKey ?? this.dateKey,
      mealSlot: mealSlot ?? this.mealSlot,
      recipeId: recipeId ?? this.recipeId,
      recipeName: recipeName ?? this.recipeName,
      sourceName: sourceName ?? this.sourceName,
      ingredients: ingredients ?? this.ingredients,
      createdAtIso: createdAtIso ?? this.createdAtIso,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'dateKey': dateKey,
        'mealSlot': mealSlot,
        'recipeId': recipeId,
        'recipeName': recipeName,
        'sourceName': sourceName,
        'ingredients': ingredients,
        'createdAtIso': createdAtIso,
      };

  factory DailyMealPlan.fromJson(Map<String, dynamic> json) {
    return DailyMealPlan(
      id: json['id'] as String,
      dateKey: json['dateKey'] as String,
      mealSlot: json['mealSlot'] as String,
      recipeId: json['recipeId'] as String? ?? '',
      recipeName: json['recipeName'] as String? ?? '',
      sourceName: json['sourceName'] as String? ?? '',
      ingredients: List<String>.from(json['ingredients'] as List? ?? const []),
      createdAtIso: json['createdAtIso'] as String?,
    );
  }
}

String mealDateKey(DateTime date) {
  final d = DateTime(date.year, date.month, date.day);
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}
