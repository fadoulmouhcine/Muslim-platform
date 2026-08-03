import 'package:flutter_test/flutter_test.dart';
import 'package:adhan/adhan.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim/services/settings_provider.dart';
import 'package:muslim/services/official_prayer_times_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('Prayer Calculation Engine Unit Tests (Full 16-Method Suite)', () {
    final formatter = DateFormat('HH:mm');

    final allMethods = [
      'morocco',
      'karachi',
      'isna',
      'mwl',
      'egypt',
      'umm_al_qura',
      'france',
      'algeria',
      'tunisia',
      'kuwait',
      'paris_mosque',
      'uae',
      'palestine',
      'turkey',
      'belgium',
      'igmg_germany',
    ];

    test('All 16 Methods Map to Valid Aladhan MethodConfigs', () {
      for (final key in allMethods) {
        final config = OfficialPrayerTimesService.getMethodConfig(key);
        expect(config.aladhanId, greaterThan(0));
        expect(config.notes, isNotEmpty);
      }
    });

    test('Method 1: Morocco Ministry of Habous (Method 21)', () async {
      final provider = SettingsProvider();
      await provider.setCalculationMethod('morocco');
      final params = provider.getCalculationParameters();
      final config = OfficialPrayerTimesService.getMethodConfig('morocco');

      expect(config.aladhanId, equals(21));
      expect(config.tune, equals("0,0,0,5,0,3,0,0,0"));
      expect(params.fajrAngle, equals(19.0));
      expect(params.ishaAngle, equals(17.0));
      expect(params.adjustments.dhuhr, equals(5));
      expect(params.adjustments.maghrib, equals(3));
    });

    test('All 16 Methods Produce Valid Offline Prayer Times', () async {
      final provider = SettingsProvider();
      final rabatCoords = Coordinates(34.0209, -6.8416);
      final date = DateComponents(2026, 8, 3);

      for (final key in allMethods) {
        await provider.setCalculationMethod(key);
        final params = provider.getCalculationParameters();
        final prayerTimes = PrayerTimes(rabatCoords, date, params);

        expect(formatter.format(prayerTimes.fajr), isNotEmpty);
        expect(prayerTimes.dhuhr, isNotNull);
        expect(prayerTimes.asr, isNotNull);
        expect(prayerTimes.maghrib, isNotNull);
        expect(prayerTimes.isha, isNotNull);
      }
    });
  });
}
