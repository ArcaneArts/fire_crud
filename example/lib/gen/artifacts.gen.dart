// GENERATED – do not modify by hand

// ignore_for_file: camel_case_types
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: constant_identifier_names
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: unused_element
import "package:example/task.dart";import "package:example/subtask.dart";import "dart:core";import "package:artifact/artifact.dart";import "package:example/en.dart";
typedef _0=ArtifactCodecUtil;typedef _1=Map<String, dynamic>;typedef _2=List<String>;typedef _3=String;typedef _4=dynamic;typedef _5=int;typedef _6=Task;typedef _7=Subtask;typedef _8=DateTime;typedef _9=List;typedef _a=double;typedef _b=List<DateTime>;typedef _c=bool;typedef _d=List<Subtask>;typedef _e=List<int>;typedef _f=ArgumentError;typedef _g=En;typedef _h=List<dynamic>;
const _2 _S=['dates','subtasks','ints','integer','doub','subtask','date','title','Missing required Subtask."dt" in map '];const _h _V=[<_8>[],<_7>[],<_5>[]];const _c _T=true;const _c _F=false;const _5 _ = 0;
extension $Task on _6{
  _6 get _H=>this;
  _3 toJson({bool pretty=_F})=>_0.j(pretty, toMap);
  _3 toYaml()=>_0.y(toMap);
  _3 toToml()=>_0.u(toMap);
  _3 toXml({bool pretty=_F})=>_0.z(pretty,toMap);
  _3 toProperties()=>_0.h(toMap);
  _1 toMap(){_;return <_3, _4>{_S[0]:dates.$m((e)=> _0.ea(e)).$l,_S[1]:subtasks.$m((e)=> e.toMap()).$l,_S[2]:ints.$m((e)=> _0.ea(e)).$l,_S[3]:_0.ea(integer),_S[4]:_0.ea(doub),_S[5]:subtask?.toMap(),_S[6]:_0.ea(date),'str':_0.ea(str),}.$nn;}
  static _6 fromJson(String j)=>fromMap(_0.o(j));
  static _6 fromYaml(String j)=>fromMap(_0.v(j));
  static _6 fromToml(String j)=>fromMap(_0.t(j));
  static _6 fromProperties(String j)=>fromMap(_0.g(j));
  static _6 fromMap(_1 r){_;_1 m=r.$nn;return _6(dates: m.$c(_S[0]) ?  (m[_S[0]] as _9).$m((e)=> _0.da(e, _8) as _8).$l : _V[0],subtasks: m.$c(_S[1]) ?  (m[_S[1]] as _9).$m((e)=>$Subtask.fromMap((e) as _1)).$l : _V[1],ints: m.$c(_S[2]) ?  (m[_S[2]] as _9).$m((e)=> _0.da(e, _5) as _5).$l : _V[2],integer: m.$c(_S[3]) ?  _0.da(m[_S[3]], _5) as _5 : 0,doub: m.$c(_S[4]) ?  _0.da(m[_S[4]], _a) as _a : 0,subtask: m.$c(_S[5]) ? $Subtask.fromMap((m[_S[5]]) as _1) : null,date: m.$c(_S[6]) ?  _0.da(m[_S[6]], _8) as _8? : null,str: m.$c('str') ?  _0.da(m['str'], _3) as _3 : "",);}
  _6 copyWith({_b? dates,_c resetDates=_F,_b? appendDates,_b? removeDates,_d? subtasks,_c resetSubtasks=_F,_d? appendSubtasks,_d? removeSubtasks,_e? ints,_c resetInts=_F,_e? appendInts,_e? removeInts,_5? integer,_c resetInteger=_F,_5? deltaInteger,_a? doub,_c resetDoub=_F,_a? deltaDoub,_7? subtask,_c deleteSubtask=_F,_8? date,_c deleteDate=_F,_3? str,_c resetStr=_F,})=>_6(dates: ((resetDates?_V[0]:(dates??_H.dates)) as _b).$u(appendDates,removeDates),subtasks: ((resetSubtasks?_V[1]:(subtasks??_H.subtasks)) as _d).$u(appendSubtasks,removeSubtasks),ints: ((resetInts?_V[2]:(ints??_H.ints)) as _e).$u(appendInts,removeInts),integer: deltaInteger!=null?(integer??_H.integer)+deltaInteger:resetInteger?0:(integer??_H.integer),doub: deltaDoub!=null?(doub??_H.doub)+deltaDoub:resetDoub?0:(doub??_H.doub),subtask: deleteSubtask?null:(subtask??_H.subtask),date: deleteDate?null:(date??_H.date),str: resetStr?"":(str??_H.str),);
  static _6 get newInstance=>_6();
}
extension $Subtask on _7{
  _7 get _H=>this;
  _3 toJson({bool pretty=_F})=>_0.j(pretty, toMap);
  _3 toYaml()=>_0.y(toMap);
  _3 toToml()=>_0.u(toMap);
  _3 toXml({bool pretty=_F})=>_0.z(pretty,toMap);
  _3 toProperties()=>_0.h(toMap);
  _1 toMap(){_;return <_3, _4>{_S[7]:_0.ea(title),'b':_0.ea(b),'c':_0.ea(c),'d':_0.ea(d),'a':_0.ea(a),'dt':_0.ea(dt),'en':en?.name,}.$nn;}
  static _7 fromJson(String j)=>fromMap(_0.o(j));
  static _7 fromYaml(String j)=>fromMap(_0.v(j));
  static _7 fromToml(String j)=>fromMap(_0.t(j));
  static _7 fromProperties(String j)=>fromMap(_0.g(j));
  static _7 fromMap(_1 r){_;_1 m=r.$nn;return _7(title: m.$c(_S[7]) ?  _0.da(m[_S[7]], _3) as _3? : null,b: m.$c('b') ?  _0.da(m['b'], _5) as _5 : 0,c: m.$c('c') ?  _0.da(m['c'], _a) as _a? : null,d: m.$c('d') ?  _0.da(m['d'], _a) as _a : 0,a: m.$c('a') ?  _0.da(m['a'], _5) as _5? : null,dt: m.$c('dt')? _0.da(m['dt'], _8) as _8:(throw _f('${_S[8]}$m.')),en: m.$c('en') ? _0.e(En.values, m['en']) as En? : null,);}
  _7 copyWith({_3? title,_c deleteTitle=_F,_5? b,_c resetB=_F,_5? deltaB,_a? c,_c deleteC=_F,_a? deltaC,_a? d,_c resetD=_F,_a? deltaD,_5? a,_c deleteA=_F,_5? deltaA,_8? dt,_g? en,_c deleteEn=_F,})=>_7(title: deleteTitle?null:(title??_H.title),b: deltaB!=null?(b??_H.b)+deltaB:resetB?0:(b??_H.b),c: deltaC!=null?(c??_H.c??0)+deltaC:deleteC?null:(c??_H.c),d: deltaD!=null?(d??_H.d)+deltaD:resetD?0:(d??_H.d),a: deltaA!=null?(a??_H.a??0)+deltaA:deleteA?null:(a??_H.a),dt: dt??_H.dt,en: deleteEn?null:(en??_H.en),);
  static _7 get newInstance=>_7(dt: DateTime.now(),);
}

bool $isArtifact(dynamic v)=>v==null?false : v is! Type ?$isArtifact(v.runtimeType):v == _6 ||v == _7 ;
T $constructArtifact<T>() => T==_6 ?$Task.newInstance as T :T==_7 ?$Subtask.newInstance as T : throw Exception();
_1 $artifactToMap(Object o)=>o is _6 ?o.toMap():o is _7 ?o.toMap():throw Exception();
T $artifactFromMap<T>(_1 m)=>T==_6 ?$Task.fromMap(m) as T:T==_7 ?$Subtask.fromMap(m) as T: throw Exception();
