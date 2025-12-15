import 'dart:async';

/// Debouncer for auto-save functionality
/// Delays execution until user stops making changes
class SaveDebouncer {
  final Duration delay;
  Timer? _timer;

  SaveDebouncer({this.delay = const Duration(milliseconds: 500)});

  /// Run action after delay, canceling previous calls
  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// Cancel pending action
  void cancel() {
    _timer?.cancel();
  }

  /// Dispose of resources
  void dispose() {
    _timer?.cancel();
  }
}
