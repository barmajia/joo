import 'package:aurora/models/analysis/insights/actionable_insight.dart';
import 'package:aurora/storage/storage.dart';

class InsightsStorage {
  static const String _insightsKey = 'actionable_insights';

  static Future<List<ActionableInsight>> getInsights(String sellerId) async {
    final insightsData = await Storage.getData<List>(_insightsKey);
    if (insightsData == null) return [];

    return insightsData
        .whereType<Map<String, dynamic>>()
        .map((data) => ActionableInsight.fromMap(data as Map<String, dynamic>))
        .where((insight) => insight.sellerId == sellerId)
        .toList();
  }

  static Future<ActionableInsight?> getInsight(String insightId) async {
    final insightsData = await Storage.getData<List>(_insightsKey);
    if (insightsData == null) return null;

    for (final data in insightsData) {
      if (data is Map<String, dynamic>) {
        final insight = ActionableInsight.fromMap(data);
        if (insight.id == insightId) return insight;
      }
    }
    return null;
  }

  static Future<void> saveInsight(ActionableInsight insight) async {
    final insightsData = await Storage.getData<List>(_insightsKey) ?? [];
    
    // Remove existing insight with same ID
    insightsData.removeWhere((item) => 
      item is Map<String, dynamic> && item['id'] == insight.id
    );
    
    insightsData.add(insight.toMap());
    await Storage.saveData(_insightsKey, insightsData);
  }

  static Future<void> markAsRead(String insightId) async {
    final insight = await getInsight(insightId);
    if (insight != null) {
      final updatedInsight = insight.copyWith(isRead: true);
      await saveInsight(updatedInsight);
    }
  }

  static Future<void> dismissInsight(String insightId) async {
    final insight = await getInsight(insightId);
    if (insight != null) {
      final updatedInsight = insight.copyWith(isDismissed: true);
      await saveInsight(updatedInsight);
    }
  }

  static Future<void> deleteInsight(String insightId) async {
    final insightsData = await Storage.getData<List>(_insightsKey) ?? [];
    insightsData.removeWhere((item) => 
      item is Map<String, dynamic> && item['id'] == insightId
    );
    await Storage.saveData(_insightsKey, insightsData);
  }

  static Future<void> clearExpiredInsights() async {
    final insightsData = await Storage.getData<List>(_insightsKey) ?? [];
    final now = DateTime.now();
    
    insightsData.removeWhere((item) {
      if (item is! Map<String, dynamic>) return false;
      final expiresAtStr = item['expires_at'] as String?;
      if (expiresAtStr == null) return false;
      
      final expiresAt = DateTime.tryParse(expiresAtStr);
      return expiresAt != null && now.isAfter(expiresAt);
    });
    
    await Storage.saveData(_insightsKey, insightsData);
  }

  static Future<int> getUnreadCount(String sellerId) async {
    final insights = await getInsights(sellerId);
    return insights.where((i) => !i.isRead && !i.isDismissed && !i.isExpired).length;
  }

  static Future<void> clearAll() async {
    await Storage.removeData(_insightsKey);
  }
}
