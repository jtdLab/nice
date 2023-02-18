enum Type { property, function }

class Argument {}

class NamedArgument extends Argument {
  NamedArgument({required this.name});

  final String name;
}

enum ReturnType {
  property,
  error,
  future,
  stream,
}

class WhenTemplate {
  WhenTemplate({
    required this.name,
    required this.type,
    this.arguments = const [],
    required this.returnType,
    required this.value,
  });

  final String name;
  final Type type;
  final List<Argument> arguments;
  final ReturnType returnType;
  final String value;

  @override
  String toString() => 'when(() => this.$_invocation).$_then($_value);';

  String get _invocation {
    if (type == Type.property) {
      return name;
    }

    final args = _arguments;
    if (args.length < 20) {
      // TODO this is hard coded add the trailing comma as soon as there is at least 1 arg in a function
      return '$name($args)';
    }
    return '$name($args),';
  }

  String get _arguments {
    final args = [
      ...arguments.where((e) => e is! NamedArgument).map((e) => 'any()'),
      ...arguments
          .whereType<NamedArgument>()
          .map((e) => '${e.name}: any(named: \'${e.name}\')'),
    ].join(', ');

    if (args.isNotEmpty) {
      return args + ',';
    }

    return args;
  }

  String get _then {
    switch (returnType) {
      case ReturnType.property:
        return 'thenReturn';
      case ReturnType.error:
        return 'thenThrow';
      default:
        return 'thenAnswer';
    }
  }

  String get _value {
    switch (returnType) {
      case ReturnType.future:
        return '(_) async => $value';
      case ReturnType.stream:
        return '(_) => $value';
      default:
        return value;
    }
  }
}
