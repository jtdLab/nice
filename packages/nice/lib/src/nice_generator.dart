import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:logging/logging.dart';
import 'package:nice/src/model.dart';
import 'package:nice/src/templates/final_mock_prop_template.dart';
import 'package:nice/src/templates/mock_template.dart';
import 'package:nice/src/templates/register_fallback_values_template.dart';
import 'package:nice/src/templates/when_template.dart';
import 'package:nice/src/tools/type.dart';
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

      final maybeMock = _maybeMockOf(element);
      if (maybeMock != null) {
        mocks.add(maybeMock);
      } else {
        final maybeFake = _maybeFakeOf(element);
        if (maybeFake != null) {
          fakes.add(maybeFake);
        }
      }
    }

    final requiredFallbackValues = <String>{};

    for (final mock in mocks) {
      final finalMockProps = [
        ...mock.fields
            .map((e) => e.type)
            .where((e) => !e.isPrimitve)
            .map((e) => FinalMockPropTemplate(name: e.element!.name!)),
        ...mock.methods
            .map((e) => e.returnType)
            .where((e) => !e.isPrimitve)
            .map((e) => FinalMockPropTemplate(name: e.element!.name!)),
      ];
      final whens = [
        ...mock.fields.map(
          (e) => WhenTemplate(
            name: e.name,
            type: Type.property,
            returnType: e.type.getReturnType(),
            value: e.type.getDefaultValue(),
          ),
        ),
        ...mock.methods.map(
          (e) => WhenTemplate(
            name: e.name,
            type: Type.function,
            arguments: [
              ...e.parameters.where((param) => !param.isNamed).map(
                    (e) => Argument(),
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

      final mockTemplate = MockTemplate(
        name: mock.name,
        finalMockProps: finalMockProps,
        whens: whens,
      );
      buffer.writeln(mockTemplate.toString());

      requiredFallbackValues.addAll(
        mock.methods
            .map(
              (e) => e.parameters
                  .where((param) => param.isNamed)
                  .map((e) => e.type.element!.name!)
                  .toList(),
            )
            .toList()
            .fold<List<String>>([], (prev, e) => prev + e),
      );
    }

    final availableFallbackValues = <String>{};
    final fakeNames = fakes.map((e) => e.name);
    for (final fallbackValue in requiredFallbackValues) {
      if (fakeNames.contains(fallbackValue)) {
        availableFallbackValues.add('Fake$fallbackValue');
      } else {
        logger.warning('''
Fake for $fallbackValue not found. Require the following code:

@nice
class Fake$fallbackValue extends Fake implements $fallbackValue {}
''');
      }
    }

    final registerFallbackValuesTemplate = RegisterFallbackValuesTemplate(
      values: availableFallbackValues,
    );
    buffer.write(registerFallbackValuesTemplate.toString());

    return buffer.toString();
  }

  MockElement? _maybeMockOf(ClassElement element) {
    try {
      if (element.supertype?.element.name == 'Fake') {
        return null;
      }

      final interfaceElement = element.interfaces.first.element;
      final name = interfaceElement.name;
      final fields = interfaceElement.fields.where((e) => e.isPublic).toList();
      final methods =
          interfaceElement.methods.where((e) => e.isPublic).toList();

      return MockElement(
        name: name,
        fields: fields,
        methods: methods,
      );
    } catch (_) {
      return null;
    }
  }

  FakeElement? _maybeFakeOf(ClassElement element) {
    try {
      if (element.supertype?.element.name != 'Fake') {
        return null;
      }

      final interfaceElement = element.interfaces.first.element;
      final name = interfaceElement.name;
      final fields = interfaceElement.fields.where((e) => e.isPublic).toList();
      final methods =
          interfaceElement.methods.where((e) => e.isPublic).toList();

      return FakeElement(
        name: name,
        fields: fields,
        methods: methods,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) =>
      throw UnimplementedError();
}
