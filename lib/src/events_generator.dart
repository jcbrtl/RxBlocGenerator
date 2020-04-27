import 'package:analyzer/dart/element/element.dart';
import 'package:rx_bloc/annotation/rx_bloc_annotations.dart';
import 'package:rx_bloc_generator/utilities/utilities.dart';
import 'package:source_gen/source_gen.dart';

import 'package:rx_bloc_generator/utilities/string_extensions.dart';

final _eventAnnotationChecker = TypeChecker.fromRuntime(RxBlocEvent);

class EventsGenerator {
  StringBuffer _stringBuffer = StringBuffer();
  ClassElement _eventsClass;
  EventsGenerator(this._eventsClass);

  void _writeln([Object obj]) => _stringBuffer.writeln(obj);
  void _write([Object obj]) => _stringBuffer.write(obj);

  String generate() {
    _writeln("\n\n  ///region Events");
    _writeln("\n");
    _writeln(_generateEvents());
    _writeln("\n  ///endregion Events");

    return _stringBuffer.toString();
  }

  String _generateEvents() =>
      _eventsClass.methods.checkForNonAbstractEvents().mapToEvents().join('\n');
}

extension _CheckingEvents on List<MethodElement> {
  List<MethodElement> checkForNonAbstractEvents() {
    this.forEach((method) {
      if (!method.isAbstract)
        logError(
            'Event \'${method.definition}\' should not contain a body definition.');
    });
    return this;
  }
}

extension _MapToEvents on Iterable<MethodElement> {
  Iterable<String> mapToEvents() => map((method) => '''
  ///region ${method.name}

  final _\$${method.name}Event = ${method.streamType};
  @override
  ${method.definition} => _\$${method.name}Event.add(${method.firstParameterName});
  ///endregion ${method.name}
  ''');
}

extension _FirstParameter on MethodElement {
  String get firstParameterType =>
      "${parameters.isNotEmpty ? parameters.first.type : 'void'}";

  String get firstParameterName =>
      "${parameters.isNotEmpty ? parameters.first.name : 'null'}";

  String get definition {
    if (this.parameters.isEmpty) {
      return "$returnType $name()";
    }

    return "$returnType $name(${parameters.first.type} ${parameters.first.name})";
  }

  String get streamType {
    // Check if it is a behaviour event
    if (_eventAnnotationChecker.hasAnnotationOfExact(this)) {
      final annotation = _eventAnnotationChecker.firstAnnotationOfExact(this);
      final isBehaviorSubject =
          annotation.getField('type').toString().contains('behaviour');

      if (isBehaviorSubject) {
        final seedField = annotation.getField('seed');

        // Check for any errors regarding the seed value
        if (!seedField.isNull) {
          final firstParam = firstParameterType.replaceAll(' ', '');
          final typeAsString = seedField.toString().getTypeFromString();
          // Check for seed value mismatch
          if (typeAsString != firstParam) {
            final msg = StringBuffer();
            msg.write('Type mismatch between seed type and ');
            msg.write('expected parameter type:\n');
            msg.write('\tExpected: \'$firstParam\'');
            msg.write('\tGot: \'$typeAsString\'');
            logError(msg.toString());
          }
        } else
          logError('Seed value can not be null.');

        final seedValue = seedField.toString().convertToValidString();
        return 'BehaviorSubject.seeded($seedValue)';
      }
    }

    // Fallback case is a publish event
    return 'PublishSubject<$firstParameterType>()';
  }
}
