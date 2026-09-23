import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/formatters.dart';
import '../../../domain/models/day_participation.dart';
import '../../firebase/firestore_paths.dart';
import '../participation_repository.dart';

class FirestoreParticipationRepository implements ParticipationRepository {
  const FirestoreParticipationRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<DayParticipation> fetch(String userId, DateTime date) async {
    final doc = _firestore.doc(
      FirestorePaths.participationDay(userId, dateKey(date)),
    );
    final snapshot = await doc.get();
    if (!snapshot.exists) return DayParticipation.empty(date);
    return DayParticipation.fromMap(snapshot.data()!);
  }

  @override
  Future<DayParticipation> completeDecade(
    String userId,
    DateTime date,
    int decadeNumber,
  ) async {
    final current = await fetch(userId, date);
    final updated = DayParticipation(
      date: current.date,
      decade1: decadeNumber == 1 || current.decade1,
      decade2: decadeNumber == 2 || current.decade2,
      decade3: decadeNumber == 3 || current.decade3,
      decade4: decadeNumber == 4 || current.decade4,
      decade5: decadeNumber == 5 || current.decade5,
      lastUpdated: DateTime.now(),
    );
    await save(userId, updated);
    return updated;
  }

  @override
  Future<void> save(String userId, DayParticipation participation) async {
    await _firestore
        .doc(FirestorePaths.participationDay(userId, participation.date))
        .set(participation.toMap());
  }
}