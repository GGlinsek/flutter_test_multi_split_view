import 'dart:async';

import 'package:flutter/material.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:test_multi_split_view/widgets/serializable_multi_split_view.dart';

import 'movable_box.dart';

class DraggableMultiListView extends SerializableMultiSplitView {
  final StreamController<Area> onWidgetInController;
  final StreamController<(MovableBox, MoveDirection)>
      onWidgetMovedOutController;

  DraggableMultiListView({
    super.key,
    super.axis,
    required this.onWidgetInController,
    required this.onWidgetMovedOutController,
    super.controller,
    // super.initialAreas,
    super.onDividerDragUpdate,
  });

  @override
  State<DraggableMultiListView> createState() => _DraggableMultiListViewState();
}

class _DraggableMultiListViewState extends State<DraggableMultiListView> {
  static const _rootKey = ValueKey("root");
  final _controllers = <Key, MultiSplitViewController>{};
  final _movingControllerMap = <Key, StreamController<bool>>{};
  final _movedControllerMap = <Key, StreamController<MoveRecord>>{};
  final _removedControllerMap = <Key, StreamController<Key>>{};
  final _edgeControllerMap = <Key, StreamController<EdgeRecord>>{};

  final _areaMap = <Key, List<double>>{};

  @override
  void initState() {
    super.initState();
    _areaMap[_rootKey] = <double>[];
    _controllers[_rootKey] = MultiSplitViewController();
    // _controllers[_rootKey]?.addArea(Area(builder: (BuildContext context, Area area) => const Text("sam mal")));

    if (!widget.onWidgetInController.hasListener) {
      widget.onWidgetInController.stream.listen((event) {
        final key = UniqueKey();
        _movingControllerMap[key] = StreamController<bool>();
        _movingControllerMap[key]!.stream.listen((isMoving) {
          // setState(() => _isMoving = isMoving);
        });
        _movedControllerMap[key] = StreamController<MoveRecord>();
        _edgeControllerMap[key] = StreamController<EdgeRecord>();
        _edgeControllerMap[key]!.stream.listen(_edgeControllerHandler);
        _removedControllerMap[key] = StreamController<Key>();
        _controllers[_rootKey]?.addArea(Area(data: key, builder: (BuildContext context, Area area) =>
          MovableBox(
            key: key,
            onMoveController: _movingControllerMap[key]!,
            onMovedController: _movedControllerMap[key]!,
            removedController: _removedControllerMap[key]!,
            onEdgeController: _edgeControllerMap[key]!,
            child: event.data,
          ),
        ),);
      });
    }

  }

  @override
  void dispose() {
    super.dispose();
    for (final controller in _movingControllerMap.values) {
      controller.close();
    }
    for (final controller in _movedControllerMap.values) {
      controller.close();
    }
    for (final controller in _removedControllerMap.values) {
      controller.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controllers[_rootKey]?.areasCount != 0) {
      return SerializableMultiSplitView(
        key: _rootKey,
        controller: _controllers[_rootKey]!,
        axis: widget.axis,

        // onWeightChange: () {
        //   _areaMap[_rootKey] = List<double>.generate(
        //     _widgets.length,
        //     (index) => _controllers[_rootKey]!.areas[index].weight!,
        //   );
        //   debugPrint("Root AreaMap: ${_areaMap[_rootKey]}");
        // },
      );
    }
    else {
      return const Text("Add a widget");
    }
  }

  // Widget? _recursiveSearch(List<Widget> widgets, Key key) {
  //   for (final widget in widgets) {
  //     if (widget.key == key) {
  //       return widget;
  //     }
  //     else if (widget is SerializableMultiSplitView) {
  //       final result = _recursiveSearch(widget.children, key);
  //       if (result != null) {
  //         return result;
  //       }
  //     }
  //   }
  //   return null;
  // }

