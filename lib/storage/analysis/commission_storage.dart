import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aurora/models/analysis/commission.dart';
import 'package:aurora/models/analysis/enums.dart';

class CommissionStorage {
  static late final SharedPreferences _prefs;
  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) return;
    _prefs = await SharedPreferences.getInstance();
    _isInitialized = true;
  }

  static Future<void> _saveString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  static Future<String?> _getString(String key) async {
    try {
      return _prefs.getString(key);
    } catch (e) {
      final value = _prefs.get(key);
      if (value is int) return value.toString();
      if (value is double) return value.toString();
      if (value is bool) return value.toString();
      return null;
    }
  }

  static Future<void> saveCommissions(List<Commission> commissions) async {
    final list = commissions.map((c) => c.toMap()).toList();
    await _saveString('commissions_data', jsonEncode(list));
  }

  static Future<List<Commission>> getCommissions() async {
    final value = await _getString('commissions_data');
    if (value == null || value.isEmpty) return [];
    try {
      final list = jsonDecode(value) as List;
      return list
          .map((item) => Commission.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<List<Commission>> getPendingCommissions() async {
    final commissions = await getCommissions();
    return commissions.where((c) => c.isPending).toList();
  }

  static Future<List<Commission>> getPaidCommissions() async {
    final commissions = await getCommissions();
    return commissions.where((c) => c.isPaid).toList();
  }

  static Future<double> getTotalPendingEarnings() async {
    final commissions = await getPendingCommissions();
    double total = 0.0;
    for (final c in commissions) {
      total += c.amount;
    }
    return total;
  }

  static Future<double> getTotalPaidEarnings() async {
    final commissions = await getPaidCommissions();
    double total = 0.0;
    for (final c in commissions) {
      total += c.amount;
    }
    return total;
  }

  static Future<void> addCommission(Commission commission) async {
    final commissions = await getCommissions();
    commissions.insert(0, commission);
    await saveCommissions(commissions);
  }

  static Future<void> updateCommissionStatus(
    String commissionId,
    CommissionStatus status,
  ) async {
    final commissions = await getCommissions();
    final index = commissions.indexWhere((c) => c.id == commissionId);
    if (index != -1) {
      final updated = commissions[index].copyWith(
        status: status,
        paidAt: status == CommissionStatus.paid ? DateTime.now() : null,
      );
      commissions[index] = updated;
      await saveCommissions(commissions);
    }
  }

  static Future<void> clearCommissions() async {
    await _prefs.remove('commissions_data');
  }

  static Future<void> clearAll() async {
    await clearCommissions();
  }
}