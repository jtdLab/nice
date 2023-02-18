import 'package:recase/recase.dart';

class TempMockDeclaration {
  final String name;

  TempMockDeclaration({required this.name});

  @override
  String toString() => 'final ${name.camelCase} = Mock$name();';
}
