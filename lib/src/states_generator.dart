import 'package:analyzer/dart/element/element.dart';
import 'package:rx_bloc/annotation/rx_bloc_annotations.dart';
import 'package:rx_bloc_generator/utilities/utilities.dart';

import 'package:rx_bloc_generator/utilities/string_extensions.dart';
import 'package:source_gen/source_gen.dart';

final _ignoreStateAnnotationChecker =
    TypeChecker.fromRuntime(RxBlocIgnoreState);

class StatesGenerator {
  StringBuffer _stringBuffer = StringBuffer();
  ClassElement _statesClass;
  StatesGenerator(this._statesClass);

  void _writeln([Object obj]) => _stringBuffer.writeln(obj);
  void _write([Object obj]) => _stringBuffer.write(obj);

  String generate() {
    _writeln("\n  ///region States");
    _writeln("\n");
    _writeln(_generateStates());
    _writeln("\n  ///endregion States");
    return _stringBuffer.toString();
  }

  String _generateStates() {
    // Check if there are any states defined as methods
    _statesClass.methods.forEach((method) {
      logError(
          'State \'${method.name}\' should be defined using the get keyword.');
    });

    return _statesClass.accessors
        .checkForErroneousStates()
        .filterRxBlocIgnoreState()
        .map((element) => element.variable)
        .mapToStates()
        .join('\n');
  }
}

extension _FilteringAndCheckingStates on List<PropertyAccessorElement> {
  List<PropertyAccessorElement> checkForErroneousStates() {
    this.forEach((fieldElement) {
      final name = fieldElement.name.replaceAll('=', '');
      if (!fieldElement.isAbstract)
        logError('State \'$name\' should not contain a body definition.');
    });
    return this;
  }

  Iterable<PropertyAccessorElement> filterRxBlocIgnoreState() =>
      where((fieldElement) {
        if (fieldElement.metadata.isEmpty) return true;
        return !_ignoreStateAnnotationChecker.hasAnnotationOf(fieldElement);
      });
}

extension _MapToStates on Iterable<PropertyInducingElement> {
  Iterable<String> mapToStates() => map((fieldElement) => '''
  ///region ${fieldElement.displayName}
  ${fieldElement.type} _${fieldElement.displayName}State;

  @override
  ${fieldElement.type} get ${fieldElement.displayName} => _${fieldElement.displayName}State ??= _mapTo${fieldElement.displayName.capitalize()}State();

  ${fieldElement.type} _mapTo${fieldElement.displayName.capitalize()}State();
  ///endregion ${fieldElement.displayName}
  ''');
}
