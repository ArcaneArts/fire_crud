import 'package:fire_crud/fire_crud.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:toxic_flutter/extensions/future.dart';
import 'package:toxic_flutter/extensions/stream.dart';

class FireGrid<T> extends StatefulWidget {
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
  final SliverGridDelegate gridDelegate;
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
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;
  final Widget filtered;
  final bool Function(T item)? filter;

  const FireGrid(
      {super.key,
      this.filtered = const SizedBox.shrink(),
      this.filter,
      required this.crud,
      required this.builder,
      this.empty = const SizedBox.shrink(),
      this.onViewerInit,
      this.loading = const ListTile(),
      this.failed = const SizedBox.shrink(),
      this.query,
      this.streamWindow = 50,
      this.streamWindowPadding = 9,
      this.memorySize = 256,
      this.limitedSizeDoubleCheckCountThreshold = 10000,
      this.sizeCheckInterval = const Duration(seconds: 30),
      this.streamRetargetCooldown = const Duration(seconds: 3),
      this.controller,
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
      this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
      required this.gridDelegate});

  @override
  State<FireGrid<T>> createState() => _FireGridState<T>();
}

class _FireGridState<T> extends State<FireGrid<T>> {
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
          : GridView.builder(
              shrinkWrap: widget.shrinkWrap,
              physics: widget.physics,
              semanticChildCount: widget.semanticChildCount,
              scrollDirection: widget.scrollDirection,
              restorationId: widget.restorationId,
              primary: widget.primary,
              keyboardDismissBehavior: widget.keyboardDismissBehavior,
              findChildIndexCallback: widget.findChildIndexCallback,
              dragStartBehavior: widget.dragStartBehavior,
              clipBehavior: widget.clipBehavior,
              cacheExtent: widget.cacheExtent,
              addSemanticIndexes: widget.addSemanticIndexes,
              addRepaintBoundaries: widget.addRepaintBoundaries,
              addAutomaticKeepAlives: widget.addAutomaticKeepAlives,
              reverse: widget.reverse,
              padding: widget.padding,
              controller: widget.controller,
              gridDelegate: widget.gridDelegate,
              itemCount: size,
              itemBuilder: (context, index) => viewer.getAt(index).build(
                  (item) => item == null
                      ? widget.failed
                      : (widget.filter?.call(item) ?? true)
                          ? widget.builder(context, item)
                          : widget.filtered,
                  loading: widget.loading))));
}
