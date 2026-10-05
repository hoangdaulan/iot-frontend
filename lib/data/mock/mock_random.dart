import 'dart:math';

/// Single seeded generator shared by every mock dataset, so generated values stay the same
/// regardless of which file a generator lives in.
final mockRandom = Random(42);
