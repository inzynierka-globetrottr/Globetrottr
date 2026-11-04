import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/regions/data/region.dart';
import 'package:globetrottr_front/features/regions/data/region_storage.dart';
import 'package:globetrottr_front/features/regions/data/region_type.dart';
import 'package:globetrottr_front/features/statistics/data/statistics_storage.dart';
import 'package:globetrottr_front/features/statistics/data/user_region_stats.dart';
import 'package:globetrottr_front/features/statistics/provider/region_detail_provider.dart';
import 'package:globetrottr_front/features/statistics/provider/statistics_providers.dart';
import 'package:globetrottr_front/features/statistics/screens/stats_routes.dart';

Region _r(
  int id,
  int? parent,
  String name,
  RegionType type, {
  String? code,
  String? en,
  String? pl,
}) => Region(
  id: id,
  parentId: parent,
  name: name,
  nameEn: en,
  namePl: pl,
  type: type,
  code: code,
  totalAreaKm2: 100,
  minLat: 0,
  maxLat: 1,
  minLon: 0,
  maxLon: 1,
);

final _regions = [
  _r(1, null, 'Polska', RegionType.country, code: 'PL', en: 'Poland'),
  _r(2, null, 'Česko', RegionType.country, code: 'CZ', pl: 'Czechy'),
  _r(3, null, 'Atlantis', RegionType.country),
  _r(10, 1, 'Małopolskie', RegionType.state),
  _r(11, 1, 'Mazowieckie', RegionType.state),
  _r(20, 10, 'Kraków', RegionType.county),
  _r(21, 10, 'krakowski', RegionType.county),
  _r(22, 10, 'wielicki', RegionType.county),
  _r(23, 10, 'tatrzański', RegionType.county),
  _r(100, 20, 'Kraków', RegionType.city),
  _r(101, 21, 'Zabierzów', RegionType.city),
  _r(102, 21, 'Skawina', RegionType.city),
  _r(103, 22, 'Niepołomice', RegionType.city),
  _r(1001, 100, 'Stare Miasto', RegionType.district),
  _r(1002, 100, 'Kazimierz', RegionType.district),
  _r(200, 2, 'Jihomoravský kraj', RegionType.state),
  _r(201, 200, 'Brno-město', RegionType.county),
  _r(210, 201, 'Brno', RegionType.city),
];

UserRegionStats _s(int id, double areaKm2, double percent) => UserRegionStats(
  regionId: id,
  discoveredAreaM2: areaKm2 * 1000000,
  discoveryPercentage: percent,
);

final _stats = [
  _s(1, 11.6, 0.004),
  _s(2, 0.5, 0.001),
  _s(3, 0.1, 0.001),
  _s(10, 9.8, 0.06),
  _s(20, 6.9, 7.3),
  _s(21, 0.5, 1.1),
  _s(22, 0.1, 0.4),
  _s(23, 0, 0),
  _s(100, 6.9, 7.3),
  _s(101, 0.3, 1.1),
  _s(102, 0.2, 1.0),
  _s(103, 0.1, 0.4),
  _s(1001, 1.7, 31),
  _s(200, 0.5, 0.01),
  _s(201, 0.5, 0.2),
  _s(210, 0.5, 0.2),
];

class _Regions extends Fake implements RegionStorage {
  @override
  Future<Region?> findRegionById(int id) async =>
      _regions.where((r) => r.id == id).firstOrNull;

  @override
  Future<List<Region>> findChildren(int parentId) async =>
      _regions.where((r) => r.parentId == parentId).toList();

  @override
  Future<List<Region>> getAncestorChain(int regionId) async {
    final chain = <Region>[];
    var current = await findRegionById(regionId);
    while (current != null) {
      chain.add(current);
      final parent = current.parentId;
      current = parent == null ? null : await findRegionById(parent);
    }
    return chain;
  }
}

class _Statistics extends Fake implements StatisticsStorage {
  @override
  Future<List<UserRegionStats>> getAllRegionStats() async => _stats;

  @override
  Future<UserRegionStats?> getRegionStats(int regionId) async =>
      _stats.where((s) => s.regionId == regionId).firstOrNull;
}

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        regionStorageProvider.overrideWithValue(_Regions()),
        statisticsStorageProvider.overrideWithValue(_Statistics()),
      ],
    );
  });

  tearDown(() => container.dispose());

  group('countries', () {
    test('countries come largest first, states hold their cities', () async {
      final data = await container.read(countriesDataProvider.future);

      expect(data.countries.map((c) => c.countryName.local), [
        'Polska',
        'Česko',
        'Atlantis',
      ]);
      final poland = data.countries.first;
      expect(poland.countryCode, 'PL');
      expect(poland.citiesCount, 4);
      expect(poland.states.map((s) => s.name.local), ['Małopolskie']);
      expect(poland.states.single.cities.map((c) => c.name.local), [
        'Kraków',
        'Zabierzów',
        'Skawina',
        'Niepołomice',
      ]);
      expect(data.visitedCitiesCount, 5);
      expect(data.visitedRegionsCount, 2);
    });

    test('a country without a code has no flag code', () async {
      final data = await container.read(countriesDataProvider.future);

      expect(data.countries.last.countryCode, isNull);
    });

    test('country names follow the app language', () async {
      final data = await container.read(countriesDataProvider.future);

      expect(data.countries[1].countryName.of('pl'), 'Czechy');
      expect(data.countries[0].countryName.of('en'), 'Poland');
    });
  });

  group('region detail', () {
    test('a state lists its discovered counties by discovery', () async {
      final data = (await container.read(regionDetailProvider(10).future))!;

      expect(data.subregionKind, RegionType.county);
      expect(data.subregions.map((s) => s.name.local), [
        'Kraków',
        'krakowski',
        'wielicki',
      ]);
      expect(data.subregions[1].details.map((n) => n.local), [
        'Zabierzów',
        'Skawina',
      ]);
      expect(data.discoveredSubregionsCount, 3);
      expect(data.totalSubregionsCount, 4);
      expect(data.citiesCount, 4);
      expect(data.countryName?.local, 'Polska');
    });
  });

  group('city detail', () {
    test('a city lists only its discovered districts', () async {
      final data = (await container.read(cityDetailProvider(100).future))!;

      expect(data.districts.map((d) => d.name.local), ['Stare Miasto']);
      expect(data.regionName?.local, 'Małopolskie');
    });
  });

  group('routes', () {
    test('states and counties open the region screen', () {
      expect(
        statsRouteFor(RegionType.state, 7),
        '/profile/statistics/region/7',
      );
      expect(
        statsRouteFor(RegionType.county, 7),
        '/profile/statistics/region/7',
      );
    });

    test('cities open the city screen', () {
      expect(statsRouteFor(RegionType.city, 9), '/profile/statistics/city/9');
    });

    test('districts and countries open nothing', () {
      expect(statsRouteFor(RegionType.district, 9), isNull);
      expect(statsRouteFor(RegionType.country, 9), isNull);
    });
  });
}
