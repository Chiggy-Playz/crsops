sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => message;
}

final class NetworkException extends AppException {
  const NetworkException()
    : super('No internet connection. Check your connection and try again.');
}

final class AuthFailureException extends AppException {
  const AuthFailureException(super.message);
}

final class DataException extends AppException {
  const DataException(super.message);
}

final class UnknownException extends AppException {
  const UnknownException() : super('Something went wrong. Please try again.');
}
