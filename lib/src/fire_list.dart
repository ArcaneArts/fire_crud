import 'package:fire_crud/fire_crud.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:toxic/toxic.dart';

class FireList<T> extends StatefulWidget {
  final FireCrud<T> crud;
  final QueryBuilder? query;
  final int streamWindow;
  final int streamWindowPadding;
  final int memorySize;
  final Duration streamRetargetCooldown;
  final Duration sizeCheckInterval;
  final int limitedSizeDoubleCheckCountThreshold;
  final Widget Function(BuildContext context, T data) builder;
  final Widget loading;
  final Widget failed;
  final Widget empty;
  final Function(CollectionViewer<T>)? onViewerInit;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final bool reverse;
  final bool addAutomaticKeepAlives;
  final bool addRepaintBoundaries;
  final bool addSemanticIndexes;
  final double cacheExtent;
  final Clip clipBehavior;
  final DragStartBehavior dragStartBehavior;
  final ChildIndexGetter? findChildIndexCallback;
  final double? itemExtent;
  final ItemExtentBuilder? itemExtentBuilder;
  final String? restorationId;
  final Axis scrollDirection;
  final int? semanticChildCount;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final bool? primary;
  final Widget? prototypeItem;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  const FireList(
      {super.key,
      required this.crud,
      required this.builder,
      this.empty = const SizedBox.shrink(),
      this.padding,
      this.reverse = false,
      this.addAutomaticKeepAlives = true,
      this.addRepaintBoundaries = true,
      this.addSemanticIndexes = true,
      this.cacheExtent = 250.0,
      this.clipBehavior = Clip.hardEdge,
      this.dragStartBehavior = DragStartBehavior.start,
      this.findChildIndexCallback,
      this.itemExtent,
      this.itemExtentBuilder,
      this.restorationId,
      this.scrollDirection = Axis.vertical,
      this.semanticChildCount,
      this.shrinkWrap = false,
      this.physics,
      this.primary,
      this.prototypeItem,
      this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
      this.controller,
      this.onViewerInit,
      this.loading = const ListTile(),
      this.failed = const SizedBox.shrink(),
      this.query,
      this.streamWindow = 50,
      this.streamWindowPadding = 9,
      this.memorySize = 256,
      this.limitedSizeDoubleCheckCountThreshold = 10000,
      this.sizeCheckInterval = const Duration(seconds: 30),
      this.streamRetargetCooldown = const Duration(seconds: 3)});

  @override
  State<FireList<T>> createState() => _FireListState<T>();
}

class _FireListState<T> extends State<FireList<T>> {
  late CollectionViewer<T> viewer;

  @override
  void initState() {
    viewer = widget.crud.view(
        streamWindowPadding: widget.streamWindowPadding,
        streamWindow: widget.streamWindow,
        memorySize: widget.memorySize,
        limitedSizeDoubleCheckCountThreshold:
            widget.limitedSizeDoubleCheckCountThreshold,
        sizeCheckInterval: widget.sizeCheckInterval,
        streamRetargetCooldown: widget.streamRetargetCooldown,
        query: widget.query);
    widget.onViewerInit?.call(viewer);
    super.initState();
  }

  @override
  void dispose() {
    viewer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      viewer.stream.build((viewer) => viewer.getSize().build((size) => size == 0
          ? widget.empty
          : ListView.builder(
              controller: widget.controller,
              padding: widget.padding,
              reverse: widget.reverse,
              addAutomaticKeepAlives: widget.addAutomaticKeepAlives,
              addRepaintBoundaries: widget.addRepaintBoundaries,
              addSemanticIndexes: widget.addSemanticIndexes,
              cacheExtent: widget.cacheExtent,
              clipBehavior: widget.clipBehavior,
              dragStartBehavior: widget.dragStartBehavior,
              findChildIndexCallback: widget.findChildIndexCallback,
              itemExtent: widget.itemExtent,
              itemExtentBuilder: widget.itemExtentBuilder,
              keyboardDismissBehavior: widget.keyboardDismissBehavior,
              physics: widget.physics,
              primary: widget.primary,
              prototypeItem: widget.prototypeItem,
              restorationId: widget.restorationId,
              scrollDirection: widget.scrollDirection,
              semanticChildCount: widget.semanticChildCount,
              shrinkWrap: widget.shrinkWrap,
              itemCount: size,
              itemBuilder: (context, index) => viewer.getAt(index).build(
                  (item) => item == null
                      ? widget.failed
                      : widget.builder(context, item),
                  loading: widget.loading))));
}
