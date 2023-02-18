import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:logging/logging.dart';
import 'package:nice/src/model.dart';
import 'package:nice/src/templates/mock_class.dart';
import 'package:nice/src/templates/register_fallback_values.dart';
import 'package:nice/src/templates/temp_mock_declaration.dart';
import 'package:nice/src/templates/when.dart';
import 'package:nice/src/tools/dart_type.dart';
import 'package:nice_annotation/nice_annotation.dart';
import 'package:source_gen/source_gen.dart';

class NiceGenerator extends GeneratorForAnnotation<Nice> {
  final Logger logger = Logger('NiceGenerator');

  @override
  FutureOr<String> generate(
    LibraryReader oldLibrary,
    BuildStep buildStep,
  ) async {
    final assetId =
        await buildStep.resolver.assetIdForElement(oldLibrary.element);
    if (await buildStep.resolver.isLibrary(assetId).then((value) => !value)) {
      return '';
    }
    final library = await buildStep.resolver.libraryFor(assetId);

    if (library.hasAliasedImports()) {
      throw InvalidGenerationSourceError(
        '''
Some of your libraries contain aliased imports.

Nice might support this in the future.
''',
      );
    }

    final buffer = StringBuffer();

    final mocks = <MockElement>[];
    final fakes = <FakeElement>[];
    for (final element
        in library.topLevelElements.where(typeChecker.hasAnnotationOf)) {
      if (element is! ClassElement) {
        throw InvalidGenerationSourceError(
          '@nice can only be applied on classes. Failing element: ${element.name}',
          element: element,
        );
      }

      if (element.isValidMock) {
        mocks.add(element.asMock());
      } else if (element.isValidFake) {
        fakes.add(element.asFake());
      } else {
        throw InvalidGenerationSourceError(
          '@nice can only be applied on classes defined in the following way:\n'
          '\n'
          'Mock:\n'
          'class MockMyClass extends _\$MockMyClass implements MyClass {}\n'
          '\n'
          'Fake:\n'
          'class FakeMyClass extends Fake implements MyClass {}\n'
          '\n'
          'Failing element: ${element.name}\n',
          element: element,
        );
      }
    }

    final requiredFallbackValues = mocks.requiredFallbackValues();
    final availableFallbackValues = <FallbackValue>{
      ...requiredFallbackValues.whereType<EnumFallbackValue>(),
      ...requiredFallbackValues
          .whereType<ClassFallbackValue>()
          .where((e) => fakes.any((fake) => fake.name == e.name))
    };
    final missingFallbackValues = {
      ...requiredFallbackValues,
    }..removeAll(availableFallbackValues);

    if (missingFallbackValues.isNotEmpty) {
      logger.warning('''
Missing fake(s) for the following classes:

${missingFallbackValues.join('\n')}

Declare fakes and annotate them with @nice like this:

@nice
class FakeFoo extends Fake implements Foo {}
''');
    }

    buffer.write(
      RegisterFallbackValues(
        fallbackValues: availableFallbackValues,
      ).toString(),
    );

    for (final mock in mocks) {
      buffer.writeln(mock.asMockClass().toString());
    }

    return buffer.toString();
  }

  @override
  Stream<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async* {
    // implemented for source_gen_test – otherwise unused
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@nice can only be applied on classes. Failing element: ${element.name}',
        element: element,
      );
    }

    // TODO impl

    /* 
    final globalData = parseGlobalData(element.library!);
    final data = parseElement(buildStep, globalData, element);

    if (data == null) return;

    for (final value in generateForData(globalData, await data)) {
      yield value.toString();
    } */
  }
}

extension on LibraryElement {
  bool hasAliasedImports() => prefixes.isNotEmpty;
}

// TODO check that names match from interface and mock names
extension on ClassElement {
  bool get isValidMock {
    if (isAbstract || isPrivate) {
      return false;
    }

    final superClass = this.supertype;
    if (superClass == null) {
      return false;
    }

    // TODO this check works but is not ideal
    final superClassName = superClass.element.name;
    if (superClassName == 'Fake') {
      return false;
    }

    final interfaces = this.interfaces;
    if (interfaces.length != 1) {
      return false;
    }

    return true;
  }

  bool get isValidFake {
    if (isAbstract || isPrivate) {
      return false;
    }

    final superClass = this.supertype;
    if (superClass == null) {
      return false;
    }

    final superClassName = superClass.element.name;
    if (superClassName != 'Fake') {
      return false;
    }

    final interfaces = this.interfaces;
    if (interfaces.length != 1) {
      return false;
    }

    return true;
  }

  MockElement asMock() {
    final interface = interfaces.first.element;
    final name = interface.name;
    final fields = interface.fields.where((e) => e.isPublic).toList();
    final methods = interface.methods.where((e) => e.isPublic).toList();

    return MockElement(
      name: name,
      fields: fields,
      methods: methods,
    );
  }

  FakeElement asFake() {
    final interface = interfaces.first.element;
    final name = interface.name;
    final fields = interface.fields.where((e) => e.isPublic).toList();
    final methods = interface.methods.where((e) => e.isPublic).toList();

    return FakeElement(
      name: name,
      fields: fields,
      methods: methods,
    );
  }
}

extension on MockElement {
  MockClass asMockClass() {
    final finalMockProps = [
      ...fields
          .map((e) => e.type)
          .where((e) => !e.isPrimitve)
          .map((e) => TempMockDeclaration(name: e.element!.name!)),
      ...methods
          .map((e) => e.returnType)
          .where((e) => !e.isPrimitve)
          .map((e) => TempMockDeclaration(name: e.element!.name!)),
    ];
    final whens = [
      ...fields.map(
        (e) => FieldWhen(
          name: e.name,
          returnType: e.type.getReturnType(),
          value: e.type.getDefaultValue(),
        ),
      ),
      ...methods.map(
        (e) => MethodWhen(
          name: e.name,
          arguments: [
            ...e.parameters.where((param) => !param.isNamed).map(
                  (e) => UnnamedArgument(),
                ),
            ...e.parameters.where((param) => param.isNamed).map(
                  (e) => NamedArgument(name: e.name),
                ),
          ],
          returnType: e.returnType.getReturnType(),
          value: e.returnType.getDefaultValue(),
        ),
      ),
    ];

    return MockClass(
      name: name,
      tempMockDeclarations: finalMockProps,
      whens: whens,
    );
  }
}

extension on List<MockElement> {
  Set<FallbackValue> requiredFallbackValues() => map(
        (e) => e.methods
            .map(
              (e) => e.parameters.where(
                (e) {
                  return !e.type.isPrimitve || e.type.element is EnumElement;
                },
              ).map(
                (e) {
                  final element = e.type.element;

                  if (element is EnumElement) {
                    return EnumFallbackValue(
                      name: element.name,
                      valueName: element.fields.first.name,
                    );
                  } else {
                    return ClassFallbackValue(
                      name: element!.name!,
                    );
                  }
                },
              ).toList(),
            )
            .toList()
            .fold<List<FallbackValue>>([], (prev, e) => prev + e),
      ).fold<List<FallbackValue>>([], (prev, e) => prev + e).toSet();
}
