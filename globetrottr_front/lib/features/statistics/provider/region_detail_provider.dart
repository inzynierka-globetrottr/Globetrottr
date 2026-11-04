import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/features/regions/data/region.dart';
import 'package:globetrottr_front/features/regions/data/region_storage.dart';
import 'package:globetrottr_front/features/regions/data/region_type.dart';
import 'package:globetrottr_front/features/statistics/data/statistics_storage.dart';
import 'package:globetrottr_front/features/statistics/data/user_region_stats.dart';
import 'package:globetrottr_front/features/statistics/provider/statistics_providers.dart';

/// A region the user has discovered, with how much of it.
class DiscoveredRegion {
  const DiscoveredRegion({
    required this.id,
    required this.type,
    required this.name,
    required this.areaKm2,
    required this.percentage,
    this.details = const [],
  });

  final int id;
  final RegionType type;
  final RegionName name;
  final double areaKm2;
  final double percentage;

  /// Names of the discovered regions inside it worth showing in its row,
  /// e.g. the cities of a county.
  final List<RegionName> details;
}

class StateGroupData {
  const StateGroupData({
    required this.id,
    required this.name,
    required this.cities,
  });

  final int id;
  final RegionName name;
  final List<DiscoveredRegion> cities;
}

class CountryGroupData {
  const CountryGroupData({
    required this.countryCode,
    required this.countryName,
    required this.areaKm2,
    required this.citiesCount,
    required this.states,
  });

  final String? countryCode;
  final RegionName countryName;
  final double areaKm2;
  final int citiesCount;
  final List<StateGroupData> states;
}

class CountriesData {
  const CountriesData({
    required this.visitedRegionsCount,
    required this.visitedCitiesCount,
    required this.countries,
  });

  final int visitedRegionsCount;
  final int visitedCitiesCount;
  final List<CountryGroupData> countries;
}

/// The discovered regions of a database, each with its ancestors.
class _Discovered {
  _Discovered(this.regions, this.stats, this.chains);

  final Map<int, Region> regions;
  final Map<int, UserRegionStats> stats;
  final Map<int, List<Region>> chains;

  static Future<_Discovered> load(
    RegionStorage regionStorage,
    StatisticsStorage statsStorage,
  ) async {
    final stats = {
      for (final stat in await statsStorage.getAllRegionStats())
        if (stat.discoveredAreaM2 > 0) stat.regionId: stat,
    };
    final known = {
      for (final r in await regionStorage.findRegionsByIds(stats.keys)) r.id: r,
    };
    // Ancestors level by level, a few queries for the whole tree.
    var missing = {
      for (final r in known.values)
        if (r.parentId != null && !known.containsKey(r.parentId)) r.parentId!,
    };
    while (missing.isNotEmpty) {
      final parents = await regionStorage.findRegionsByIds(missing);
      for (final r in parents) {
        known[r.id] = r;
      }
      missing = {
        for (final r in parents)
          if (r.parentId != null && !known.containsKey(r.parentId)) r.parentId!,
      };
      if (parents.isEmpty) break;
    }
    List<Region> chainOf(Region region) {
      final chain = <Region>[];
      Region? current = region;
      while (current != null && chain.length < 10) {
        chain.add(current);
        current = known[current.parentId];
      }
      return chain;
    }

    final regions = {
      for (final id in stats.keys)
        if (known[id] != null) id: known[id]!,
    };
    return _Discovered(
      regions,
      {for (final id in regions.keys) id: stats[id]!},
      {for (final r in regions.values) r.id: chainOf(r)},
    );
  }

  Iterable<Region> ofType(RegionType type) =>
      regions.values.where((r) => r.type == type);

  Iterable<Region> inside(int ancestorId, RegionType type) => ofType(
    type,
  ).where((r) => chains[r.id]!.skip(1).any((a) => a.id == ancestorId));

  DiscoveredRegion item(Region region, {List<RegionName> details = const []}) {
    final stat = stats[region.id]!;
    return DiscoveredRegion(
      id: region.id,
      type: region.type,
      name: region.displayName,
      areaKm2: stat.discoveredAreaM2 / 1000000,
      percentage: stat.discoveryPercentage,
      details: details,
    );
  }

  List<DiscoveredRegion> items(
    Iterable<Region> regions, {
    List<RegionName> Function(Region)? details,
  }) =>
      [
        for (final r in regions) item(r, details: details?.call(r) ?? const []),
      ]..sort((a, b) {
        final byPercent = b.percentage.compareTo(a.percentage);
        return byPercent != 0 ? byPercent : b.areaKm2.compareTo(a.areaKm2);
      });
}

final countriesDataProvider = FutureProvider<CountriesData>((ref) async {
  ref.watch(statisticsRevisionProvider);
  final found = await _Discovered.load(
    ref.watch(regionStorageProvider),
    ref.watch(statisticsStorageProvider),
  );

  final countries = [
    for (final country in found.ofType(RegionType.country))
      CountryGroupData(
        countryCode: country.code,
        countryName: country.displayName,
        areaKm2: found.stats[country.id]!.discoveredAreaM2 / 1000000,
        citiesCount: found.inside(country.id, RegionType.city).length,
        states: [
          for (final state in found.items(
            found
                .ofType(RegionType.state)
                .where((s) => s.parentId == country.id),
          ))
            StateGroupData(
              id: state.id,
              name: state.name,
              cities: found.items(found.inside(state.id, RegionType.city)),
            ),
        ],
      ),
  ]..sort((a, b) => b.areaKm2.compareTo(a.areaKm2));

  return CountriesData(
    visitedRegionsCount: found.ofType(RegionType.state).length,
    visitedCitiesCount: found.ofType(RegionType.city).length,
    countries: countries,
  );
});

