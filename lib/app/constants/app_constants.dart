class AppConstants {
  AppConstants._();

  /// How the history screens show a timestamp, and the format their time search expects.
  static const String dateTimeFormat = 'yyyy/MM/dd HH:mm:ss';

  /// The dashboard charts show the latest [chartWindow] of readings, averaged over
  /// [chartBucket] windows by the backend.
  static const Duration chartWindow = Duration(hours: 24);
  static const Duration chartBucket = Duration(minutes: 5);

  /// Rows the history screens request at once. They filter, aggregate and paginate this window
  /// on the client.
  static const int historyFetchSize = 5000;
}
