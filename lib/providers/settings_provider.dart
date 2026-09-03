import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPrefsProvider = FutureProvider<SharedPreferences>((ref) {
  return SharedPreferences.getInstance();
});

final localeProvider =
    StateNotifierProvider<LocaleController, String>((ref) {
  return LocaleController(ref);
});

class LocaleController extends StateNotifier<String> {
  LocaleController(this.ref) : super('en') {
    _load();
  }

  final Ref ref;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('locale') ?? 'en';
  }

  Future<void> setLocale(String code) async {
    state = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', code);
  }
}
