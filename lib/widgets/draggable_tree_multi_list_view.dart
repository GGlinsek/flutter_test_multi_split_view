import 'dart:async';

import 'package:flutter/material.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:test_multi_split_view/widgets/serializable_multi_split_view.dart';

import '../data_types/tree.dart';
import 'movable_box.dart';

class DraggableTreeMultiListView extends StatefulWidget {
  final StreamController<Widget> onWidgetInController;
  final StreamController<(MovableBox, MoveDirection)>
      onWidgetMovedOutController;
  final Axis axis;
  final Tree<MultiSplitView> tree;

  const DraggableTreeMultiListView({
    super.key,
    required this.axis,
    required this.onWidgetInController,
    required this.onWidgetMovedOutController,
    required this.tree,
  });

  @override
  State<DraggableTreeMultiListView> createState() => _DraggableMultiListViewState();
}

class _DraggableMultiListViewState extends State<DraggableTreeMultiListView> {
  static const _rootKey = ValueKey("root");
  final _controllers = <Key, MultiSplitViewController>{};
  final _widgets = <Widget>[];
  final _movingControllerMap = <Key, StreamController<bool>>{};
  final _movedControllerMap = <Key, StreamController<MoveRecord>>{};
  final _removedControllerMap = <Key, StreamController<Key>>{};
  final _edgeControllerMap = <Key, StreamController<EdgeRecord>>{};

  final _areaMap = <Key, List<double>>{};

  @override
  void initState() {
    _areaMap[_rootKey] = <double>[];
    _controllers[_rootKey] = MultiSplitViewController();

    if (!widget.onWidgetInController.hasListener) {
      widget.onWidgetInController.stream.listen((event) {
        final key = UniqueKey();
        _movingControllerMap[key] = StreamController<bool>();
        _movingControllerMap[key]!.stream.listen((isMoving) {
          // setState(() => _isMoving = isMoving);
        });
        _movedControllerMap[key] = StreamController<MoveRecord>();
        _movedControllerMap[key]!.stream.listen(_movedControllerHandler);
        _edgeControllerMap[key] = StreamController<EdgeRecord>();
        _edgeControllerMap[key]!.stream.listen(_edgeControllerHandler);
        _removedControllerMap[key] = StreamController<Key>();
        _widgets.add(
          MovableBox(
            key: key,
            onMoveController: _movingControllerMap[key]!,
            onMovedController: _movedControllerMap[key]!,
            removedController: _removedControllerMap[key]!,
            onEdgeController: _edgeControllerMap[key]!,
            child: event,
          ),
        );
      });
    }

    super.initState();
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
    return MultiSplitView(
        key: _rootKey,
        resizable: false,
        antiAliasingWorkaround: false,
        controller: _controllers[_rootKey]!,
        axis: widget.axis,
        children: _widgets,
        onWeightChange: () {
          _areaMap[_rootKey] = List<double>.generate(
            _widgets.length,
            (index) => _controllers[_rootKey]!.areas[index].weight!,
          );
          debugPrint("Root AreaMap: ${_areaMap[_rootKey]}");
        });
  }

  Widget? _recursiveWidgetSearchByKey(Key key) {
    for (final widget in _widgets) {
      final result = _recursiveWidgetSearch(widget, key);
      if (result != null) {
        return result;
      }
    }
    return null;
  }

  Widget? _recursiveWidgetSearch(Widget widget, Key key) {
    if (widget.key == key) {
      return widget;
    } else if (widget is SerializableMultiSplitView) {
      for (final child in widget.children) {
        final result = _recursiveWidgetSearch(child, key);
        if (result != null) {
          return result;
        }
      }
    }
    return null;
  }

  SerializableMultiSplitView? _getMovableBoxParentViewRecursive(
      MovableBox box, List<Widget> widgets) {
    for (final widget in widgets) {
      if (widget is SerializableMultiSplitView) {
        for (final child in widget.children) {
          if (child.key == box.key) {
            return widget;
          } else {
            final result =
                _getMovableBoxParentViewRecursive(box, widget.children);
            if (result != null) {
              return result;
            }
          }
        }
      }
    }
    return null;
  }

