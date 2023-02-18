import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/nice_generator.dart';

/// Builds generators for `build_runner` to run
Builder nice(BuilderOptions options) {
  return PartBuilder(
    [NiceGenerator()],
    '.nice.dart',
    header: '// GENERATED CODE - DO NOT MODIFY BY HAND',
    options: options,
  );
}
