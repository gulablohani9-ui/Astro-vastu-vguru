import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:jyotish/jyotish.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:astro_vastu_report/main.dart' show cuspZoneText;

void main() {
  test('Astro-Vastu 4 degree cusp orb maps both adjacent zones', () {
    expect(cuspZoneText(30 * 2 + 28, false), 'North-North-West + North-North-East');
    expect(cuspZoneText(30 * 2 + 10, false), 'North-North-West');
  });

  test('Swiss Ephemeris calculates a chart and Vimshottari periods', () async {
    tzdata.initializeTimeZones();
    final j = Jyotish();
    final ephePath = Directory('assets/ephe').absolute.path;
    await j.initialize(ephemerisPath: ephePath);
    final birthZone = tz.getLocation('Asia/Kolkata');
    final local = tz.TZDateTime(birthZone, 1983, 6, 30, 1, 19);
    final chart = await j.calculateVedicChart(
      dateTime: local.toUtc(),
      location: GeographicLocation(
        latitude: 26.2389,
        longitude: 73.0243,
        timezone: 'Asia/Kolkata',
      ),
      houseSystem: 'P',
      flags: CalculationFlags.kp(),
    );
    final dasha = await j.getVimshottariDasha(natalChart: chart);
    expect(chart.houses.cusps, hasLength(12));
    expect(chart.planets, isNotEmpty);
    expect(chart.ascendant, inInclusiveRange(0, 360));
    expect(dasha.birthNakshatra, isNotEmpty);
    expect(dasha.allMahadashas, isNotEmpty);
    j.dispose();
  });
}
