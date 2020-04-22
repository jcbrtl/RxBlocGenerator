import 'dart:async';

import 'package:logging/logging.dart';
import 'package:rx_bloc_generator/string_extensions.dart';

const Symbol logKey = #buildLog;

final _default = Logger('build.fallback');

/// The log instance for the currently running BuildStep.
///
/// Will be `null` when not running within a build.
Logger get log => Zone.current[logKey] as Logger ?? _default;

logError(String str) {
  final exceptionStr = 'Exception: ';
  String msg = str;
  if (msg.contains(exceptionStr))
    msg = msg.substring(msg.indexOf(exceptionStr) + exceptionStr.length);
  msg = '[ERROR] ' + msg;
  log.severe('\n' + msg.toRedString() + '\n');
}
