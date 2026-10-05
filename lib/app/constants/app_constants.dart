class AppConstants {
  AppConstants._();

  /// The system has exactly one ESP32 device, seeded in the backend with this id.
  static const int deviceId = 1;

  /// Rows the history screens request at once. They filter, aggregate and paginate this window
  /// on the client.
  static const int historyFetchSize = 5000;
}
