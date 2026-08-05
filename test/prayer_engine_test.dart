import 'package:flutter_test/flutter_test.dart';
import 'package:adhan/adhan.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim/services/settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('Prayer Calculation Engine Unit Tests (100% Offline, Full 16-Method Suite)', () {
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

    test('Method 1: Morocco Ministry of Habous uses correct offline astronomical angles', () async {
      final provider = SettingsProvider();
      await provider.setCalculationMethod('morocco');
      final params = provider.getCalculationParameters();

      expect(params.fajrAngle, equals(19.0));
      expect(params.ishaAngle, equals(17.0));
      expect(params.adjustments.dhuhr, equals(5));
      expect(params.adjustments.maghrib, equals(3));
    });

    test('All 16 Methods Produce Valid Offline Prayer Times (no network required)', () async {
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

    test('Madhab selection (Shafi vs Hanafi) affects Asr calculation', () async {
      final provider = SettingsProvider();
      await provider.setCalculationMethod('mwl');
      final rabatCoords = Coordinates(34.0209, -6.8416);
      final date = DateComponents(2026, 8, 3);

      await provider.setMadhab('shafi');
      expect(provider.madhab, equals('shafi'));
      final shafiParams = provider.getCalculationParameters();
      expect(shafiParams.madhab, equals(Madhab.shafi));
      final shafiTimes = PrayerTimes(rabatCoords, date, shafiParams);

      await provider.setMadhab('hanafi');
      expect(provider.madhab, equals('hanafi'));
      final hanafiParams = provider.getCalculationParameters();
      expect(hanafiParams.madhab, equals(Madhab.hanafi));
      final hanafiTimes = PrayerTimes(rabatCoords, date, hanafiParams);

      // Hanafi Asr (2x shadow length) is always later than or equal to
      // Shafi'i Asr (1x shadow length) for the same date/location.
      expect(
        hanafiTimes.asr.isAfter(shafiTimes.asr) ||
            hanafiTimes.asr.isAtSameMomentAs(shafiTimes.asr),
        isTrue,
      );
    });
  });
}
