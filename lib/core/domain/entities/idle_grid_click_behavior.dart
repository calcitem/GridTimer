/// Defines behavior when clicking on an idle timer grid cell.
enum IdleGridClickBehavior {
  /// Show a dialog with actions (Start, Adjust Time, Cancel).
  /// This is safer and prevents accidental starts (recommended for seniors).
  showDialog,

  /// Directly start the timer.
  /// This is faster but easier to trigger accidentally (better for power users).
  directStart,
}
