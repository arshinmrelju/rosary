import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/models/rosary_schedule_settings.dart';
import '../../firebase/firestore_paths.dart';
import '../schedule_settings_repository.dart';

class FirestoreScheduleSettingsRepository implements ScheduleSettingsRepository {
  const FirestoreScheduleSettingsRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<RosaryScheduleSettings?> fetch() async {
    final snapshot = await _firestore
        .doc(FirestorePaths.rosaryScheduleSetting)
        .get();
    if (!snapshot.exists) return null;
    return RosaryScheduleSettings.fromMap(snapshot.data()!);
  }

  @override
  Future<void> save(RosaryScheduleSettings settings) async {
    await _firestore
        .doc(FirestorePaths.rosaryScheduleSetting)
        .set(settings.toMap());
  }
}