import 'dart:math' as math;

const double earthRadiusMeters = 6378137.0;

/// Length of one degree of latitude on the Web Mercator sphere.
const double metersPerDegree = 2 * math.pi * earthRadiusMeters / 360;
