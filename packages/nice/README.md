# Motivation

[mocktail] is a great package to easily define mocks and verify behaviour, but in some situations there comes some inconvenience:

- stubbing lots of methods and fields
- stubbing methods with many args
- registering (many) fallback values

Nice tries to address these issues by generating mocks that are fully stubbed (also referred to as [nice] mocks) with reasonable return values and an easy way to register all required fallback values.

# How to use

## Install

To use [nice], you will need [mocktail] and your typical [build_runner]/code-generator setup.\
First, install [mocktail], [build_runner] and [nice] by adding them to your `pubspec.yaml` file:

For a Flutter project:

```console
flutter pub add --dev mocktail
flutter pub add --dev build_runner
flutter pub add --dev nice_annotation
flutter pub add --dev nice
```

For a Dart project:

```console
dart pub add --dev mocktail
dart pub add --dev build_runner
dart pub add --dev nice_annotation
dart pub add --dev nice
```

This installs four packages:

- [mocktail], the mocking package [nice] was created for
- [build_runner], the tool to run code-generators
- [nice], the code generator
- [nice_annotation], a package containing annotations for [nice].

## Run the generator

To run the code generator, execute the following command:

```
dart run build_runner build
```

For Flutter projects, you can also run:

```
flutter pub run build_runner build
```

In most projects it is recommended to have a single `mocks.dart` file somewhere inside your `test` directory where all of your fakes and mocks will be declared once and can be shared across the project.

```dart
import 'package:nice_annotation/nice_annotation.dart';

part 'mocks.nice.dart';

// Mocks

@nice
class MockA extends _$MockA implements A {}

class MockB extends Mock implements B {} // plain mocktail mock ignored by nice

@nice
class MockC extends _$MockC implements C {}

// Fakes

@nice
class FakeFoo extends Fake implements Foo {}

@nice
class FakeBar extends Fake implements Bar {}

class FakeBaz extends Fake implements Baz {} // plain mocktail fake ignored by nice
```

Note: It is also possible to generate [nice] mocks using multiple files. Every file will have its seperate scope and does NOT know about any fakes or mocks declared in other files. The best result in terms of sharing code can be achieved using the single file approach.

#### Nice Mocks

Generate [nice] mocks that are ready to use in a single line.

Note: When using a [nice] mock its only required to stub methods/fields whose return value is necessary in the verification/assert part of the test. This leads to increased readability and expressiveness of the test.

Before:

```dart
/// mocks.dart
MockDependency extends Mock implements Dependency {}

/// my_class_test.dart
test('.myMethod()', () async {
  final dependency = MockDependency();
  when(() => dependency.foo()).thenAnswer((_) async => 1);
  when(() => dependency.bar()).thenAnswer((_) async => 'some');
  when(() => dependency.baz()).thenAnswer((_) => Stream.value(1));
  final myClass = MyClass(dependency: dependency);

  await myClass.myMethod();

  verify(() => dependency.foo()).called(1);
  verify(() => dependency.bar()).called(1);
  verify(() => dependency.baz()).called(1);
});
```

After:

```dart
/// mocks.dart
@nice
MockDependency extends _$MockDependency implements Dependency {}

/// my_class_test.dart
test('.myMethod()', () async {
  final dependency = MockDependency(); // no stubbing required
  final myClass = MyClass(dependency: dependency);

  await myClass.myMethod();

  verify(() => dependency.foo()).called(1);
  verify(() => dependency.bar()).called(1);
  verify(() => dependency.baz()).called(1);
});
```

#### Registering Fallback Values

Generate [nice] `registerFallbackValues` method ready to use in `setupAll`.
It will register all required fallback values for your mocks to function correctly.

Before:

```dart
/// mocks.dart
FakeMyType extends Fake implements MyType {}

/// my_class_test.dart
group('MyClass', () {
  setupAll(() {
    registerFallbackValue(FakeMyType());
    registerFallbackValue(MyEnum.myValue);
    // ...
  });
});
```

After:

```dart
/// mocks.dart
@nice
FakeMyType extends Fake implements MyType {}

/// my_class_test.dart
group('MyClass', () {
  setupAll(() {
    registerFallbackValues(); // use method generated by nice
  });
});
```

[mocktail]: https://pub.dartlang.org/packages/mocktail
[build_runner]: https://pub.dev/packages/build_runner
[nice]: https://pub.dartlang.org/packages/nice
[nice_annotation]: https://pub.dartlang.org/packages/nice_annotation