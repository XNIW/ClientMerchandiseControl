import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef AppClock = DateTime Function();

abstract interface class AppScheduledTask {
  bool get isActive;

  void cancel();
}

abstract interface class AppScheduler {
  AppScheduledTask schedule(Duration delay, void Function() callback);

  AppScheduledTask periodic(Duration interval, void Function() callback);
}

final appClockProvider = Provider<AppClock>((ref) {
  return () => DateTime.now().toUtc();
});

final appSchedulerProvider = Provider<AppScheduler>((ref) {
  return const TimerAppScheduler();
});

final class TimerAppScheduler implements AppScheduler {
  const TimerAppScheduler();

  @override
  AppScheduledTask schedule(Duration delay, void Function() callback) {
    return _TimerScheduledTask(Timer(delay, callback));
  }

  @override
  AppScheduledTask periodic(Duration interval, void Function() callback) {
    return _TimerScheduledTask(Timer.periodic(interval, (_) => callback()));
  }
}

final class _TimerScheduledTask implements AppScheduledTask {
  const _TimerScheduledTask(this._timer);

  final Timer _timer;

  @override
  bool get isActive => _timer.isActive;

  @override
  void cancel() => _timer.cancel();
}
