import '../../domain/models/campaign_settings.dart';

/// Campaign configuration (`settings/campaign`).
///
/// Read by both the student app (to show the pause message) and the admin
/// dashboard (to edit it). Writing is restricted to Super Admins by rules.
abstract interface class CampaignRepository {
  Future<CampaignSettings?> fetch();

  Future<void> save(CampaignSettings settings);
}