class AppConstants {
  AppConstants._();

  /// Rows the history screens request at once. They filter, aggregate and paginate this window
  /// on the client.
  static const int historyFetchSize = 5000;
}
