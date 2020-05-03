import 'package:analyzer/dart/element/element.dart';
import 'package:rx_bloc_generator/src/events_generator.dart';
import 'package:rx_bloc_generator/src/states_generator.dart';

class RxBlocGenerator {
  final StringBuffer _stringBuffer = StringBuffer();
  final ClassElement viewModelElement;
  final ClassElement eventsElement;
  final ClassElement statesElement;
  final EventsGenerator _eventsGenerator;
  final StatesGenerator _statesGenerator;

  RxBlocGenerator(
    this.viewModelElement,
    this.eventsElement,
    this.statesElement,
  )   : _eventsGenerator = EventsGenerator(eventsElement),
        _statesGenerator = StatesGenerator(statesElement);

  // helper functions
  void _writeln([Object obj]) => _stringBuffer.writeln(obj);

  String generate() {
    _generatePartOf();
    _generateTypeClass();
    _generateBlocClass();
    return _stringBuffer.toString();
  }

  void _generatePartOf() {
    final uri = Uri.tryParse(viewModelElement.location.components.first);
    _writeln("part of '${uri.pathSegments.last}';");
  }

  void _generateTypeClass() {
    _writeln(
        "\nabstract class ${viewModelElement.displayName}Type extends RxBlocTypeBase {");
    _writeln("\n  ${eventsElement.displayName} get events;");
    _writeln("\n  ${statesElement.displayName} get states;");
    _writeln("\n}");
  }

  void _generateBlocClass() {
    _writeln("\n");
    _writeln(
        "\nabstract class \$${viewModelElement.displayName} extends RxBlocBase");
    _writeln("\n    implements");
    _writeln("\n        ${eventsElement.displayName},");
    _writeln("\n        ${statesElement.displayName},");
    _writeln("\n        ${viewModelElement.displayName}Type {");
    _writeln(_eventsGenerator.generate());
    _writeln(_statesGenerator.generate());
    _writeln("\n  ///region Type");
    _writeln("\n  @override");
    _writeln("\n  ${eventsElement.displayName} get events => this;");
    _writeln("\n");
    _writeln("\n  @override");
    _writeln("\n  ${statesElement.displayName} get states => this;");
    _writeln("\n  ///endregion Type");
    _generateDisposeMethod();
    _writeln("\n}\n");
    _writeln(_eventsGenerator.generateArgumentClasses());
  }

  void _generateDisposeMethod() {
    _writeln("\nvoid dispose(){");

    eventsElement.methods.forEach((method) {
      _writeln("_\$${method.name}Event.close();");
    });
    _writeln("super.dispose();");
    _writeln("}");
  }
}
