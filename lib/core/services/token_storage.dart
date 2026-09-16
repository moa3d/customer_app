import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// تخزين آمن للتوكن.
///
/// كان التوكن محفوظاً في `SharedPreferences` نصاً صريحاً — أي أن أي وصول
/// لملفات التطبيق (جهاز مكسور الحماية، نسخة احتياطية غير مشفّرة، أو أداة
/// تحليل) يكشفه مباشرة. الآن يُحفظ في Keychain على iOS و EncryptedSharedPreferences
/// على أندرويد.
///
/// نحتفظ بنسخة في الذاكرة لأن `flutter_secure_storage.read` نداء عبر
/// Platform Channel، ولا يصحّ تنفيذه مع **كل** طلب شبكة في الـ interceptor.
class TokenStorage {
  static final TokenStorage _instance = TokenStorage._internal();

  factory TokenStorage() => _instance;

  TokenStorage._internal();

  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'userId';

  static const FlutterSecureStorage _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  String? _cachedToken;
  String? _cachedUserId;
  bool _loaded = false;

  /// ترحيل لمرة واحدة من SharedPreferences إلى التخزين الآمن،
  /// حتى لا يُخرَج المستخدمون الحاليون من حساباتهم عند التحديث.
  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;

    try {
      _cachedToken = await _secure.read(key: _tokenKey);
      _cachedUserId = await _secure.read(key: _userIdKey);

      if (_cachedToken != null && _cachedToken!.isNotEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      final legacyToken = prefs.getString(_tokenKey);
      final legacyUserId = prefs.getString(_userIdKey);

      if (legacyToken != null && legacyToken.isNotEmpty) {
        debugPrint('[TOKEN]: migrating legacy token to secure storage');
        await _secure.write(key: _tokenKey, value: legacyToken);
        _cachedToken = legacyToken;
      }
      if (legacyUserId != null && legacyUserId.isNotEmpty) {
        await _secure.write(key: _userIdKey, value: legacyUserId);
        _cachedUserId = legacyUserId;
      }

      await prefs.remove(_tokenKey);
      await prefs.remove(_userIdKey);
    } catch (e) {
      debugPrint('[TOKEN]: secure storage unavailable -> $e');
    }
  }

  /// يُستدعى مرة عند الإقلاع لتسخين النسخة المخزّنة في الذاكرة
  Future<void> init() => _ensureLoaded();

  Future<String?> getToken() async {
    await _ensureLoaded();
    return _cachedToken;
  }

  /// قراءة متزامنة للاستعمال داخل الـ interceptor بعد `init()`.
  /// تُرجع null إذا لم يُحمَّل بعد.
  String? get cachedToken => _cachedToken;

  Future<String?> getUserId() async {
    await _ensureLoaded();
    return _cachedUserId;
  }

  Future<void> saveToken(String token) async {
    _cachedToken = token;
    _loaded = true;
    try {
      await _secure.write(key: _tokenKey, value: token);
    } catch (e) {
      debugPrint('[TOKEN]: write failed -> $e');
    }
  }

  Future<void> saveUserId(String userId) async {
    _cachedUserId = userId;
    try {
      await _secure.write(key: _userIdKey, value: userId);
    } catch (e) {
      debugPrint('[TOKEN]: write failed -> $e');
    }
  }

  Future<void> clear() async {
    _cachedToken = null;
    _cachedUserId = null;
    try {
      await _secure.delete(key: _tokenKey);
      await _secure.delete(key: _userIdKey);
    } catch (e) {
      debugPrint('[TOKEN]: delete failed -> $e');
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userIdKey);
    } catch (_) {}
  }
}
