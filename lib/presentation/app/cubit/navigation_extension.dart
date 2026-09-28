part of 'app_cubit.dart';

enum FeatureGroup {
  iot('IoT');

  final String title;

  const FeatureGroup(this.title);
}

extension NavigationExtension on AppState {
  Map<FeatureGroup, List<AppRoute>> get featureGroups {
    return {
      FeatureGroup.iot: AppRoute.all,
    };
  }

  Set<AppRoute> get accessibleRoutes {
    return featureGroups.values.expand((routes) => routes).toSet();
  }
}
