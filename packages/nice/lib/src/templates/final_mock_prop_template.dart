class FinalMockPropTemplate {
  FinalMockPropTemplate({
    required this.name,
  });

  final String name;

  @override
  String toString() => 'final ${name.toLowerCase()} = Mock$name();';
}
