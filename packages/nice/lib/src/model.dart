import 'package:analyzer/dart/element/element.dart';

class MockElement {
  final String name;
  final List<FieldElement> fields;
  final List<MethodElement> methods;

  MockElement({
    required this.name,
    required this.fields,
    required this.methods,
  });
}

class FakeElement {
  final String name;
  final List<FieldElement> fields;
  final List<MethodElement> methods;

  FakeElement({
    required this.name,
    required this.fields,
    required this.methods,
  });
}