  // List<Widget> _removeEmptySplitViews(List<Widget> widgets) {
  //   var cleanedWidgets = widgets;
  //   var widgetList = List.of(widgets);
  //   for (var widget in widgetList) {
  //     if (widget is SerializableMultiSplitView) {
  //       if (widget.children.isEmpty) {
  //         if (_areaMap.containsKey(widget.key)) {
  //           _areaMap.remove(widget.key);
  //         }
  //         cleanedWidgets.remove(widget);
  //       }
  //       else {
  //         var cleanedWidget = _removeEmptyChildren(widget);
  //         if (cleanedWidget == null) {
  //           if (_areaMap.containsKey(widget.key)) {
  //             _areaMap.remove(widget.key);
  //           }
  //           cleanedWidgets.remove(widget);
  //         }
  //         else {
  //           cleanedWidgets[cleanedWidgets.indexWhere((element) => element == widget)] = cleanedWidget;
  //
  //         }
  //       }
  //     }
  //     _controllers[widget.key]!.areas = List<Area>.from(_controllers[widget.key]!.areas);
  //   }
  //   _controllers[_rootKey]!.areas = List<Area>.from(_controllers[_rootKey]!.areas);
  //   return cleanedWidgets;
  // }

  // Widget? _removeEmptyChildren(SerializableMultiSplitView widget) {
  //   final widgetChildren = List.of(widget.children);
  //   for (final child in widgetChildren) {
  //     if (child is SerializableMultiSplitView) {
  //       if (child.children.isNotEmpty) {
  //         var childWidget = _removeEmptyChildren(child);
  //         if (childWidget == null){
  //           if (_areaMap.containsKey(child.key)) {
  //             _areaMap.remove(child.key);
  //           }
  //           widget.children.remove(child);
  //         }
  //         else {
  //           widget.children[widget.children.indexWhere((element) => element == child)] = childWidget;
  //         }
  //       }
  //       if (child.children.isEmpty) {
  //         if (_areaMap.containsKey(child.key)) {
  //           _areaMap.remove(child.key);
  //         }
  //         widget.children.remove(child);
  //       }
  //     }
  //   }
  //   if (widget.children.isEmpty) {
  //     return null;
  //   }
  //
  //
  //
  //   _controllers[widget.key]!.areas = List<Area>.from(_controllers[widget.key]!.areas);
  //   return widget;
  // }

  // SerializableMultiSplitView? _getMovableBoxParentViewRecursive1(
  //     MovableBox box, List<Widget> widgets) {
  //   for (final widget in widgets) {
  //     if (widget is SerializableMultiSplitView) {
  //       for (final child in widget.children) {
  //         if (child.key == box.key) {
  //           return widget;
  //         } else {
  //           final result =
  //               _getMovableBoxParentViewKeyRecursive(box, widget.children);
  //           if (result != null) {
  //             return result;
  //           }
  //         }
  //       }
  //     }
  //   }
  //   return null;
  // }

  Key? _getMovableBoxParentViewKeyRecursive(
      MovableBox box, Key key) {

    for (Area asd in _controllers[key]!.areas) {
      if (asd.data == box.key) {
        return key;
      }
      else if (asd.builder is SerializableMultiSplitView) {
        final result = _getMovableBoxParentViewKeyRecursive(box, key);
        if (result != null) {
          return result;
        }
      }
    }
    return null;
  }

