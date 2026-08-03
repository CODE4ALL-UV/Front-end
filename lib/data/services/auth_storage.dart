import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthStorage {
  static const _tokenKey = 'auth_token';
  static const _roleKey = 'auth_role';
  static const _nameKey = 'auth_name';
  static const _emailKey = 'auth_email';
  static const _photoUrlKey = 'auth_photo_url';
  static const _userIdKey = 'auth_user_id';
  static final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> saveRole(String role) async {
    await _storage.write(key: _roleKey, value: role);
  }

  Future<void> saveName(String name) async {
    await _storage.write(key: _nameKey, value: name);
  }

  Future<void> saveEmail(String email) async {
    await _storage.write(key: _emailKey, value: email);
  }

  Future<void> saveUserId(int userId) async {
    await _storage.write(key: _userIdKey, value: userId.toString());
  }

  Future<void> savePhotoUrl(String photoUrl) async {
    await _storage.write(key: _photoUrlKey, value: photoUrl);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<String?> getRole() async {
    return await _storage.read(key: _roleKey);
  }

  Future<String?> getName() async {
    return await _storage.read(key: _nameKey);
  }

  Future<String?> getEmail() async {
    return await _storage.read(key: _emailKey);
  }

  Future<String?> getPhotoUrl() async {
    return await _storage.read(key: _photoUrlKey);
  }

  Future<int?> getUserId() async {
    final value = await _storage.read(key: _userIdKey);
    return value == null ? null : int.tryParse(value);
  }

  Future<void> clear() async {
    // Remove all stored auth data on logout, including photo URL
    await _storage.deleteAll();
  }
}
