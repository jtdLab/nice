class RegisterFallbackValuesTemplate {
  RegisterFallbackValuesTemplate({
    required this.values,
  });

  final Set<String> values;

  @override
  String toString() {
    return '''
void registerFallbackValues() {
$_values
}
''';
  }

  String get _values =>
      values.map((e) => '  registerFallbackValue($e());').join('\n');
}
