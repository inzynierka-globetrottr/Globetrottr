import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/features/regions/data/region_type.dart';
import 'package:globetrottr_front/features/statistics/provider/statistics_providers.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/country_accordion_card.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/stats_discovery_card.dart';

class CountryGroupData {
  const CountryGroupData({
    required this.countryCode,
    required this.countryName,
    required this.subtitle,
    required this.subregions,
  });

  final String countryCode;
  final String countryName;
  final String subtitle;
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
  final statsStorage = ref.watch(statisticsStorageProvider);
  final regionStorage = ref.watch(regionStorageProvider);

  final allStats = await statsStorage.getAllRegionStats();

  var visitedRegions = 0;
  var visitedCities = 0;
  final countryMap = <int, CountryGroupData>{};

  for (final stat in allStats) {
    final region = await regionStorage.findRegionById(stat.regionId);
    if (region == null) continue;

    if (region.type == RegionType.state) {
      visitedRegions++;
    } else if (region.type == RegionType.city) {
      visitedCities++;
    } else if (region.type == RegionType.country) {
      final children = await regionStorage.findChildren(region.id);
      final subregions = children
          .map((c) => SubregionItem(id: c.id, name: c.name))
          .toList();
      countryMap[region.id] = CountryGroupData(
        countryCode: region.code ?? 'PL',
        countryName: region.name,
        subtitle: '${(stat.discoveredAreaM2 / 1000000).toStringAsFixed(1)} km²',
        subregions: subregions,
      );
    }
  }

  // TODO(data): Return mockup placeholder countries when storage is empty
  if (countryMap.isEmpty) {
    return const CountriesData(
      visitedRegionsCount: 8,
      visitedCitiesCount: 12,
      countries: [
        CountryGroupData(
          countryCode: 'PL',
          countryName: 'Polska',
          subtitle: '11,6 km² · 9 miast',
          subregions: [
            SubregionItem(id: 1, name: 'Małopolskie'),
            SubregionItem(id: 2, name: 'Mazowieckie'),
            SubregionItem(id: 3, name: 'Pomorskie'),
            SubregionItem(id: 4, name: 'Dolnośląskie'),
            SubregionItem(id: 5, name: 'Podkarpackie'),
          ],
        ),
        CountryGroupData(
          countryCode: 'CZ',
          countryName: 'Czechy',
          subtitle: '0,42 km² · 2 miasta',
          subregions: [
            SubregionItem(id: 6, name: 'Moravskoslezský kraj'),
          ],
        ),
        CountryGroupData(
          countryCode: 'SK',
          countryName: 'Słowacja',
          subtitle: '0,18 km² · 1 miasto',
          subregions: [
            SubregionItem(id: 7, name: 'Žilinský kraj'),
            SubregionItem(id: 8, name: 'Prešovský kraj'),
          ],
        ),
      ],
    );
  }

  return CountriesData(
    visitedRegionsCount: visitedRegions,
    visitedCitiesCount: visitedCities,
    countries: countryMap.values.toList(),
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
    required this.streetsCount,
    required this.subregions,
    required this.firstVisit,
    required this.lastVisit,
    required this.highestPoint,
  });

  final int id;
  final String name;
  final String countryName;
  final int discoveredSubregionsCount;
  final int totalSubregionsCount;
  final double discoveryPercentage;
  final double discoveredAreaKm2;
  final int citiesCount;
  final int streetsCount;
  final List<DiscoveryRowItem> subregions;
  final String firstVisit;
  final String lastVisit;
  final String highestPoint;
}

final regionDetailProvider = FutureProvider.family<RegionDetailData, int>((
  ref,
  regionId,
) async {
  final statsStorage = ref.watch(statisticsStorageProvider);
  final regionStorage = ref.watch(regionStorageProvider);

  final region = await regionStorage.findRegionById(regionId);
  final stat = await statsStorage.getRegionStats(regionId);

  // TODO(data): Return mockup placeholder data for the region when not populated yet
  final regionName = region?.name ?? 'Małopolskie';
  final percentage = stat?.discoveryPercentage ?? 0.06;
  final areaKm2 = stat != null ? stat.discoveredAreaM2 / 1000000 : 9.8;

  return RegionDetailData(
    id: regionId,
    name: regionName,
    countryName: 'Polska',
    discoveredSubregionsCount: 4,
    totalSubregionsCount: 22,
    discoveryPercentage: percentage,
    discoveredAreaKm2: areaKm2,
    citiesCount: 4,
    streetsCount: 386,
    subregions: const [
      DiscoveryRowItem(name: 'Kraków', percentage: 7.3),
      DiscoveryRowItem(name: 'krakowski', percentage: 1.1),
      DiscoveryRowItem(name: 'wielicki', percentage: 0.4),
    ],
    firstVisit: '14 marca 2026',
    lastVisit: 'Dziś',
    highestPoint: '383 m · Kopiec Krakusa',
  );
});

class CityDetailData {
  const CityDetailData({
    required this.id,
    required this.name,
    required this.regionName,
    required this.discoveryPercentage,
    required this.discoveredAreaKm2,
    required this.streetsCount,
    required this.routesCount,
    required this.districts,
    required this.firstVisit,
    required this.lastVisit,
    required this.mostVisitedPlace,
    required this.timeSpent,
  });

  final int id;
  final String name;
  final String regionName;
  final double discoveryPercentage;
  final double discoveredAreaKm2;
  final int streetsCount;
  final int routesCount;
  final List<DiscoveryRowItem> districts;
  final String firstVisit;
  final String lastVisit;
  final String mostVisitedPlace;
  final String timeSpent;
}

final cityDetailProvider = FutureProvider.family<CityDetailData, int>((
  ref,
  cityId,
) async {
  final statsStorage = ref.watch(statisticsStorageProvider);
  final regionStorage = ref.watch(regionStorageProvider);

  final city = await regionStorage.findRegionById(cityId);
  final stat = await statsStorage.getRegionStats(cityId);

  // TODO(data): Return mockup placeholder data for the city when not populated yet
  final cityName = city?.name ?? 'Kraków';
  final percentage = stat?.discoveryPercentage ?? 7.3;
  final areaKm2 = stat != null ? stat.discoveredAreaM2 / 1000000 : 6.9;

  return CityDetailData(
    id: cityId,
    name: cityName,
    regionName: 'Małopolskie',
    discoveryPercentage: percentage,
    discoveredAreaKm2: areaKm2,
    streetsCount: 286,
    routesCount: 19,
    districts: const [
      DiscoveryRowItem(name: 'Stare Miasto', percentage: 31.0),
      DiscoveryRowItem(name: 'Kazimierz', percentage: 24.0),
      DiscoveryRowItem(name: 'Dębniki', percentage: 18.0),
      DiscoveryRowItem(name: 'Podgórze', percentage: 11.0),
    ],
    firstVisit: '14 marca 2026',
    lastVisit: 'Dziś',
    mostVisitedPlace: 'Bulwary Wiślane',
    timeSpent: '46 h',
  );
});
