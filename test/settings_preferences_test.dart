import 'package:flutter_test/flutter_test.dart';
import 'package:mdlovfimusic/ui/screens/Settings/settings_preferences.dart';

void main() {
  test('uses the mobile default only when no preference is stored', () {
    expect(
      resolveBottomNavBarPreference(isDesktop: false, storedValue: null),
      isTrue,
    );
  });

  test('restores a saved mobile preference instead of overwriting it', () {
    expect(
      resolveBottomNavBarPreference(isDesktop: false, storedValue: false),
      isFalse,
    );
    expect(
      resolveBottomNavBarPreference(isDesktop: false, storedValue: true),
      isTrue,
    );
  });

  test('desktop keeps the desktop navigation layout regardless of stored value', () {
    expect(
      resolveBottomNavBarPreference(isDesktop: true, storedValue: true),
      isFalse,
    );
    expect(
      resolveBottomNavBarPreference(isDesktop: true, storedValue: false),
      isFalse,
    );
  });
}
