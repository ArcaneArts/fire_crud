// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'subtask.dart';

class SubtaskMapper extends ClassMapperBase<Subtask> {
  SubtaskMapper._();

  static SubtaskMapper? _instance;
  static SubtaskMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SubtaskMapper._());
      EnMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'Subtask';

  static String? _$title(Subtask v) => v.title;
  static const Field<Subtask, String> _f$title =
      Field('title', _$title, opt: true);
  static int _$b(Subtask v) => v.b;
  static const Field<Subtask, int> _f$b = Field('b', _$b, opt: true, def: 0);
  static double? _$c(Subtask v) => v.c;
  static const Field<Subtask, double> _f$c = Field('c', _$c, opt: true);
  static double _$d(Subtask v) => v.d;
  static const Field<Subtask, double> _f$d = Field('d', _$d, opt: true, def: 0);
  static int? _$a(Subtask v) => v.a;
  static const Field<Subtask, int> _f$a = Field('a', _$a, opt: true);
  static DateTime _$dt(Subtask v) => v.dt;
  static const Field<Subtask, DateTime> _f$dt = Field('dt', _$dt);
  static En? _$en(Subtask v) => v.en;
  static const Field<Subtask, En> _f$en = Field('en', _$en, opt: true);

  @override
  final MappableFields<Subtask> fields = const {
    #title: _f$title,
    #b: _f$b,
    #c: _f$c,
    #d: _f$d,
    #a: _f$a,
    #dt: _f$dt,
    #en: _f$en,
  };

  static Subtask _instantiate(DecodingData data) {
    return Subtask(
        title: data.dec(_f$title),
        b: data.dec(_f$b),
        c: data.dec(_f$c),
        d: data.dec(_f$d),
        a: data.dec(_f$a),
        dt: data.dec(_f$dt),
        en: data.dec(_f$en));
  }

  @override
  final Function instantiate = _instantiate;

  static Subtask fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<Subtask>(map);
  }

  static Subtask fromJson(String json) {
    return ensureInitialized().decodeJson<Subtask>(json);
  }
}

mixin SubtaskMappable {
  String toJson() {
    return SubtaskMapper.ensureInitialized()
        .encodeJson<Subtask>(this as Subtask);
  }

  Map<String, dynamic> toMap() {
    return SubtaskMapper.ensureInitialized()
        .encodeMap<Subtask>(this as Subtask);
  }

  SubtaskCopyWith<Subtask, Subtask, Subtask> get copyWith =>
      _SubtaskCopyWithImpl<Subtask, Subtask>(
          this as Subtask, $identity, $identity);
  @override
  String toString() {
    return SubtaskMapper.ensureInitialized().stringifyValue(this as Subtask);
  }

  @override
  bool operator ==(Object other) {
    return SubtaskMapper.ensureInitialized()
        .equalsValue(this as Subtask, other);
  }

  @override
  int get hashCode {
    return SubtaskMapper.ensureInitialized().hashValue(this as Subtask);
  }
}

extension SubtaskValueCopy<$R, $Out> on ObjectCopyWith<$R, Subtask, $Out> {
  SubtaskCopyWith<$R, Subtask, $Out> get $asSubtask =>
      $base.as((v, t, t2) => _SubtaskCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class SubtaskCopyWith<$R, $In extends Subtask, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call(
      {String? title,
      int? b,
      double? c,
      double? d,
      int? a,
      DateTime? dt,
      En? en});
  SubtaskCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _SubtaskCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, Subtask, $Out>
    implements SubtaskCopyWith<$R, Subtask, $Out> {
  _SubtaskCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<Subtask> $mapper =
      SubtaskMapper.ensureInitialized();
  @override
  $R call(
          {Object? title = $none,
          int? b,
          Object? c = $none,
          double? d,
          Object? a = $none,
          DateTime? dt,
          Object? en = $none}) =>
      $apply(FieldCopyWithData({
        if (title != $none) #title: title,
        if (b != null) #b: b,
        if (c != $none) #c: c,
        if (d != null) #d: d,
        if (a != $none) #a: a,
        if (dt != null) #dt: dt,
        if (en != $none) #en: en
      }));
  @override
  Subtask $make(CopyWithData data) => Subtask(
      title: data.get(#title, or: $value.title),
      b: data.get(#b, or: $value.b),
      c: data.get(#c, or: $value.c),
      d: data.get(#d, or: $value.d),
      a: data.get(#a, or: $value.a),
      dt: data.get(#dt, or: $value.dt),
      en: data.get(#en, or: $value.en));

  @override
  SubtaskCopyWith<$R2, Subtask, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _SubtaskCopyWithImpl<$R2, $Out2>($value, $cast, t);
}
