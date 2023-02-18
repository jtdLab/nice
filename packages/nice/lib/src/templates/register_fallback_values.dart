abstract class FallbackValue implements Comparable<FallbackValue> {
  @override
  int compareTo(FallbackValue other) => toString().compareTo(other.toString());
}

class ClassFallbackValue extends FallbackValue {
  final String name;

  ClassFallbackValue({required this.name});

  @override
  String toString() => '$name()';

  @override
  bool operator ==(Object other) =>
      other is ClassFallbackValue && name == other.name;

  @override
  int get hashCode => name.hashCode;
}

class EnumFallbackValue extends FallbackValue {
  final String name;
  final String valueName;

  EnumFallbackValue({required this.name, required this.valueName});

  @override
  String toString() => '$name.$valueName';

  @override
  bool operator ==(Object other) =>
      other is EnumFallbackValue &&
      name == other.name &&
      valueName == other.valueName;

  @override
  int get hashCode => Object.hash(name, valueName);
}

class RegisterFallbackValues {
  RegisterFallbackValues({required this.fallbackValues});

  final Set<FallbackValue> fallbackValues;

  @override
  String toString() {
    return '''
void registerFallbackValues() {
$_values
}
''';
  }

  String get _values => (fallbackValues.toList()..sort())
      .map((e) => 'registerFallbackValue(${e.toString()});')
      .join('\n');
}
