import 'package:latlong2/latlong.dart';

class RegionBoundary {
  final String name;
  final List<List<LatLng>> polygons;
  final double bufferZoneKm;

  RegionBoundary({
    required this.name,
    required this.polygons,
    this.bufferZoneKm = 50,
  });
}
