import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim/services/settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Location-Aware Automatic Calculation Method Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('1. Country ISO Mapping & Fallback to MWL', () {
      expect(SettingsProvider.resolveMethodForCountry('MA'), equals('morocco'));
      expect(SettingsProvider.resolveMethodForCountry('SA'),
          equals('umm_al_qura'));
      expect(SettingsProvider.resolveMethodForCountry('EG'), equals('egypt'));
      expect(SettingsProvider.resolveMethodForCountry('DZ'), equals('algeria'));
      expect(SettingsProvider.resolveMethodForCountry('TN'), equals('tunisia'));
      expect(SettingsProvider.resolveMethodForCountry('KW'), equals('kuwait'));
      expect(SettingsProvider.resolveMethodForCountry('TR'), equals('turkey'));
      expect(SettingsProvider.resolveMethodForCountry('PK'), equals('karachi'));
      expect(SettingsProvider.resolveMethodForCountry('US'), equals('isna'));
      expect(SettingsProvider.resolveMethodForCountry('CA'), equals('isna'));
      expect(SettingsProvider.resolveMethodForCountry('FR'), equals('france'));
      expect(SettingsProvider.resolveMethodForCountry('AE'), equals('uae'));
      expect(
          SettingsProvider.resolveMethodForCountry('PS'), equals('palestine'));
      expect(SettingsProvider.resolveMethodForCountry('BE'), equals('belgium'));
      expect(SettingsProvider.resolveMethodForCountry('DE'),
          equals('igmg_germany'));

      // Fallback for unmapped ISO codes
      expect(SettingsProvider.resolveMethodForCountry('XX'), equals('mwl'));
      expect(SettingsProvider.resolveMethodForCountry(null), equals('mwl'));
    });

    test('2. Manual Selection Locks Auto-Mode (isAutoMethod = false)',
        () async {
      final provider = SettingsProvider();
      await provider.loadSettings();

      expect(provider.isAutoMethod, isTrue);

      // User manually picks 'egypt'
      await provider.setCalculationMethod('egypt', isUserAction: true);

      expect(provider.calculationMethod, equals('egypt'));
      expect(provider.isAutoMethod, isFalse);

      // A location check for Saudi Arabia should NOT override the user's manual choice
      final didSwitch = await provider.resolveLocationMethod(countryCode: 'SA');
      expect(didSwitch, isFalse);
      expect(provider.calculationMethod, equals('egypt'));
    });

    test('3. Travel Debounce Requires 2 Consecutive Checks Before Auto-Switch',
        () async {
      final provider = SettingsProvider();
      await provider.loadSettings();

      // Initial country set to Morocco
      await provider.resolveLocationMethod(countryCode: 'MA');
      expect(provider.calculationMethod, equals('morocco'));

      // Check 1: User travels to Saudi Arabia (1st check -> debounce returns false)
      final check1 = await provider.resolveLocationMethod(countryCode: 'SA');
      expect(check1, isFalse);
      expect(provider.calculationMethod, equals('morocco'));

      // Check 2: User still in Saudi Arabia (2nd check -> auto-switch to umm_al_qura)
      final check2 = await provider.resolveLocationMethod(countryCode: 'SA');
      expect(check2, isTrue);
      expect(provider.calculationMethod, equals('umm_al_qura'));
      expect(provider.autoSwitchNoticeMessage, contains('السعودية'));
    });

    test('4. Revert Action Restores Previous Method and Locks Auto-Mode',
        () async {
      final provider = SettingsProvider();
      await provider.loadSettings();

      // Start in Morocco
      await provider.resolveLocationMethod(countryCode: 'MA');
      expect(provider.calculationMethod, equals('morocco'));

      // Auto-switch to Saudi Arabia after 2 checks
      await provider.resolveLocationMethod(countryCode: 'SA');
      await provider.resolveLocationMethod(countryCode: 'SA');
      expect(provider.calculationMethod, equals('umm_al_qura'));

      // User taps "Keep previous method" (Revert)
      await provider.revertAutoSwitch();

      expect(provider.calculationMethod, equals('morocco'));
      expect(provider.isAutoMethod, isFalse);
      expect(provider.autoSwitchNoticeMessage, isNull);
    });

    test(
        '5. Eager Upgrade from Low-Confidence Locale Guess to Authoritative GPS Bypasses Debounce',
        () async {
      final provider = SettingsProvider();
      await provider.loadSettings();

      // Step 1: Initial resolution from device locale fallback (e.g. en_US -> US -> isna)
      final localeCheck = await provider.resolveLocationMethod(
          countryCode: 'US', isGpsSource: false);
      expect(localeCheck, isTrue);
      expect(provider.calculationMethod, equals('isna'));
      expect(provider.lastResolutionSource, equals('locale'));

      // Step 2: Real GPS fix resolves to Morocco (isGpsSource = true).
      // Must EAGERLY upgrade on 1st check without waiting for 2-step debounce!
      final gpsCheck = await provider.resolveLocationMethod(
          countryCode: 'MA', isGpsSource: true);
      expect(gpsCheck, isTrue);
      expect(provider.calculationMethod, equals('morocco'));
      expect(provider.lastResolutionSource, equals('gps'));
    });

    test(
        '6. Confirmed GPS to GPS Travel Debounce Still Requires 2 Consecutive Checks',
        () async {
      final provider = SettingsProvider();
      await provider.loadSettings();

      // Step 1: Confirmed GPS location in Morocco
      await provider.resolveLocationMethod(
          countryCode: 'MA', isGpsSource: true);
      expect(provider.calculationMethod, equals('morocco'));
      expect(provider.lastResolutionSource, equals('gps'));

      // Step 2: User travels to Saudi Arabia (1st GPS check -> debounced)
      final gpsTravel1 = await provider.resolveLocationMethod(
          countryCode: 'SA', isGpsSource: true);
      expect(gpsTravel1, isFalse);
      expect(provider.calculationMethod, equals('morocco'));

      // Step 3: 2nd GPS check in Saudi Arabia -> auto-switch committed
      final gpsTravel2 = await provider.resolveLocationMethod(
          countryCode: 'SA', isGpsSource: true);
      expect(gpsTravel2, isTrue);
      expect(provider.calculationMethod, equals('umm_al_qura'));
    });
  });
}
