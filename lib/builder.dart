import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:rx_bloc/annotation/rx_bloc_annotations.dart';
import 'package:rx_bloc_generator/rx_bloc_generator.dart';
import 'package:rx_bloc_generator/utilities/utilities.dart';
import 'package:source_gen/source_gen.dart';

Builder rxBlocGenerator(BuilderOptions options) {
  return LibraryBuilder(
    RxBlocGeneratorForAnnotation(),
    generatedExtension: ".rxb.g.dart",
  );
}

class RxBlocGeneratorForAnnotation extends GeneratorForAnnotation<RxBloc> {
  String _generateMissingClassError(String className, String blocName) {
    StringBuffer buffer = StringBuffer();
    buffer.write('\'$blocName$className\' class missing.\n');
    buffer.write('\n\tPlease make sure you have properly named and specified');
    buffer
        .write('\n\tyour class in the same file where the $blocName resides.');
    return buffer.toString();
  }

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
      logError(_generateMissingClassError(eventsClassName, classElement.name));
    if (statesClass == null)
      logError(_generateMissingClassError(statesClassName, classElement.name));

    if (statesClass != null && eventsClass != null)
      return RxBlocGenerator(classElement, eventsClass, statesClass).generate();
  }
}
