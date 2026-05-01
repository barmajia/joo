import 'package:aurora/models/analysis/goals/goal_enums.dart';
import 'package:aurora/models/analysis/goals/seller_goal.dart';
import 'package:aurora/models/analysis/insights/actionable_insight.dart';
import 'package:aurora/storage/storage.dart';

class GoalsStorage {
  static const String _goalsKey = 'seller_goals';
  static const String _achievementsKey = 'seller_achievements';

  static Future<List<SellerGoal>> getGoals(String sellerId) async {
    final goalsData = await Storage.getData<List>(_goalsKey);
    if (goalsData == null) return [];

    return goalsData
        .whereType<Map<String, dynamic>>()
        .map((data) => SellerGoal.fromMap(data))
        .where((goal) => goal.sellerId == sellerId)
        .toList();
  }

  static Future<SellerGoal?> getGoal(String goalId) async {
    final goalsData = await Storage.getData<List>(_goalsKey);
    if (goalsData == null) return null;

    for (final data in goalsData) {
      if (data is Map<String, dynamic>) {
        final goal = SellerGoal.fromMap(data);
        if (goal.id == goalId) return goal;
      }
    }
    return null;
  }

  static Future<void> saveGoal(SellerGoal goal) async {
    final goalsData = await Storage.getData<List>(_goalsKey) ?? [];

    // Remove existing goal with same ID
    goalsData.removeWhere(
      (item) => item is Map<String, dynamic> && item['id'] == goal.id,
    );

    goalsData.add(goal.toMap());
    await Storage.saveData(_goalsKey, goalsData);
  }

  static Future<void> updateGoalProgress(
    String goalId,
    double currentValue,
  ) async {
    final goal = await getGoal(goalId);
    if (goal != null) {
      final updatedGoal = goal.copyWith(
        currentValue: currentValue,
        status: currentValue >= goal.targetValue
            ? GoalStatus.achieved
            : GoalStatus.active,
        updatedAt: DateTime.now(),
      );
      await saveGoal(updatedGoal);
    }
  }

  static Future<void> deleteGoal(String goalId) async {
    final goalsData = await Storage.getData<List>(_goalsKey) ?? [];
    goalsData.removeWhere(
      (item) => item is Map<String, dynamic> && item['id'] == goalId,
    );
    await Storage.saveData(_goalsKey, goalsData);
  }

  static Future<List<Achievement>> getAchievements(String sellerId) async {
    final achievementsData = await Storage.getData<List>(_achievementsKey);
    if (achievementsData == null) return [];

    return achievementsData
        .whereType<Map<String, dynamic>>()
        .map((data) => Achievement.fromMap(data))
        .where((achievement) => achievement.sellerId == sellerId)
        .toList();
  }

  static Future<void> awardAchievement(Achievement achievement) async {
    final achievementsData =
        await Storage.getData<List>(_achievementsKey) ?? [];

    // Check if already awarded
    final exists = achievementsData.any(
      (item) => item is Map<String, dynamic> && item['id'] == achievement.id,
    );

    if (!exists) {
      achievementsData.add(achievement.toMap());
      await Storage.saveData(_achievementsKey, achievementsData);
    }
  }

  static Future<int> getTotalPoints(String sellerId) async {
    final achievements = await getAchievements(sellerId);
    return achievements.fold<int>(
      0,
      (sum, achievement) => sum + achievement.points,
    );
  }

  static Future<void> clearAll() async {
    await Storage.removeData(_goalsKey);
    await Storage.removeData(_achievementsKey);
  }
}
