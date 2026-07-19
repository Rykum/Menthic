import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oracle_engine/oracle_engine.dart';
import 'package:oracle_store/oracle_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firestore_event_store.dart';
import 'persistent_event_store.dart';
import 'priors_codec.dart';

const kPriorsKey = 'twin_priors_v1';
const kOnboardedKey = 'onboarded';

final _authStateProvider = StreamProvider<fb.User?>((ref) {
  if (Firebase.apps.isEmpty) return Stream<fb.User?>.value(null);
  return fb.FirebaseAuth.instance.authStateChanges();
});

/// Logado com Firebase → eventos sincronizados no Firestore (offline-first
/// pelo cache do SDK). Senão → snapshot local (shared_preferences), como nas
/// levas anteriores. O provider se refaz quando o login muda.
final eventStoreProvider = FutureProvider<EventStore>((ref) async {
  final user = Firebase.apps.isEmpty
      ? null
      : ref.watch(_authStateProvider).valueOrNull;
  if (user != null) {
    return FirestoreEventStore(FirebaseFirestore.instance, user.uid);
  }
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
