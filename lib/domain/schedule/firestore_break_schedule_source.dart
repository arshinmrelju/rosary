import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/firebase/firestore_paths.dart';
import '../models/rosary_schedule_settings.dart';
import 'break_schedule.dart';
import 'break_schedule_source.dart';
import 'default_break_schedule_source.dart';

/// Reads the break schedule from Firestore `settings/rosarySchedule`, which
/// Super Admins edit from the Admin dashboard.
///
/// When the document is missing (first run) or unreadable, it falls back to
/// the built-in default schedule so the app keeps working. Because this is
/// the schedule source wired into the student app, an admin schedule change
/// automatically appears in the student UI on the next load.
class FirestoreBreakScheduleSource implements BreakScheduleSource {
  FirestoreBreakScheduleSource(this._firestore)
      : _fallback = DefaultBreakScheduleSource();

  final FirebaseFirestore _firestore;
  final DefaultBreakScheduleSource _fallback;

  @override
  Future<BreakSchedule> load({DateTime? date}) async {
    try {
      final snapshot = await _firestore
          .doc(FirestorePaths.rosaryScheduleSetting)
          .get();
      if (!snapshot.exists) return await _fallback.load(date: date);
      final settings = RosaryScheduleSettings.fromMap(snapshot.data()!);
      if (!settings.isComplete) return await _fallback.load(date: date);
      return settings.toBreakSchedule();
    } catch (e) {
      return _fallback.load(date: date);
    }
  }
}