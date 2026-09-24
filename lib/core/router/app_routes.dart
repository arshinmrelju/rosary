/// Central route path declarations.
abstract final class AppRoutes {
  static const String home = '/';
  static const String today = '/today';
  static const String intention = '/intention';
  static const String reflection = '/reflection';
  static const String settings = '/settings';
  static const String history = '/history';
  static const String reminders = '/reminders';

  /// Parameterised decade path: `/decade/{number}`.
  static const String decade = '/decade';

  static String decadeFor(int number) => '$decade/$number';

  // ----- Admin dashboard -----

  static const String admin = '/admin';
  static const String adminLogin = '/admin/login';
  static const String adminDashboard = '/admin/dashboard';

  // Content
  static const String adminContentToday = '/admin/content/today';
  static const String adminContentCalendar = '/admin/content/calendar';
  static const String adminContentBulk = '/admin/content/bulk';

  /// Parameterised daily content editor: `/admin/content/today/{date}`.
  static const String adminContentDate = '/admin/content/today/:date';

  static String adminContentDateFor(String dateKey) => '$adminContentToday/$dateKey';

  // Prayer wall
  static const String adminPrayerPending = '/admin/prayer/pending';
  static const String adminPrayerPublished = '/admin/prayer/published';

  // Operations
  static const String adminReports = '/admin/reports';
  static const String adminSchedule = '/admin/schedule';
  static const String adminCampaign = '/admin/campaign';
  static const String adminStatistics = '/admin/statistics';
  static const String adminSettings = '/admin/settings';

  /// All admin location strings (used by the shell to highlight the nav).
  static const List<String> adminPages = <String>[
    adminDashboard,
    adminContentToday,
    adminContentCalendar,
    adminContentBulk,
    adminPrayerPending,
    adminPrayerPublished,
    adminReports,
    adminSchedule,
    adminCampaign,
    adminStatistics,
    adminSettings,
  ];
}