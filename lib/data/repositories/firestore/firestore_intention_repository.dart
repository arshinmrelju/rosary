import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/models/prayer_intention.dart';
import '../../firebase/firestore_paths.dart';
import '../intention_repository.dart';

class FirestoreIntentionRepository implements IntentionRepository {
  const FirestoreIntentionRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<List<PrayerIntention>> fetchApproved({int limit = 10}) async {
    final query = await _firestore
        .collection(FirestorePaths.prayerIntentions)
        .where('approved', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return query.docs
        .map((doc) => PrayerIntention.fromMap(doc.id, doc.data()))
        .toList();
  }

  @override
  Future<PrayerIntention> submit(PrayerIntention intention) async {
    final doc = _firestore.collection(FirestorePaths.prayerIntentions).doc();
    final data = intention.toMap();
    await doc.set(data);
    return PrayerIntention.fromMap(doc.id, data);
  }

  @override
  Future<void> incrementPrayerCount(String intentionId) async {
    await _firestore
        .collection(FirestorePaths.prayerIntentions)
        .doc(intentionId)
        .update(<String, dynamic>{'prayerCount': FieldValue.increment(1)});
  }

  @override
  Future<void> approve(String intentionId) async {
    await _firestore
        .collection(FirestorePaths.prayerIntentions)
        .doc(intentionId)
        .update(<String, dynamic>{'approved': true});
  }
}