/// Extension methods for precise comparison of [double] values.
///
/// Provides a more fluent and readable API for comparing doubles with a tolerance (epsilon),
/// avoiding common pitfalls of direct floating-point comparison.
extension DoubleComparisonExtensions on double {
  /// A very small constant used as a tolerance for floating-point comparisons.
  static const double _epsilon = 1e-9;

  /// Checks if this double is "close enough" to another double to be considered equal.
  ///
  /// This is the recommended way to check for equality.
  ///
  /// Instead of `(0.1 + 0.2) == 0.3` (which is false), use:
  /// `(0.1 + 0.2).isCloseTo(0.3)` (which is true).
  bool isCloseTo(double other) {
    return (this - other).abs() < _epsilon;
  }

  /// Checks if this double is strictly less than another double, considering tolerance.
  ///
  /// Returns `true` only if this number is definitively smaller than the other.
  bool isLessThan(double other) {
    // True if 'other' is larger than 'this' by at least epsilon.
    return other - this > _epsilon;
  }

  /// Checks if this double is strictly greater than another double, considering tolerance.
  bool isGreaterThan(double other) {
    // True if 'this' is larger than 'other' by at least epsilon.
    return this - other > _epsilon;
  }

  /// Checks if this double is less than or equal to another double, considering tolerance.
  ///
  /// This is the safe alternative to the `<=` operator.
  bool isLessOrEqual(double other) {
    // True if this number is less than the other, or if they are close enough to be equal.
    return this < other || isCloseTo(other);
  }

  /// Checks if this double is greater than or equal to another double, considering tolerance.
  ///
  /// This is the safe alternative to the `>=` operator.
  bool isGreaterOrEqual(double other) {
    // True if this number is greater than the other, or if they are close enough to be equal.
    return this > other || isCloseTo(other);
  }

  /// Checks if this double is in the range of [min] and [max], considering tolerance.
  ///
  /// This is the safe alternative to the `>=` and `<=` operators.
  bool inRange(double min, double max) {
    return isGreaterOrEqual(min) && isLessOrEqual(max);
  }
}