class RegionDetailData {
  const RegionDetailData({
    required this.id,
    required this.name,
    required this.countryName,
    required this.subregionKind,
    required this.discoveredSubregionsCount,
    required this.totalSubregionsCount,
    required this.discoveryPercentage,
    required this.discoveredAreaKm2,
    required this.citiesCount,
    required this.subregions,
    required this.firstVisit,
    required this.lastVisit,
  });

  final int id;
  final RegionName name;
  final RegionName? countryName;

  /// The type of the regions directly inside, which names the list.
  final RegionType? subregionKind;
  final int discoveredSubregionsCount;
  final int totalSubregionsCount;
  final double discoveryPercentage;
  final double discoveredAreaKm2;
  final int citiesCount;
  final List<DiscoveredRegion> subregions;
  final DateTime? firstVisit;
  final DateTime? lastVisit;
}

final regionDetailProvider = FutureProvider.family<RegionDetailData?, int>((
  ref,
  regionId,
) async {
  ref.watch(statisticsRevisionProvider);
  final regionStorage = ref.watch(regionStorageProvider);
  final statsStorage = ref.watch(statisticsStorageProvider);
  final region = await regionStorage.findRegionById(regionId);
  if (region == null) return null;
  final found = await _Discovered.load(regionStorage, statsStorage);
  final stat = found.stats[regionId];
  final chain = await regionStorage.getAncestorChain(regionId);
  final children = await regionStorage.findChildren(regionId);
  final discoveredChildren = children.where(
    (c) => found.regions.containsKey(c.id),
  );

  return RegionDetailData(
    id: regionId,
    name: region.displayName,
    countryName: chain
        .skip(1)
        .where((r) => r.type == RegionType.country)
        .firstOrNull
        ?.displayName,
    subregionKind: children.firstOrNull?.type,
    discoveredSubregionsCount: discoveredChildren.length,
    totalSubregionsCount: children.length,
    discoveryPercentage: stat?.discoveryPercentage ?? 0,
    discoveredAreaKm2: (stat?.discoveredAreaM2 ?? 0) / 1000000,
    citiesCount: found.inside(regionId, RegionType.city).length,
    subregions: found.items(
      discoveredChildren,
      details: (child) => child.type == RegionType.city
          ? const []
          : [
              for (final city in found.items(
                found.inside(child.id, RegionType.city),
              ))
                city.name,
            ],
    ),
    firstVisit: _visitDate(stat?.firstVisitMs),
    lastVisit: _visitDate(stat?.lastVisitMs),
  );
});

class CityDetailData {
  const CityDetailData({
    required this.id,
    required this.name,
    required this.regionName,
    required this.discoveryPercentage,
    required this.discoveredAreaKm2,
    required this.districts,
    required this.firstVisit,
    required this.lastVisit,
  });

  final int id;
  final RegionName name;

  /// The state of the city, else its county or country.
  final RegionName? regionName;
  final double discoveryPercentage;
  final double discoveredAreaKm2;
  final List<DiscoveredRegion> districts;
  final DateTime? firstVisit;
  final DateTime? lastVisit;
}

final cityDetailProvider = FutureProvider.family<CityDetailData?, int>((
  ref,
  cityId,
) async {
  ref.watch(statisticsRevisionProvider);
  final regionStorage = ref.watch(regionStorageProvider);
  final statsStorage = ref.watch(statisticsStorageProvider);
  final city = await regionStorage.findRegionById(cityId);
  if (city == null) return null;
  final found = await _Discovered.load(regionStorage, statsStorage);
  final stat = found.stats[cityId];
  final ancestors = (await regionStorage.getAncestorChain(cityId)).skip(1);
  Region? ofType(RegionType type) =>
      ancestors.where((r) => r.type == type).firstOrNull;
  final children = await regionStorage.findChildren(cityId);

  return CityDetailData(
    id: cityId,
    name: city.displayName,
    regionName:
        (ofType(RegionType.state) ??
                ofType(RegionType.county) ??
                ofType(RegionType.country))
            ?.displayName,
    discoveryPercentage: stat?.discoveryPercentage ?? 0,
    discoveredAreaKm2: (stat?.discoveredAreaM2 ?? 0) / 1000000,
    districts: found.items(
      children.where((c) => found.regions.containsKey(c.id)),
    ),
    firstVisit: _visitDate(stat?.firstVisitMs),
    lastVisit: _visitDate(stat?.lastVisitMs),
  );
});

DateTime? _visitDate(int? timestampMs) {
  if (timestampMs == null || timestampMs <= 0) return null;
  return DateTime.fromMillisecondsSinceEpoch(timestampMs);
}
