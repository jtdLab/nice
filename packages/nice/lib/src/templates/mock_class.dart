import 'package:nice/src/templates/temp_mock_declaration.dart';
import 'package:nice/src/templates/when.dart';

class MockClass {
  MockClass({
    required this.name,
    required this.tempMockDeclarations,
    required this.whens,
  });

  final String name;
  final List<TempMockDeclaration> tempMockDeclarations;
  final List<When> whens;

  @override
  String toString() {
    return '''
class _\$Mock$name extends Mock implements $name {
_\$Mock$name() {
$_tempMockDeclarations
$_whens
}
}
''';
  }

  String get _tempMockDeclarations =>
      tempMockDeclarations.map((e) => e.toString()).join('\n');

  String get _whens => whens.map((e) => e.toString()).join('\n');
}
