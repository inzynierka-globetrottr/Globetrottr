enum RegionType {
  country,
  state,
  county,
  city,
  district;

  static RegionType fromString(String value) {
    return RegionType.values.firstWhere(
      (t) => t.name.toLowerCase() == value.toLowerCase(),
      orElse: () => RegionType.city,
    );
  }
}
