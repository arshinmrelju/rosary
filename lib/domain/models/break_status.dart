/// Lifecycle of a break slot during a college day.
enum BreakStatus {
  /// The break clock time has passed and the decade is not completed.
  missed,

  /// The break time has passed and the decade was completed.
  completed,

  /// The break is happening now (current time window).
  active,

  /// The break has not started yet.
  upcoming,
}