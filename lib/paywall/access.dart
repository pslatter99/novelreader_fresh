import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccessManager {
  AccessManager._();
  static final AccessManager instance = AccessManager._();

  late SharedPreferences _prefs;
  bool _ready = false;

  // While testing, you can bypass the gate. Turn this off for real builds.
  bool _debugPassThrough = kDebugMode;
  void setDebugPassThrough(bool value) => _debugPassThrough = value;

  /// First locked chapter is [gateAtChapter] + 1.
  static const int gateAtChapter = 5;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _ready = true;
  }

  // ---- entitlements ----
  bool get isSubscribed => _prefs.getBool('subscribed') ?? false;
  bool hasAdsAccess(String bookKey) => _prefs.getBool('ads:$bookKey') ?? false;
  bool hasPurchased(String bookKey) => _prefs.getBool('purchased:$bookKey') ?? false;

  Future<void> chooseSubscribe() async {
    await _prefs.setBool('subscribed', true);
  }

  Future<void> chooseAds(String bookKey) async {
    await _prefs.setBool('ads:$bookKey', true);
  }

  Future<void> choosePurchase(String bookKey) async {
    await _prefs.setBool('purchased:$bookKey', true);
  }

  bool canAccessChapter(String bookKey, int chapterNumber) {
    if (!_ready) return true; // fail-open so the app isn't blocked
    if (_debugPassThrough) return true;
    if (chapterNumber <= gateAtChapter) return true;
    if (isSubscribed) return true;
    if (hasPurchased(bookKey)) return true;
    if (hasAdsAccess(bookKey)) return true;
    return false;
  }

  // ---- progress ----
  Future<void> saveProgress(String bookKey, {required int chapter, required int page}) async {
    final data = jsonEncode({'chapter': chapter, 'page': page});
    await _prefs.setString('progress:$bookKey', data);
  }

  Map<String, int>? getProgress(String bookKey) {
    final raw = _prefs.getString('progress:$bookKey');
    if (raw == null) return null;
    try {
      final m = (jsonDecode(raw) as Map<String, dynamic>);
      return {
        'chapter': (m['chapter'] ?? 1) as int,
        'page': (m['page'] ?? 0) as int,
      };
    } catch (_) {
      return null;
    }
  }
}
