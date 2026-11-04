import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/features/regions/data/region_type.dart';
import 'package:globetrottr_front/features/statistics/provider/statistics_providers.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/country_accordion_card.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/stats_discovery_card.dart';

class CountryGroupData {
  const CountryGroupData({
    required this.countryCode,
    required this.countryName,
    required this.areaKm2,
    required this.citiesCount,
    required this.subregions,
  });

  final String countryCode;
  final String countryName;
  final double areaKm2;
  final int citiesCount;
  final List<SubregionItem> subregions;
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

final countriesDataProvider = FutureProvider<CountriesData>((ref) async {
  ref.watch(statisticsRevisionProvider);
  final statsStorage = ref.watch(statisticsStorageProvider);
  final regionStorage = ref.watch(regionStorageProvider);

  final allStats = await statsStorage.getAllRegionStats();

  var visitedRegions = 0;
  var visitedCities = 0;
  final countryMap = <int, CountryGroupData>{};

  for (final stat in allStats) {
    if (stat.discoveredAreaM2 <= 0) continue;
    final region = await regionStorage.findRegionById(stat.regionId);
    if (region == null) continue;

    if (region.type == RegionType.state) {
      visitedRegions++;
    } else if (region.type == RegionType.city) {
      visitedCities++;
    }

    if (region.type == RegionType.country) {
      final children = await regionStorage.findChildren(region.id);
      final subregions = <SubregionItem>[];
      for (final child in children) {
        final childStat = await statsStorage.getRegionStats(child.id);
        if (childStat != null && childStat.discoveredAreaM2 > 0) {
          subregions.add(SubregionItem(id: child.id, name: child.name));
        }
      }

      countryMap[region.id] = CountryGroupData(
        countryCode: region.code ?? 'PL',
        countryName: region.name,
        areaKm2: stat.discoveredAreaM2 / 1000000,
        citiesCount: 0,
        subregions: subregions.isNotEmpty
            ? subregions
            : children
                  .map((c) => SubregionItem(id: c.id, name: c.name))
                  .toList(),
      );
    }
  }

  for (final stat in allStats) {
    if (stat.discoveredAreaM2 <= 0) continue;
    final region = await regionStorage.findRegionById(stat.regionId);
    if (region == null || region.type == RegionType.country) continue;

    final ancestors = await regionStorage.getAncestorChain(region.id);
    for (final ancestor in ancestors) {
      if (ancestor.type == RegionType.country &&
          !countryMap.containsKey(ancestor.id)) {
        final countryStat = await statsStorage.getRegionStats(ancestor.id);
        final children = await regionStorage.findChildren(ancestor.id);
        final subregions = <SubregionItem>[];
        for (final child in children) {
          final childStat = await statsStorage.getRegionStats(child.id);
          if (childStat != null && childStat.discoveredAreaM2 > 0) {
            subregions.add(SubregionItem(id: child.id, name: child.name));
          }
        }
        final area = countryStat?.discoveredAreaM2 ?? stat.discoveredAreaM2;
        countryMap[ancestor.id] = CountryGroupData(
          countryCode: ancestor.code ?? 'PL',
          countryName: ancestor.name,
          areaKm2: area / 1000000,
          citiesCount: 0,
          subregions: subregions.isNotEmpty
              ? subregions
              : children
                    .map((c) => SubregionItem(id: c.id, name: c.name))
                    .toList(),
        );
      }
    }
  }

  final citiesPerCountry = <int, int>{};
  for (final stat in allStats) {
    if (stat.discoveredAreaM2 <= 0) continue;
    final region = await regionStorage.findRegionById(stat.regionId);
    if (region == null || region.type != RegionType.city) continue;
    for (final ancestor in await regionStorage.getAncestorChain(region.id)) {
      if (ancestor.type == RegionType.country) {
        citiesPerCountry[ancestor.id] =
            (citiesPerCountry[ancestor.id] ?? 0) + 1;
      }
    }
  }

  return CountriesData(
    visitedRegionsCount: visitedRegions,
    visitedCitiesCount: visitedCities,
    countries: [
      for (final entry in countryMap.entries)
        CountryGroupData(
          countryCode: entry.value.countryCode,
          countryName: entry.value.countryName,
          areaKm2: entry.value.areaKm2,
          citiesCount: citiesPerCountry[entry.key] ?? 0,
          subregions: entry.value.subregions,
        ),
    ],
  );
});

class RegionDetailData {
  const RegionDetailData({
    required this.id,
    required this.name,
    required this.countryName,
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
  final String name;
  final String countryName;
  final int discoveredSubregionsCount;
  final int totalSubregionsCount;
  final double discoveryPercentage;
  final double discoveredAreaKm2;
  final int citiesCount;
  final List<DiscoveryRowItem> subregions;
  final DateTime? firstVisit;
  final DateTime? lastVisit;
}

final regionDetailProvider = FutureProvider.family<RegionDetailData, int>((
  ref,
  regionId,
) async {
  ref.watch(statisticsRevisionProvider);
  final statsStorage = ref.watch(statisticsStorageProvider);
  final regionStorage = ref.watch(regionStorageProvider);

  final region = await regionStorage.findRegionById(regionId);
  final stat = await statsStorage.getRegionStats(regionId);

  final regionName = region?.name ?? '–';
  final percentage = stat?.discoveryPercentage ?? 0.0;
  final areaKm2 = stat != null ? stat.discoveredAreaM2 / 1000000 : 0.0;

  var countryName = '–';
  if (region != null) {
    final ancestors = await regionStorage.getAncestorChain(region.id);
    for (final a in ancestors) {
      if (a.type == RegionType.country) {
        countryName = a.name;
        break;
      }
    }
  }

  final children = await regionStorage.findChildren(regionId);
  final subregions = <DiscoveryRowItem>[];
  var discoveredCount = 0;
  var citiesCount = 0;

  for (final child in children) {
    final childStat = await statsStorage.getRegionStats(child.id);
    final childPercentage = childStat?.discoveryPercentage ?? 0.0;
    if (childStat != null && childStat.discoveredAreaM2 > 0) {
      discoveredCount++;
      if (child.type == RegionType.city) {
        citiesCount++;
      }
    }
    subregions.add(
      DiscoveryRowItem(
        id: child.id,
        name: child.name,
        percentage: childPercentage,
      ),
    );
  }

  return RegionDetailData(
    id: regionId,
    name: regionName,
    countryName: countryName,
    discoveredSubregionsCount: discoveredCount,
    totalSubregionsCount: children.length,
    discoveryPercentage: percentage,
    discoveredAreaKm2: areaKm2,
    citiesCount: citiesCount,
    subregions: subregions,
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
  final String name;
  final String regionName;
  final double discoveryPercentage;
  final double discoveredAreaKm2;
  final List<DiscoveryRowItem> districts;
  final DateTime? firstVisit;
  final DateTime? lastVisit;
}

final cityDetailProvider = FutureProvider.family<CityDetailData, int>((
  ref,
  cityId,
) async {
  ref.watch(statisticsRevisionProvider);
  final statsStorage = ref.watch(statisticsStorageProvider);
  final regionStorage = ref.watch(regionStorageProvider);

  final city = await regionStorage.findRegionById(cityId);
  final stat = await statsStorage.getRegionStats(cityId);

  final cityName = city?.name ?? '–';
  final percentage = stat?.discoveryPercentage ?? 0.0;
  final areaKm2 = stat != null ? stat.discoveredAreaM2 / 1000000 : 0.0;

  var regionName = '–';
  if (city != null) {
    final ancestors = await regionStorage.getAncestorChain(city.id);
    for (final a in ancestors) {
      if (a.type == RegionType.state || a.type == RegionType.county) {
        regionName = a.name;
        break;
      }
    }
    if (regionName == '–') {
      for (final a in ancestors) {
        if (a.type == RegionType.country) {
          regionName = a.name;
          break;
        }
      }
    }
  }

  final children = await regionStorage.findChildren(cityId);
  final districts = <DiscoveryRowItem>[];
  for (final child in children) {
    final childStat = await statsStorage.getRegionStats(child.id);
    districts.add(
      DiscoveryRowItem(
        id: child.id,
        name: child.name,
        percentage: childStat?.discoveryPercentage ?? 0.0,
      ),
    );
  }

  return CityDetailData(
    id: cityId,
    name: cityName,
    regionName: regionName,
    discoveryPercentage: percentage,
    discoveredAreaKm2: areaKm2,
    districts: districts,
    firstVisit: _visitDate(stat?.firstVisitMs),
    lastVisit: _visitDate(stat?.lastVisitMs),
  );
});

DateTime? _visitDate(int? timestampMs) {
  if (timestampMs == null || timestampMs <= 0) return null;
  return DateTime.fromMillisecondsSinceEpoch(timestampMs);
}
