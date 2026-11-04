import 'package:globetrottr_front/features/regions/data/region_type.dart';
import 'package:globetrottr_front/features/statistics/screens/city_detail_screen.dart';
import 'package:globetrottr_front/features/statistics/screens/countries_screen.dart';
import 'package:globetrottr_front/features/statistics/screens/region_detail_screen.dart';
import 'package:globetrottr_front/features/statistics/screens/stats_not_found_screen.dart';
import 'package:globetrottr_front/features/statistics/screens/stats_screen.dart';
import 'package:go_router/go_router.dart';

/// The screen a region row opens; null for regions without one.
String? statsRouteFor(RegionType type, int id) => switch (type) {
  RegionType.state || RegionType.county => '/profile/statistics/region/$id',
  RegionType.city => '/profile/statistics/city/$id',
  RegionType.country || RegionType.district => null,
};

/// The statistics screens, under `/profile`.
final statisticsRoute = GoRoute(
  path: 'statistics',
  builder: (context, state) => const StatsScreen(),
  routes: [
    GoRoute(
      path: 'countries',
      builder: (context, state) => const CountriesScreen(),
    ),
    GoRoute(
      path: 'region/:id',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        return id == null
            ? const StatsNotFoundScreen()
            : RegionDetailScreen(regionId: id);
      },
    ),
    GoRoute(
      path: 'city/:id',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        return id == null
            ? const StatsNotFoundScreen()
            : CityDetailScreen(cityId: id);
      },
    ),
  ],
);