  SerializableMultiSplitView? _getParentView(
      SerializableMultiSplitView view, List<Widget> widgets) {
    for (final widget in widgets) {
      if (widget is SerializableMultiSplitView) {
        for (final child in widget.children) {
          if (child.key == view.key) {
            return widget;
          } else {
            final result = _getParentView(view, widget.children);
            if (result != null) {
              return result;
            }
          }
        }
      }
    }
    return null;
  }


  _movedControllerHandler(MoveRecord data) {
    final movedWidget = data.movedBox;
    final targetWidget = data.targetBox;
    final movedWidgetParentKey =
        _getMovableBoxParentViewRecursive(movedWidget, _widgets)?.key;
    final targetWidgetParentKey =
        _getMovableBoxParentViewRecursive(targetWidget, _widgets)?.key;

    if (movedWidget.key == targetWidget.key) {
      return;
    }

    debugPrint(
        "Moved MovedWidgetParentKey: $movedWidgetParentKey; TargetWidgetParentKey: $targetWidgetParentKey");

    // 1. both widgets are children of the root multi split view
    if (movedWidgetParentKey == null && targetWidgetParentKey == null) {
      // 1. get the index of the target widget
      final targetWidgetIndex =
          _widgets.indexWhere((w) => w.key == targetWidget.key);
      // 2. remove the moved widget from the root multi split view
      _widgets.remove(movedWidget);
      // 3. insert the moved widget to the root multi split view at the index of the target widget
      _widgets.insert(targetWidgetIndex, movedWidget);
      // 4. update the areas of the root multi split view
      final rootAreas = List<Area>.from(_controllers[_rootKey]!.areas);
      _controllers[_rootKey]!.areas = rootAreas;
    }

    // 2. target widget is on the root multi split view and moved widget is a child of a child multi split view
    if (targetWidgetParentKey == null && movedWidgetParentKey != null) {
      // 1. remove the moved widget from the child multi split view
      (_recursiveWidgetSearchByKey(movedWidgetParentKey)!
              as SerializableMultiSplitView)
          .children
          .remove(movedWidget);
      // 1.1 remove the parent if empty
      bool movedParentEmpty = false;
      if ((_recursiveWidgetSearchByKey(movedWidgetParentKey)!
              as SerializableMultiSplitView)
          .children
          .isEmpty) {
        movedParentEmpty = true;
        _widgets.remove(_recursiveWidgetSearchByKey(movedWidgetParentKey)!);
      }
      // 2. get the index of the target widget
      final targetIndex = _widgets.indexWhere((w) => w.key == targetWidget.key);
      // 3. insert the moved widget to the root multi split view at the index of the target widget
      _widgets.insert(targetIndex, movedWidget);
      // 4. update the areas of the moved widget parent
      if (!movedParentEmpty) {
        _controllers[movedWidgetParentKey]!.areas =
            List<Area>.from(_controllers[movedWidgetParentKey]!.areas)
              ..removeAt(0);
      }
      // 5. update the areas of the root multi split view
      final rootAreas = List<Area>.from(_controllers[_rootKey]!.areas);
      rootAreas.insert(targetIndex, Area());
      _controllers[_rootKey]!.areas = rootAreas;

      // 6. remove the moved parent if it has only one child and put the child in the parent's place
      if ((_recursiveWidgetSearchByKey(movedWidgetParentKey)!
      as SerializableMultiSplitView)
          .children
          .length ==
          1) {
        final parent = _recursiveWidgetSearchByKey(movedWidgetParentKey)!
        as SerializableMultiSplitView;
        final parentsParent = _getParentView(parent, _widgets);
        int parentIndex = 0;

        if (parentsParent != null) {
          // TODO Check if this is valid!!!
          parentIndex =
              parentsParent.children.indexWhere((w) => w.key == parent.key);
          parentsParent.children.removeAt(parentIndex);
          parentsParent.children.insert(parentIndex, parent.children.first);
          final areas = List<Area>.from(_controllers[parentsParent.key]!.areas);
          _controllers[parentsParent.key]!.areas = areas;
        } else {
          parentIndex = _widgets.indexWhere((w) => w.key == parent.key);
          _widgets.remove(parent);
          _widgets.insert(parentIndex, parent.children.first);
          final areas = List<Area>.from(_controllers[_rootKey]!.areas);
          _controllers[_rootKey]!.areas = areas;
        }
      }
    }

    // 3. old widget is a child of root
    if (movedWidgetParentKey == null && targetWidgetParentKey != null) {
      final targetWidgetIndex =
          (_recursiveWidgetSearchByKey(targetWidgetParentKey)!
                  as SerializableMultiSplitView)
              .children
              .indexWhere((element) => element.key == targetWidget.key);
      (_recursiveWidgetSearchByKey(targetWidgetParentKey)!
              as SerializableMultiSplitView)
          .children
          .insert(targetWidgetIndex, movedWidget);

      final movedWidgetIndex =
          _widgets.indexWhere((w) => w.key == movedWidget.key);
      // _widgets.insert(movedWidgetIndex, targetWidget);
      _widgets.removeAt(movedWidgetIndex);

      final areas = List<Area>.from(_controllers[targetWidgetParentKey]!.areas);
      areas.add(Area());
      _controllers[targetWidgetParentKey]!.areas = areas;

      final rootAreas = List<Area>.from(_controllers[_rootKey]!.areas);
      rootAreas.removeAt(0);
      _controllers[_rootKey]!.areas = rootAreas;
    }

    // 4. both parents are multi split views
    if (movedWidgetParentKey != null && targetWidgetParentKey != null) {
      final movedWidgetIndex =
          (_recursiveWidgetSearchByKey(movedWidgetParentKey)!
                  as SerializableMultiSplitView)
              .children
              .indexWhere((w) => w.key == movedWidget.key);
      final targetWidgetIndex =
          (_recursiveWidgetSearchByKey(targetWidgetParentKey)!
                  as SerializableMultiSplitView)
              .children
              .indexWhere((w) => w.key == targetWidget.key);
      // remove the new widget from their parent
      (_recursiveWidgetSearchByKey(targetWidgetParentKey)!
              as SerializableMultiSplitView)
          .children
          .removeAt(targetWidgetIndex);
      // remove parent if empty
      if ((_recursiveWidgetSearchByKey(targetWidgetParentKey)!
              as SerializableMultiSplitView)
          .children
          .isEmpty) {
        _widgets.remove(_recursiveWidgetSearchByKey(targetWidgetParentKey)!);
      }
      // add the new widget to the old parent
      (_recursiveWidgetSearchByKey(movedWidgetParentKey)!
              as SerializableMultiSplitView)
          .children
          .insert(movedWidgetIndex, targetWidget);
      final movedWidgetParentAreas =
          List<Area>.from(_controllers[movedWidgetParentKey]!.areas);
      movedWidgetParentAreas.removeAt(0);
      _controllers[movedWidgetParentKey]!.areas = movedWidgetParentAreas;
      final targetWidgetParentAreas =
          List<Area>.from(_controllers[targetWidgetParentKey]!.areas);
      targetWidgetParentAreas.add(Area());
      _controllers[targetWidgetParentKey]!.areas = targetWidgetParentAreas;
    }
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
    final newMultiSplitView = SerializableMultiSplitView(
      key: newMultiSplitViewKey,
      controller: _controllers[newMultiSplitViewKey],
      axis: direction == MoveDirection.up || direction == MoveDirection.down
          ? Axis.vertical
          : Axis.horizontal,
      children:
          (direction == MoveDirection.up || direction == MoveDirection.left)
              ? [targetBox, movedBox]
              : [movedBox, targetBox],
      onWeightChange: () {
        final newWeights = <double>[];
        for (final a in _controllers[newMultiSplitViewKey]!.areas) {
          newWeights.add(a.weight!);
        }
        _areaMap[newMultiSplitViewKey] = newWeights;
        debugPrint(
            "$newMultiSplitViewKey AreaMap: ${_areaMap[newMultiSplitViewKey]}");
      },
    );

    final targetBoxParentKey =
        _getMovableBoxParentViewRecursive(targetBox, _widgets)?.key;
    final movedBoxParentKey =
        _getMovableBoxParentViewRecursive(movedBox, _widgets)?.key;

    debugPrint(
        "Edge MovedWidgetParentKey: $movedBoxParentKey; TargetWidgetParentKey: $targetBoxParentKey");

    // if both boxes are children of the root multi split view
    if (targetBoxParentKey == null && movedBoxParentKey == null) {
      // 1. get the target box index from the root multi split view
      final targetBoxIndex = _widgets.indexWhere((w) => w.key == targetBox.key);
      // 2. remove target & moved box from the root multi split view
      _widgets.remove(targetBox);
      _widgets.remove(movedBox);
      // 3. remove moved box from the root multi split view
      final movedBoxIndex = _widgets.indexWhere((w) => w.key == movedBox.key);
      // 4. insert the new multi split view to the root multi split view on the target box index
      _widgets.insert(targetBoxIndex, newMultiSplitView);
      // 5. update the areas of the root multi split view
      final rootAreas = List<Area>.from(_controllers[_rootKey]!.areas);
      rootAreas.removeAt(0);
      _controllers[_rootKey]!.areas = rootAreas;
      // 6. update the areas of the new multi split view
      _controllers[newMultiSplitViewKey]!.areas =
          List<Area>.generate(2, (index) => Area());
    }

    // if the target box is a child of the root multi split view, but the moved box is a child of a child multi split view
    if (targetBoxParentKey == null && movedBoxParentKey != null) {
      // 1. get the index of the target box from the root multi split view
      final targetBoxIndex = _widgets.indexWhere((w) => w.key == targetBox.key);
      // 2. remove the moved box from the child multi split view
      (_recursiveWidgetSearchByKey(movedBoxParentKey)!
              as SerializableMultiSplitView)
          .children
          .remove(movedBox);
      // 2.1 remove the parent if empty
      bool movedParentEmpty = false;
      if ((_recursiveWidgetSearchByKey(movedBoxParentKey)!
              as SerializableMultiSplitView)
          .children
          .isEmpty) {
        movedParentEmpty = true;
        _widgets.remove(_recursiveWidgetSearchByKey(movedBoxParentKey)!);
      }
      // 3. remove the target box from the root multi split view
      _widgets.remove(targetBox);
      // 4. insert the new multi split view to the root multi split view on the target box index
      _widgets.insert(targetBoxIndex, newMultiSplitView);
      // 5. update the areas of the new multi split view
      _controllers[newMultiSplitViewKey]!.areas =
          List<Area>.generate(2, (index) => Area());
      // 6. update the areas of the moved box parent, if the moved parent is not empty
      if (!movedParentEmpty) {
        final movedBoxParentAreas =
            List<Area>.from(_controllers[movedBoxParentKey]!.areas);
        movedBoxParentAreas.removeAt(0);
        _controllers[movedBoxParentKey]!.areas = movedBoxParentAreas;
      }
    }

    // if the moved box is a child of the root multi split view, but the target box is a child of a child multi split view
    if (targetBoxParentKey != null && movedBoxParentKey == null) {
      // 1. get the index of the target box in the target parent multi split view
      final targetBoxIndex = (_recursiveWidgetSearchByKey(targetBoxParentKey)!
              as SerializableMultiSplitView)
          .children
          .indexWhere((element) => element.key == targetBox.key);
      // 2. remove the target box from the target parent multi split view
      (_recursiveWidgetSearchByKey(targetBoxParentKey)!
              as SerializableMultiSplitView)
          .children
          .remove(targetBox);
      // 3. remove the moved box from the root multi split view
      _widgets.remove(movedBox);
      // 4. insert the new multi split view to the target parent multi split view on the target box index
      (_recursiveWidgetSearchByKey(targetBoxParentKey)!
              as SerializableMultiSplitView)
          .children
          .insert(targetBoxIndex, newMultiSplitView);
      // 5. update the areas of the target parent multi split view
      final targetAreas =
          List<Area>.from(_controllers[targetBoxParentKey]!.areas);
      _controllers[targetBoxParentKey]!.areas = targetAreas;
      // 6. update the areas of the new multi split view
      _controllers[newMultiSplitViewKey]!.areas =
          List<Area>.generate(2, (index) => Area());
      final rootAreas = List<Area>.from(_controllers[_rootKey]!.areas);
      rootAreas.removeAt(0);
      _controllers[_rootKey]!.areas = rootAreas;
    }

    // if both boxes are children of a child multi split view
    if (targetBoxParentKey != null && movedBoxParentKey != null) {
      // 1. get the index of the target box in the target parent multi split view
      final targetBoxIndex = (_recursiveWidgetSearchByKey(targetBoxParentKey)!
              as SerializableMultiSplitView)
          .children
          .indexWhere((element) => element.key == targetBox.key);
      // 2. remove the target box from the target parent multi split view
      (_recursiveWidgetSearchByKey(targetBoxParentKey)!
              as SerializableMultiSplitView)
          .children
          .remove(targetBox);
      // 3. remove the moved box from the moved parent multi split view
      (_recursiveWidgetSearchByKey(movedBoxParentKey)!
              as SerializableMultiSplitView)
          .children
          .remove(movedBox);
      // 3.a remove the parent if empty
      bool movedParentEmpty = false;
      if ((_recursiveWidgetSearchByKey(movedBoxParentKey)!
              as SerializableMultiSplitView)
          .children
          .isEmpty) {
        movedParentEmpty = true;
        _widgets.remove(_recursiveWidgetSearchByKey(movedBoxParentKey)!);
      }
      // 4. insert the new multi split view to the target parent multi split view on the target box index
      (_recursiveWidgetSearchByKey(targetBoxParentKey)!
              as SerializableMultiSplitView)
          .children
          .insert(targetBoxIndex, newMultiSplitView);
      // 5. update the areas of the target parent multi split view
      final targetAreas =
          List<Area>.from(_controllers[targetBoxParentKey]!.areas);
      _controllers[targetBoxParentKey]!.areas = targetAreas;
      // 6. update the areas of the moved parent multi split view, if the moved parent is not empty
      if (!movedParentEmpty) {
        final movedBoxParentAreas =
            List<Area>.from(_controllers[movedBoxParentKey]!.areas);
        movedBoxParentAreas.removeAt(0);
        _controllers[movedBoxParentKey]!.areas = movedBoxParentAreas;
      }
      // 7. update the areas of the new multi split view
      _controllers[newMultiSplitViewKey]!.areas =
          List<Area>.generate(2, (index) => Area());
    }

    // if (targetBoxParentKey != null) {
    //   (_recursiveWidgetSearchByKey(targetBoxParentKey)!
    //           as SerializableMultiSplitView)
    //       .children
    //       .remove(targetBox);
    //   if ((_recursiveWidgetSearchByKey(targetBoxParentKey)!
    //           as SerializableMultiSplitView)
    //       .children
    //       .isEmpty) {
    //     _widgets.remove(_recursiveWidgetSearchByKey(targetBoxParentKey)!);
    //   }
    //   final targetAreas =
    //       List<Area>.from(_controllers[targetBoxParentKey]!.areas);
    //   targetAreas.removeAt(0);
    //   _controllers[targetBoxParentKey]!.areas = targetAreas;
    //
    //   // get the new widget parent; if null, the parent is root
    //   final movedBoxParentKey =
    //       _getWidgetParentViewRecursive(movedBox, _widgets)?.key;
    //   if (movedBoxParentKey != null) {
    //     final newIdx = (_recursiveWidgetSearchByKey(movedBoxParentKey)!
    //             as SerializableMultiSplitView)
    //         .children
    //         .indexWhere((element) => element.key == movedBox.key);
    //     (_recursiveWidgetSearchByKey(movedBoxParentKey)!
    //             as SerializableMultiSplitView)
    //         .children
    //         .remove(movedBox);
    //     setState(() => (_recursiveWidgetSearchByKey(movedBoxParentKey)!
    //             as SerializableMultiSplitView)
    //         .children
    //         .insert(newIdx, newMultiSplitView));
    //   } else {
    //     // 1. remove the old movable box from the root multi split view
    //     _widgets.remove(movedBox);
    //     // 2. remove the area from the root multi split view
    //     final rootAreas = List<Area>.from(_controllers[_rootKey]!.areas);
    //     rootAreas.removeAt(0);
    //     _controllers[_rootKey]!.areas = rootAreas;
    //     // 3. add the new multi split view in to the target parent view
    //     final newIdx = (_recursiveWidgetSearchByKey(targetBoxParentKey)!
    //     as SerializableMultiSplitView)
    //         .children
    //         .indexWhere((element) => element.key == movedBox.key);
    //     (_recursiveWidgetSearchByKey(targetBoxParentKey)!
    //     as SerializableMultiSplitView)
    //         .children
    //         .remove(movedBox);
    //     setState(() => (_recursiveWidgetSearchByKey(targetBoxParentKey)!
    //     as SerializableMultiSplitView)
    //         .children
    //         .insert(newIdx, newMultiSplitView));
    //     //_widgets.insert(0, newMultiSplitView);
    //   }
    //   _controllers[newMultiSplitViewKey]!.areas =
    //       List<Area>.generate(2, (index) => Area());
    //
    //   _removeEmptyParentViewsRecursive(_widgets);
    //
    //   for (final controller in _controllers.values) {
    //     final listOfAreas = List<Area>.from(controller.areas);
    //     controller.areas = listOfAreas;
    //   }
    // } else {
    //   // the parent widget is root
    //   // create a new multi split view with the two widgets
    //   // remove the old widgets from the widgets
    //
    //   final movedBoxIndex =
    //       _widgets.indexWhere((element) => element.key == movedBox.key);
    //   final targetBoxIndex = _widgets.indexOf(targetBox);
    //   _widgets.removeAt(targetBoxIndex);
    //   final areas = List<Area>.from(_controllers[_rootKey]!.areas);
    //   //_controllers[_rootKey]!.areas = areas;
    //
    //   // get the new widget parent
    //   final movedBoxParentKey =
    //       _getWidgetParentViewRecursive(movedBox, _widgets)?.key!;
    //
    //   if (movedBoxParentKey != null) {
    //     final newIdx = (_recursiveWidgetSearchByKey(movedBoxParentKey)!
    //             as SerializableMultiSplitView)
    //         .children
    //         .indexWhere((element) => element.key == movedBox.key);
    //     (_recursiveWidgetSearchByKey(movedBoxParentKey)!
    //             as SerializableMultiSplitView)
    //         .children
    //         .remove(movedBox);
    //     setState(() => (_recursiveWidgetSearchByKey(movedBoxParentKey)!
    //             as SerializableMultiSplitView)
    //         .children
    //         .insert(newIdx, newMultiSplitView));
    //     _controllers[newMultiSplitViewKey]!.areas =
    //         List<Area>.generate(2, (index) => Area());
    //   } else {
    //     _widgets.remove(movedBox);
    //     _widgets.insert(targetBoxIndex, newMultiSplitView);
    //     areas.removeAt(targetBoxIndex);
    //     _controllers[_rootKey]!.areas = areas;
    //   }
    //
    //   _removeEmptyParentViewsRecursive(_widgets);
    //
    //   for (final controller in _controllers.values) {
    //     final listOfAreas = List<Area>.from(controller.areas);
    //     controller.areas = listOfAreas;
    //   }
    // }
  }
}
