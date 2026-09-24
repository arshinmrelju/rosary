import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../features/admin/presentation/admin_session.dart';
import '../core/config/app_config.dart';
import '../domain/schedule/break_schedule_source.dart';
import '../domain/schedule/default_break_schedule_source.dart';
import '../domain/schedule/firestore_break_schedule_source.dart';
import 'auth/auth_service.dart';
import 'auth/firebase_auth_service.dart';
import 'mock/mock_admin_store.dart';
import 'mock/mock_community.dart';
import 'mock/mock_repositories.dart';
import 'notifications/local_notification_service.dart';
import 'notifications/notification_service.dart';
import 'notifications/notification_settings_store.dart';
import 'offline/cached_break_schedule_source.dart';
import 'offline/cached_daily_content_repository.dart';
import 'offline/local_cache.dart';
import 'offline/network_status.dart';
import 'offline/offline_participation_repository.dart';
import 'repositories/admin_content_repository.dart';
import 'repositories/admin_log_repository.dart';
import 'repositories/admin_stats_repository.dart';
import 'repositories/admin_users_repository.dart';
import 'repositories/announcements_repository.dart';
import 'repositories/campaign_repository.dart';
import 'repositories/daily_content_repository.dart';
import 'repositories/firestore/firestore_admin_content_repository.dart';
import 'repositories/firestore/firestore_admin_log_repository.dart';
import 'repositories/firestore/firestore_admin_stats_repository.dart';
import 'repositories/firestore/firestore_admin_users_repository.dart';
import 'repositories/firestore/firestore_announcements_repository.dart';
import 'repositories/firestore/firestore_campaign_repository.dart';
import 'repositories/firestore/firestore_daily_content_repository.dart';
import 'repositories/firestore/firestore_intention_repository.dart';
import 'repositories/firestore/firestore_moderation_repository.dart';
import 'repositories/firestore/firestore_participation_repository.dart';
import 'repositories/firestore/firestore_reports_repository.dart';
import 'repositories/firestore/firestore_schedule_settings_repository.dart';
import 'repositories/firestore/firestore_stats_repository.dart';
import 'repositories/firestore/firestore_user_repository.dart';
import 'repositories/intention_repository.dart';
import 'repositories/moderation_repository.dart';
import 'repositories/participation_repository.dart';
import 'repositories/reports_repository.dart';
import 'repositories/schedule_settings_repository.dart';
import 'repositories/stats_repository.dart';
import 'repositories/user_repository.dart';

/// Composition root: builds concrete services/repositories for the runtime
/// mode chosen by [AppConfig].
///
/// Everything a feature needs is available here; screens never construct
/// Firebase objects directly.
class AppDependencies {
  AppDependencies({
    required this.authService,
    required this.userRepository,
    required this.dailyContentRepository,
    required this.participationRepository,
    required this.intentionRepository,
    required this.statsRepository,
    required this.breakScheduleSource,
    required this.networkStatus,
    required this.notificationService,
    required this.notificationSettingsStore,
    required this.adminSession,
    required this.adminContentRepository,
    required this.moderationRepository,
    required this.reportsRepository,
    required this.campaignRepository,
    required this.scheduleSettingsRepository,
    required this.announcementsRepository,
    required this.adminStatsRepository,
    required this.adminLogRepository,
    required this.adminUsersRepository,
  });

  final AuthService authService;
  final UserRepository userRepository;
  final DailyContentRepository dailyContentRepository;
  final ParticipationRepository participationRepository;
  final IntentionRepository intentionRepository;
  final StatsRepository statsRepository;
  final BreakScheduleSource breakScheduleSource;

  /// Connectivity observer (defaults online; harmless on unsupported hosts).
  final NetworkStatus networkStatus;

  /// Local notification scheduling (no-ops on web / unsupported platforms).
  final NotificationService notificationService;

  /// Persisted reminder preferences.
  final NotificationSettingsStore notificationSettingsStore;

  // ----- Admin dashboard -----

  /// Holds the current admin session (Google identity + role).
  final AdminSession adminSession;

  final AdminContentRepository adminContentRepository;
  final ModerationRepository moderationRepository;
  final ReportsRepository reportsRepository;
  final CampaignRepository campaignRepository;
  final ScheduleSettingsRepository scheduleSettingsRepository;
  final AnnouncementsRepository announcementsRepository;
  final AdminStatsRepository adminStatsRepository;
  final AdminLogRepository adminLogRepository;
  final AdminUsersRepository adminUsersRepository;

