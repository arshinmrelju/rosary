import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/models/campaign_settings.dart';
import '../../firebase/firestore_paths.dart';
import '../campaign_repository.dart';

class FirestoreCampaignRepository implements CampaignRepository {
  const FirestoreCampaignRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<CampaignSettings?> fetch() async {
    final snapshot = await _firestore
        .doc(FirestorePaths.campaignSetting)
        .get();
    if (!snapshot.exists) return null;
    return CampaignSettings.fromMap(snapshot.data()!);
  }

  @override
  Future<void> save(CampaignSettings settings) async {
    await _firestore
        .doc(FirestorePaths.campaignSetting)
        .set(settings.toMap());
  }
}