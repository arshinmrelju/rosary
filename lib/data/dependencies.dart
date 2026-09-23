import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/config/app_config.dart';
import '../domain/schedule/break_schedule_source.dart';
import '../domain/schedule/default_break_schedule_source.dart';
import 'auth/auth_service.dart';
import 'auth/firebase_auth_service.dart';
import 'mock/mock_repositories.dart';
import 'repositories/daily_content_repository.dart';
import 'repositories/firestore/firestore_daily_content_repository.dart';
import 'repositories/firestore/firestore_intention_repository.dart';
import 'repositories/firestore/firestore_participation_repository.dart';
import 'repositories/firestore/firestore_stats_repository.dart';
import 'repositories/firestore/firestore_user_repository.dart';
import 'repositories/intention_repository.dart';
import 'repositories/participation_repository.dart';
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
  });

  final AuthService authService;
  final UserRepository userRepository;
  final DailyContentRepository dailyContentRepository;
  final ParticipationRepository participationRepository;
  final IntentionRepository intentionRepository;
  final StatsRepository statsRepository;
  final BreakScheduleSource breakScheduleSource;

  /// Whether the stack is talking to Firebase or serving mock data.
  final ValueNotifier<bool> isUsingFirebase = ValueNotifier<bool>(false);

  static Future<AppDependencies> create() async {
    final config = AppConfig.instance;
    final useFirebase = config.canUseFirebase;

    AppDependencies deps;
    if (useFirebase) {
      final firestore = FirebaseFirestore.instance;
      deps = AppDependencies(
        authService: FirebaseAuthService(),
        userRepository: FirestoreUserRepository(firestore),
        dailyContentRepository: FirestoreDailyContentRepository(firestore),
        participationRepository: FirestoreParticipationRepository(firestore),
        intentionRepository: FirestoreIntentionRepository(firestore),
        statsRepository: FirestoreStatsRepository(firestore),
        breakScheduleSource: DefaultBreakScheduleSource(),
      );
    } else {
      deps = AppDependencies(
        authService: const GuestAuthService(),
        userRepository: MockUserRepository(),
        dailyContentRepository: MockDailyContentRepository(),
        participationRepository: MockParticipationRepository(),
        intentionRepository: MockIntentionRepository(),
        statsRepository: MockStatsRepository(),
        breakScheduleSource: DefaultBreakScheduleSource(),
      );
    }
    deps.isUsingFirebase.value = useFirebase;
    return deps;
  }
}