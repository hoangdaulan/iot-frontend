class AppConstants {
  AppConstants._();

  /// How the history screens show a timestamp, and the format their time search expects.
  static const String dateTimeFormat = 'yyyy/MM/dd HH:mm:ss';

  /// Rows the history screens request at once. They filter, aggregate and paginate this window
  /// on the client.
  static const int historyFetchSize = 5000;
}
