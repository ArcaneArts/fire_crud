// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'en.dart';

class EnMapper extends EnumMapper<En> {
  EnMapper._();

  static EnMapper? _instance;
  static EnMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = EnMapper._());
    }
    return _instance!;
  }

  static En fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  En decode(dynamic value) {
    switch (value) {
      case r'a':
        return En.a;
      case r'b':
        return En.b;
      case r'c':
        return En.c;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(En self) {
    switch (self) {
      case En.a:
        return r'a';
      case En.b:
        return r'b';
      case En.c:
        return r'c';
    }
  }
}

extension EnMapperExtension on En {
  String toValue() {
    EnMapper.ensureInitialized();
    return MapperContainer.globals.toValue<En>(this) as String;
  }
}
