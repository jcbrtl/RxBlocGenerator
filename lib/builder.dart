import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:rx_bloc/annotation/rx_bloc_annotations.dart';
import 'package:rx_bloc_generator/rx_bloc_generator.dart';
import 'package:rx_bloc_generator/utilities.dart';
import 'package:source_gen/source_gen.dart';

Builder rxBlocGenerator(BuilderOptions options) {
  return LibraryBuilder(
    RxBlocGeneratorForAnnotation(),
    generatedExtension: ".rxb.g.dart",
  );
}

class RxBlocGeneratorForAnnotation extends GeneratorForAnnotation<RxBloc> {
  @override
  generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async {
    // return early if annotation is used for a none class element
    if (element is! ClassElement) return null;

    final classElement = element as ClassElement;

    final libraryReader = LibraryReader(classElement.library);

    final eventsClassName = annotation.read('eventsClassName')?.stringValue;
    final statesClassName = annotation.read('statesClassName')?.stringValue;

    final eventsClass = libraryReader.classes.firstWhere(
        (classElement) => classElement.displayName.contains(eventsClassName),
        orElse: () => null);

    final statesClass = libraryReader.classes.firstWhere(
        (classElement) => classElement.displayName.contains(statesClassName),
        orElse: () => null);

    if (eventsClass == null)
      logError('No events class specified for ${classElement.name} bloc!');
    if (statesClass == null)
      logError('No states class specified for ${classElement.name} bloc!');

    try {
      return RxBlocGenerator(classElement, eventsClass, statesClass).generate();
    } catch (ex) {
      // We cannot generate empty file, but we can write a warning message
      return '/// Please fix errors in order to successfully generate file.';
    }
  }
}
