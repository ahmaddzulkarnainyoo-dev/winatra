import 'package:shared_preferences/shared_preferences.dart';

/// Simpan & baca preferensi widget (floating mode / non-floating).
/// Disimpan di SharedPreferences biar ringan, tidak perlu Firestore.
class WidgetPreferenceService {
  Future<bool> isFloatingMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('widget_floating_mode') ?? true; // default: floating
  }

  Future<void> setFloatingMode(bool isFloating) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('widget_floating_mode', isFloating);
  }
}