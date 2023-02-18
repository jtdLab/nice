import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:nice/src/templates/when.dart';

extension DartTypeX on DartType {
  bool get isPrimitve {
    return isDartCoreBool ||
        isDartCoreInt ||
        isDartCoreDouble ||
        isDartCoreNum ||
        isDartCoreString ||
        isDartCoreList ||
        isDartCoreSet ||
        isDartCoreMap ||
        isDartCoreObject ||
        isDynamic ||
        isVoid ||
        element is EnumElement ||
        isDartAsyncFuture ||
        isDartAsyncFutureOr ||
        isDartAsyncStream;
  }

  String getDefaultValue() {
    if (isDartCoreBool) {
      return 'false';
    } else if (isDartCoreInt || isDartCoreDouble || isDartCoreNum) {
      return '0';
    } else if (isDartCoreString) {
      return '\'\'';
    } else if (isDartCoreList) {
      return '<dynamic>[]';
    } else if (isDartCoreSet) {
      return '<dynamic>{}';
    } else if (isDartCoreMap) {
      return '<dynamic, dynamic>{}';
    } else if (isDartCoreObject || isDynamic || isVoid) {
      return 'null';
    } else if (element is EnumElement) {
      final e = element as EnumElement;
      return '${e.name}.${e.fields.first.name}';
    } else if (isDartAsyncFuture || isDartAsyncFutureOr) {
      return (this as ParameterizedType).typeArguments.first.getDefaultValue();
    } else if (isDartAsyncStream) {
      return 'Stream.empty()';
    } else {
      return element!.name!.toLowerCase();
    }
  }

  ReturnType getReturnType() {
    if (isDartAsyncFuture || isDartAsyncFutureOr) {
      return ReturnType.future;
    } else if (isDartAsyncStream) {
      return ReturnType.stream;
    } else {
      return ReturnType.property;
    }
  }
}
