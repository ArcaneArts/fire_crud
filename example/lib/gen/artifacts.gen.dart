// GENERATED – do not modify by hand

// ignore_for_file: camel_case_types
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: library_private_types_in_public_api
import "package:example/task.dart";
import "package:example/subtask.dart";
import "dart:core";
import "package:artifact/artifact.dart";
import "package:example/en.dart";
typedef _0 = ArtifactCodecUtil;
typedef _1 = Map<String, dynamic>;
typedef _2 = List<String>;
typedef _3 = String;
typedef _4 = dynamic;
typedef _5 = int;
typedef _6 = Task;
typedef _7 = Subtask;
typedef _8 = DateTime;
typedef _9 = List;
typedef _a = double;
typedef _b = List<DateTime>;
typedef _c = bool;
typedef _d = List<Subtask>;
typedef _e = List<int>;
typedef _f = ArgumentError;
typedef _g = En;
_2 _S = ['dates','subtasks','ints','integer','doub','subtask','date','title','Missing required Subtask."dt" in map '];
const bool _T = true;
const bool _F = false;
const _5 _ = 0;
extension $Task on _6 {
  _6 get _t => this;
  _3 toJson({bool pretty = false}) => _0.j(pretty, toMap);
  _1 toMap() {
    _;
    return <_3, _4>{
      _S[0]:  dates.map((e) =>  _0.ea(e)).toList(),
      _S[1]:  subtasks.map((e) =>  e.toMap()).toList(),
      _S[2]:  ints.map((e) =>  _0.ea(e)).toList(),
      _S[3]:  _0.ea(integer),
      _S[4]:  _0.ea(doub),
      _S[5]:  subtask?.toMap(),
      _S[6]:  _0.ea(date),
      'str':  _0.ea(str),
    };
  }
  static _6 fromJson(String j) => fromMap(_0.o(j));
  static _6 fromMap(_1 map) {
    _;
    return Task(
      dates: map.$c(_S[0]) ?  (map[_S[0]] as _9).map((e) =>  _0.da(e, _8) as _8).toList() : const [],
      subtasks: map.$c(_S[1]) ?  (map[_S[1]] as _9).map((e) => $Subtask.fromMap((e) as _1)).toList() : const [],
      ints: map.$c(_S[2]) ?  (map[_S[2]] as _9).map((e) =>  _0.da(e, _5) as _5).toList() : const [],
      integer: map.$c(_S[3]) ?  _0.da(map[_S[3]], _5) as _5 : 0,
      doub: map.$c(_S[4]) ?  _0.da(map[_S[4]], _a) as _a : 0,
      subtask: map.$c(_S[5]) ? $Subtask.fromMap((map[_S[5]]) as _1) : null,
      date: map.$c(_S[6]) ?  _0.da(map[_S[6]], _8) as _8? : null,
      str: map.$c('str') ?  _0.da(map['str'], _3) as _3 : "",
    );
  }
  _6 copyWith({
    _b? dates,
    _c resetDates = _F,
    _d? subtasks,
    _c resetSubtasks = _F,
    _e? ints,
    _c resetInts = _F,
    _5? integer,
    _c resetInteger = _F,
    _5? deltaInteger,
    _a? doub,
    _c resetDoub = _F,
    _a? deltaDoub,
    _7? subtask,
    _c deleteSubtask = _F,
    _8? date,
    _c deleteDate = _F,
    _3? str,
    _c resetStr = _F,
  }) 
    => Task(
      dates:  resetDates ? const [] : (dates ?? _t.dates),
      subtasks:  resetSubtasks ? const [] : (subtasks ?? _t.subtasks),
      ints:  resetInts ? const [] : (ints ?? _t.ints),
      integer: deltaInteger != null ? (integer ?? _t.integer) + deltaInteger :  resetInteger ? 0 : (integer ?? _t.integer),
      doub: deltaDoub != null ? (doub ?? _t.doub) + deltaDoub :  resetDoub ? 0 : (doub ?? _t.doub),
      subtask:  deleteSubtask ? null : (subtask ?? _t.subtask),
      date:  deleteDate ? null : (date ?? _t.date),
      str:  resetStr ? "" : (str ?? _t.str),
    );
}
extension $Subtask on _7 {
  _7 get _t => this;
  _3 toJson({bool pretty = false}) => _0.j(pretty, toMap);
  _1 toMap() {
    _;
    return <_3, _4>{
      _S[7]:  _0.ea(title),
      'b':  _0.ea(b),
      'c':  _0.ea(c),
      'd':  _0.ea(d),
      'a':  _0.ea(a),
      'dt':  _0.ea(dt),
      'en':  en?.name,
    };
  }
  static _7 fromJson(String j) => fromMap(_0.o(j));
  static _7 fromMap(_1 map) {
    _;
    return Subtask(
      title: map.$c(_S[7]) ?  _0.da(map[_S[7]], _3) as _3? : null,
      b: map.$c('b') ?  _0.da(map['b'], _5) as _5 : 0,
      c: map.$c('c') ?  _0.da(map['c'], _a) as _a? : null,
      d: map.$c('d') ?  _0.da(map['d'], _a) as _a : 0,
      a: map.$c('a') ?  _0.da(map['a'], _5) as _5? : null,
      dt: map.$c('dt') ?  _0.da(map['dt'], _8) as _8 : (throw _f('${_S[8]}$map.')),
      en: map.$c('en') ? _0.e(En.values, map['en']) as En? : null,
    );
  }
  _7 copyWith({
    _3? title,
    _c deleteTitle = _F,
    _5? b,
    _c resetB = _F,
    _5? deltaB,
    _a? c,
    _c deleteC = _F,
    _a? deltaC,
    _a? d,
    _c resetD = _F,
    _a? deltaD,
    _5? a,
    _c deleteA = _F,
    _5? deltaA,
    _8? dt,
    _g? en,
    _c deleteEn = _F,
  }) 
    => Subtask(
      title:  deleteTitle ? null : (title ?? _t.title),
      b: deltaB != null ? (b ?? _t.b) + deltaB :  resetB ? 0 : (b ?? _t.b),
      c: deltaC != null ? (c ?? _t.c ?? 0) + deltaC :  deleteC ? null : (c ?? _t.c),
      d: deltaD != null ? (d ?? _t.d) + deltaD :  resetD ? 0 : (d ?? _t.d),
      a: deltaA != null ? (a ?? _t.a ?? 0) + deltaA :  deleteA ? null : (a ?? _t.a),
      dt: dt ?? _t.dt,
      en:  deleteEn ? null : (en ?? _t.en),
    );
}

