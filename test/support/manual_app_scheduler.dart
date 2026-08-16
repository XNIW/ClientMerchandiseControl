import 'package:client_merchandise_control/core/time/app_scheduler.dart';

final class ManualAppScheduler implements AppScheduler {
  ManualAppScheduler({DateTime? start})
    : _now = (start ?? DateTime.utc(2026)).toUtc();

  DateTime _now;
  var _sequence = 0;
  final List<_ManualScheduledTask> _tasks = [];

  DateTime now() => _now;

  int get activeTaskCount => _tasks.where((task) => task.isActive).length;

  @override
  AppScheduledTask schedule(Duration delay, void Function() callback) {
    if (delay.isNegative) {
      throw ArgumentError.value(delay, 'delay', 'must not be negative');
    }
    final task = _ManualScheduledTask(
      sequence: _sequence++,
      dueAt: _now.add(delay),
      callback: callback,
    );
    _tasks.add(task);
    return task;
  }

  @override
  AppScheduledTask periodic(Duration interval, void Function() callback) {
    if (interval <= Duration.zero) {
      throw ArgumentError.value(interval, 'interval', 'must be positive');
    }
    final task = _ManualScheduledTask(
      sequence: _sequence++,
      dueAt: _now.add(interval),
      callback: callback,
      interval: interval,
    );
    _tasks.add(task);
    return task;
  }

  void advance(Duration duration) {
    if (duration.isNegative) {
      throw ArgumentError.value(duration, 'duration', 'must not be negative');
    }
    final target = _now.add(duration);
    while (true) {
      final due = _nextDueAtOrBefore(target);
      if (due == null) break;
      _now = due.dueAt;
      if (!due.isActive) continue;
      final interval = due.interval;
      if (interval == null) {
        due._active = false;
      } else {
        due.dueAt = due.dueAt.add(interval);
      }
      due.callback();
    }
    _now = target;
    _tasks.removeWhere((task) => !task.isActive);
  }

  _ManualScheduledTask? _nextDueAtOrBefore(DateTime target) {
    _ManualScheduledTask? result;
    for (final task in _tasks) {
      if (!task.isActive || task.dueAt.isAfter(target)) continue;
      if (result == null ||
          task.dueAt.isBefore(result.dueAt) ||
          (task.dueAt == result.dueAt && task.sequence < result.sequence)) {
        result = task;
      }
    }
    return result;
  }
}

final class _ManualScheduledTask implements AppScheduledTask {
  _ManualScheduledTask({
    required this.sequence,
    required this.dueAt,
    required this.callback,
    this.interval,
  });

  final int sequence;
  DateTime dueAt;
  final void Function() callback;
  final Duration? interval;
  bool _active = true;

  @override
  bool get isActive => _active;

  @override
  void cancel() => _active = false;
}