  /// Whether the stack is talking to Firebase or serving mock data.
  final ValueNotifier<bool> isUsingFirebase = ValueNotifier<bool>(false);

  static Future<AppDependencies> create() async {
    final config = AppConfig.instance;
    final useFirebase = config.canUseFirebase;

    // Shared services that exist in both modes.
    final cache = await LocalCache.create();
    final networkStatus = NetworkStatus();
    final notificationSettingsStore = await NotificationSettingsStore.create();
    final notificationService = LocalNotificationService();

    AppDependencies deps;
    if (useFirebase) {
      final firestore = FirebaseFirestore.instance;
      final authService = FirebaseAuthService();
      final adminUsers = FirestoreAdminUsersRepository(firestore);
      deps = AppDependencies(
        authService: authService,
        userRepository: FirestoreUserRepository(firestore),
        dailyContentRepository: _cacheContent(
          FirestoreDailyContentRepository(firestore),
          cache,
        ),
        participationRepository: _cacheParticipation(
          FirestoreParticipationRepository(firestore),
          cache,
        ),
        intentionRepository: FirestoreIntentionRepository(firestore),
        statsRepository: FirestoreStatsRepository(firestore),
        breakScheduleSource: _cacheSchedule(
          FirestoreBreakScheduleSource(firestore),
          cache,
        ),
        networkStatus: networkStatus,
        notificationService: notificationService,
        notificationSettingsStore: notificationSettingsStore,
        adminContentRepository: FirestoreAdminContentRepository(firestore),
        moderationRepository: FirestoreModerationRepository(firestore),
        reportsRepository: FirestoreReportsRepository(firestore),
        campaignRepository: FirestoreCampaignRepository(firestore),
        scheduleSettingsRepository: FirestoreScheduleSettingsRepository(firestore),
        announcementsRepository: FirestoreAnnouncementsRepository(firestore),
        adminStatsRepository: FirestoreAdminStatsRepository(firestore),
        adminLogRepository: FirestoreAdminLogRepository(firestore),
        adminUsersRepository: adminUsers,
        adminSession: AdminSession(
          adminUsersRepository: adminUsers,
          authService: authService,
          firebaseEnabled: true,
        ),
      );
    } else {
      // One shared community ledger keeps the mock statistics consistent
      // across participation, intentions and stats reads.
      final communityStore = MockCommunityStore();
      final adminStore = MockAdminStore();
      final adminUsers = MockAdminUsersRepository(adminStore);
      const authService = GuestAuthService();
      deps = AppDependencies(
        authService: authService,
        userRepository: MockUserRepository(),
        dailyContentRepository: _cacheContent(
          MockDailyContentRepository(),
          cache,
        ),
        participationRepository: _cacheParticipation(
          await MockParticipationRepository.create(store: communityStore),
          cache,
        ),
        intentionRepository: await MockIntentionRepository.create(
          store: communityStore,
        ),
        statsRepository: MockStatsRepository(communityStore),
        breakScheduleSource: _cacheSchedule(
          DefaultBreakScheduleSource(),
          cache,
        ),
        networkStatus: networkStatus,
        notificationService: notificationService,
        notificationSettingsStore: notificationSettingsStore,
        adminContentRepository: MockAdminContentRepository(adminStore),
        moderationRepository: MockModerationRepository(adminStore),
        reportsRepository: MockReportsRepository(adminStore),
        campaignRepository: MockCampaignRepository(adminStore),
        scheduleSettingsRepository: MockScheduleSettingsRepository(adminStore),
        announcementsRepository: MockAnnouncementsRepository(adminStore),
        adminStatsRepository: MockAdminStatsRepository(adminStore, communityStore),
        adminLogRepository: MockAdminLogRepository(adminStore),
        adminUsersRepository: adminUsers,
        adminSession: AdminSession(
          adminUsersRepository: adminUsers,
          authService: authService,
          firebaseEnabled: false,
        ),
      );
    }
    deps.isUsingFirebase.value = useFirebase;
    return deps;
  }

  static ParticipationRepository _cacheParticipation(
    ParticipationRepository delegate,
    LocalCache? cache,
  ) =>
      cache == null ? delegate : OfflineParticipationRepository(delegate, cache);

  static DailyContentRepository _cacheContent(
    DailyContentRepository delegate,
    LocalCache? cache,
  ) =>
      cache == null ? delegate : CachedDailyContentRepository(delegate, cache);

  static BreakScheduleSource _cacheSchedule(
    BreakScheduleSource delegate,
    LocalCache? cache,
  ) =>
      cache == null ? delegate : CachedBreakScheduleSource(delegate, cache);
}