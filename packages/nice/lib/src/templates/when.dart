abstract class Argument {}

class UnnamedArgument extends Argument {}

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

abstract class When {
  When({
    required this.name,
    required this.returnType,
    required this.value,
  });

  final String name;
  final ReturnType returnType;
  final String value;

  @override
  String toString() => 'when(() => this.$_invocation).$_then($_value);';

  String get _invocation;

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

class FieldWhen extends When {
  FieldWhen({
    required super.name,
    required super.returnType,
    required super.value,
  });

  @override
  String get _invocation => name;
}

class MethodWhen extends When {
  final List<Argument> arguments;

  MethodWhen({
    required super.name,
    required this.arguments,
    required super.returnType,
    required super.value,
  });

  @override
  String get _invocation {
    if (arguments.isEmpty) {
      return '$name($_arguments)';
    }

    return '$name($_arguments),';
  }

  String get _arguments {
    final args = [
      ...arguments.where((e) => e is! NamedArgument).map((e) => 'any()'),
      ...arguments
          .whereType<NamedArgument>()
          .map((e) => '${e.name}: any(named: \'${e.name}\')'),
    ].join(', ');

    if (arguments.isEmpty) {
      return args;
    }

    return '$args,';
  }
}
