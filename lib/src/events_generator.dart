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

  String generate() {
    _writeln("\n\n  ///region Events");
    _writeln("\n");
    _writeln(_generateEvents());
    _writeln("\n  ///endregion Events");

    return _stringBuffer.toString();
  }

  String generateArgumentClasses() {
    StringBuffer _argClassString = StringBuffer();
    _argClassString.writeln('/// region Argument classes\n');
    for (var method in _eventsClass.methods
        .where((method) => method.parameters.length > 1)) {
      _argClassString.writeln('/// region ${method.argumentsClassName} class');
      _argClassString.writeln(_generateArgumentClass(method));
      _argClassString
          .writeln('/// endregion ${method.argumentsClassName} class');
    }
    _argClassString.writeln('\n/// endregion Argument classes\n');
    return _argClassString.toString();
  }

  String _generateArgumentClass(MethodElement method) {
    StringBuffer _buffer = StringBuffer();
    final className = method.argumentsClassName;
    final paramNames = method.parameterNames;
    _buffer.writeln('\nclass $className {\n');
    // Create all the parameters first
    paramNames.forEach((paramName) {
      final param = method.getParameter(paramName);
      _buffer.writeln('final ${param.type.toString()} $paramName;');
    });
    // Create the constant constructor
    _buffer.writeln('\nconst $className({');
    paramNames.forEach((paramName) => _buffer.writeln('this.$paramName,'));
    _buffer.writeln('});');
    _buffer.writeln('\n}');
    return _buffer.toString();
  }

  String _generateEvents() {
    _eventsClass.fields.forEach((field) {
      var msg = '${_eventsClass.name} should contain methods only,';
      msg += ' while \'${field.name}\' seems to be a field.';
      logError(msg);
    });

    return _eventsClass.methods
        .checkForNonAbstractEvents()
        .mapToEvents()
        .join('\n');
  }
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
  Iterable<String> mapToEvents() => map((method) {
        return '''
  ///region ${method.name}
 
  final _\$${method.name}Event = ${method.streamType};
  @override
  ${method.definition} => _\$${method.name}Event.add(${method.firstParameterName});
  ///endregion ${method.name}
  ''';
      });
}

extension _MethodExtensions on MethodElement {
  /// The name of the arguments class that will be generated if
  /// the event contains more than one parameter
  String get argumentsClassName => '_${this.name.capitalize()}EventArgs';

  String get streamTypeBasedOnParameters {
    if (this.parameters.length > 1) return this.argumentsClassName;
    return "${parameters.isNotEmpty ? parameters.first.type : 'void'}";
  }

  String get firstParameterName {
    if (this.parameters.length > 1) {
      var str = '${this.argumentsClassName}(';
      this
          .parameterNames
          .forEach((paramName) => str += ' $paramName:$paramName,');
      str += ')';
      return str;
    }
    return "${parameters.isNotEmpty ? parameters.first.name : 'null'}";
  }

  String get definition {
    var def = this.toString();
    this.parameterNames.forEach((paramName) {
      final param = this.getParameter(paramName);

      // Add required annotation before type
      if (param.hasRequired) {
        int index = def.indexOf(paramName);
        index = def.lastIndexOf(param.type.toString(), index);
        def = def.substring(0, index) + ' @required ' + def.substring(index);
      }

      // Add default value (if any)
      if (param.defaultValueCode != null) {
        int index = def.indexOf(paramName);
        def = def.substring(0, index) +
            def.substring(index, index + paramName.length) +
            ': ${param.defaultValueCode}' +
            def.substring(index + paramName.length);
      }
    });

    return def;
  }

  ParameterElement getParameter(String paramName) {
    return this.parameters.firstWhere((param) => param.name == paramName);
  }

  List<String> get parameterNames =>
      this.parameters.map((param) => param.name).toList();

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
          final firstParam = streamTypeBasedOnParameters.replaceAll(' ', '');
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
    return 'PublishSubject<$streamTypeBasedOnParameters>()';
  }
}
