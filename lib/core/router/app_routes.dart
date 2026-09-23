/// Central route path declarations.
abstract final class AppRoutes {
  static const String home = '/';
  static const String today = '/today';
  static const String intention = '/intention';
  static const String progress = '/progress';
  static const String settings = '/settings';

  /// Parameterised decade path: `/decade/{number}`.
  static const String decade = '/decade';

  static String decadeFor(int number) => '$decade/$number';
}