  _edgeControllerHandler(EdgeRecord record) {
    debugPrint("EdgeRecord: $record");
    MovableBox targetBox = record.targetBox;
    MovableBox movedBox = record.movedBox;
    MoveDirection direction = record.moveDirection;
    // ignore if the boxes are the same
    if (targetBox.key == movedBox.key) {
      debugPrint("same widget!!");
      return;
    }
    // merge the two boxes into a new multi split view
    // the new view must have a controller
    final newMultiSplitViewKey = UniqueKey();
    _controllers[newMultiSplitViewKey] = MultiSplitViewController();
    _controllers[newMultiSplitViewKey]?.areas =
      (direction == MoveDirection.down || direction == MoveDirection.right)
          ? [Area(data: newMultiSplitViewKey, builder: (BuildContext context, Area area) => targetBox), Area(data: newMultiSplitViewKey, builder: (BuildContext context, Area area) => movedBox)]
          : [Area(data: newMultiSplitViewKey, builder: (BuildContext context, Area area) => movedBox), Area(data: newMultiSplitViewKey, builder: (BuildContext context, Area area) => targetBox)];

    final newMultiSplitView = SerializableMultiSplitView(
      key: newMultiSplitViewKey,
      controller: _controllers[newMultiSplitViewKey],
      axis: direction == MoveDirection.up || direction == MoveDirection.down
          ? Axis.vertical
          : Axis.horizontal,

      // onWeightChange: () {
      //   final newWeights = <double>[];
      //   for (final a in _controllers[newMultiSplitViewKey]!.areas) {
      //     newWeights.add(a.weight!);
      //   }
      //   _areaMap[newMultiSplitViewKey] = newWeights;
      //   debugPrint(
      //       "$newMultiSplitViewKey AreaMap: ${_areaMap[newMultiSplitViewKey]}");
      // },
    );

    final targetBoxParentKey =
        _getMovableBoxParentViewKeyRecursive(targetBox, _rootKey);
    final movedBoxParentKey =
        _getMovableBoxParentViewKeyRecursive(movedBox, _rootKey);

    debugPrint(
        "Edge MovedWidgetParentKey: $movedBoxParentKey; TargetWidgetParentKey: $targetBoxParentKey");

    // if both boxes are children of the root multi split view
    if (targetBoxParentKey == _rootKey && movedBoxParentKey == _rootKey) {
      // 1. get the target & moved box index from the root multi split view
      final targetBoxIndex = _controllers[targetBoxParentKey]?.areas.indexWhere((w) => w.data == targetBox.key);
      final movedBoxIndex = _controllers[movedBoxParentKey]?.areas.indexWhere((w) => w.data == movedBox.key);
      // 2. remove moved box from the root multi split view
      _controllers[movedBoxParentKey]?.removeAreaAt(movedBoxIndex!);
      // 3. insert the new multi split view to the root multi split view on the target box index
      var areas = _controllers[targetBoxParentKey]?.areas.toList();

      areas?.insert(targetBoxIndex!, Area(data: newMultiSplitViewKey, builder: (BuildContext context, Area area) => newMultiSplitView));
      // 4. remove target box from the root multi split view
      areas?.removeWhere((w) => w.data == targetBox.key);

      _controllers[targetBoxParentKey]?.areas = areas!;
      // 5. update the areas of the root multi split view
      final rootAreas = List<Area>.from(_controllers[_rootKey]!.areas);
      // rootAreas.removeAt(0);
      // _controllers[_rootKey]!.areas = rootAreas;
      // // 6. update the areas of the new multi split view
      // _controllers[newMultiSplitViewKey]!.areas =
      //     List<Area>.generate(2, (index) => Area());
    }

    // // if the target box is a child of the root multi split view, but the moved box is a child of a child multi split view
    // if (targetBoxParentKey == null && movedBoxParentKey != null) {
    //   // 1. get the index of the target box from the root multi split view
    //   final targetBoxIndex = _widgets.indexWhere((w) => w.key == targetBox.key);
    //   // 2. remove the moved box from the child multi split view
    //   (_recursiveSearch(_widgets, movedBoxParentKey)!
    //           as SerializableMultiSplitView)
    //       .children
    //       .remove(movedBox);
    //   // 2.1 remove the parent if empty
    //   bool movedParentEmpty = false;
    //   if ((_recursiveSearch(_widgets, movedBoxParentKey)!
    //           as SerializableMultiSplitView)
    //       .children
    //       .isEmpty) {
    //     movedParentEmpty = true;
    //     _widgets.remove(_recursiveSearch(_widgets, movedBoxParentKey)!);
    //   }
    //   // 3. remove the target box from the root multi split view
    //   _widgets.remove(targetBox);
    //   // 4. insert the new multi split view to the root multi split view on the target box index
    //   _widgets.insert(targetBoxIndex, newMultiSplitView);
    //   // 5. update the areas of the new multi split view
    //   _controllers[newMultiSplitViewKey]!.areas =
    //       List<Area>.generate(2, (index) => Area());
    //   // 6. update the areas of the moved box parent, if the moved parent is not empty
    //   if (!movedParentEmpty) {
    //     final movedBoxParentAreas =
    //         List<Area>.from(_controllers[movedBoxParentKey]!.areas);
    //     movedBoxParentAreas.removeAt(0);
    //     _controllers[movedBoxParentKey]!.areas = movedBoxParentAreas;
    //   }
    // }
    //
    // // if the moved box is a child of the root multi split view, but the target box is a child of a child multi split view
    // if (targetBoxParentKey != null && movedBoxParentKey == null) {
    //   // 1. get the index of the target box in the target parent multi split view
    //   final targetBoxIndex = (_recursiveSearch(_widgets, targetBoxParentKey)!
    //           as SerializableMultiSplitView)
    //       .children
    //       .indexWhere((element) => element.key == targetBox.key);
    //   // 2. remove the target box from the target parent multi split view
    //   (_recursiveSearch(_widgets, targetBoxParentKey)!
    //           as SerializableMultiSplitView)
    //       .children
    //       .remove(targetBox);
    //   // 3. remove the moved box from the root multi split view
    //   _widgets.remove(movedBox);
    //   // 4. insert the new multi split view to the target parent multi split view on the target box index
    //   (_recursiveSearch(_widgets, targetBoxParentKey)!
    //           as SerializableMultiSplitView)
    //       .children
    //       .insert(targetBoxIndex, newMultiSplitView);
    //   // 5. update the areas of the target parent multi split view
    //   final targetAreas =
    //       List<Area>.from(_controllers[targetBoxParentKey]!.areas);
    //   _controllers[targetBoxParentKey]!.areas = targetAreas;
    //   // 6. update the areas of the new multi split view
    //   _controllers[newMultiSplitViewKey]!.areas =
    //       List<Area>.generate(2, (index) => Area());
    //   final rootAreas = List<Area>.from(_controllers[_rootKey]!.areas);
    //   rootAreas.removeAt(0);
    //   _controllers[_rootKey]!.areas = rootAreas;
    // }
    //
    // // if both boxes are children of a child multi split view
    // if (targetBoxParentKey != null && movedBoxParentKey != null) {
    //   // 1. get the index of the target box in the target parent multi split view
    //   final targetBoxIndex = (_recursiveSearch(_widgets, targetBoxParentKey)!
    //           as SerializableMultiSplitView)
    //       .children
    //       .indexWhere((element) => element.key == targetBox.key);
    //   // 2. remove the target box from the target parent multi split view
    //   (_recursiveSearch(_widgets, targetBoxParentKey)!
    //           as SerializableMultiSplitView)
    //       .children
    //       .remove(targetBox);
    //   // 3. remove the moved box from the moved parent multi split view
    //   (_recursiveSearch(_widgets, movedBoxParentKey)!
    //           as SerializableMultiSplitView)
    //       .children
    //       .remove(movedBox);
    //   // 3.a remove the parent if empty
    //   bool movedParentEmpty = false;
    //   if ((_recursiveSearch(_widgets, movedBoxParentKey)!
    //           as SerializableMultiSplitView)
    //       .children
    //       .isEmpty) {
    //     movedParentEmpty = true;
    //     _widgets.remove(_recursiveSearch(_widgets, movedBoxParentKey)!);
    //   }
    //   // 4. insert the new multi split view to the target parent multi split view on the target box index
    //   (_recursiveSearch(_widgets, targetBoxParentKey)!
    //           as SerializableMultiSplitView)
    //       .children
    //       .insert(targetBoxIndex, newMultiSplitView);
    //   // 5. update the areas of the target parent multi split view
    //   final targetAreas =
    //       List<Area>.from(_controllers[targetBoxParentKey]!.areas);
    //   _controllers[targetBoxParentKey]!.areas = targetAreas;
    //   // 6. update the areas of the moved parent multi split view, if the moved parent is not empty
    //   if (!movedParentEmpty) {
    //     final movedBoxParentAreas =
    //         List<Area>.from(_controllers[movedBoxParentKey]!.areas);
    //     movedBoxParentAreas.removeAt(0);
    //     _controllers[movedBoxParentKey]!.areas = movedBoxParentAreas;
    //   }
    //   // 7. update the areas of the new multi split view
    //   _controllers[newMultiSplitViewKey]!.areas =
    //       List<Area>.generate(2, (index) => Area());
    //
    //   if (movedParentEmpty) {
    //     debugPrint("movedparentempty");
    //     _controllers.remove(movedBoxParentKey);
    //   }
    // }
    // _widgets = _removeEmptySplitViews(_widgets);
  }
}
