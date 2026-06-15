// TODO: consider inheriting from this to make specific exceptions like AuthException or FriendException etc.
class AppException implements Exception {
  final String message;
  final int? statusCode;

  AppException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}