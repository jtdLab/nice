import 'package:nice/src/templates/final_mock_prop_template.dart';
import 'package:nice/src/templates/when_template.dart';

class MockTemplate {
  MockTemplate({
    required this.name,
    required this.finalMockProps,
    required this.whens,
  });

  final String name;
  final List<FinalMockPropTemplate> finalMockProps;
  final List<WhenTemplate> whens;

  @override
  String toString() {
    return '''
class _\$Mock$name extends Mock implements $name {
_\$Mock$name() {
$_finalMockProps
$_whens
}
}
''';
  }

  String get _finalMockProps =>
      finalMockProps.map((e) => e.toString()).join('\n');

  String get _whens => whens.map((e) => e.toString()).join('\n');
}

// TODO rm
/* void main() {
  final whens = [
    WhenTemplate(
      name: 'shake',
      type: Type.function,
      returnType: ReturnType.future,
      value: '3',
    ),
    WhenTemplate(
      name: 'talk',
      type: Type.property,
      returnType: ReturnType.stream,
      value: 'Stream.empty()',
    ),
    WhenTemplate(
      name: 'fail',
      type: Type.function,
      returnType: ReturnType.error,
      value: 'Error()',
    ),
    WhenTemplate(
      name: 'canHelp',
      type: Type.function,
      returnType: ReturnType.property,
      value: 'true',
    ),
  ];
  final mockTmp = MockTemplate(
    name: 'Person',
    whens: whens,
  );

  print(mockTmp.toString());
}
 */
