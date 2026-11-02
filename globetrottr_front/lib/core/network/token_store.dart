import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The stored session: the access token, or the choice to use the app as a
/// guest.
class TokenStore {
  final _storage = const FlutterSecureStorage();
  final String _key = 'jwt_token';
  final String _guestKey = 'guest_mode';

  Future<String?> getToken() => _storage.read(key: _key);
  Future<void> saveToken(String token) =>
      _storage.write(key: _key, value: token);
  Future<void> deleteToken() => _storage.delete(key: _key);

  Future<bool> isGuest() async => await _storage.read(key: _guestKey) != null;
  Future<void> saveGuest() => _storage.write(key: _guestKey, value: '1');
  Future<void> deleteGuest() => _storage.delete(key: _guestKey);
}

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());
