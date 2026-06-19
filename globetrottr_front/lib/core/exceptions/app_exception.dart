/// Base type for every *expected* error in the app — a bad password, no
/// internet, a 404, a malformed server payload, GPS turned off, etc. —
/// as opposed to a programming bug.
///
/// Any class anywhere in the codebase can `extends AppException` to add a
/// new domain-specific error (e.g. a future `QuestException`). Because
/// everything funnels through this one base type, a `catch (AppException e)`
/// anywhere in the UI layer is guaranteed to see a real `e.message` and
/// never fall through to a generic "Something went wrong" with the actual
/// reason lost.
abstract class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

/// A 4xx/5xx response came back from the API and we don't have a more
/// specific type for it. [message] is whatever the server told us (or a
/// generic fallback if the body couldn't be parsed).
class ServerException extends AppException {
  const ServerException(super.message, [super.statusCode]);
}

/// 401 — the access token is missing, invalid, or expired.
class UnauthorizedException extends AppException {
  const UnauthorizedException([
    String message = 'Session expired. Please log in again.',
  ]) : super(message, 401);
}

/// 403 — authenticated, but not allowed to do this.
class ForbiddenException extends AppException {
  const ForbiddenException([
    String message = "You don't have permission to do that.",
  ]) : super(message, 403);
}

/// 404
class NotFoundException extends AppException {
  const NotFoundException([String message = 'Not found.']) : super(message, 404);
}

/// 400/422-style validation failure. Kept distinct from [ServerException]
/// so forms can special-case it later (e.g. map field-level errors).
class ValidationException extends AppException {
  const ValidationException(super.message, [super.statusCode]);
}

/// The request never reached the server, or never got a response: no
/// connectivity, DNS failure, timeout, airplane mode, etc.
class NetworkException extends AppException {
  const NetworkException([
    super.message = 'Network error. Please check your connection.',
  ]);
}

/// The app itself is misconfigured (e.g. missing backend URL at build
/// time). Not the user's fault, and not really a "network" problem.
class ConfigurationException extends AppException {
  const ConfigurationException(super.message);
}

/// The server returned data we couldn't understand — e.g. an enum value
/// the client doesn't know about yet. Usually means the app is older than
/// the API contract.
class DataParsingException extends AppException {
  const DataParsingException(super.message);
}

/// Device-level failure unrelated to our API: location services off,
/// permission denied, sensor unavailable, etc.
class LocationException extends AppException {
  const LocationException(super.message);
}

/// Auth-domain failure that isn't an HTTP error (e.g. the Google sign-in
/// flow itself failed before we ever called our API).
class AuthException extends AppException {
  const AuthException(super.message);
}

/// True last resort. If you find yourself reaching for this, prefer adding
/// a more specific subclass instead — it exists so a `catch (AppException e)`
/// never has to fall through to a hardcoded string in the UI layer, even
/// for the rare, genuinely-unclassified case.
class UnknownException extends AppException {
  const UnknownException([super.message = 'Something went wrong.']);
}
