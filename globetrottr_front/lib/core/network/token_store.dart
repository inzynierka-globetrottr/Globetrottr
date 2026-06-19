import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStore {
  final _storage = const FlutterSecureStorage();
  final String _key = 'jwt_token';

  Future<String?> getToken() => _storage.read(key: _key);
  Future<void> saveToken(String token) => _storage.write(key: _key, value: token);
  Future<void> deleteToken() => _storage.delete(key: _key);
}

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());
