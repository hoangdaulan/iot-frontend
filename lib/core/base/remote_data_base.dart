abstract interface class RemoteDataBase {
  /// Performs a refresh token request.
  ///
  /// **Important:** When implementing this, make sure to add `AuthInterceptor.isRefreshTokenRequestKey: true`
  /// to the request's `extra` options so that the interceptor knows this is a refresh token
  /// request and doesn't attempt to intercept it again if it fails with 401.
  /// For example: `Options(extra: {AuthInterceptor.isRefreshTokenRequestKey: true})`
  Future<(String, String)> refreshToken(String token);
}
