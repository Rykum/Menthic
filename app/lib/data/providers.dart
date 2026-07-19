import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oracle_engine/oracle_engine.dart';
import 'package:oracle_store/oracle_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'persistent_event_store.dart';
import 'priors_codec.dart';

const kPriorsKey = 'twin_priors_v1';
const kOnboardedKey = 'onboarded';

final eventStoreProvider = FutureProvider<EventStore>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return PersistentEventStore.open(prefs);
});

/// Persistência dos priors do twin e da flag de onboarding.
class PriorsRepo {
  Future<TraitPriors> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(kPriorsKey);
    if (raw == null) return TraitPriors.neutral;
    return priorsFromJson((jsonDecode(raw) as Map).cast<String, dynamic>());
  }

  Future<void> save(TraitPriors p) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kPriorsKey, jsonEncode(priorsToJson(p)));
  }

  Future<bool> onboarded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(kOnboardedKey) ?? false;
  }

  Future<void> setOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kOnboardedKey, true);
  }
}

final priorsRepoProvider = Provider<PriorsRepo>((ref) => PriorsRepo());
